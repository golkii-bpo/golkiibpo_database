USE master
GO
ALTER DATABASE AUTOMATOR SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE AUTOMATOR
GO
CREATE DATABASE AUTOMATOR
GO
USE AUTOMATOR
GO
CREATE TABLE CAMPAIGN
    (
        CAMPAIGN_ID NVARCHAR(15) PRIMARY KEY NOT NULL,
        DESCRIPTION NVARCHAR(150),
        PREFIX CHAR(5),
        CREATE_DATE DATE DEFAULT GETDATE() NOT NULL,
        MODIFY_DATE DATE DEFAULT GETDATE() NOT NULL,
        STATE BIT DEFAULT 1 NOT NULL,
        MIN_NEW_LEAD_LEVEL INT DEFAULT 1000
    )
GO
CREATE PROCEDURE ADD_CAMPAIGN
    (
        @CAMPAIGN_ID CHAR(15),
        @DESCRIPTION NVARCHAR(150),
        @PREFIX CHAR(5)
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM AUTOMATOR.DBO.CAMPAIGN WHERE CAMPAIGN_ID =  @CAMPAIGN_ID)
        BEGIN 
            RAISERROR('LA CAMPAÑA ESPECIFICADA YA EXISTE',10,1)
        END
        ELSE
        BEGIN 
            INSERT INTO AUTOMATOR.DBO.CAMPAIGN VALUES (@CAMPAIGN_ID,@DESCRIPTION,@PREFIX,DEFAULT,DEFAULT,DEFAULT,DEFAULT)
        END
    END
GO
CREATE PROCEDURE DISABLE_CAMPAING
    (
        @CAMPAIGN_ID CHAR(15)
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM AUTOMATOR.DBO.CAMPAIGN WHERE CAMPAIGN_ID =  @CAMPAIGN_ID)
        BEGIN 
            UPDATE AUTOMATOR.DBO.CAMPAIGN 
            SET STATE = 0
            WHERE CAMPAIGN_ID =  @CAMPAIGN_ID
        END
        ELSE
        BEGIN 
            PRINT 'LA CAMPAÑA ESPECIFICADA NO EXISTE'
        END
    END
GO
CREATE PROCEDURE ENABLE_CAMPAING
    (
        @CAMPAIGN_ID CHAR(15)
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM AUTOMATOR.DBO.CAMPAIGN WHERE CAMPAIGN_ID =  @CAMPAIGN_ID)
        BEGIN 
            UPDATE AUTOMATOR.DBO.CAMPAIGN 
            SET STATE = 1
            WHERE CAMPAIGN_ID =  @CAMPAIGN_ID
        END
        ELSE
        BEGIN 
            PRINT 'LA CAMPAÑA ESPECIFICADA NO EXISTE'
        END
    END
GO
CREATE TABLE PROFILE
    (
        PROFILE_ID INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
        CAMPAIGN NVARCHAR(15) FOREIGN KEY REFERENCES AUTOMATOR.DBO.CAMPAIGN(CAMPAIGN_ID),
        NOMBRE NVARCHAR(150),
        SALARIO_MIN INT NOT NULL CHECK(SALARIO_MIN >= 0),
        SALARIO_MAX INT NULL CHECK(SALARIO_MAX >= 0 OR SALARIO_MAX IS NULL),
        CREDEX BIT NOT NULL,
        FORCE_CREDEX BIT NOT NULL,
        FORCE_TC BIT NOT NULL,
        STATE BIT DEFAULT 0
    )
GO
CREATE PROCEDURE ADD_PROFILE
    (
        @CAMPAIGN CHAR(15),
        @NOMBRE NVARCHAR(150),
        @SALARIO_MIN INT,
        @SALARIO_MAX INT,
        @CREDEX BIT,
        @FORCE_CREDEX BIT,
        @FORCE_TC BIT
    )
    AS BEGIN
        IF(EXISTS(SELECT * FROM CAMPAIGN WHERE CAMPAIGN_ID = @CAMPAIGN))
        BEGIN 
            IF(EXISTS(SELECT * FROM PROFILE WHERE 
            @CAMPAIGN = CAMPAIGN AND
            @SALARIO_MIN = SALARIO_MIN AND
            @SALARIO_MAX = SALARIO_MAX AND
            @FORCE_CREDEX = FORCE_CREDEX AND
            @FORCE_TC = FORCE_TC AND 
            @CREDEX = CREDEX
            ))
            BEGIN
                SELECT 
                    @NOMBRE = NOMBRE
                FROM PROFILE WHERE 
                    @CAMPAIGN = CAMPAIGN AND
                    @SALARIO_MIN = SALARIO_MIN AND
                    @SALARIO_MAX = SALARIO_MAX AND
                    @FORCE_CREDEX = FORCE_CREDEX AND
                    @FORCE_TC = FORCE_TC AND 
                    @CREDEX = CREDEX

                    RAISERROR(
                        N'EL PERFIL ESPECIFICADO, YA SE ENCUENTRA REGISTRADO BAJO EL NOMBRE "%S"',
                        10,
                        1,
                        @NOMBRE
                    )
            END
            ELSE
            BEGIN 
                INSERT INTO PROFILE 
                (
                    CAMPAIGN,
                    NOMBRE,
                    SALARIO_MIN,
                    SALARIO_MAX,
                    CREDEX,
                    FORCE_CREDEX,
                    FORCE_TC,
                    [STATE]
                )
                VALUES(
                    @CAMPAIGN,
                    @NOMBRE,
                    @SALARIO_MIN,
                    @SALARIO_MAX,
                    @CREDEX,
                    @FORCE_CREDEX,
                    @FORCE_TC,
                    DEFAULT
                )
            END
        END
        ELSE
        BEGIN
            RAISERROR(
                'NO EXISTE LA CAMAPAÑA ESPECIFICADA',
                10,
                1
            )
        END

    END 
