
SELECT  
A.CEDULA,
B.Cedula,
A.NOMBRE AS NIMPORTED,
B.Nombre AS NACTUAL,
C.IdProcedencia,
C.Telefono,
A.TEL#1,
B.IdPersona AS IDACTUAL,
C.IdPersonas AS ANOTHERID
FROM BasesRecibidas..db_banpro_corregida_03072019 A
INNER JOIN Persona B ON A.NOMBRE COLLATE DATABASE_DEFAULT = B.Nombre
LEFT JOIN Telefonos C ON A.TEL#1 = C.Telefono
AND 
B.IdPersona != C.IdPersonas
ORDER BY C.IdPersonas DESC









