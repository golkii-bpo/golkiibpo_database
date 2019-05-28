if(OBJECT_ID('tempdb..#TempData') is not null)
begin
    drop table #TempData
end

go

;with cte_data
as
(
    select a.Nombres,a.Cedula,a.departamento,a.municipio,a.edad,a.sexo, a.domicilio,a.salario from BasesRecibidas.dbo.DB_06052019 a 
), cte_uData
as
(
    select a.Cedula from cte_data a
    except
    select b.Cedula from Persona b
    -- left join [Persona] b on a.Cedula = b.Cedula where b.Cedula is null
), cte_Unique
as
(
    select a.* from cte_data a inner join cte_uData b on a.Cedula = b.Cedula
)

select * into #TempData from cte_Unique a

insert into Persona (Nombre,Cedula,Domicilio,Municipios,Edad,Sexo,IdProcedencia,Estado,Salario)
select
    a.Nombres,
    a.Cedula,
    a.Domicilio,
    a.Municipio,
    a.Edad,
    IIF(a.Sexo = 'MASCULINO',1,0),
    1,
    1,
    a.Salario
from
    #TempData a

;with cte_data
as
(
    select 
        b.IdPersona, c.Telefono, c.Telefono1 
    from 
        #TempData a 
        inner join Persona b on a.Cedula = b.Cedula 
        inner join BasesRecibidas.dbo.DB_06052019 c on a.Cedula = c.Cedula
), cte_Telefonos
as
(
    select b.IdPersona,b.Tel from cte_data a unpivot (Tel for Title in (a.Telefono,a.Telefono1)) b 
    left join Telefonos c on c.Telefono = b.Tel
    where c.IdTelefono is null and b.Tel is not null
)

insert into Telefonos (IdPersona,Telefono,IdProcedencia,FechaIngreso)
select a.IdPersona,a.Tel,1,GETDATE() from cte_Telefonos a


;with cte_data
as
(
    select c.IdPersona,
    case b.banco
        when 'BANCO DE LA PRODUCCION S' then 5
        when 'BANCENTRO' then 4
        when 'Banco Lafise Bancentro' then 4
        when 'BANCO DE AMERICA CENTRAL' then 1
        when 'BANPRO' then 5
        when 'Banco Ficohsa Nicaragua' then 3
        else null
    end [IdBanco]
    from #TempData a inner join Persona c on c.Cedula = a.Cedula inner join BasesRecibidas.dbo.DB_06052019 b on a.Cedula = b.Cedula
)
insert into Tarjetas(IdCliente,IdBancos,IdProcedencia,Estado,FechaIngreso)
select a.IdPersona,a.IdBanco,1,1,GETDATE() from cte_data a where a.IdBanco is not null

-- select a.banco,count(1) from cte_data a group by a.banco
BANCO DE LA PRODUCCION S 5
BANCENTRO 4
Banco Lafise Bancentro 4
BANCO DE AMERICA CENTRAL 1
BANPRO 5
Banco Ficohsa Nicaragua, S.A3

select * from Bancos

;with cte_oldData
as
(
    select 
        a.IdPersona,b.IdBancos,b.IdTarjetaCliente
    from 
        Persona a 
        inner join Tarjetas b on a.IdPersona = b.IdCliente
),cte_bancos
as
(
    select a.IdTarjetaCliente, ROW_NUMBER() OVER (PARTITION BY a.IdPersona,a.IdBancos order by a.IdTarjetaCliente desc) [Ct] from cte_oldData a 
)

delete b from cte_bancos a inner join Tarjetas b on a.IdTarjetaCliente = b.IdTarjetaCliente where a.Ct > 1

;with cte_oldData
as
(
    select 
        a.IdPersona,b.IdBancos,b.IdTarjetaCliente
    from 
        Persona a 
        inner join Tarjetas b on a.IdPersona = b.IdCliente
), cte_data
as
(
    select 
    b.IdPersona,
    case a.banco
        when 'BANCO DE LA PRODUCCION S' then 5
        when 'BANCENTRO' then 4
        when 'Banco Lafise Bancentro' then 4
        when 'BANCO DE AMERICA CENTRAL' then 1
        when 'BANPRO' then 5
        when 'Banco Ficohsa Nicaragua' then 3
        when 'SIMAN' then 6
        when 'BAC' then 1
        when 'BDF' then 2
        when 'NULL' then null
        else 7
    end [IdBancos]
     from BasesRecibidas.dbo.DB_06052019 a inner join Persona b on a.Cedula = b.Cedula
), cte_except
as
(
    select b.IdPersona,b.IdBancos from cte_data b where b.IdBancos is not null
    except
    select a.IdPersona,a.IdBancos from cte_oldData a
)

insert into Tarjetas (IdCliente,IdBancos,IdProcedencia)
select a.IdPersona,a.IdBancos,1 from cte_except a

GO

;with cte_telefonos
as
(
    select c.IdPersona,STR(b.Tel,8,0) Tel 
    from BasesRecibidas.dbo.DB_06052019 a unpivot (Tel for D in (a.Telefono,a.Telefono1)) b 
    inner join Persona c on c.Cedula = b.Cedula
),cte_data
as
(
    select a.* from cte_telefonos a left join Telefonos b on a.Tel = STR(b.Telefono,8,0) where b.Telefono is null
)
insert into Telefonos(IdPersona,Telefono,FechaIngreso,Estado)
select a.IdPersona,a.Tel,GETDATE(),1 from cte_data a where a.Tel like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'


