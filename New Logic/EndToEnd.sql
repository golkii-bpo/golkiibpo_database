CREATE PROCEDURE GET_EndToEnd
AS BEGIN
DECLARE @STATUSES NVARCHAR(MAX)
SET @STATUSES    = '';
WITH CTE_STATUSES (STATUS)
AS (
    SELECT STATUS FROM OPENQUERY([VICIDIAL],'SELECT DISTINCT STATUS FROM vicidial_log where call_date > DATE(NOW()) AND user != ''VDAD''')
)
select @STATUSES = @STATUSES + '['+STATUS+'],' FROM CTE_STATUSES
SET @STATUSES = SUBSTRING(@STATUSES,1,LEN(@STATUSES)-1)
DECLARE @QUERY NVARCHAR(MAX)
SET @QUERY = 
'

SELECT *
    FROM OPENQUERY(
        [VICIDIAL],''
        SELECT
        B.`user`,
        B.full_name,
        A.`status`,
        1 AS CC
        FROM vicidial_log A
        INNER JOIN vicidial_users B on A.`user` = B.`user`
        WHERE A.call_date >= DATE(NOW())
        AND B.`user` != ''''VDAD''''
    '')
PIVOT (
    SUM(CC) FOR [status] IN (
'+@STATUSES+'))P

'

EXEC sp_sqlexec @QUERY
END 