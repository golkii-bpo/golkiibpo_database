


select 
    * 
from
    (
        select 
            d.Tipificacion [Tipificacion], count(1) [catalogo]
        from 
            Persona a 
            inner join Telefonos b on a.IdPersona = b.IdPersona
            inner join TelefonosPerCampaign c on c.IdTelefono = b.IdTelefono and c.IdCampaign = 'EFNI'
            inner join Vicidial.campaignStatuses d on d.IdTipificacion = c.IdTipificacion and d.CampaingId = 'EFNI'
        where 
            a.IdProcedencia = 3
            and (d.CustomerContact != 1 or d.HumanAnswered != 1 or d.Completed != 1 and d.IsSale != 1)
            -- and c.IdTipificacion in ('NE')
        group by
            -- c.IdTipificacion
            d.Tipificacion
    ) a
order by
    a.catalogo desc


-- select * from Vicidial.campaignStatuses a where a.HumanAnswered = 1

