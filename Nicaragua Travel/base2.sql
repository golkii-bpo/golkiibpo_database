 -- DROP TABLE #TEMP_TELEFONOS
-- SELECT * FROM BasesRecibidas.SYS.tables ORDER BY create_date DESC
WITH 
CTE_DB
AS (
    select 
        LTRIM(RTRIM([NOMBRE DEL CLIENTE ])) AS NOMBRE,
        LTRIM(RTRIM(REPLACE(CEDULA,'-',''))) AS CEDULA,
        LTRIM(RTRIM(REPLACE(TEL2,'-',''))) AS TEL1,
        LTRIM(RTRIM(REPLACE(TEL3,'-',''))) AS TEL2,
        LTRIM(RTRIM(REPLACE(TEL4,'-',''))) AS TEL3,
        LTRIM(RTRIM(REPLACE(TEL5,'-',''))) AS TEL4,
        LTRIM(RTRIM(REPLACE(TEL6,'-',''))) AS TEL5,
        DATO
    from BasesRecibidas.dbo.DB_25062019
),
CTE_TELEFONOS
AS (
    SELECT     
        NOMBRE,
        CEDULA,
        REPLACE(REPLACE(TEL,'*',''),'+','') AS TEL,
        DATO,
        ROW_NUMBER() OVER(PARTITION BY NOMBRE,CEDULA ORDER BY CEDULA) AS TelNo
    FROM CTE_DB
    UNPIVOT
    (  
        TEL FOR TELEFONOS IN (TEL1,TEL2,TEL3,TEL4,TEL5)
    ) PVT
)

SELECT * 
INTO #TEMP_TELEFONOS
FROM CTE_TELEFONOS 
ORDER BY CEDULA


DELETE FROM #TEMP_TELEFONOS WHERE TEL NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'


SELECT 
    A.*,
    ROW_NUMBER() OVER(PARTITION BY TEL ORDER BY TEL) AS N
INTO #REPEATED
FROM #TEMP_TELEFONOS A
DELETE FROM #REPEATED WHERE N = 1

SELECT A.*
INTO #UNREPEATED
FROM #TEMP_TELEFONOS A
LEFT JOIN #REPEATED B ON A.TEL = B.TEL
WHERE B.TEL IS NULL


SELECT 
DISTINCT NOMBRE,CEDULA 
INTO #TEMP_PERSONA
FROM #UNREPEATED


UPDATE #TEMP_PERSONA
SET CEDULA  = NULL 
WHERE CEDULA NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'

INSERT INTO BD_REF.PERSONA
(NOMBRE,CEDULA, LOTE)
SELECT A.NOMBRE,A.CEDULA,2
FROM #TEMP_PERSONA A
LEFT JOIN BD_REF.PERSONA B ON A.NOMBRE COLLATE DATABASE_DEFAULT = B.NOMBRE COLLATE DATABASE_DEFAULT
WHERE B.NOMBRE IS NULL

UPDATE #UNREPEATED
SET CEDULA  = NULL 
WHERE CEDULA NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][a-Z]'




select 
    a.TEL,b.id as [idpersona],0 as called,null as datecall,2 as lote
into #joinedData
from #UNREPEATED a
inner join BD_REF.persona b on a.nombre collate database_default = b.nombre collate database_default
            and a.CEDULA collate database_default = b.cedula collate database_default
where b.lote = 2


insert into BD_REF.Telefono 
(telefono,idpersona,called,datecall,lote)
 select 
    a.tel,
    a.idpersona,
    0,
    null,
    2
  from #joinedData a
left join BD_REF.telefono b on a.TEL collate database_default = b.telefono collate database_default
where b.telefono is null

DROP TABLE #TEMP_TELEFONOS
DROP TABLE #TEMP_PERSONA
DROP TABLE #REPEATED
DROP TABLE #UNREPEATED
drop table #joinedData





