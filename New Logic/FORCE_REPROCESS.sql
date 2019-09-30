update efni.dbo.Persona 
set Disponible = 1,
    FechaReprocesamiento = GETDATE()
where UltimaLlamada < DATEADD(MONTH,-3,GETDATE()) and Disponible = 0;

update efni.dbo.Persona 
set Disponible = 0
where UltimaLlamada > DATEADD(MONTH,-3,GETDATE()) and Disponible = 1;

UPDATE efni.dbo.Telefono SET Disponible = 0 WHERE EFNI_Telefono LIKE '2%' and Disponible = 1

UPDATE EFNI.DBO.Telefono 
SET Disponible = 0
WHERE Tipificacion  = 'NAPOL'
AND Disponible = 1