




select * from BasesRecibidas.sys.tables a where a.name like '%banpro%' order by a.create_date desc

;with cte_Base_Banpro (Cedula)
as
(
	select a.Cedula from BasesRecibidas.dbo.DB_BANPRO_22032019 a where a.Cedula like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'
	union
	select a.Cedula from BasesRecibidas.dbo.BOBEDA_BANPRO_PART1 a where a.Cedula like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'
	union
	select a.Cedula from BasesRecibidas.dbo.INTER_BANPRO_26022019 a where a.Cedula like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'
	union
	select a.Cedula from BasesRecibidas.dbo.DB_BANPRO_15012019 a where a.Cedula like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'
)

select a.Cedula into #TempData from cte_Base_Banpro a group by a.Cedula

select * from Persona a inner join #TempData b on a.Cedula = b.Cedula

;with cte_tarjeta
as
(
	select CAST(LEFT(REPLACE(a.Cedula,space(1),space(0)),14) AS VARCHAR(14)) [Cedula] 
	from 
		Persona a
		cross apply
		(
			select top 1 * from Tarjetas b where b.IdCliente = a.IdPersona and b.IdBancos = 5
		) b
),cte_data
as
(
	select CAST(LEFT(REPLACE(a.Cedula,space(1),space(0)),14) AS VARCHAR(14)) [Cedula] from #TempData a 
)
insert into Tarjetas (IdCliente,IdBancos,FechaIngreso,IdProcedencia,Estado)
select b.IdPersona,5,GETDATE(),1,1 from (
	select a.Cedula from cte_data a
	except
	select b.Cedula from cte_tarjeta b
) a inner join Persona b on a.Cedula = b.Cedula