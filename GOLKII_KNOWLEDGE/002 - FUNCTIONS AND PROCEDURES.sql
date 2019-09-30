USE GOLKII_KNOWLEDGE
GO
CREATE FUNCTION 
NIC.GET_AGE_FROM_CEDULA
(
    @CEDULA CHAR(14)
)
RETURNS INT 
BEGIN  
    DECLARE @D INT, @M INT, @Y INT
    SELECT @D = SUBSTRING(@CEDULA,4,2), @M = SUBSTRING(@CEDULA,6,2), @Y = SUBSTRING(@CEDULA,8,2)
    DECLARE @BDAY DATE, @AGE INT
    SELECT @BDAY = CONCAT(@M,'/',@D,'/',@Y)
    SELECT @AGE = DATEDIFF( MONTH,@BDAY,GETDATE())/12
    RETURN @AGE;
END 
GO
CREATE FUNCTION DBO.GET_AGENT_FEEDBACK_ID_CLIENT
(
    @WHO_DO CHAR(100)
)
RETURNS INT 
BEGIN 
    DECLARE @RES INT
    SET @RES = 0;
    SELECT @RES = ISNULL(MAX(BASERECIBIDA_ID),0) FROM CLIENT WHERE WHO_DO = @WHO_DO AND BASERECIBIDA_NAME = 'AGENT_FEEDBACK'
    RETURN @RES;
END
GO
CREATE FUNCTION DBO.GET_AGENT_FEEDBACK_ID_PHONE
(
    @WHO_DO CHAR(100)
)
RETURNS INT 
BEGIN 
    DECLARE @RES INT
    SET @RES = 0;
    SELECT @RES = ISNULL(MAX(BASERECIBIDA_ID),0) FROM PHONES WHERE WHO_DO = @WHO_DO AND BASERECIBIDA_NAME = 'AGENT_FEEDBACK'
    RETURN @RES;
END
GO
CREATE FUNCTION DBO.GET_AGENT_FEEDBACK_ID_CARD
(
    @WHO_DO CHAR(100)
)
RETURNS INT 
BEGIN 
    DECLARE @RES INT
    SET @RES = 0;
    SELECT @RES = ISNULL(MAX(BASERECIBIDA_ID),0) FROM CARDS WHERE WHO_DO = @WHO_DO AND BASERECIBIDA_NAME = 'AGENT_FEEDBACK'
    RETURN @RES;
END
GO
CREATE PROCEDURE 
SP_ADD_FULLNAME_CLIENT
    (
        @FULL_NAME NVARCHAR(100),
        @ADDRESS NVARCHAR(255),
        @SALARY MONEY,
        @PERSONAL_ID CHAR(16),
        @GENDER CHAR(1),
        @AGE INT,
        @EMAIL NVARCHAR(60),
        @DEPARTMENT INT ,
        @CITY INT ,
        @STATUS_CREDEX INT,
        @WHO_DO CHAR(100)
    )
    AS BEGIN
        -- REALIZAR VALIDACIONES
        
        INSERT INTO CLIENT
            (
                FULL_NAME,
                ADDRESS,
                SALARY,
                PERSONAL_ID,
                GENDER,
                AGE,
                EMAIL,
                DEPARTMENT,
                CITY,
                STATUS_CREDEX,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                LAST_UPDATE,
                WHO_DO
            )
            VALUES
            (
                @FULL_NAME,
                @ADDRESS,
                @SALARY,
                @PERSONAL_ID,
                @GENDER,
                @AGE,
                @EMAIL,
                @DEPARTMENT,
                @CITY,
                @STATUS_CREDEX ,
                'AGENT_FEEDBACK',
                DBO.GET_AGENT_FEEDBACK_ID_CLIENT(@WHO_DO) + 1,
                DEFAULT,
                @WHO_DO
            )
    END  
