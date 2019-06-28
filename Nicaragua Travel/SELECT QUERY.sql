with cte_base 
as (
    select 
        A.NOMBRE,
        A.CEDULA,
        B.TELEFONO
    from NICATRAV.BD_REF.PERSONA a
    left join bd_ref.telefono b on a.id = b.idpersona
    where a.lote = 2
),
cte_countTel
as (
    select 
    a.Nombre,
    a.Cedula,
    cast(a.telefono as INT) as telefono,
    ROW_NUMBER() over (partition by Nombre,cedula order by TELEFONO) [N]
    from cte_base a
    where a.TELEFONO is not null
),
CTE_DATA
AS (
    select 
        PVT.*
    from cte_countTel a
    PIVOT (MAX(A.Telefono) FOR A.N IN ([1],[2],[3])) PVT
)
SELECT * FROM CTE_DATA
