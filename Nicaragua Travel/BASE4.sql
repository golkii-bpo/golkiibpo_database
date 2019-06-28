-- 1000 FICOHSA BANPRO LAFISE
WITH 
CTE_PERSONA
AS(
    SELECT * FROM BASECONTROL.DBO.Persona
    WHERE (Salario > 100000 OR SalarioInss > 100000)
    AND Municipios = 'MANAGUA'
    AND Domicilio IS NOT NULL
),
CTE_BANCOS 
AS (
   SELECT IdBancos,Banco FROM BaseControl.dbo.Bancos 
   WHERE Banco IN ('FICOHSA')
),
CTE_TARJETA
AS (
    SELECT 
        B.IdPersona,
        B.Nombre,
        B.Domicilio,
        B.Salario,
        B.Cedula,
        C.Banco
    FROM BaseControl.dbo.Tarjetas A
    INNER JOIN CTE_PERSONA B ON A.IdCliente = B.IdPersona
    INNER JOIN CTE_BANCOS C ON A.IdBancos = C.IdBancos
),
CTE_TELEFONO
AS(
    SELECT 
    DISTINCT    B.IdPersona,
                B.Telefono,
                ROW_NUMBER() OVER(PARTITION BY B.IdPersona ORDER BY B.Telefono) N
    FROM CTE_TARJETA A
    INNER JOIN BaseControl.dbo.Telefonos B ON A.IdPersona = B.IdPersona 
),
CTE_PIVOT_TELEFONO
AS (
    SELECT 
        *
    FROM CTE_TELEFONO A
    PIVOT (MAX(A.TELEFONO) FOR A.N IN ([1],[2],[3])) P
)

SELECT 
    A.Nombre,
    Domicilio,
    Salario,
    A.Cedula,
    Banco,
    [1] AS TEL1,
    [2] AS TEL2,
    [3] AS TEL3
from CTE_TARJETA A
INNER JOIN CTE_PIVOT_TELEFONO B ON A.IdPersona = B.IdPersona
LEFT JOIN NICATRAV.BD_REF.PERSONA C ON A.Cedula = C.CEDULA COLLATE  DATABASE_DEFAULT
WHERE C.CEDULA IS NULL
