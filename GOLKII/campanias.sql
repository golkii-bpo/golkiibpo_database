
USE GOLKII
GO
CREATE  TABLE CAMPANIA
(
    ID CHAR(15) PRIMARY KEY NOT NULL,
    NOMBRE NVARCHAR(150) NOT NULL,
    ABREVIATION CHAR(8) UNIQUE NOT NULL,
    CREATE_DATE DATE NOT NULL DEFAULT GETDATE(),
    MODIFICACION_DATE DATE NOT NULL DEFAULT GETDATE(),
    ESTATE BIT NOT NULL DEFAULT 1
)
GO
CREATE PROCEDURE ADD_CAMPANIA
    (
        @ID CHAR(15),
        @NOMBRE NVARCHAR(150),
        @ABREVIATION CHAR(8),
        @FORCE BIT = 0
    )
    AS BEGIN 
        DECLARE @N CHAR(15)
        IF EXISTS(SELECT * FROM CAMPANIA WHERE ID = @ID)
        BEGIN 
            PRINT 'El ID de campaña especificado pertenece a otra camaña '
        END
        ELSE
        BEGIN 
            IF EXISTS(SELECT * FROM CAMPANIA WHERE NOMBRE = @NOMBRE)
            BEGIN
                IF(@FORCE = 1)
                BEGIN 
                    INSERT INTO CAMPANIA VALUES (@ID,@NOMBRE,@ABREVIATION,GETDATE(),GETDATE(),1)
                END
                ELSE
                BEGIN 
                    PRINT 'EL Nombre espeficado ya se encuentra registrado, agrege el flag ",1" para proceder con la insercion'
                END
            END
            ELSE
            BEGIN
                IF(EXISTS(SELECT * FROM CAMPANIA WHERE ABREVIATION = @ABREVIATION))
                    PRINT 'La abreviacion especificada ya existe y debe ser UNICA, Cambiela e intente nuevamente'
                ELSE
                    INSERT INTO CAMPANIA VALUES (@ID,@NOMBRE,@ABREVIATION,GETDATE(),GETDATE(),1)
            END
        END
    END 
    GO
GO
ADD_CAMPANIA 'EFNI','Equipos Financiados','EFNI' 
GO
ADD_CAMPANIA 'NICTRAV','Nicaragua Travel','NT'
GO
CREATE TABLE COLABORADOR
(
    IDBIOMETRICO INT PRIMARY KEY NOT NULL,
    CARGO INT NOT NULL,
    NOMBRE NVARCHAR(150),
    CEDULA CHAR(14),
    CORREO NVARCHAR(50), 
    VICI_EXTENSION INT,
    ESTADO BIT
)
GO

GO
CREATE PROCEDURE COLABORADOR
(
    @IDBIOMETRICO INT,
    @CARGO INT,
    @NOMBRE NVARCHAR(150),
    @CEDULA CHAR(14),
    @CORREO NVARCHAR(50), 
    @VICI_EXTENSION INT
)
AS BEGIN 
    
END GO

