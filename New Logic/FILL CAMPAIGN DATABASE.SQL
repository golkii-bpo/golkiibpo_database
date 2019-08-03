USE NICTRAV;

INSERT INTO NICTRAV.DBO.Persona
SELECT 
A.IdPersona,
NULL,   --  ULTIMA LLAMADA
0,      --  CCMENSUAL
0,      --  CCGLOBAL
0,      --  CCREPROCESO
1,      --  DISPONIBLE
0,      --  LOTE
NULL    --  FECHA REPROCESO
FROM GOLKIIDATA.DBO.PERSONA A

INSERT INTO NICTRAV.dbo.Telefono
SELECT 
    Telefono,
    IdPersonas,
    NULL,   -- TIPIFICACION,
    NULL,   -- FECHA LLAMADA
    0,      -- CC
    0,      -- REPROCESADA
    NULL,   -- FECHA REPROCESO
    0,      -- LOTE
    1       -- DISPONIBLE
FROM GOLKIIDATA.dbo.Telefonos





