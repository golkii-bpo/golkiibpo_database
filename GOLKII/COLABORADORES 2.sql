select Nombre,Cedula,Correo,Extension,Estado,FechaIngreso,IdBiometrico from Colaboradores ORDER BY IdBiometrico

go
INSERT INTO [dbo].[Colaboradores]
( 
 IDCARGO,Nombre,Cedula,Correo,Extension,Estado,FechaIngreso,IdBiometrico
)
VALUES
( 
    1,'OSCAR BACA','','OSCAR.BACA@golkiibpo.com',258,1,GETDATE(),61
),
( 
    1,'GUILLERMO TORRES','0011310890002E','guillermo.torres@golkiibpo.com',264,1,GETDATE(),57
),
( 
   1, 'LAURA MERCYA VILLAVICENCIO','0011601970027L','laura.villavicencio@golkiibpo.com',235,1,GETDATE(),59
),
( 
   1, 'PEDRO MANUEL ESPINOZA','0011208930056B','pedro.espinoza@golkiibpo.com',236,1,GETDATE(),60
),
( 
    1,'CHRISTIAN VALERIA URBINA','0010905920039M','christian.urbina@golkiibpo.com',237,1,GETDATE(),58
)