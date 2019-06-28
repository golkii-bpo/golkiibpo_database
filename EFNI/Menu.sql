if(object_id('tempdb.dbo.#TempData') is not null)
begin
    drop table #TempData
end

;with cte_Data
as
(
    select 
        b.IdPersona,
        b.Telefono,
        ROW_NUMBER() OVER (PARTITION BY b.IdPersona ORDER BY b.Telefono DESC) [Registros]
    from 
        TelefonosPerCampaign a 
        inner join Telefonos b on a.IdTelefono = b.IdTelefono 
    where 
        a.IdCampaign = 'EFNI' and a.Disponible = 1 and STR(b.Telefono,8,0) like '[5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' and b.Estado = 1 and a.Estado = 1
),
cte_PersonaDisponibles
as
(
    select a.IdPersona from cte_Data a group by a.IdPersona
    
),
cte_Telefonos
AS
(
    SELECT 
        PVT.IdPersona,
        PVT.[1] [Telefono],
        PVT.[2] [Alt_Phone]
    FROM 
        cte_Data A 
        PIVOT (MAX(A.Telefono) FOR A.Registros IN ([1],[2],[3])) PVT
),
cte_DataTarjeta (IdCliente,Registros,Banco)
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
        A.IdBancos BETWEEN 1 AND 7
        AND A.IdBancos != 6

),
cte_Tarjeta(IdCliente,Banco)
AS
(
	SELECT pvt.IdCliente,[1] [Banco] FROM cte_DataTarjeta x PIVOT ( max(x.Banco) FOR x.Registros IN ([1]) ) pvt
),
cte_Personas
as
(
    select 
        a.* 
    from   
        Persona a 
        inner join cte_PersonaDisponibles b on a.IdPersona = b.IdPersona 
    where 
        a.IsWorking = 1
        and a.Estado = 1
        and (a.SalarioInss >= 18000 OR A.Salario >= 18000)
        and (
                a.Departamento in ('managua')
                -- --OR
                -- --A.Municipios IN ('BLUEFIELDS')
        )
        -- and  a.StatusCredex is null
        -- AND StatusCredex IN ('Linea Autorizada','Verificado','Aprobado Credex')
        -- Suspendida   -> Por mora menor a 60 dias
        -- Cancelado    -> Inicio tramite de apertura de cuenta pero no termino
        -- En proceso   -> Cuenta en tramite de apertura
)
-- MENU
-- SELECT  
--     A.Departamento,
--     -- A.Municipios,
--     COUNT(A.IdPersona) [MENU]
-- FROM cte_Personas A
-- INNER join cte_Tarjeta  B on B.IdCliente = A.IdPersona
-- inner join cte_Telefonos    C on C.IdPersona = A.IdPersona
-- GROUP BY A.Departamento
-- -- --GROUP BY A.Municipios
-- ORDER BY [MENU]

-- Carga de base
select top 4000
    a.Nombre,
    a.Cedula,
    a.Domicilio,
    a.Departamento,
    a.Municipios,
    a.SalarioInss [Salario],
    c.Telefono,
    c.Alt_Phone,
    b.Banco
INTO
	#TempData
from
    cte_Personas a
    INNER join cte_Tarjeta b on b.IdCliente = a.IdPersona
    inner join cte_Telefonos c on c.IdPersona = a.IdPersona
    
select * from #TempData



/*SE HACE UPDATE A LOS TELEFONOS PARA QUE NO SE VUELVAN A LLAMAR*/

DECLARE @IdCampaign AS VARCHAR(8) SET @IdCampaign = 'EFNI'
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
SELECT B.IdPersona,1,A.Telefono,A.Alt_Phone FROM #TempData A INNER JOIN dbo.Persona B ON B.Cedula = A.Cedula

DROP TABLE #TempData









