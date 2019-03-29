

	CREATE PROCEDURE GetUpdatePhones ( IN FechaValidacion DATETIME)
	BEGIN
			DROP TABLE IF EXISTS GolkiiPhones;
			
			CREATE TABLE GolkiiPhones
			with cte_TelefonosDirty (Telefono,IdTipificacion,IdCampaign,list_id,CalledCount,CallDate,FullName)
			as
			(
				select 
					a.phone_number,
					a.status,
					a.campaign_id,
					a.list_id,
					a.called_count,
					a.call_date,
					b.full_name
				from 
					vicidial_log a
					inner join vicidial_users b on a.`user` = b.`user`
				where
					a.call_date > FechaValidacion
			),cte_Telefonos(Registros,Telefono,IdTipificacion,IdCampaign,list_id,CalledCount,CallDate,FullName)
			as
			(
				select 
					ROW_NUMBER() OVER (PARTITION BY A.Telefono,A.IdCampaign ORDER BY A.CallDate DESC),
					A.Telefono,
					A.IdTipificacion,
					A.IdCampaign,
					A.list_id,
					ROW_NUMBER() OVER (PARTITION BY A.Telefono,A.IdCampaign ORDER BY A.CallDate ASC),
					A.CallDate,
					A.FullName
				from 
					cte_TelefonosDirty A
			)
			SELECT A.Telefono,A.IdTipificacion,A.IdCampaign,A.list_id 'ListId',A.CalledCount,A.CallDate,A.FullName FROM cte_Telefonos A WHERE A.Registros = 1;
	END;

	CREATE PROCEDURE DropPhones()
	BEGIN
		DROP TABLE IF EXISTS GolkiiPhones;
	END;








