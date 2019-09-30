
-- ALREADY CALLED
GO
CREATE FUNCTION QUERY_PHONES_ALREADY_CALLED ()
RETURNS NVARCHAR(MAX)
AS BEGIN
    DECLARE @QUERY NVARCHAR(MAX)
    SET @QUERY = CONCAT('
    SELECT phone_number FROM OPENQUERY([192.168.1.250],''
        SELECT phone_number FROM vicidial_log
        WHERE call_date >= ''''',CONVERT(VARCHAR,DATEADD(MONTH,-3,GETDATE()),23),'''''
    '')')
    SET @QUERY = CONCAT('INSERT INTO @PHONES',SPACE(1),@QUERY)
    RETURN @QUERY;
END
GO
--  ALREADY IN LIST

CREATE FUNCTION TBL_PHONES_IN_ACTIVE_LIST()
RETURNS TABLE
AS
RETURN
    SELECT TELEFONO FROM OPENQUERY([192.168.1.250],'
        SELECT CAST(a.phone_number AS INT) phone_number,CAST(a.alt_phone AS INT) alt_phone FROM vicidial_list a
        inner join vicidial_lists b on a.list_id = b.list_id
        WHERE b.active >= ''Y''
    ')
    UNPIVOT(TELEFONO FOR TELEFONOS IN ([phone_number],[alt_phone]))U
    WHERE Telefono != 0


