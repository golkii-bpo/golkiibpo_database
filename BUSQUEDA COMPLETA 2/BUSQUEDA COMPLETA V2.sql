

CREATE SCHEMA GOLKII_APP
    GO
CREATE PROCEDURE GOLKII_APP.SP_GetPersonaByCedula
    (
        @Cedula NVARCHAR(16)
    )
    AS BEGIN
        SET @Cedula = REPLACE(UPPER(@Cedula),'-','')
        SELECT 
            A.IdPersona,
            A.Nombre,
            A.Cedula,
            A.EDAD,
            IIF(A.Sexo=0,'Femenino','Masculino') [Sexo],
            A.Salario,
            C.Nombre,
            D.Municipio,
            E.Departamento,
            A.Domicilio,
            A.EDAD
        FROM PERSONA A
        LEFT JOIN Credex B ON A.IdPersona = B.IdPersona
        LEFT JOIN StatusCredex C ON B.IdStatus = C.IdStatus
        LEFT JOIN Municipio D ON D.CodMunicipio = CAST(A.Demografia AS INT)
        LEFT JOIN Departamento E ON E.IdDepartamento = D.IdDepartamento
        WHERE CEDULA = @Cedula
    END
    GO
CREATE PROCEDURE GOLKII_APP.SP_GetPersonaByTelefono
    (
        @TELEFONO NVARCHAR(8)
    )
    AS BEGIN
    SELECT 
            A.IdPersona,
            A.Nombre,
            A.Cedula,
            A.EDAD,
            IIF(A.Sexo=0,'Femenino','Masculino') [Sexo],
            A.Salario,
            C.Nombre,
            D.Municipio,
            E.Departamento,
            A.Domicilio,
            A.EDAD
        FROM PERSONA A
        LEFT JOIN Credex B ON A.IdPersona = B.IdPersona
        LEFT JOIN StatusCredex C ON B.IdStatus = C.IdStatus
        LEFT JOIN Municipio D ON D.CodMunicipio = CAST(A.Demografia AS INT)
        LEFT JOIN Departamento E ON E.IdDepartamento = D.IdDepartamento
        INNER JOIN Telefonos F ON F.IdPersonas = A.IdPersona
        WHERE F.Telefono = @TELEFONO
    END
    GO
CREATE PROCEDURE GOLKII_APP.SP_GetTarjetasDePersonaID
    (
        @PersonaID INT
    )
    AS BEGIN
        SELECT A.BANCO 
        FROM Bancos A
        INNER JOIN Tarjetas B ON A.IdBanco = B.IdBanco
        WHERE B.IdPersona = @PersonaID
    END
    GO
CREATE PROCEDURE GOLKII_APP.SP_GetTelefonosDePersonaID
    (
        @PersonaID INT
    )
    AS BEGIN
        SELECT 
            A.Telefono,
            A.Operadora
        FROM Telefonos A
        WHERE IdPersonas = @PersonaID
    END
    GO
