-- 
--
-- 
--      LISTA DE YA MARCADOS
--          CHINANDEGA LEON
-- 			'Granada','Carazo','Masaya','Rivas'
-- 
--
-- 
-- 
-- 
--
-- 
--
-- 
--

WITH
CTE_DATA
AS
(
	SELECT 
	CEDULA,
	NOMBRE,
	TEL#1 T1,
	TEL2 T2,
	PRODUCTO TTARJETA
	FROM BasesRecibidas.DBO.db_tarjetas_banpro_02072019
	WHERE TEL#1 LIKE '[8|5|7|4][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_INSS
AS (
	SELECT 
		CEDULA,
		SUM(SALARIO) SALARIO
	FROM db_inss_29062019_1
	GROUP BY CEDULA
),
CTE_MUNICIPIOS
AS(
	SELECT 
		A.CodMunicipio,
		A.Municipio,
		B.Departamento
	FROM GOLKIIDATA.DBO.Municipio A
	INNER JOIN GOLKIIDATA.DBO.Departamento B ON A.IdDepartamento = B.IdDepartamento
),
CTE_FINISHED
AS (
	SELECT 
		A.CEDULA,
		A.NOMBRE,
		CAST(A.T1 AS INT) T1,
		CAST(A.T2 AS INT) T2,
		A.TTARJETA,
		B.SALARIO,
		C.Municipio,
		C.Departamento
	FROM CTE_DATA A
	INNER JOIN CTE_MUNICIPIOS C ON CAST(SUBSTRING(A.CEDULA,1,3) AS INT) = C.CodMunicipio
	LEFT JOIN  CTE_INSS B ON A.CEDULA = B.CEDULA
	WHERE A.CEDULA LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'
)
,
CTE_VICIDIAL_STATUS
as (
    SELECT  status code,status_name FROM OPENQUERY([VICIDIAL],'select `STATUS`,status_name from vicidial_campaign_statuses WHERE campaign_ID = ''EFNI''')
),
cte_all
as (
	select A.*,
			B.Tipificacion,
			c.status_name 
		from CTE_FINISHED A
	LEFT JOIN EFNI.DBO.Telefono B ON A.T1 = B.EFNI_Telefono
	left join CTE_VICIDIAL_STATUS c on b.Tipificacion = c.code
)
SELECT 
TOP 2000
        a.* 
INTO #TEMP_LLAMADOSBASEBANPRO
FROM cte_all a
where Departamento 
IN 
(
	'Managua'
)
EXCEPT
select * from LLAMADOSBASEBANPRO

-- select Departamento ,
--     COUNT(Departamento) N
-- from cte_all
-- where Departamento NOT IN 
-- (
-- 	'CHINANDEGA', 'LEON',
-- 	'Granada','Carazo','Masaya','Rivas',
-- 'Matagalpa','Jinotega','Esteli'
-- )
-- GROUP BY DEPARTAMENTO
-- ORDER BY N
-- drop table #TEMP_LLAMADOSBASEBANPRO
-- INSERT INTO LLAMADOSBASEBANPRO
-- select * from #TEMP_LLAMADOSBASEBANPRO