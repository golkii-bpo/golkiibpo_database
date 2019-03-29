
ALTER TRIGGER [dbo].[TRI_LT_HistorialTelefonos]
ON [dbo].[Telefonos]
FOR UPDATE
AS
BEGIN
	BEGIN TRY
		DECLARE @Lote AS INT,@F AS DATETIME
		SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM Logs.HistorialTelefonos A),0) + 1
		SET @F = GETDATE()

		INSERT INTO Logs.HistorialTelefonos 
		(NewIdPersona,OldIdPersona,IdProcedencia,Lote,Telefono,FechaIngreso)
		SELECT 
			A.IdPersona,B.IdPersona,A.IdProcedencia,@Lote,A.Telefono,@F 
		FROM 
			inserted A INNER JOIN Deleted B ON A.IdTelefono = B.IdTelefono 
		WHERE 
			A.IdPersona != B.IdPersona OR A.IdProcedencia != B.IdProcedencia
		/*POLITICAS PARA ALMACENAR EN UN LOG A LOS TELEFONOS*/
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
END

GO

CREATE TRIGGER [dbo].[Trigger_Ingreso_Telefono]
ON [dbo].[Telefonos]
AFTER INSERT
AS
BEGIN
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO dbo.TelefonosPerCampaign (IdTelefono,IdCampaign,Disponible,Estado)
		SELECT  A.IdTelefono,B.IdCampaign,1,1 FROM Inserted A INNER JOIN Vicidial.Campaigns B ON 1 = 1
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END

GO

ALTER TRIGGER [dbo].[Trigger_Modificar_Telefono]
ON [dbo].[Telefonos]
FOR UPDATE
AS
BEGIN
	UPDATE B SET B.Estado = A.Estado FROM Inserted A INNER JOIN dbo.TelefonosPerCampaign B ON B.IdTelefono = A.IdTelefono
END
