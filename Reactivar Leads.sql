
UPDATE
    Persona
    SET Disponible = 1,
    Estado = 1,
    FechaModificacion = GETDATE()
from 
    Persona a 
    INNER JOIN RegistroLlamadas B ON A.IdPersona = B.IdPersona
where B.FechaIngreso = '2019-06-12 10:48:48.850'


UPDATE
    TelefonosPerCampaign
    set Disponible = 1
from 
    TelefonosPerCampaign A
    INNER JOIN Telefonos B ON A.IdTelefono = B.IdTelefono
    INNER JOIN Persona C ON B.IdPersona = C.IdPersona
    INNER JOIN RegistroLlamadas D ON D.IdPersona = C.IdPersona
where D.FechaIngreso = '2019-06-12 10:48:48.850'
    AND IdCampaign = 'EFNI'



SELECT TOP(1) * FROM TelefonosPerCampaign

SELECT  MAX(LOTE) FROM TelefonosPerCampaign


select distinct(fechaingreso) from RegistroLlamadas
where FechaIngreso > '2019-06-12'
order by FechaIngreso asc

select * from RegistroLlamadas where FechaIngreso = '2019-06-12 10:48:48.850'

select * from persona where FechaModificacion = '2019-06-12 17:20:56.947'
