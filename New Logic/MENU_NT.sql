USE NICTRAV;

go
DECLARE @SALARIO_MIN FLOAT
SET @SALARIO_MIN = 20000;
DECLARE @BANCOS TABLE (IDB INT)
INSERT INTO @BANCOS 
VALUES  
        -- (1) -- BAC
        -- ,
        -- (2) -- BDF
        -- ,
        (3) -- FICOHSA
        ,
        (4) -- LAFISE
        ,
        (5) -- BANPRO
        -- ,
        -- (6) -- OTROS
        ; 
WITH
CTE_PERSONAS_DISPONIBLES AS
(
    SELECT 
        *
    FROM NICTRAV.DBO.PERSONA 
    WHERE disponible =1
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
    INNER JOIN GOLKIIDATA.DBO.Persona B ON A.NICTRAV_Persona = B.IdPersona
    LEFT JOIN CTE_DEMOGRAFIA C ON CAST(B.Demografia AS INT) = C.CodMunicipio
    WHERE B.Salario > @SALARIO_MIN
),
CTE_TARJETAS
AS(
    SELECT 
        A.Banco,
        B.IdPersona,
        ROW_NUMBER() OVER(PARTITION BY B.IdPersona ORDER BY A.Banco) N 
    FROM GOLKIIDATA.DBO.Bancos A
    INNER JOIN GOLKIIDATA.DBO.Tarjetas B ON A.IdBanco = B.IdBanco
    INNER JOIN CTE_PERSONAS_DISPONIBLES C ON B.IdPersona = C.NICTRAV_Persona
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
        ROW_NUMBER() OVER(PARTITION BY A.IdPersonas ORDER BY A.Telefono) N
    FROM GOLKIIDATA.DBO.Telefonos A
    INNER JOIN CTE_PERSONAS_DISPONIBLES B ON A.IdPersonas = B.NICTRAV_Persona
    WHERE A.Telefono LIKE '[8|7|5|4][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_TELEFONOS_PIVOTED
AS(
    SELECT 
        P.IdPersonas,
        [1] AS TEL1,
        [2] AS TEL2
    FROM CTE_TELEFONOS
    PIVOT(MAX(TELEFONO) FOR N IN ([1],[2])) P
),
-- CTE_LASTCREDEX
-- AS(
--     SELECT 
--         A.IdPersona,
--         MAX(A.IdCredex) AS LAST_INCOME    
--     FROM GOLKIIDATA.DBO.Credex A
--     INNER JOIN CTE_PERSONAS_DISPONIBLES B ON A.IdPersona = B.NICTRAV_Persona
--     INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON A.IdStatus = C.IdStatus 
--     WHERE C.Aprobado = 1
--     GROUP BY (A.IdPersona)
-- ),
-- CTE_CREDEX
-- AS(
--     SELECT  
--         A.IdPersona,
--         C.Nombre AS STATUSCREDEX
--     FROM CTE_LASTCREDEX A
--     INNER JOIN GOLKIIDATA.DBO.CREDEX B ON A.IdPersona = B.IdPersona AND A.LAST_INCOME = B.IdCredex
--     INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON B.IdStatus = C.IdStatus
-- ),
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
        C.TARJETA1
        -- D.STATUSCREDEX
    FROM CTE_PERSONAS A
    INNER JOIN CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
    INNER JOIN CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
    -- INNER JOIN CTE_CREDEX D ON A.IdPersona = D.IdPersona
    WHERE Cedula LIKE '001%'
),
CTE_MENU
AS(
    SELECT Departamento,
        COUNT(Departamento) N
    FROM CTE_DATA
    GROUP BY DEPARTAMENTO
),
CTE_BASE
AS(
    SELECT 
    TOP 2000
    * 
    FROM CTE_DATA
    WHERE Departamento 
    IN (
        'MANAGUA'
    )
)
-- SELECT * FROM CTE_MENU ORDER BY N DESC
SELECT * FROM CTE_BASE
