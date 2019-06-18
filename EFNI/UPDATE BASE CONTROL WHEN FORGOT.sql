if(object_id('tempdb.dbo.#TempData') is not null)
begin
    drop table #TempData
end
 
SELECT address3, phone_number, alt_phone
into #TempData
FROM OPENQUERY ([VICIDIAL], 'select address3, phone_number, alt_phone from vicidial_list where list_id = 300000358')

DECLARE @IdCampaign AS VARCHAR(8) SET @IdCampaign = 'EFNI'
UPDATE
	D
SET
	D.Disponible = 0
FROM 
	#TempData A 
	INNER JOIN dbo.Persona B ON B.Cedula COLLATE DATABASE_DEFAULT = A.address3 COLLATE DATABASE_DEFAULT
	INNER JOIN dbo.Telefonos C ON C.IdPersona = B.IdPersona
	INNER JOIN dbo.TelefonosPerCampaign D ON D.IdTelefono = C.IdTelefono AND D.IdCampaign = @IdCampaign
WHERE
	D.Disponible = 1

INSERT INTO dbo.RegistroLlamadas (IdPersona,IdCampania,Telefono,Alt_Phone)
SELECT B.IdPersona,1,A.phone_number as Telefono,A.alt_phone Alt_Phone 
FROM #TempData A 
INNER JOIN dbo.Persona B ON B.Cedula COLLATE DATABASE_DEFAULT = A.address3 COLLATE DATABASE_DEFAULT

DROP TABLE #TempData




