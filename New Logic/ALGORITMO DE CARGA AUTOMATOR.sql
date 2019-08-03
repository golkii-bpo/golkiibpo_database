PRINT 'ACTIVE CAMPAIGNS'
SELECT CAMPAIGN_ID,CAMPAIGN_NAME,HOPPER_LEVEL,AUTO_DIAL_LEVEL 
INTO #VICI_ACTIVE_CAMPAIGNS
FROM OPENQUERY([VICIDIAL],
'select campaign_id,campaign_name,hopper_level,auto_dial_level 
from vicidial_campaigns 
where active = ''Y''
and campaign_id not in (''calioutb'',''atencion'')')

PRINT 'NEW LEADS IN CAMPAIGNS'
SELECT * 
INTO #VICI_NEW_LEADS
FROM OPENQUERY([VICIDIAL],
'SELECT 
	B.campaign_id,
	COUNT(LEAD_ID) NEW_LEADS
FROM vicidial_list A
INNER JOIN vicidial_lists B ON A.list_id = B.list_id
INNER JOIN vicidial_campaigns  C ON B.campaign_id = C.campaign_id
WHERE A.`status`=''NEW'' AND B.active = ''Y''
AND  C.active = ''Y''
and C.campaign_id not in (''calioutb'',''atencion'')
GROUP BY campaign_id')

PRINT 'ACTIVE PROFILES AUTOMATOR'
SELECT  A.PROFILE_ID,
        A.CAMPAIGN,
        A.NOMBRE AS PROFILE_NAME,
        A.SALARIO_MIN,
        A.SALARIO_MAX,
        A.FORCE_CREDEX,
        A.FORCE_TC,
        A.[STATE],
        A.CREDEX,
        B.MIN_NEW_LEAD_LEVEL,
        ROW_NUMBER() OVER(PARTITION BY CAMPAIGN ORDER BY PROFILE_ID) N
INTO #ACTIVE_PROFILES
FROM AUTOMATOR.DBO.PROFILE A
INNER JOIN AUTOMATOR.dbo.CAMPAIGN B ON A.CAMPAIGN = B.CAMPAIGN_ID
WHERE A.[STATE] = 1;





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
    PRINT 'SELECT RESULTADO'
    EXEC ('SELECT TOP '+@CHARGE_LEVEL+' * INTO #INSERTION FROM #RESULT')

    -- TODO:
    -- INSERTAR LISTA
    EXEC DBO.AUTO_LIST @CAMPAIGN_ID
    -- INSERTAR LEADS
    

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

