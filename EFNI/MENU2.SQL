use BaseControl
go

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
        a.* ,
        CASE
            WHEN (Salario IS NULL OR SalarioInss IS NULL) THEN 'NULL'
            WHEN (Salario < 5000 OR SalarioInss < 5000) THEN '<5K'
            WHEN (Salario BETWEEN 5000 AND 10000 OR SalarioInss BETWEEN 5000 AND 10000) THEN '5K-10K'
            WHEN (Salario BETWEEN 10001 AND 15000 OR SalarioInss BETWEEN 10001 AND 15000) THEN '10K-15K'
            WHEN (Salario BETWEEN 15001 AND 20000 OR SalarioInss BETWEEN 15001 AND 20000) THEN '15K-20K'
            WHEN (Salario BETWEEN 20001 AND 30000 OR SalarioInss BETWEEN 20001 AND 30000) THEN '20K-30K'
            ELSE '>30K'
        END AS SALKIND
    from   
        Persona a 
        inner join cte_PersonaDisponibles b on a.IdPersona = b.IdPersona 
    where 
        a.IsWorking = 1
        and a.Estado = 1
        -- and (a.SalarioInss >= 9000 OR A.Salario >= 9000)
        -- and (
        --         a.Departamento in ('managua')
        --         -- --OR
        --         -- --A.Municipios IN ('BLUEFIELDS')
        -- )
        -- and  a.StatusCredex is null
        -- AND StatusCredex IN ('Linea Autorizada','Aprobado Credex')
        -- Suspendida   -> Por mora menor a 60 dias
        -- Cancelado    -> Inicio tramite de apertura de cuenta pero no termino
        -- En proceso   -> Cuenta en tramite de apertura
)
-- -- MENU
-- SELECT  
--     A.Departamento,
--     A.SALKIND AS SALARIO,
--     -- A.Municipios,
--     COUNT(A.IdPersona) [CANTIDAD]
-- FROM cte_Personas A
-- INNER join cte_Tarjeta  B on B.IdCliente = A.IdPersona
-- inner join cte_Telefonos    C on C.IdPersona = A.IdPersona
-- WHERE A.Departamento IS NOT NULL
-- GROUP BY A.Departamento,A.SALKIND
-- -- --GROUP BY A.Municipios
-- ORDER BY [CANTIDAD]

-- Carga de base
select 
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








