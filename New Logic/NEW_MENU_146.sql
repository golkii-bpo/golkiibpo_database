
USE EFNI
GO
/*
----------------------------------------------------------------------------------
-- PARA AGILIZAR SOLO EJECUTAR LA PRIMERA VEZ ESTA PARTE                        --
                                                                                --
IF OBJECT_ID('tempdb..#PHONES') IS NOT NULL                                     --
    DROP TABLE #PHONES                                                          --
                                                                                --
DECLARE @QUERY NVARCHAR(MAX)                                                    --
SELECT @QUERY = GOLKIIDATA.DBO.QUERY_PHONES_ALREADY_CALLED ();                  --
CREATE TABLE #PHONES (PHONE INT)                                                --
SET @QUERY = 'INSERT INTO #PHONES '+@QUERY                                      --
EXEC (@QUERY)                                                                   --
                                                                                --
-- HASTA AQUI LA PRIMERA EJECUCION                                              --
----------------------------------------------------------------------------------
*/
;
WITH 
    CTE_ALREADY_CALLED
        AS(
            SELECT DISTINCT PHONE FROM #PHONES
        ),
    CTE_PHONES_IN_ACTIVE_LIST
        AS(
            SELECT DISTINCT TELEFONO FROM GOLKIIDATA.DBO.TBL_PHONES_IN_ACTIVE_LIST()
        ),
    CTE_PHONES
        AS(
            SELECT 
                A.IdPersonas,
                A.Telefono,
                SUBSTRING(STR(A.Telefono,8),1,4) PREFIX
            FROM 
                GOLKIIDATA.dbo.Telefonos A
                LEFT JOIN CTE_ALREADY_CALLED B ON A.Telefono = B.PHONE
                LEFT JOIN CTE_PHONES_IN_ACTIVE_LIST C ON A.Telefono = C.TELEFONO
                LEFT JOIN EFNI.dbo.Telefono D ON A.Telefono = D.EFNI_Telefono
            WHERE 
                B.PHONE IS NULL 
                AND 
                C.TELEFONO IS NULL
                AND 
                D.Tipificacion NOT IN ('NAPOL','DC') 
        ),
    CTE_TELEFONO_OPERADORA
        AS(
            SELECT 
                A.IdPersonas,
                A.Telefono,
                ROW_NUMBER() OVER (PARTITION BY A.IdPersonas ORDER BY  A.IdPersonas) N
            FROM CTE_PHONES A
            INNER JOIN GOLKIIDATA.DBO.Prefijos B ON A.PREFIX = B.Prefijo
            WHERE B.Operadora IN (
                'CLARO'
                ,
                'MOVISTAR'
                )
            AND PREFIX LIKE '[5|6|7|8]%'
        ),
    CTE_PIVOT_TELEFONO
        AS(
            SELECT 
                IdPersonas,
                [1] AS TELEFONO1,
                [2] AS TELEFONO2,
                [3] AS TELEFONO3    
            FROM CTE_TELEFONO_OPERADORA
            PIVOT(MAX(Telefono) FOR N IN ([1],[2],[3])  )P
        )

SELECT * 
INTO #CALLABLE_PHONES
FROM CTE_PIVOT_TELEFONO;
----------------------------------------------------------------------------------

WITH
    CTE_DEMOGRAFIA
        AS(
            SELECT 
                A.CodMunicipio,A.Municipio,B.Departamento 
            FROM GOLKIIDATA.DBO.Municipio A
            INNER JOIN GOLKIIDATA.DBO.Departamento B ON A.IdDepartamento = B.IdDepartamento
        ),
    CTE_PERSONA_TELEFONO
        AS(
            SELECT 
                DISTINCT
                A.IdPersona,
                A.Nombre,
                A.Cedula,
                A.Domicilio,
                A.Salario,
                A.Demografia
            FROM GOLKIIDATA.DBO.Persona A
            INNER JOIN GOLKIIDATA.dbo.Telefonos B ON A.IdPersona = B.IdPersonas
        ),
    CTE_PERSONA
        AS(
            SELECT 
                A.IdPersona,
                A.Nombre,
                A.Cedula,
                A.Domicilio,
                A.Salario,
                C.Departamento,
                C.Municipio
            FROM CTE_PERSONA_TELEFONO A
            INNER JOIN #CALLABLE_PHONES B ON A.IdPersona = B.IdPersonas
            LEFT JOIN CTE_DEMOGRAFIA C ON A.Demografia = C.CodMunicipio
            GROUP BY A.IdPersona,
                A.Nombre,
                A.Cedula,
                A.Domicilio,
                A.Salario,
                C.Departamento,
                C.Municipio
        )

SELECT * 
INTO #CALLABLE_PEOPLE
FROM CTE_PERSONA;
----------------------------------------------------------------------------------