GO
CREATE PROCEDURE ENABLE_PROFILE
    (
        @PROFILE_ID INT
    )
    AS BEGIN 
        IF ((SELECT COUNT(*) FROM PROFILE WHERE PROFILE_ID = @PROFILE_ID) = 1)
        BEGIN
            DECLARE @CAMPAIGN NVARCHAR(15)
            SELECT @CAMPAIGN = CAMPAIGN FROM PROFILE WHERE @PROFILE_ID = PROFILE_ID
            UPDATE PROFILE SET [STATE] = 0 WHERE CAMPAIGN = @CAMPAIGN AND @PROFILE_ID != PROFILE_ID
            UPDATE PROFILE SET [STATE] = 1 WHERE @PROFILE_ID = PROFILE_ID
        END
    END
GO
CREATE TABLE PROFILE_DEP
    (
        PDEP INT,-- FOREIGN KEY REFERENCES GOLKIIDATA.DBO.DEPARTAMENTOS(IDDEPARTAMENTO), SE DEBE VALIDAR A TRAVES DEL PROCEDIMIENTO DE INSERCION
        FKPROFILE INT FOREIGN KEY REFERENCES PROFILE(PROFILE_ID),
        PRIMARY KEY(PDEP,FKPROFILE)
    )
GO
CREATE PROCEDURE ADD_DEP_PROFILE
    (
        @DEPARTAMENTO INT,
        @PROFILE INT
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM GOLKIIDATA.DBO.Departamento WHERE IdDepartamento =  @DEPARTAMENTO)
        BEGIN 
            IF EXISTS(SELECT * FROM PROFILE WHERE PROFILE_ID = @PROFILE)
            BEGIN 
                INSERT INTO PROFILE_DEP VALUES (@DEPARTAMENTO,@PROFILE)
            END
            ELSE
            BEGIN
                RAISERROR(
                    'EL PERFIL ESPECIFICADO NO EXISTE',10,1
                )
            END
        END
        ELSE 
        BEGIN
            RAISERROR (
                'EL DEPARTAMENTO QUE HA ESPECIFICADO NO EXISTE',
                10,
                1
            )
        END
    END
GO
CREATE TABLE PROFILE_BANCOS
    (
        PBANCO INT,-- FOREIGN KEY REFERENCES GOLKIIDATA.DBO.BANCOS(IDBANCO), SE DEBE VALIDAR A TRAVES DEL PROCEDIMIENTO DE INSERCION
        FKPROFILE INT FOREIGN KEY REFERENCES PROFILE(PROFILE_ID),
        PRIMARY KEY(PBANCO,FKPROFILE)
    )
GO
CREATE PROCEDURE ADD_BANK_PROFILE
    (
        @BANCO INT,
        @PROFILE INT
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM GOLKIIDATA.DBO.Bancos WHERE IdBanco =  @BANCO)
        BEGIN 
            IF EXISTS(SELECT * FROM PROFILE WHERE PROFILE_ID = @PROFILE)
            BEGIN 
                INSERT INTO PROFILE_BANCOS VALUES (@BANCO,@PROFILE)
            END
            ELSE
            BEGIN
                RAISERROR(
                    'EL PERFIL ESPECIFICADO NO EXISTE',10,1
                )
            END
        END
        ELSE 
        BEGIN
            RAISERROR (
                'EL BANCO QUE HA ESPECIFICADO NO EXISTE',
                10,
                1
            )
        END
    END
GO
CREATE TABLE LIST
    (
        LIST_ID INT PRIMARY KEY NOT NULL,
        CAMPAIGN_ID NVARCHAR(15) NOT NULL,
        NAME NVARCHAR(100),
        DESCRIPTION NVARCHAR(255),
        CREATE_DATE DATE DEFAULT GETDATE() NOT NULL,
        MODIFY_DATE DATE DEFAULT GETDATE() NOT NULL,
        STATE BIT DEFAULT 1 NOT NULL
    )
