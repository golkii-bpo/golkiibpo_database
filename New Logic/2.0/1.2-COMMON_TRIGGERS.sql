USE GOLKIIDATA_2
GO
CREATE TRIGGER TRI_AU_PERSONA 
ON Persona 
AFTER UPDATE 
AS
BEGIN
    DECLARE @F AS DATE SET @F = GETDATE();
    UPDATE A SET A.FechaModificacion = @F FROM Persona A INNER JOIN inserted B ON A.IdPersona = B.IdPersona
END
GO
CREATE TRIGGER TRI_AI_Tarjetas
ON Tarjetas
AFTER INSERT 
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM Tarjetas A),0) + 1
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote, A.FechaIngreso = @F,A.FechaModificacion = @F FROM Tarjetas A INNER JOIN inserted B ON A.IdBanco = B.IdBanco AND A.IdPersona = B.IdPersona
END
GO
CREATE TRIGGER TRI_AU_Tarjetas
ON Tarjetas
AFTER UPDATE 
AS
BEGIN
	IF(SESSION_CONTEXT(N'TRI_U_Tarjetas')IS NULL)
	BEGIN
		DECLARE @Lote AS INT, @F AS DATE 
		SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM Tarjetas A),0) + 1 ; 
		SET @F = GETDATE();
		UPDATE A SET A.Lote = @Lote,A.FechaModificacion = @F FROM Tarjetas A INNER JOIN inserted B ON A.IdBanco = B.IdBanco AND A.IdPersona = B.IdPersona
	END ELSE BEGIN EXEC sp_set_session_context 'TRI_U_Tarjetas', NULL END
END
GO
CREATE TRIGGER TRI_AI_Credex
ON Credex
AFTER INSERT
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    
	SET @Lote = ISNULL((SELECT MAX(Lote) FROM Credex),0) + 1;
    SET @F = GETDATE()
    
	UPDATE A SET A.Lote = @Lote,A.FechaIngreso = @F FROM Credex A INNER JOIN inserted B ON A.IdPersona = B.IdPersona
END
GO 
CREATE TRIGGER TRI_AU_Credex
ON Credex
AFTER UPDATE
AS
BEGIN
	IF(SESSION_CONTEXT(N'TRI_U_Credex') IS NULL)
	BEGIN
		EXEC sp_set_session_context 'TRI_U_Credex', 1
		DECLARE @Lote AS INT, @F AS DATE 
		SET @Lote = ISNULL((SELECT MAX(Lote) FROM Credex),0) + 1;
		SET @F = GETDATE()
		UPDATE A SET A.Lote = @Lote,A.FechaModificacion = @F FROM Credex A INNER JOIN inserted B ON A.IdPersona = B.IdPersona
	END ELSE BEGIN EXEC sp_set_session_context 'TRI_U_Credex', NULL END
END
GO
CREATE TRIGGER TRI_AI_Telefono
ON Telefonos
AFTER INSERT
AS
BEGIN
	DECLARE @F AS DATE,@Lote AS INT; 
	SET @Lote = ISNULL((SELECT MAX(Lote) FROM Telefonos),0) + 1; 
	SET @F = GETDATE()
	UPDATE A SET A.Lote = @Lote, A.FechaIngreso = @F FROM Telefonos A INNER JOIN inserted B ON A.Telefono = B.Telefono
END
GO
CREATE TRIGGER TRI_AU_Telefono
ON Telefonos
AFTER UPDATE
AS
BEGIN
	IF(SESSION_CONTEXT(N'TRI_U_Telefono') IS NULL)
	BEGIN
		EXEC sp_set_session_context 'TRI_U_Telefono', 1;
		DECLARE @F AS DATE,@Lote AS INT;
		SET @Lote = ISNULL((SELECT MAX(Lote) FROM Telefonos),0) + 1; 
		SET @F = GETDATE()
		UPDATE A SET A.Lote = @Lote, A.FechaModificacion = @F FROM Telefonos A INNER JOIN inserted B ON A.Telefono = B.Telefono
	END ELSE BEGIN EXEC sp_set_session_context 'TRI_U_Telefono', NULL END
END
GO