
WITH
CTE_BaseRecibida
AS (
    select 
        LTRIM(RTRIM(REPLACE(CEDULA,'-',''))) COLLATE DATABASE_DEFAULT As Cedula,
        LTRIM(RTRIM(NOMBRE)) COLLATE DATABASE_DEFAULT AS Nombre,
        'BANPRO' AS BANCO,
        PRODUCTO as TTarjeta,
        LTRIM(RTRIM(REPLACE([value],'-',''))) COLLATE DATABASE_DEFAULT As Telefono
    from BasesRecibidas..DB_BANPRO_2_25072019 
    CROSS APPLY
    string_split(replace([tel#1],' ','/'),'/')
),
Cte_limpia
as (
    SELECT DISTINCT * FROM CTE_BaseRecibida A
    WHERE [Telefono] LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    AND A.Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-Z]'
    and A.Telefono is not null
    and A.Telefono != ''
    
),
CTE_COUNT_TELS
AS(
    select 
        *,
        ROW_NUMBER() OVER (PARTITION BY Telefono ORDER BY CEDULA) N
    from Cte_limpia 
),
CTE_REPEATED
AS(
    SELECT Telefono FROM CTE_COUNT_TELS WHERE N > 1
),
CTE_ALREADY_CALLED
AS  (
    SELECT EFNI_Telefono FROM EFNI.DBO.Telefono a
    LEFT JOIN EFNI.DBO.CampaingStatuses B ON A.Tipificacion = B.IdStatus
where  A.Disponible = 0


),
CTE_PREPIVOT
AS (
    select A.*,
    ROW_NUMBER() OVER(PARTITION BY A.Telefono ORDER BY A.CEDULA) N
    from Cte_limpia A
    LEFT JOIN CTE_REPEATED B ON A.Telefono = B.Telefono
    LEFT JOIN CTE_ALREADY_CALLED C ON A.Telefono = C.EFNI_Telefono
    WHERE B.Telefono IS NULL 
    AND B.Telefono IS NULL
    AND A.Telefono LIKE '[5-8]%'
),
CTE_PIVOTED
AS(
    SELECT * FROM CTE_PREPIVOT
    PIVOT(MAX(TELEFONO) FOR N IN ([1],[2]))P
),
CTE_DATA
AS
(

SELECT  
        A.[1] AS TEL1,
        CASE 
            WHEN A.Nombre IS NOT NULL THEN A.NOMBRE
            ELSE 
            CONCAT(B.NOMBRE1,SPACE(1),B.NOMBRE2,SPACE(2),B.APELLIDO1,SPACE(1),B.APELLIDO2) 
        END AS NOMBRE,
        B.DOMICILIO_ASE AS DOMICILIO,
        SUM(B.SALARIO) AS SALARIO,
        A.Cedula,
        A.[2] AS TEL2,
        A.TTarjeta
FROM CTE_PIVOTED A
LEFT JOIN BasesRecibidas..db_inss_29062019_1 B ON REPLACE(B.Cedula,'-','') = REPLACE(A.Cedula,'-','')
GROUP BY 
    A.Nombre,
    A.BANCO,
    A.Cedula,
    A.TTarjeta,
    A.[1],
    A.[2],
    B.DOMICILIO_ASE,
    B.NOMBRE1,B.NOMBRE2,B.APELLIDO1,B.APELLIDO2
),
CTE_READY
AS (
    SELECT A.*,B.Municipio,C.Departamento FROM CTE_DATA A 
    LEFT JOIN Municipio B ON SUBSTRING(A.Cedula,1,3) = B.CodMunicipio
    LEFT JOIN Departamento C ON B.IdDepartamento = C.IdDepartamento
)

    SELECT 
        ''''+Departamento+''',' Departamento,
        COUNT(*) N
    FROM CTE_READY A
    INNER JOIN GOLKIIDATA.DBO.Prefijos B ON A.TEL1 LIKE CONCAT(B.Prefijo,'%')
    WHERE 
    Departamento NOT IN ('MATAGALPA','JINOTEGA','Leon','Chinandega','Masaya','Granada','Atlantico Sue','Atlantico Norte','Chontales','Managua','Carazo','Esteli','Rivas','Boaco')
    AND B.Operadora ='CLARO'
    GROUP BY Departamento
    ORDER BY N

-- SELECT * FROM CTE_READY A
--     INNER JOIN GOLKIIDATA.DBO.Prefijos B ON A.TEL1 LIKE CONCAT(B.Prefijo,'%')
-- WHERE 
-- Departamento IN ('Carazo',
-- 'Esteli',
-- 'Rivas',
-- 'Boaco')
-- AND
-- Departamento NOT IN ('MATAGALPA','JINOTEGA','Leon','Chinandega','Masaya','Granada','Managua','Carazo',
-- 'Esteli',
-- 'Rivas',
-- 'Boaco')
--  AND B.Operadora ='CLARO'