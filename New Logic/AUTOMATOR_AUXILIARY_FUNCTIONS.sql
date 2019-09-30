CREATE FUNCTION GET_VICI_ACTIVE_CAMPAIGNS 
(
)
RETURNS TABLE
AS  
RETURN
    SELECT CAMPAIGN_ID,CAMPAIGN_NAME,HOPPER_LEVEL,AUTO_DIAL_LEVEL 
        FROM OPENQUERY([AUTOMATOR_VICIDIAL],
        'select campaign_id,campaign_name,hopper_level,auto_dial_level 
        from vicidial_campaigns 
        where active = ''Y''
        and campaign_id not in (''calioutb'',''atencion'')')
GO
GO
SELECT * FROM GET_VICI_ACTIVE_CAMPAIGNS()
GO
CREATE FUNCTION GET_VICI_NEW_LEADS ()
RETURNS TABLE 
AS
RETURN 
    SELECT CAMPAIGN_ID, NEW_LEADS
        FROM OPENQUERY([AUTOMATOR_VICIDIAL],
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
GO
SELECT * FROM GET_VICI_NEW_LEADS()
GO
SELECT DBO.GET_LAST_VICI_LIST_ID() 
GO
SELECT DBO.GET_PERSONAS_DISPONIBLES('EFNI')
GO
CREATE FUNCTION GET_ACTIVE_PROFILES()
RETURNS TABLE 
AS
RETURN
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
            FROM AUTOMATOR.DBO.PROFILE A
            INNER JOIN AUTOMATOR.dbo.CAMPAIGN B ON A.CAMPAIGN = B.CAMPAIGN_ID
            WHERE A.[STATE] = 1;
GO
SELECT * FROM GET_ACTIVE_PROFILES()