WITH
    CTE_TARJETAS
        AS(
            SELECT 
                C.Banco,
                B.IdPersona,
                ROW_NUMBER() OVER(PARTITION BY B.IdPersona ORDER BY C.Banco) N 
            FROM #CALLABLE_PEOPLE A
            INNER JOIN GOLKIIDATA.DBO.Tarjetas B ON A.IdPersona = B.IdPersona
            INNER JOIN GOLKIIDATA.DBO.Bancos C ON B.IdBanco = C.IdBanco
            WHERE C.IdBanco IN (
                (1) -- BAC
                ,
                (2) -- BDF
                ,
                (3) -- FICOHSA
                ,
                (4) -- LAFISE
                ,
                (5) -- BANPRO
                -- ,
                -- (6) -- OTROS
            ) 
            GROUP BY C.Banco,B.IdPersona
        ),
    CTE_TARJETAS_PIVOTED
        AS (
            SELECT 
                IdPersona,
                [1] AS TARJETA1,
                [2] AS TARJETA2,
                [3] AS TARJETA3    
            FROM CTE_TARJETAS
            PIVOT(MAX(BANCO) FOR N IN ([1],[2],[3])  )P
        )

SELECT *
INTO #CARDS_PEOPLE
FROM CTE_TARJETAS_PIVOTED;
----------------------------------------------------------------------------------

WITH
    CTE_LASTCREDEX
        AS(
            SELECT 
                A.IdPersona,
                MAX(B.IdCredex) AS LAST_INCOME    
            FROM #CALLABLE_PEOPLE  A
            INNER JOIN GOLKIIDATA.DBO.Credex B ON A.IdPersona = B.IdPersona
            INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON B.IdStatus = C.IdStatus 
            WHERE C.Aprobado = 1
            GROUP BY (A.IdPersona)
        ),
    CTE_CREDEX
        AS(
            SELECT  
                A.IdPersona,
                C.Nombre AS STATUSCREDEX
            FROM CTE_LASTCREDEX A
            INNER JOIN GOLKIIDATA.DBO.CREDEX B ON A.IdPersona = B.IdPersona AND A.LAST_INCOME = B.IdCredex
            INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON B.IdStatus = C.IdStatus
        )
SELECT *
INTO #CREDEX
FROM CTE_CREDEX;
----------------------------------------------------------------------------------

WITH
    CTE_DATA
        AS(
            SELECT 
                A.Nombre,
                A.Cedula,
                A.Domicilio,
                A.Salario,
                A.Departamento,
                A.Municipio,
                B.TELEFONO1,
                B.TELEFONO2,
                CONCAT(
                    'BANCO #1: ',C.TARJETA1,
                    '; BANCO #2: ',C.TARJETA2,
                    '; BANCO #3: ',C.TARJETA3,
                    '; TELEFONO #3: ',B.TELEFONO3
                ) AS COMMENT,
                D.STATUSCREDEX
            FROM #CALLABLE_PEOPLE A
            INNER JOIN #CALLABLE_PHONES B ON A.IdPersona = B.IdPersonas
            INNER JOIN #CARDS_PEOPLE C ON A.IdPersona = C.IdPersona
            INNER JOIN #CREDEX D ON A.IdPersona = D.IdPersona 
            -- WHERE D.IdPersona IS NULL
        )
        ,
    CTE_MENU
        AS(
            SELECT 
                ''''+Departamento+''',' AS DEPARTAMENTO,
                -- ''''+Municipio+''',' AS MUNICIPIO,
                CASE
                    WHEN (Salario = 0 ) THEN 'UNKNOW'
                    WHEN (Salario BETWEEN 1 AND 5000) THEN '01K-<5K'
                    WHEN (Salario BETWEEN 5000 AND 10000) THEN '05K-10K'
                    WHEN (Salario BETWEEN 10001 AND 15000) THEN '10K-15K'
                    WHEN (Salario BETWEEN 15001 AND 20000) THEN '15K-20K'
                    WHEN (Salario BETWEEN 20001 AND 30000) THEN '20K-30K'
                    ELSE '30K-INFINITY'
                END AS SALKIND,
                1 AS C
            FROM CTE_DATA
        )
--------------------------------------
--              MENU                --
--------------------------------------

    -- SELECT * FROM CTE_MENU A
    -- PIVOT ( SUM(C) FOR SALKIND IN ( [UNKNOW], [01K-<5K],[05K-10K],[10K-15K],[15K-20K],[20K-30K],[30K-INFINITY]) )P

--------------------------------------
--              BASE                --
-- --------------------------------------
    SELECT 
        DISTINCT
        TOP 2000
            * 
        FROM CTE_DATA
        WHERE 
        Departamento 
        IN (
            'Matagalpa'
        )
        AND 
        Salario = 0 
        
--     GO 
    
-- /*
-- DROP TABLE #CALLABLE_PEOPLE
-- DROP TABLE #CALLABLE_PHONES
-- DROP TABLE #CARDS_PEOPLE
-- DROP TABLE #CREDEX
-- */



