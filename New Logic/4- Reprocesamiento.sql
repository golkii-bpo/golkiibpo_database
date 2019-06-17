
DECLARE @F AS VARCHAR(10);
SELECT @F = MAX(A.FechaLlamada) FROM EFNI.dbo.Telefono A
SELECT * FROM OPENQUERY([VICIDIA],'select * from vicidial_log a where a.campaign_id = ''EFNI'' and a.call_date > '+@F+'');