;WITH cte_DataTelefonos
AS
(
    select A.IdPersona,A.Telefono,ROW_NUMBER() OVER (PARTITION BY A.Telefono ORDER BY A.Telefono) [Registros] from Telefonos A WHERE STR(A.Telefono,8,0) Like '[,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' AND A.Estado = 1
), cte_Telefonos
AS
(
    SELECT 
        PVT.IdPersona,
        PVT.[1] [Telefono],
        PVT.[2] [AltPhone] 
    FROM 
        cte_DataTelefonos A 
        PIVOT (MAX(A.Telefono) FOR A.Registros IN ([1],[2])) PVT
),cte_DataTarjeta (IdCliente,Registros,Banco)
AS
(
    SELECT 
        A.IdCliente,
        ROW_NUMBER() OVER (PARTITION BY A.IdCliente ORDER BY A.IdBancos ASC) [Registros],
        B.Banco 
    FROM 
        dbo.Tarjetas A 
        INNER JOIN dbo.Bancos B ON B.IdBancos = A.IdBancos 
    WHERE a.IdCliente IS NOT NULL AND A.IdBancos BETWEEN 3 AND 5
),cte_Tarjeta(IdCliente,Banco)
AS
(
    SELECT pvt.IdCliente,[1] [Banco] FROM cte_DataTarjeta x PIVOT ( max(x.Banco) FOR x.Registros IN ([1]) ) pvt
),cte_Persona 
AS
(
    SELECT 
        *
    FROM 
        Persona A
    WHERE   
        A.IsWorking = 1
        AND A.Departamento = 'MANAGUA'
        AND (A.Salario >= 17000 OR A.SalarioInss >= 17000)
)

SELECT
    COUNT(1)
FROM
    cte_Persona A 
    INNER JOIN cte_Telefonos B ON A.IdPersona = B.IdPersona
    INNER JOIN cte_Tarjeta C ON A.IdPersona = C.IdCliente