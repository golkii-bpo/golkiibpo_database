-- 1000 FICOHSA BANPRO LAFISE
-- SE DEBE HACER EL FILTRO UNICO POR BANCOS


WITH 
CTE_PERSONA
AS(
    SELECT * FROM BASECONTROL.DBO.Persona
    -- WHERE (Salario BETWEEN 50000 AND 90000) OR (SalarioInss  BETWEEN 50000 AND 90000)
    WHERE (Salario > 30000 OR SalarioInss > 30000)
    AND DEPARTAMENTO = 'CHONTALES'
    -- AND Domicilio IS NOT NULL
),
CTE_BANCOS 
AS (
   SELECT IdBancos,Banco FROM BaseControl.dbo.Bancos 
--    WHERE Banco IN ('FICOHSA','BANPRO','LAFISE')
),
CTE_TARJETA
AS (
    SELECT 
        B.IdPersona,
        B.Nombre,
        B.Domicilio,
        B.Salario,
        B.Cedula,
        C.Banco,
        B.Departamento,
        B.Municipios
    FROM BaseControl.dbo.Tarjetas A
    INNER JOIN CTE_PERSONA B ON A.IdCliente = B.IdPersona
    INNER JOIN CTE_BANCOS C ON A.IdBancos = C.IdBancos
),
CTE_TELEFONO
AS(
    SELECT 
    DISTINCT    B.IdPersona,
                B.Telefono
    FROM CTE_TARJETA A
    INNER JOIN BaseControl.dbo.Telefonos B ON A.IdPersona = B.IdPersona 
    WHERE Telefono LIKE '[5|8|7][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_COUNT_TEL
as (
    select  A.*,
            ROW_NUMBER() OVER(PARTITION BY a.IdPersona ORDER BY a.Telefono) N
    from CTE_TELEFONO A
    GROUP by a.IdPersona,a.Telefono
),
CTE_PIVOT_TELEFONO
AS (
    SELECT 
        *
    FROM CTE_COUNT_TEL A
    PIVOT (MAX(A.TELEFONO) FOR A.N IN ([1],[2],[3])) P
),
cte_base
as (
    SELECT 
        A.Nombre,
        Domicilio,
        Salario,
        A.Cedula,
        Banco,
        [1] AS TEL1,
        [2] AS TEL2,
        [3] AS TEL3,
        A.Departamento,
        A.Municipios
    from CTE_TARJETA A
    INNER JOIN CTE_PIVOT_TELEFONO B ON A.IdPersona = B.IdPersona
    LEFT JOIN NICATRAV.BD_REF.PERSONA C ON A.Cedula = C.CEDULA COLLATE  DATABASE_DEFAULT
    WHERE C.CEDULA IS NULL
)
select * 
into #tempbase
from cte_base;


with
CTE_PERSONAS_NO_DISPONIBLES
AS(
select address3 COLLATE DATABASE_DEFAULT as cedula 
 from openquery
([VICIDIAL],
'select b.address3
from vicidial_lists a
inner join vicidial_list b on a.list_id = b.list_id
where list_name like ''nt%''
and b.address3 is not NULL
and b.address3 != ''''')
),
CTE_FILTER_CEDULA
AS (
    SELECT * 
    FROM CTE_PERSONAS_NO_DISPONIBLES 
    WHERE CEDULA LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]' 
)
select * 
into #tempExclude
from CTE_FILTER_CEDULA;


WITH CTE_DATA
AS(
    select 
        DISTINCT
        A.Nombre,
        A.Domicilio,
        A.Salario,
        A.Cedula,
        A.Departamento,
        A.TEL1,
        A.TEL2,
        A.TEL3
    from #tempbase a
    left join #tempExclude b on a.Cedula collate database_default = b.cedula collate database_default 
    where b.cedula is null
)
-- SELECT 
--     Departamento,
--     COUNT(Departamento)
-- FROM CTE_DATA
-- GROUP BY Departamento


select * 
from CTE_DATA



DROP TABLE #tempbase
DROP TABLE #tempExclude
