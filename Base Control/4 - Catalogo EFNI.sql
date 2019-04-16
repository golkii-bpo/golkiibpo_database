DECLARE @IdCampaign VARCHAR(8) SET @IdCampaign = 'EFNI'
;WITH cte_TelefonosLlamados
AS
(
    SELECT 
        A.IdTelefono,
        ROW_NUMBER() OVER (PARTITION BY A.IdTelefono ORDER BY A.IdTelefono)[Registros] 
    FROM 
        TelefonosPerCampaign A 
    WHERE 
        A.IdCampaign = @IdCampaign AND A.Disponible = 0
),cte_PersonasLlamadas
AS
(
    SELECT 
        A.IdPersona 
    FROM
        Telefonos A 
        INNER JOIN cte_TelefonosLlamados B ON A.IdTelefono = B.IdTelefono 
    WHERE 
        B.Registros = 1
        AND A.Estado = 1
        AND A.IdPersona IS NOT NULL
    GROUP BY A.IdPersona
),cte_TelefonosD
AS
(
    SELECT 
        B.IdPersona,
        B.Telefono,
        ROW_NUMBER() OVER (PARTITION BY B.IdPersona ORDER BY B.Telefono DESC) [Registros]
    FROM 
        TelefonosPerCampaign A 
        INNER JOIN Telefonos B ON A.IdTelefono = B.IdTelefono
    WHERE 
        A.IdCampaign = @IdCampaign 
        AND STR(B.Telefono,8,0) LIKE '[5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        AND A.Disponible = 1
        AND B.Estado = 1
        -- AND A.LastCalled IS NULL
),cte_Telefonos
AS
(
    SELECT 
        PVT.IdPersona,
        PVT.[1] [Telefono],
        PVT.[2] [Alt_Phone]
    FROM 
        cte_TelefonosD A 
        PIVOT (MAX(A.Telefono) FOR A.Registros IN ([1],[2],[3])) PVT
        LEFT JOIN cte_PersonasLlamadas B ON B.IdPersona = PVT.IdPersona
    WHERE
        B.IdPersona IS NULL
),cte_DataTarjeta (IdCliente,Registros,Banco)
AS
(
	SELECT 
        A.IdCliente,
        ROW_NUMBER() OVER (PARTITION BY A.IdCliente ORDER BY A.IdBancos DESC) [Registros],
        B.Banco 
    FROM 
        dbo.Tarjetas A 
        INNER JOIN dbo.Bancos B ON B.IdBancos = A.IdBancos 
    WHERE 
        a.IdCliente IS NOT NULL 
        AND A.IdBancos BETWEEN 1 AND 5
),cte_Tarjeta(IdCliente,Banco)
AS
(
	SELECT pvt.IdCliente,[1] [Banco] FROM cte_DataTarjeta x PIVOT ( max(x.Banco) FOR x.Registros IN ([1]) ) pvt
), cte_Persona
AS
(
    SELECT 
        * 
    FROM 
        Persona A
    WHERE
        A.IsWorking = 1
        AND A.Estado = 1
        AND (a.Salario < 20000 OR a.SalarioInss < 20000)
)

SELECT
    A.Departamento,
    COUNT(1) [Menu]
FROM
    cte_Persona A
    INNER JOIN cte_Telefonos B ON A.IdPersona = B.IdPersona
    INNER JOIN cte_Tarjeta C ON C.IdCliente = A.IdPersona
GROUP BY
    A.Departamento
ORDER BY
    A.Departamento ASC


