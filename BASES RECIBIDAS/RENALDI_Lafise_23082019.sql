WITH
CTE_BASE_RECIBIDA
AS(
    select 
    CAST(NOMBRE AS NVARCHAR(255)) COLLATE DATABASE_DEFAULT NOMBRE,
    'LAFISE' TARJETA,
    REPLACE(A.NUIC,'-','') COLLATE DATABASE_DEFAULT AS CEDULA,
    TEL1,
    TEL2,
    TEL3,
    'RENALDI_LAFISE_SIGNATU_23082019$' BASE,
    ID
    from RENALDI_LAFISE_SIGNATU_23082019$ A
    UNION
    select 
    CAST(NOMBRE AS NVARCHAR(255)) COLLATE DATABASE_DEFAULT NOMBRE,
    'LAFISE'  TARJETA,
    '[ESCRIBA LA CEDULA AQUI]' CEDULA,
    STR(TEL1,8),
    STR(TEL2,8),
    STR(TEL3,8),
    'RENALDI_LAFISE_CLASICA_23082019$' BASE,
    ID
    from RENALDI_LAFISE_CLASICA_23082019$
)
,
CTE_UNPIVOT_BASE
AS(
    SELECT 
    NOMBRE,
    TARJETA,
    CEDULA,
    TELEFONOS,
    BASE,
    ID
    FROM CTE_BASE_RECIBIDA A
    UNPIVOT(TELEFONOS FOR NoTelefono IN (TEL1,TEL2,TEL3))UP
    WHERE TELEFONOS LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_CLEANING_1
AS(
    SELECT A.*
    FROM CTE_UNPIVOT_BASE A
    WHERE TELEFONOS NOT LIKE '2%'
),
CTE_CLEANING_2
AS(
    SELECT MIN(ID) ID,NOMBRE,TARJETA,CEDULA,TELEFONOS,BASE,SUBSTRING(TELEFONOS,1,4) PREFIJO
    FROM CTE_CLEANING_1 
    GROUP BY NOMBRE,TARJETA,CEDULA,TELEFONOS,BASE
),
CTE_PREFIJOS
AS(
    SELECT A.* FROM CTE_CLEANING_2 A
    INNER JOIN GOLKIIDATA.DBO.Prefijos B ON A.PREFIJO = B.Prefijo
    -- WHERE OPERADORA = 'MOVISTAR'
)
,
CTE_COUNTER
AS(
    SELECT *,
        ROW_NUMBER()OVER(PARTITION BY CEDULA,NOMBRE ORDER BY CEDULA,NOMBRE)N
    FROM CTE_PREFIJOS
),
CTE_DATA
AS( 
    SELECT NOMBRE,TARJETA,CEDULA,BASE,MAX([1]) TEL1,MAX([2]) TEL2,MAX([3]) TEL3,SUBSTRING(CEDULA,1,3) DEMOGRAFIA FROM CTE_COUNTER
    PIVOT(MAX(TELEFONOS) FOR N IN([1],[2],[3]))P
    GROUP BY NOMBRE,TARJETA,CEDULA,BASE
),
CTE_DATA_DEMO
AS(
SELECT 
    A.*,
    B.Municipio,
    C.Departamento,
    C.IdDepartamento
FROM CTE_DATA A
LEFT JOIN GOLKIIDATA.DBO.MUNICIPIO B ON CAST(B.CodMunicipio AS CHAR(3)) = A.DEMOGRAFIA
LEFT JOIN GOLKIIDATA.DBO.Departamento C ON B.IdDepartamento = C.IdDepartamento
)


SELECT 
    Departamento,
    COUNT(*)
FROM CTE_DATA_DEMO
WHERE Departamento NOT IN ('LEON','CHINANDEGA','Masaya','Granada','Rivas','Boaco','Chontales','Jinotega','Matagalpa')
GROUP BY Departamento,IdDepartamento
ORDER BY IdDepartamento



-- SELECT * 
-- FROM CTE_DATA_DEMO
-- WHERE Departamento IN ('Jinotega',
-- 'Matagalpa')