GO
CREATE PROCEDURE 
SP_UPDATE_CLIENT
    (
        @FULL_NAME NVARCHAR(100),
        @ADDRESS NVARCHAR(255),
        @SALARY MONEY,
        @PERSONAL_ID CHAR(16),
        @GENDER CHAR(1),
        @AGE INT,
        @EMAIL NVARCHAR(60),
        @DEPARTMENT INT ,
        @CITY INT ,
        @STATUS_CREDEX INT,
        @WHO_DO CHAR(100)
    )
    AS BEGIN 
        IF EXISTS(SELECT * FROM CLIENT WHERE PERSONAL_ID = @PERSONAL_ID AND PERSONAL_ID IS NOT NULL)
        BEGIN 
            -- REALIZAR VALIDACIONES 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            UPDATE CLIENT 
                SET
                    FULL_NAME = @FULL_NAME,
                    ADDRESS = @ADDRESS,
                    SALARY = @SALARY,
                    GENDER = @GENDER,
                    AGE = @AGE,
                    EMAIL = @EMAIL,
                    DEPARTMENT = @DEPARTMENT,
                    CITY = @CITY,
                    STATUS_CREDEX = @STATUS_CREDEX ,
                    WHO_DO = @WHO_DO,
                    LAST_UPDATE = DEFAULT,
                    BASERECIBIDA_NAME = 'AGENT_FEEDBACK',
                    BASERECIBIDA_ID = DBO.GET_AGENT_FEEDBACK_ID_CLIENT(@WHO_DO) + 1
                WHERE 
                    PERSONAL_ID = @PERSONAL_ID
        END
        ELSE
        BEGIN 
    END
GO
CREATE TRIGGER
TRGG_CLIENT_AI_AU
ON CLIENT AFTER INSERT,UPDATE
AS
BEGIN  
    IF EXISTS(SELECT * FROM DELETED)
    BEGIN 
        INSERT INTO CLIENT_LOG
        ( CLIENT, FULL_NAME, [ADDRESS], SALARY, PERSONAL_ID, GENDER, AGE, EMAIL, DEPARTMENT, CITY, STATUS_CREDEX, BASERECIBIDA_NAME, BASERECIBIDA_ID, [DATE], WHO_DO, [ACTION] )
        SELECT
            ID, FULL_NAME, [ADDRESS], ISNULL(SALARY,0), PERSONAL_ID, GENDER, ISNULL(AGE,0), EMAIL, DEPARTMENT, CITY, STATUS_CREDEX, BASERECIBIDA_NAME, BASERECIBIDA_ID, GETDATE(), WHO_DO, 'DEL'
        FROM DELETED
    END

    IF EXISTS(SELECT * FROM inserted)
    BEGIN 
        INSERT INTO CLIENT_LOG
        ( CLIENT, FULL_NAME, [ADDRESS], SALARY, PERSONAL_ID, GENDER, AGE, EMAIL, DEPARTMENT, CITY, STATUS_CREDEX, BASERECIBIDA_NAME, BASERECIBIDA_ID, [DATE], WHO_DO, [ACTION] )
        SELECT
            ID, FULL_NAME, [ADDRESS], ISNULL(SALARY,0), PERSONAL_ID, GENDER, ISNULL(AGE,0), EMAIL, DEPARTMENT, CITY, STATUS_CREDEX, BASERECIBIDA_NAME, BASERECIBIDA_ID, GETDATE(), WHO_DO, 'INS'
        FROM inserted
    END
END

GO

CREATE PROCEDURE 
SP_ADD_OR_UPDATE_PHONE
    (
        @PHONE INT,
        @CLIENT INT,
        @IS_OWNER_CONFIRMED BIT,
        @WHO_DO CHAR(100)
    )
    AS BEGIN
        IF EXISTS(SELECT * FROM PHONES WHERE PHONE = @PHONE)
        BEGIN
            UPDATE A
            SET
                CLIENT = @CLIENT,
                IS_OWNER_CONFIRMED = @IS_OWNER_CONFIRMED,
                BASERECIBIDA_NAME = 'AGENT_FEEDBACK',
                BASERECIBIDA_ID = DBO.GET_AGENT_FEEDBACK_ID_PHONE(WHO_DO) + 1,
                LAST_UPDATE = GETDATE(),
                WHO_DO = @WHO_DO
            FROM PHONES A
            WHERE PHONE = @PHONE
        END
        ELSE
        BEGIN
            INSERT INTO PHONES
            (
                PHONE,
                CLIENT,
                IS_OWNER_CONFIRMED,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                LAST_UPDATE,
                WHO_DO
            )
            VALUES
            (
                @PHONE,
                @CLIENT,
                @IS_OWNER_CONFIRMED,
                'AGENT_FEEDBACK',
                DBO.GET_AGENT_FEEDBACK_ID_PHONE(@WHO_DO) + 1,
                GETDATE(),
                @WHO_DO
            )
        END
    END 
    GO
