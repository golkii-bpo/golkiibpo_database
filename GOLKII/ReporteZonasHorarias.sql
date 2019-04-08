
WITH cte_Zonashorarias
 as (
    SELECT 
        Cargo [IDCargo],
        ZonaHorariaReloj,
        ROW_NUMBER() OVER (PARTITION BY Cargo ORDER BY ZonaHorariaReloj ASC) [Conteo]
    FROM ZONAHORARIOCARGO
),
cte_PvtZonashorarias
AS (
    select IDCargo, [1],[2],[3] from cte_Zonashorarias
        PIVOT (
            MAX(ZonaHorariaReloj) FOR Conteo in ([1],[2],[3])
        ) as p
),
cte_ZonasHorariasCargo
as(
    SELECT
        A.Id [IDCargo],
        A.Cargo,
        CASE
            WHEN B.[3] IS NOT NULL THEN CONCAT(B.[1],', ',B.[2],', ',B.[3]) 
            WHEN B.[2] IS NOT NULL THEN CONCAT(B.[1],', ',B.[2]) 
            WHEN B.[1] IS NOT NULL THEN STR(B.[1]) 
        END
            AS ZonasHorarias
    FROM Cargo A
    INNER JOIN cte_PvtZonashorarias B ON A.Id = B.IDCargo
)
SELECT 
    A.Nombre,
    B.Cargo,
    B.ZonasHorarias
FROM Colaboradores A
INNER JOIN cte_ZonasHorariasCargo B ON A.IdCargo = B.IDCargo
WHERE A.Estado = 1
ORDER BY B.ZonasHorarias