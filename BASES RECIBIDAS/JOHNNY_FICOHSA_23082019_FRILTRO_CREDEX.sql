
WITH
CTE_BASE
AS(
    SELECT 
        CEDULA COLLATE DATABASE_DEFAULT CEDULA,
        NOMBRES COLLATE DATABASE_DEFAULT CLIENTE,
        DEPARTAMENTO COLLATE DATABASE_DEFAULT DEPARTAMENTO,
        MUNICIPIO COLLATE DATABASE_DEFAULT MUNICIPIO,
        DOMICILIO COLLATE DATABASE_DEFAULT DOMICILIO,
        SALARIO,
        CAST(TELEFONO AS INT) TELEFONO1,
        CAST(TELEFONO1 AS INT) TELEFONO2,
        'FICOHSA' BANCO,
        ID,
        'JOHNNY_FICOHSA_23082019' BASE
    FROM BASESRECIBIDAS.DBO.JOHNNY_FICOHSA_23082019
),
CTE_CLEANING_1
AS(
    SELECT DISTINCT 
    ID,
    BASE,
    TELEFONO  ,
    CEDULA,
    CLIENTE,
    DEPARTAMENTO,
    MUNICIPIO,
    DOMICILIO,
    salario,
    BANCO
    FROM CTE_BASE
    UNPIVOT(TELEFONO FOR TELNO IN (TELEFONO1,TELEFONO2))UP
    WHERE TELEFONO LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
)
,CTE_CLEANER
AS(
    SELECT A.* ,
    SUBSTRING(CAST(A.TELEFONO AS CHAR(8)),1,4) PREFIJO
    FROM CTE_CLEANING_1 A
    LEFT JOIN EFNI.DBO.Telefono B ON A.TELEFONO = B.EFNI_Telefono
    WHERE A.TELEFONO NOT LIKE '[1|2]%'
    OR (
        B.FechaLlamada >= DATEADD(MONTH,-3,GETDATE()) 
        and B.FechaLlamada<= '2019-08-25'
    )
),
CTE_OPERADORA
AS(
    select A.*
    from CTE_CLEANER A
    INNER JOIN GOLKIIDATA.DBO.Prefijos B ON A.PREFIJO  = B.Prefijo 
    WHERE B.Operadora = 'CLARO'
),
CTE_CREDEX
AS(
    SELECT '%'+REPLACE(C.Nombre,' ','%')+'%' AS Nombre,C.Cedula AS CEDULA2,B.Nombre AS STATUS_CREDEX FROM GOLKIIDATA.DBO.CREDEX A
    INNER JOIN GOLKIIDATA.DBO.StatusCredex B ON A.IdStatus = B.IdStatus
    INNER JOIN GOLKIIDATA.DBO.Persona C ON A.IdPersona = C.IdPersona
    WHERE B.Aprobado = 1 OR B.EnProceso = 1
),
CTE_CREDEX2
AS(
    SELECT A.*,B.STATUS_CREDEX FROM CTE_OPERADORA A
    INNER JOIN CTE_CREDEX B ON A.CEDULA = B.Cedula2 AND A.CLIENTE LIKE B.Nombre
)
,
CTE_COUNTER
AS(
    SELECT 
    A.*,
    ROW_NUMBER()OVER(PARTITION BY ID ORDER BY ID) N
    FROM CTE_CREDEX2 A
)
,
CTE_PIVOT
AS(
    SELECT 
        ID,
        BASE,
        CEDULA,
        CLIENTE,
        DEPARTAMENTO,
        MUNICIPIO,
        DOMICILIO,
        SALARIO,
        BANCO,
        MAX([1]) TEL1,
        MAX([2]) TEL2,
        STATUS_CREDEX
    FROM CTE_COUNTER
    PIVOT(MAX(TELEFONO) FOR N IN ([1],[2]))P
    GROUP BY ID,
    BASE,
        CEDULA,
        CLIENTE,
        DEPARTAMENTO,
        MUNICIPIO,
        DOMICILIO,
        SALARIO,
        BANCO,
        STATUS_CREDEX
)

-- -- MENU
-- SELECT A.DEPARTAMENTO,COUNT(A.ID) FICOHSA 
-- FROM CTE_PIVOT A 
-- LEFT JOIN GOLKIIDATA.DBO.Departamento B ON A.DEPARTAMENTO = B.Departamento
-- GROUP BY A.DEPARTAMENTO,B.IdDepartamento
-- ORDER BY B.IdDepartamento


-- -- TIRAJE - MANAGUA (1) TOTAL MOVISTAR
SELECT 
    *
FROM CTE_PIVOT 
WHERE DEPARTAMENTO in ('LEON','ESTELI')
OR MUNICIPIO IN ('JUIGALPA','BOACO','MASAYA','GRANADA')
ORDER BY CEDULA
OFFSET 0 ROWS
FETCH NEXT 3000 ROWS ONLY

-- -- TIRAJE - MANAGUA (1) TOTAL MOVISTAR
-- SELECT 
--     *
-- FROM CTE_PIVOT 
-- WHERE DEPARTAMENTO = 'MASAYA'
-- ORDER BY CEDULA
-- OFFSET 0 ROWS
-- FETCH NEXT 1000 ROWS ONLY