GO
CREATE PROCEDURE ADD_LIST
    (
        @LIST_ID INT,
        @CAMPAIGN_ID NVARCHAR(15),
        @NAME NVARCHAR(100),
        @DESCRIPTION NVARCHAR(255)
    )
    AS BEGIN
        IF EXISTS(SELECT * FROM AUTOMATOR.DBO.LIST WHERE LIST_ID = @LIST_ID)
        BEGIN 
            RAISERROR ('LA LISTA ESPECIFICADA YA EXISTE',11,1)
        END
        ELSE
        BEGIN
            INSERT INTO LIST VALUES(@LIST_ID,@CAMPAIGN_ID,@NAME,@DESCRIPTION,DEFAULT,DEFAULT,DEFAULT)

            PRINT 'SE HA INGRESADO LA LISTA AUTOMATICA EXITOSAMENTE'
        END
    END
GO
CREATE FUNCTION GET_PERSONAS_DISPONIBLES
    (
        @CAMPAIGN_ID NVARCHAR(15)
    )
    RETURNS NVARCHAR(MAX)
    AS
    BEGIN
        DECLARE @MYSQL_QUERY NVARCHAR(MAX),@EXECUTE NVARCHAR(MAX)
        SET @MYSQL_QUERY = CONCAT(N'
        SELECT DISTINCT C.phone_number FROM vicidial_lists A
        inner join vicidial_list B ON A.list_id = B.list_id
        inner join vicidial_log C on B.lead_id = C.lead_id
        WHERE A.campaign_id = ''''',RTRIM(LTRIM(@CAMPAIGN_ID)),'''''
        AND call_date >= DATE_ADD(NOW(), INTERVAL -3 MONTH)
        ORDER BY call_date DESC')
        SET @EXECUTE = CONCAT('SELECT * FROM OPENQUERY([VICIDIAL],''', @MYSQL_QUERY,''')')
        
        RETURN @EXECUTE
    END
GO
CREATE FUNCTION GET_LAST_VICI_LIST_ID ()
    RETURNS INT 
    AS BEGIN 
        DECLARE @LIST_ID INT
        SELECT @LIST_ID = cast(list_id as int)  FROM OPENQUERY([AUTOMATOR_VICIDIAL],'select max(list_id) as list_id from vicidial_lists')
        RETURN @LIST_ID
    END
GO
 ALTER PROCEDURE AUTO_LIST
    (
        @CAMPAIGN_ID CHAR(15)
    )
    AS BEGIN 

        IF((SELECT COUNT(*) FROM CAMPAIGN A WHERE CAMPAIGN_ID = @CAMPAIGN_ID AND [STATE] = 1) = 0)
        BEGIN
            RAISERROR('ERROR: No existe ningun perfil activo en la campaña, por lo cual no se puede realizar una seleccion automatica.',10,1)
        END
        ELSE
        IF((SELECT COUNT(*) FROM CAMPAIGN A WHERE CAMPAIGN_ID = @CAMPAIGN_ID AND [STATE] = 1) > 1)
        BEGIN
            RAISERROR('Existe mas de un perfil activo en la campaña, por lo cual no se puede realizar una seleccion automatica.',10,1)
        END
        ELSE BEGIN
            -- DECLARACION DE VARIABLES
            DECLARE @LIST_NAME NVARCHAR(MAX), @LIST_SHORT_NAME NVARCHAR(MAX), @PROFILE_ID INT
            -- INICIALIZACION DE VARIABLES
            SELECT @LIST_SHORT_NAME = LTRIM(RTRIM(B.PREFIX)),@PROFILE_ID = A.PROFILE_ID 
                FROM PROFILE A
                INNER JOIN CAMPAIGN B ON A.CAMPAIGN = B.CAMPAIGN_ID
                WHERE A.CAMPAIGN = @CAMPAIGN_ID AND A.[STATE] = 1
            SET @LIST_NAME = @LIST_SHORT_NAME
            -- CONTRUCCCION SEGUN DEPARTAMENTOS
            SELECT  @LIST_SHORT_NAME += '_'+B.Abreviatura,
                @LIST_NAME += '_'+B.Departamento
            FROM PROFILE_DEP A
            INNER JOIN GOLKIIDATA.DBO.DEPARTAMENTO B ON A.PDEP = B.IdDepartamento
            -- CONSTRUCCION SEGUN FILTROS
            SELECT 
                -- FILTRO SALARIO MINIMO
                @LIST_SHORT_NAME += 
                CASE
                    WHEN A.SALARIO_MIN != 0 THEN '_SMIN'+FORMAT(A.SALARIO_MIN/1000,'N1')+'K' 
                    ELSE ''
                END,
                @LIST_NAME += 
                CASE
                    WHEN A.SALARIO_MIN != 0 THEN '_SMIN'+FORMAT(A.SALARIO_MIN,'N0')+''
                    ELSE '' 
                END,
                -- FILTRO SALARIO MAXIMO
                @LIST_SHORT_NAME += 
                CASE
                    WHEN A.SALARIO_MAX != 0 AND A.SALARIO_MAX IS NOT NULL THEN '_SMAX'+FORMAT(A.SALARIO_MAX/1000,'N1')+'K' 
                    ELSE ''
                END, 
                @LIST_NAME += 
                CASE
                    WHEN A.SALARIO_MAX != 0 AND A.SALARIO_MAX IS NOT NULL THEN '_SMAX'+FORMAT(A.SALARIO_MAX,'N1')+'K' 
                    ELSE ''
                END,
                -- FILTRO FORCE CREDEX
                @LIST_SHORT_NAME += 
                CASE
                    WHEN A.FORCE_CREDEX != 0 THEN '_CDX' 
                    ELSE ''
                END, 
                @LIST_NAME += 
                CASE
                    WHEN A.FORCE_CREDEX != 0 THEN '_CREDEX' 
                    ELSE ''
                END,
                -- FILTRO FORCE TC
                @LIST_SHORT_NAME += 
                CASE
                    WHEN A.FORCE_TC != 0 THEN '_TC' 
                    ELSE ''
                END, 
                @LIST_NAME += 
                CASE
                    WHEN A.FORCE_TC != 0 THEN '_TARJETA' 
                    ELSE ''
                END
            FROM PROFILE A
            WHERE PROFILE_ID = @PROFILE_ID
            SET @LIST_SHORT_NAME +=  '_'+ REPLACE(CONVERT(VARCHAR(8), GETDATE(), 3),'/','')
            SET @LIST_NAME +=  '_'+ REPLACE(CONVERT(VARCHAR(8), GETDATE(), 3),'/','')

            DECLARE @LIST_ID INT
            PRINT 'GET LAST VICI LIST ID'
            BEGIN TRY
                SELECT @LIST_ID = cast(list_id as int) + 1  FROM OPENQUERY([AUTOMATOR_VICIDIAL],'select max(list_id) as list_id from vicidial_lists')
                PRINT CONCAT('ID OBTENIDO CON EXITO ',@LIST_ID)
            END TRY
            BEGIN CATCH
                PRINT 'ERROR AL OBTENER SIGUIENTE VICI LIST ID'
            RETURN ;
            END CATCH
            
            -- EXEC ADD_LIST @LIST_ID,@CAMPAIGN_ID,@LIST_SHORT_NAME,@LIST_NAME
             IF EXISTS(SELECT * FROM AUTOMATOR.DBO.LIST WHERE LIST_ID = @LIST_ID)
                BEGIN 
                    RAISERROR ('LA LISTA ESPECIFICADA YA EXISTE',11,1)
                END
                ELSE
                BEGIN
                    PRINT CONCAT('LIST_ID: ',@LIST_ID)
                    PRINT CONCAT('CAMPAIGN_ID: ',@CAMPAIGN_ID)
                    PRINT CONCAT('SHORT NAME: ',@LIST_SHORT_NAME)
                    PRINT CONCAT('LIST_NAME: ',@LIST_NAME)
                    INSERT INTO LIST VALUES(@LIST_ID,@CAMPAIGN_ID,@LIST_SHORT_NAME,@LIST_NAME,DEFAULT,DEFAULT,DEFAULT)

                DECLARE @ID INT 
                SET @ID = CAST(@LIST_ID AS INT)
                DECLARE @NAME NVARCHAR(20)
                SET @NAME = SUBSTRING(@LIST_SHORT_NAME,1,20)

                INSERT  OPENQUERY 
                (
                    [AUTOMATOR_VICIDIAL],
                    '
                        SELECT 
                            list_id,
                            list_name,
                            campaign_id,
                            active,
                            list_description,
                            list_changedate,
                            list_lastcalldate,
                            reset_time,
                            agent_script_override,
                            campaign_cid_override,
                            am_message_exten_override,
                            drop_inbound_group_override,
                            xferconf_a_number,
                            xferconf_b_number,
                            xferconf_c_number,
                            xferconf_d_number,
                            xferconf_e_number,
                            web_form_address,
                            web_form_address_two,
                            time_zone_setting,
                            inventory_report,
                            expiration_date,
                            na_call_url,
                            local_call_time,
                            web_form_address_three,
                            status_group_id,
                            user_new_lead_limit,
                            inbound_list_script_override,
                            default_xfer_group,
                            daily_reset_limit,
                            resets_today
                        FROM vicidial_lists
                    '
                )
                VALUES
                (
                    @ID,	        --  LIST_ID
                    @NAME,   --  LIST_NAME
                    @CAMPAIGN_ID,	    --  CAMPAIGN_ID
                    'N',	            --  ACTIVE
                    @LIST_NAME,	        -- LIST_DESCRIPTION
                    NULL,	            -- LIST_CHANGEDATE
                    NULL,		        -- LIST_LASTCALLDATE
                    NULL,		        -- RESET_TIME
                    NULL,		        -- AGENT_SCRIPT_OVERRIDE
                    NULL,		        -- CAMPAING_CID_OVERRIDE
                    NULL,		        -- AM_MESSAGE_EXTEND_OVERRIDE
                    NULL,		        -- DROP_INBOUND_GROUP_OVERRIDE
                    NULL,		        -- XFERCONF_A_NUMBER
                    NULL,		        -- XFERCONF_B_NUMBER
                    NULL,		        -- XFERCONF_C_NUMBER
                    NULL,		        -- XFERCONF_D_NUMBER
                    NULL,		        -- XFERCONF_E_NUMBER
                    NULL, 	            -- WEB_FORM_ADDRESS
                    NULL,		        -- WEB_FORM_ADDRESS_TWO
                    'COUNTRY_AND_AREA_CODE', -- TIME_ZONE_SETTING
                    'Y',		        -- INVENTORY_REPORT
                    '2099-12-31',       -- EXPIRATION_DATE
                    NULL,	            -- NA_CALL_URL
                    'campaign',	        -- LOCAL_CALL_TIME
                    NULL,		        -- WEB_FORM_ADDRESS_THREE
                    NULL,		        -- STATUS_GROUP_ID
                    -1,			        -- USER_NEW_LEAD_LIMIT
                    NULL,		        -- INBOUND_LIST_SCRIPT_OVERRIDE
                    '-- -NONE-- -',	    -- DEFAULT_XFER_GROUP
                    -1,		            -- DAILY_RESET_LIMIT
                    0			        -- RESETS_TODAY
                )




                                PRINT 'SE HA INGRESADO LA LISTA AUTOMATICA EXITOSAMENTE'
                            END
                    END
                END 
GO
ALTER PROCEDURE UPLOAD_LEAD_FOR_LIST 
    -- (   
    --     @CAMPAING_ID NVARCHAR(15),
    --     @LIST_ID INT
    -- )
    AS BEGIN

        PRINT 'ACTIVE CAMPAIGNS'
            SELECT CAMPAIGN_ID,CAMPAIGN_NAME,HOPPER_LEVEL,AUTO_DIAL_LEVEL  
            INTO #VICI_ACTIVE_CAMPAIGNS
            FROM GET_VICI_ACTIVE_CAMPAIGNS()

        PRINT 'NEW LEADS IN CAMPAIGNS'
            SELECT * 
            INTO #VICI_NEW_LEADS
            FROM GET_VICI_NEW_LEADS()

        PRINT 'ACTIVE PROFILES AUTOMATOR'
            SELECT * 
            INTO #ACTIVE_PROFILES
            FROM GET_ACTIVE_PROFILES()

        PRINT 'CHARGE CAMPAIGN'
            SELECT 
                A.CAMPAIGN_ID,
                A.HOPPER_LEVEL,
                A.AUTO_DIAL_LEVEL, 
                C.MIN_NEW_LEAD_LEVEL,
                CASE WHEN B.NEW_LEADS IS NULL THEN 0 ELSE B.NEW_LEADS END AS NEW_LEADS,
                C.PROFILE_ID,
                C.PROFILE_NAME,
                C.SALARIO_MIN,
                C.SALARIO_MAX,
                C.FORCE_CREDEX,
                C.FORCE_TC,
                C.CREDEX
            INTO #CHARGE_CAMPAIGN
            FROM #VICI_ACTIVE_CAMPAIGNS A
            LEFT JOIN #VICI_NEW_LEADS B ON  A.CAMPAIGN_ID = B.CAMPAIGN_ID
            INNER JOIN #ACTIVE_PROFILES C ON A.CAMPAIGN_ID = C.CAMPAIGN


        DECLARE CURSOR_AUTOMATOR_CHARGE CURSOR FOR
            SELECT 
                A.CAMPAIGN_ID,
                A.HOPPER_LEVEL,
                A.AUTO_DIAL_LEVEL, 
                A.MIN_NEW_LEAD_LEVEL,
                A.NEW_LEADS,
                A.PROFILE_ID,
                A.PROFILE_NAME,
                A.SALARIO_MIN,
                A.SALARIO_MAX,
                A.CREDEX,
                A.FORCE_CREDEX,
                A.FORCE_TC
            FROM #CHARGE_CAMPAIGN A
            WHERE A.MIN_NEW_LEAD_LEVEL >= A.NEW_LEADS

        OPEN CURSOR_AUTOMATOR_CHARGE

        DECLARE 
        @CAMPAIGN_ID VARCHAR(15),@HOPPER_LEVEL INT,@AUTO_DIAL_LEVEL INT,@MIN_NEW_LEAD_LEVEL INT,@NEW_LEADS INT,@PROFILE_ID INT,@PROFILE_NAME NVARCHAR(MAX),@SMIN FLOAT,@SMAX FLOAT,@CREDEX BIT, @FCREDEX BIT, @FTC BIT

        FETCH NEXT FROM CURSOR_AUTOMATOR_CHARGE
        INTO @CAMPAIGN_ID, @HOPPER_LEVEL, @AUTO_DIAL_LEVEL,@MIN_NEW_LEAD_LEVEL, @NEW_LEADS, @PROFILE_ID,@PROFILE_NAME, @SMIN, @SMAX, @CREDEX, @FCREDEX, @FTC

        WHILE @@FETCH_STATUS = 0
        BEGIN 
            PRINT CONCAT(@CAMPAIGN_ID,SPACE(1),'- PERFIL ACTIVO:',SPACE(1),@PROFILE_NAME)

            DECLARE @CHARGE_LEVEL INT
            SET @CHARGE_LEVEL = CEILING(@AUTO_DIAL_LEVEL * @HOPPER_LEVEL * 2)
            PRINT CONCAT(RTRIM(@CAMPAIGN_ID),SPACE(1),' NEW DIAL CHARGE LEVEL',SPACE(1),@CHARGE_LEVEL)

            IF(@SMAX IS NULL OR @SMAX = 0 )
                BEGIN 
                    SELECT @SMAX = MAX(Salario) FROM GOLKIIDATA.DBO.Persona
                END;
            
            --  SE TIENE QUE HACER UN SWITCH INTELIGENTE SOBRE DONDE CONSULTAR LA DISPONIBILIDAD DE LOS CLIENTES
            PRINT 'PERSONAS NO DISPONIBLES';
                DECLARE @EXECUTE NVARCHAR(MAX)
                CREATE TABLE #TMP (PHONE INT)
                SET @EXECUTE = 'INSERT INTO #TMP '+DBO.GET_PERSONAS_DISPONIBLES(@CAMPAIGN_ID)
                EXEC (@EXECUTE)
                SELECT C.IdPersona 
                INTO #PERSONA_NO_DISPONIBLE
                FROM #TMP A
                INNER JOIN GOLKIIDATA.DBO.Telefonos B ON A.PHONE = B.Telefono
                INNER JOIN GOLKIIDATA.DBO.Persona C ON B.IdPersonas = C.IdPersona;

                DROP TABLE #TMP;
            
            PRINT 'PERSONAS DISPONIBLES'
                SELECT 
                    A.IdPersona,
                    A.Cedula,
                    A.Demografia,
                    A.Domicilio,
                    A.Nombre,
                    A.Salario
                INTO #CTE_PERSONAS_DISPONIBLES
                FROM GOLKIIDATA.DBO.PERSONA A
                LEFT JOIN #PERSONA_NO_DISPONIBLE B ON A.IdPersona = B.IdPersona WHERE B.IdPersona IS NULL

            PRINT 'PERSONAS FILTRADAS';
                WITH CTE_DEMOGRAFIA
                    AS(
                        SELECT 
                            A.CodMunicipio,A.Municipio,B.Departamento 
                        FROM GOLKIIDATA.DBO.Municipio A
                        INNER JOIN GOLKIIDATA.DBO.Departamento B ON A.IdDepartamento = B.IdDepartamento
                        INNER JOIN AUTOMATOR.DBO.PROFILE_DEP C ON C.PDEP = B.IdDepartamento
                        INNER JOIN AUTOMATOR.DBO.PROFILE D ON C.FKPROFILE = @PROFILE_ID
                    )
                SELECT 
                    A.*,
                    C.Departamento,
                    C.Municipio
                INTO #CTE_PERSONAS
                FROM #CTE_PERSONAS_DISPONIBLES A
                INNER JOIN CTE_DEMOGRAFIA C ON A.Demografia = C.CodMunicipio
                WHERE A.Salario >= @SMIN
                AND A.Salario <= @SMAX;

            PRINT 'TARJETAS';
                WITH CTE_TARJETAS
                    AS(
                        SELECT 
                            A.Banco,
                            B.IdPersona,
                            ROW_NUMBER() OVER(PARTITION BY B.IdPersona ORDER BY A.Banco) N 
                        FROM GOLKIIDATA.DBO.Bancos A
                        INNER JOIN GOLKIIDATA.DBO.Tarjetas B ON A.IdBanco = B.IdBanco
                        INNER JOIN #CTE_PERSONAS_DISPONIBLES C ON B.IdPersona = C.IdPersona
                        WHERE A.IdBanco IN (
                            SELECT A.PBANCO FROM AUTOMATOR.DBO.PROFILE_BANCOS A 
                            WHERE A.FKPROFILE = @PROFILE_ID    
                        ) 
                        GROUP BY A.Banco,B.IdPersona
                    )
                SELECT 
                    IdPersona,
                    [1] AS TARJETA1,
                    [2] AS TARJETA2,
                    [3] AS TARJETA3  
                INTO #CTE_TARJETAS_PIVOTED
                FROM CTE_TARJETAS
                PIVOT(MAX(BANCO) FOR N IN ([1],[2],[3]))P;

            PRINT 'TELEFONOS';
                WITH CTE_TELEFONOS
                    AS(
                        SELECT  
                            A.IdPersonas,
                            A.Telefono,
                            ROW_NUMBER() OVER(PARTITION BY A.IdPersonas ORDER BY A.Telefono) N
                        FROM GOLKIIDATA.DBO.Telefonos A
                        INNER JOIN #CTE_PERSONAS_DISPONIBLES B ON A.IdPersonas = B.IdPersona
                        WHERE A.Telefono LIKE '[8|7|5|4][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
                    )
                SELECT 
                    P.IdPersonas,
                    [1] AS TEL1,
                    [2] AS TEL2
                INTO #CTE_TELEFONOS_PIVOTED
                FROM CTE_TELEFONOS
                PIVOT(MAX(TELEFONO) FOR N IN ([1],[2])) P;

            PRINT 'CREDEX';
                WITH CTE_LASTCREDEX
                    AS(
                        SELECT 
                            A.IdPersona,
                            MAX(A.IdCredex) AS LAST_INCOME    
                        FROM GOLKIIDATA.DBO.Credex A
                        INNER JOIN #CTE_PERSONAS_DISPONIBLES B ON A.IdPersona = B.IdPersona
                        INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON A.IdStatus = C.IdStatus 
                        WHERE C.Aprobado = 1
                        GROUP BY (A.IdPersona)
                    )
                SELECT  
                    A.IdPersona,
                    C.Nombre AS STATUSCREDEX
                INTO #CTE_CREDEX
                FROM CTE_LASTCREDEX A
                INNER JOIN GOLKIIDATA.DBO.CREDEX B ON A.IdPersona = B.IdPersona AND A.LAST_INCOME = B.IdCredex
                INNER JOIN GOLKIIDATA.DBO.StatusCredex C ON B.IdStatus = C.IdStatus;

            CREATE TABLE #RESULT
                (
                    Nombre NVARCHAR(MAX),
                    Cedula VARCHAR(16),
                    Domicilio NVARCHAR(MAX),
                    Salario FLOAT,
                    Departamento NVARCHAR(50),
                    Municipio NVARCHAR(50),
                    TEL1 INT,
                    TEL2 INT,
                    TARJETA1 NVARCHAR(50),
                    STATUSCREDEX NVARCHAR(100)
                )   
    
        -- --------------------------------------
        -- --------------------------------------
        -- ALGORITMO DE CARGA DE BASE DE DATOS --
        -- --------------------------------------
        -- --------------------------------------


            IF(@CREDEX = 0 AND @FCREDEX = 0 AND @FTC = 0 )
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    LEFT JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    LEFT JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona WHERE D.IdPersona IS NULL
                END
            ELSE IF(@CREDEX = 0 AND @FCREDEX = 0 AND @FTC = 1)
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    INNER JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    LEFT JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona WHERE D.IdPersona IS NULL
                END
            ELSE IF(@CREDEX = 0 AND @FCREDEX = 1 AND @FTC = 0)
                BEGIN 
                    RAISERROR('NO SE PUEDE GENERAR UN RESULTADO DONDE SE FORCE CREDEX PERO NO SE ADMITAN CUENTAS DE CREDEX',1,10)
                END
            ELSE IF(@CREDEX = 0 AND @FCREDEX = 1 AND @FTC = 1)
                BEGIN 
                    RAISERROR('NO SE PUEDE GENERAR UN RESULTADO DONDE SE FORCE CREDEX PERO NO SE ADMITAN CUENTAS DE CREDEX',1,10)
                END
            ELSE IF(@CREDEX = 1 AND @FCREDEX = 0 AND @FTC = 0 )
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    LEFT JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    LEFT JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona 
                END
            ELSE IF(@CREDEX = 1 AND @FCREDEX = 0 AND @FTC = 1)
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    INNER JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    LEFT JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona 
                END
            ELSE IF(@CREDEX = 1 AND @FCREDEX = 1 AND @FTC = 0)
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    LEFT JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    INNER JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona
                END
            ELSE IF(@CREDEX = 1 AND @FCREDEX = 1 AND @FTC = 1)
                BEGIN 
                    PRINT 'INSERT RESULTADO'
                    INSERT INTO #RESULT
                    SELECT 
                        A.Nombre,
                        A.Cedula,
                        A.Domicilio,
                        A.Salario,
                        A.Departamento,
                        A.Municipio,
                        B.TEL1,
                        B.TEL2,
                        C.TARJETA1,
                        D.STATUSCREDEX
                    FROM #CTE_PERSONAS A
                    INNER JOIN #CTE_TELEFONOS_PIVOTED B ON A.IdPersona = B.IdPersonas
                    INNER JOIN #CTE_TARJETAS_PIVOTED C ON A.IdPersona = C.IdPersona
                    INNER JOIN #CTE_CREDEX D ON A.IdPersona = D.IdPersona
                END
            -- --------------------------------------

            -- TODO:
            -- INSERTAR LISTA

            EXEC DBO.AUTO_LIST @CAMPAIGN_ID

            DECLARE @LIST_ID INT
            PRINT 'GET LAST VICI LIST ID'
            BEGIN TRY
                SELECT @LIST_ID = cast(list_id as int)  FROM OPENQUERY([AUTOMATOR_VICIDIAL],'select max(list_id) as list_id from vicidial_lists')
                PRINT CONCAT('ID OBTENIDO CON EXITO ',@LIST_ID)
            END TRY
            BEGIN CATCH
                PRINT 'ERROR AL OBTENER SIGUIENTE VICI LIST ID'
            RETURN ;
            END CATCH

            PRINT CONCAT('LIST_ID IN VICIDIAL ',@LIST_ID)

            PRINT 'SELECT RESULTADO INTO INSERTION'
            SELECT TOP (@CHARGE_LEVEL) * INTO #INSERTION FROM #RESULT

            -- INSERTAR LEADS
            -------------------------------------------------------------------------------------------------------------------------------------------   
            -- VIEW RESULT
            INSERT OPENQUERY
                ([VICIDIAL],
                '
                    SELECT 
                        entry_date	,
                        modify_date	,
                        status	,
                        user	,
                        vendor_lead_code	,
                        source_id	,
                        list_id	,
                        gmt_offset_now	,
                        called_since_last_reset	,
                        phone_code	,
                        phone_number	,
                        title	,
                        first_name	,
                        middle_initial	,
                        last_name	,
                        address1	,
                        address2	,
                        address3	,
                        city	,
                        state	,
                        province	,
                        postal_code	,
                        country_code	,
                        gender	,
                        date_of_birth	,
                        alt_phone	,
                        email	,
                        security_phrase	,
                        comments	,
                        called_count	,
                        last_local_call_time	,
                        rank	,
                        owner	,
                        entry_list_id	
                    FROM vicidial_list
                ')
                SELECT 
                    GETDATE()				AS [entry_date],
                    NULL               	    AS [modify_date],
                    'NEW'					AS [status],
                    NULL					AS [user],
                    NULL					AS [vendor_lead_code],
                    NULL					AS [source_id],
                    @LIST_ID				AS [list_id],
                    '-6'					AS [gmt_offset_now],
                    'N'					    AS [called_since_last_reset],
                    '505'					AS [phone_code],
                    A.TEL1			        AS [phone_number],
                    NULL					AS [title],
                    SUBSTRING(A.Nombre,1,30)        AS [first_name],
                    NULL					AS [middle_initial],
                    NULL					AS [last_name],
                    SUBSTRING(A.Domicilio,1,100)    AS [address1],
                    A.Salario				AS [address2],
                    A.Cedula				AS [address3],
                    A.Departamento			AS [city],
                    NULL					AS [state],
                    A.Municipio			    AS [province],
                    NULL					AS [postal_code],
                    NULL					AS [country_code],
                    NULL					AS [gender],
                    NULL			        AS [date_of_birth],
                    A.TEL2				    AS [alt_phone],
                    A.STATUSCREDEX			AS [email],
                    NULL					AS [security_phrase],
                    A.TARJETA1				AS [comments],
                    0						AS [called_count],
                    NULL			        AS [last_local_call_time],
                    0						AS [rank],
                    NULL					AS [owner],
                    0						AS [entry_list_id]
                FROM #INSERTION A

         

            -- --------------------------------------
            -- --------------------------------------
            DROP TABLE #INSERTION
            DROP TABLE #RESULT
            DROP TABLE #CTE_CREDEX
            DROP TABLE #PERSONA_NO_DISPONIBLE
            DROP TABLE #CTE_PERSONAS_DISPONIBLES
            DROP TABLE #CTE_PERSONAS
            DROP TABLE #CTE_TARJETAS_PIVOTED
            DROP TABLE #CTE_TELEFONOS_PIVOTED
            -- --------------------------------------

            FETCH NEXT FROM CURSOR_AUTOMATOR_CHARGE
                INTO @CAMPAIGN_ID, @HOPPER_LEVEL, @AUTO_DIAL_LEVEL,@MIN_NEW_LEAD_LEVEL, @NEW_LEADS, @PROFILE_ID,@PROFILE_NAME, @SMIN, @SMAX, @CREDEX, @FCREDEX, @FTC

        END

    CLOSE CURSOR_AUTOMATOR_CHARGE
    DEALLOCATE CURSOR_AUTOMATOR_CHARGE

    DROP TABLE #VICI_ACTIVE_CAMPAIGNS
    DROP TABLE #ACTIVE_PROFILES
    DROP TABLE #VICI_NEW_LEADS
    DROP TABLE #CHARGE_CAMPAIGN
END
GO
-- SE REGISTRA LA CAMPAÑA DE PRUEBA EN LA BASE DE DATOS
EXEC ADD_CAMPAIGN 'TESTE','CAMPAÑA PARA REALIZACION DE PRUEBAS Y ENTRENAMIENTO','TEST'
-- SE AGREGA UN PERFIL DE AUTOCARGA PARA LA CAMPAÑA DE PRUEBA
EXEC ADD_PROFILE 'TESTE','CIERRE DE MES, MANAGUA 10K-25K [F]CREDEX [F]TC',10000,25000,1,1,1
-- SE REGISTRAN TODOS LOS BANCOS EXCEPTO "OTROS" PARA EL PERFIL DE AUTOCARGA DE PRUEBA
EXEC ADD_BANK_PROFILE 1,1
EXEC ADD_BANK_PROFILE 2,1
EXEC ADD_BANK_PROFILE 3,1
EXEC ADD_BANK_PROFILE 4,1
EXEC ADD_BANK_PROFILE 5,1
-- SE AGREGA EL DEPARTAMENTO DE MANAGUA AL PERFIL DE AUTOCARGA DE PRUEBA
EXEC ADD_DEP_PROFILE  3,1
-- SE ACTIVA EL PERFIL DE AUTOCARGA DE PRUEBA
EXEC ENABLE_PROFILE 1
