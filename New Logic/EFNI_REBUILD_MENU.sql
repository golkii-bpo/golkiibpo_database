
USE EFNI;
GO



DECLARE @BANCOS TABLE (IDB INT)
INSERT INTO @BANCOS 
VALUES  
        (1) -- BAC
        ,
        (2) -- BDF
        ,
        (3) -- FICOHSA
        ,
        (4) -- LAFISE
        ,
        (5) -- BANPRO
        ,
        (6) -- OTROS
        ; 
WITH
CTE_PERSONAS_DISPONIBLES AS
(
    SELECT 
        *
    FROM EFNI.DBO.PERSONA 
    WHERE Disponible = 1
),
CTE_DEMOGRAFIA
AS(
    SELECT 
        A.CodMunicipio,A.Municipio,B.Departamento 
    FROM GOLKIIDATA.DBO.Municipio A
    INNER JOIN GOLKIIDATA.DBO.Departamento B ON A.IdDepartamento = B.IdDepartamento
),
CTE_PERSONAS
AS(
    SELECT 
        B.*,
        C.Departamento,
        C.Municipio
    FROM CTE_PERSONAS_DISPONIBLES A
    INNER JOIN GOLKIIDATA.DBO.Persona B ON A.EFNI_Persona = B.IdPersona
    LEFT JOIN CTE_DEMOGRAFIA C ON B.Demografia = C.CodMunicipio
)
,
CTE_TARJETAS
AS(
    SELECT 
        A.Banco,
        B.IdPersona,
        ROW_NUMBER() OVER(PARTITION BY B.IdPersona ORDER BY A.Banco) N 
    FROM GOLKIIDATA.DBO.Bancos A
    INNER JOIN GOLKIIDATA.DBO.Tarjetas B ON A.IdBanco = B.IdBanco
    INNER JOIN CTE_PERSONAS_DISPONIBLES C ON B.IdPersona = C.EFNI_Persona
    WHERE A.IdBanco IN (
            SELECT * FROM @BANCOS
    ) 
    GROUP BY A.Banco,B.IdPersona
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
),
CTE_TELEFONOS
AS(
    SELECT  
        A.IdPersonas,
        A.Telefono,
        C.Tipificacion,
        ROW_NUMBER() OVER(PARTITION BY A.IdPersonas ORDER BY A.Telefono) N
    FROM GOLKIIDATA.DBO.Telefonos A
    INNER JOIN CTE_PERSONAS_DISPONIBLES B ON A.IdPersonas = B.EFNI_Persona
    INNER JOIN EFNI.DBO.Telefono C ON A.Telefono = C.EFNI_Telefono
    WHERE 
    -- c.Tipificacion in ('AA','A','B','NA')
    C.Tipificacion NOT IN ('NAPOL','DC') 
    AND 
    C.Disponible = 1
    AND (
        A.Operadora IN (
            -- 'CLARO'
            -- ,
            'MOVISTAR'
            )
        -- OR Operadora IS NULL
    )
),
CTE_TELEFONOS_PIVOTED
AS(
    SELECT 
        P.IdPersonas,
        MAX([1]) AS TEL1,
        MAX([2]) AS TEL2
    FROM CTE_TELEFONOS
    PIVOT(MAX(TELEFONO) FOR N IN ([1],[2])) P
    GROUP BY P.IdPersonas
)
,
CTE_LASTCREDEX
AS(
    SELECT 
        A.IdPersona,
        MAX(A.IdCredex) AS LAST_INCOME    
    FROM GOLKIIDATA.DBO.Credex A
    INNER JOIN CTE_PERSONAS_DISPONIBLES B ON A.IdPersona = B.EFNI_Persona
    INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON A.IdStatus = C.IdStatus 
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
),
CTE_DATA
AS(
    SELECT 
        A.Nombre,
        A.Cedula,
        A.Domicilio,
        A.Salario,
        A.Departamento,
        A.Municipio,
        B.TEL1,
        B.TEL2,
        C.TARJETA1,
        D.STATUSCREDEX
    FROM CTE_PERSONAS A
    INNER JOIN CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
    INNER JOIN CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
    INNER JOIN CTE_CREDEX D ON A.IdPersona = D.IdPersona 
    -- WHERE D.IdPersona IS NULL
)
,
CTE_MENU
AS(
    SELECT ''''+Departamento+''',' AS DEPARTAMENTO,

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

SELECT * FROM CTE_MENU A
PIVOT ( SUM(C) FOR SALKIND IN ( [UNKNOW], [01K-<5K],[05K-10K],[10K-15K],[15K-20K],[20K-30K],[30K-INFINITY]) )P

--------------------------------------
--              BASE                --
-- --------------------------------------
--     SELECT 
--         * 
--     FROM CTE_DATA
--     WHERE 
--     Departamento 
--     IN (
-- 'Chinandega'
--     )
--     AND 
--     Salario BETWEEN 10001 AND 20000
 
    




