
/*

    NO SE HA GUARDADO NADA 
    FAVOR VALIDARLO
    CREAR TABLA PARA PODER GUARDAR DE UNA MEJOR MANERA LOS DATOS

*/

IF(OBJECT_ID('tempdb..#TempData') IS NOT NULL)
BEGIN
	DROP TABLE #TempData
END

DECLARE @IdCampaign VARCHAR(8) SET @IdCampaign = 'EFNI'
;WITH cte_DataTelefono
AS
(
    SELECT 
        A.IdPersona,
        A.Telefono,
        ROW_NUMBER() OVER (PARTITION BY A.Telefono,A.IdPersona ORDER BY A.Telefono) Registro 
    FROM 
        dbo.Telefonos A
    WHERE
        A.Estado = 1
        AND STR(A.Telefono,8,0) LIKE '[5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),cte_Telefonos
AS
(
    select PVT.IdPersona,PVT.[1] [Telefono], PVT.[2] [Alt_Phone] from cte_DataTelefono A PIVOT (MAX(A.Telefono) FOR A.Registro IN ([1],[2])) PVT
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
    WHERE 
        a.IdCliente IS NOT NULL 
        AND A.IdBancos BETWEEN 3 AND 5
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
        AND A.Departamento IN ('MANAGUA')
        AND (A.Salario > 17000 OR A.SalarioInss>17000)
)

SELECT
    A.Nombre,
    A.Cedula,
    A.Departamento,
    A.Municipios,
    A.Domicilio,
    A.Salario,
    A.SalarioInss,
    C.Banco,
    B.Telefono,
    B.Alt_Phone
INTO
    #TempData
FROM
    cte_Persona A
    INNER JOIN cte_Telefonos B ON A.IdPersona = B.IdPersona
    INNER JOIN cte_Tarjeta C ON C.IdCliente = A.IdPersona