CREATE TRIGGER
TRGG_PHONES_AI_AU
    ON PHONES AFTER INSERT,UPDATE
    AS BEGIN 
        IF EXISTS(SELECT * FROM DELETED)
        BEGIN 
            INSERT INTO PHONES_LOG
            SELECT 
                PHONE,
                CLIENT,
                CARRIER,
                IS_OWNER_CONFIRMED,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                GETDATE(),
                WHO_DO,
                'DEL'
            FROM DELETED
        END

        IF EXISTS(SELECT * FROM INSERTED)
        BEGIN 
            UPDATE A
                SET 
                    LAST_UPDATE = GETDATE(),
                    CARRIER = C.CARRIER
            FROM PHONES A 
            INNER JOIN INSERTED B ON A.PHONE = B.PHONE
            LEFT JOIN CARRIER_PREFIX C ON A.PREFIX = C.PREFIX

            INSERT INTO PHONES_LOG
            SELECT 
                PHONE,
                CLIENT,
                CARRIER,
                IS_OWNER_CONFIRMED,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                GETDATE(),
                WHO_DO,
                'INS'
            FROM INSERTED
        END
    END
GO
CREATE PROCEDURE 
SP_ADD_OR_UPDATE_CARDS
    (    
        @CLIENT INT,
        @BANK INT,
        @IS_CREDIT BIT,
        @IS_DEBIT BIT,
        @COLOR NVARCHAR(100),
        @ACTIVE BIT,
        @WHO_DO CHAR(100)
    )
    AS BEGIN
        IF EXISTS(SELECT * FROM CARDS WHERE CLIENT = @CLIENT AND BANK = @BANK AND IS_CREDIT = @IS_CREDIT AND IS_DEBIT = @IS_CREDIT AND COLOR = @COLOR)
        BEGIN
            UPDATE A
            SET
                ACTIVE = @ACTIVE,
                BASERECIBIDA_NAME = 'AGENT_FEEDBACK',
                BASERECIBIDA_ID = DBO.GET_AGENT_FEEDBACK_ID_CARD(@WHO_DO) + 1,
                LAST_UPDATE = GETDATE(),
                WHO_DO = @WHO_DO
            FROM CARDS A
            WHERE CLIENT = @CLIENT AND BANK = @BANK AND IS_CREDIT = @IS_CREDIT AND IS_DEBIT = @IS_CREDIT AND COLOR = @COLOR
        END
        ELSE
        BEGIN
            INSERT INTO CARDS
            ( 
                CLIENT,
                BANK,
                IS_CREDIT,
                IS_DEBIT,
                COLOR,
                ACTIVE,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                LAST_UPDATE,
                WHO_DO
            )
            VALUES
            (
                @CLIENT,
                @BANK,
                @IS_CREDIT,
                @IS_DEBIT,
                @COLOR,
                @ACTIVE,
                'AGENT_FEEDBACK',
                DBO.GET_AGENT_FEEDBACK_ID_CARD(@WHO_DO) + 1,
                GETDATE(),
                @WHO_DO
            )
        END
    END 
GO




CREATE TRIGGER
TRGG_CARDS_AI_AU
    ON CARD AFTER INSERT,UPDATE
    AS BEGIN 
        IF EXISTS(SELECT * FROM DELETED)
        BEGIN 
            INSERT INTO CARDS_LOG
            SELECT 
                CLIENT,
                BANK,
                IS_CREDIT,
                IS_DEBIT,
                COLOR,
                ACTIVE,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                GETDATE(),
                WHO_DO,
                'DEL'
            FROM DELETED
        END

        IF EXISTS(SELECT * FROM INSERTED)
        BEGIN 
            INSERT INTO CARDS_LOG
            SELECT 
                CLIENT,
                BANK,
                IS_CREDIT,
                IS_DEBIT,
                COLOR,
                ACTIVE,
                BASERECIBIDA_NAME,
                BASERECIBIDA_ID,
                GETDATE(),
                WHO_DO,
                'INS'
            FROM INSERTED
        END
    END
GO