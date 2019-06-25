
-- select * from NicaTrav_22062019

;WITH CTE_NicaTrav_22062019
AS(
    select 
        [NOMBRE DEL CLIENTE ] AS 'NOMBRE',
        REPLACE(TEL1,'-','') AS TEL1,
        REPLACE(TEL2,'-','') AS TEL2,
        REPLACE(TEL3,'-','') AS TEL3,
        REPLACE(TEL4,'-','') AS TEL4,
        DATO
    from NT_DB_22062019
),
CTE_PersonaInss
AS(
    select
        ROW_NUMBER() OVER (PARTITION BY A.CEDULA ORDER BY A.CEDULA ASC) AS RN,
        A.*
    from REFCOMERCIAL.DBO.infoINSS A
    WHERE CEDULA IS NOT NULL
),
CTE_UniquePersonaInss
as (
    select 
        MAX(RN) as RN,
        A.CEDULA,
        A.NOMBRE
    from CTE_PersonaInss A
    GROUP BY A.CEDULA,A.NOMBRE
),
CTE_PersonaInssTelefono
as (
    select A.NOMBRE,B.CEDULA,A.TEL1,A.TEL2,A.TEL3,A.TEL4,A.DATO
    from CTE_NicaTrav_22062019 A
    left join CTE_UniquePersonaInss B ON A.NOMBRE COLLATE DATABASE_DEFAULT = B.NOMBRE COLLATE DATABASE_DEFAULT
    where tel1 is not null
),
cte_DataTarjeta (IdCliente,Registros,Banco)
AS
(
	SELECT 
        A.IdPersona,
        ROW_NUMBER() OVER (PARTITION BY A.IdPersona ORDER BY A.IdBanco ASC) [Registros],
        B.Banco 
    FROM 
        GOLKIIDATA.dbo.Tarjetas A 
        INNER JOIN GOLKIIDATA.dbo.Bancos B ON B.IdBanco = A.IdBanco
),
cte_Tarjeta(IdCliente,Banco)
AS
(
	SELECT pvt.IdCliente,[1] [Banco] FROM cte_DataTarjeta x PIVOT ( max(x.Banco) FOR x.Registros IN ([1]) ) pvt
)

select A.*,C.Banco
from CTE_PersonaInssTelefono A
LEFT JOIN GOLKIIDATA.dbo.Persona B ON A.CEDULA = B.Cedula
LEFT JOIN cte_Tarjeta C ON C.IDCLIENTE = B.IdPersona

