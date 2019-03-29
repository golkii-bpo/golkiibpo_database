
IF(OBJECT_ID('tempdb..#TempData') IS NOT NULL)
BEGIN
	DROP TABLE #TempData
END

DECLARE @IdCampaign VARCHAR(8) SET @IdCampaign = 'AsistFam'
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
        ROW_NUMBER() OVER (PARTITION BY A.IdCliente ORDER BY A.IdBancos ASC) [Registros],
        B.Banco 
    FROM 
        dbo.Tarjetas A 
        INNER JOIN dbo.Bancos B ON B.IdBancos = A.IdBancos 
    WHERE a.IdCliente IS NOT NULL AND A.IdBancos BETWEEN 1 AND 5
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
		AND A.StatusCredex IN ('Aprobado Credex','Linea Autorizada','Linea Autorizada','Linea Autorizada')
        AND (A.Salario > 16000 OR A.SalarioInss > 16000)
        AND A.Estado = 1
)

SELECT TOP 2000
	A.Nombre,
	A.Cedula,
	A.Domicilio,
	A.Salario,
	A.Departamento,
	A.Municipios,
	B.Telefono,
	B.Alt_Phone,
	C.Banco [Banco] 
INTO
	#TempData
FROM
    cte_Persona A
    INNER JOIN cte_Telefonos B ON A.IdPersona = B.IdPersona
    INNER JOIN cte_Tarjeta C ON C.IdCliente = A.IdPersona
WHERE
	A.Departamento IN ('MANAGUA')

SELECT * FROM #TempData A

GO

DECLARE 
	@IdCampaign AS VARCHAR(8)

SET @IdCampaign = 'AsistFam'
/*SE HACE UPDATE A LOS TELEFONOS PARA QUE NO SE VUELVAN A LLAMAR*/

UPDATE
	D
SET
	D.Disponible = 0
FROM 
	#TempData A 
	INNER JOIN dbo.Persona B ON B.Cedula = A.Cedula
	INNER JOIN dbo.Telefonos C ON C.IdPersona = B.IdPersona
	INNER JOIN dbo.TelefonosPerCampaign D ON D.IdTelefono = C.IdTelefono AND D.IdCampaign = @IdCampaign
WHERE
	D.Disponible = 1

INSERT INTO dbo.RegistroLlamadas (IdPersona,IdCampania,Telefono,Alt_Phone)
SELECT B.IdPersona,3,A.Telefono,A.Alt_Phone FROM #TempData A INNER JOIN dbo.Persona B ON B.Cedula = A.Cedula
