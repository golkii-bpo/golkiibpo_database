

SELECT * FROM Persona WHERE cedula = '0012101800017D'	
SELECT B.Banco FROM Tarjetas A INNER JOIN Bancos B ON A.IdBanco = B.IdBanco WHERE IdPersona = 447012 
SELECT * FROM Credex WHERE IdPersona = 447012

SELECT * FROM Persona WHERE IdPersona = 114682
SELECT * FROM Persona WHERE IdPersona = 2905546	


UPDATE PERSONA 
    SET IdProcedencia = 4
WHERE IdPersona = 34212

UPDATE Telefonos
SET IdProcedencia = 4
WHERE Telefono  = 85837500


UPDATE PERSONA 
SET NOMBRE ='Marcia Elena Morales'
    ,
    IdProcedencia = 4
WHERE IdPersona = 359276


SELECT * FROM Persona WHERE IDPERSONA  = 119956
SELECT * FROM Telefonos WHERE IdPersonas = 119956

UPDATE Telefonos
SET IdPersonas = 119956
WHERE Telefono ='86456742'







