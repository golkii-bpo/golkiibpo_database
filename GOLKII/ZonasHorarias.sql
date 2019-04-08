
/*
CREATE TABLE ZonaHorariaReloj
(
    id INT PRIMARY KEY NOT NULL,
    inSun TIME,
    outSun TIME,
    inMon TIME,
    outMon TIME,
    inTue TIME,
    outTue TIME,
    inWen TIME,
    outWen TIME,
    inThu TIME,
    outThu TIME,
    inFri TIME,
    outFri TIME,
    inSat TIME,
    outSat TIME
)
CREATE TABLE ZonaHorarioCargo
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    Cargo INT FOREIGN KEY REFERENCES CARGO(ID),
    ZonaHorariaReloj INT FOREIGN KEY REFERENCES ZonaHorariaReloj(id)
)

INSERT INTO ZonaHorariaReloj
VALUES
(
    9,                 -- ID
    '00:00','00:00',    -- DOMINGO
    '07:00','20:00',    -- LUNES
    '07:00','20:00',    -- MARTES
    '07:00','20:00',    -- MIERCOLES
    '07:00','20:00',    -- JUEVES
    '07:00','20:00',    -- VIERNES
    '07:00','20:00'     -- SABADO
),
(
    10,                 -- ID
    '00:00','00:00',    -- DOMINGO
    '07:00','08:05',    -- LUNES
    '07:00','08:05',    -- MARTES
    '07:00','08:05',    -- MIERCOLES
    '07:00','08:05',    -- JUEVES
    '07:00','08:05',    -- VIERNES
    '00:00','00:00'     -- SABADO
),
(
    11,                 -- ID
    '00:00','00:00',    -- DOMINGO
    '11:30','13:05',    -- LUNES
    '11:30','13:05',    -- MARTES
    '11:30','13:05',    -- MIERCOLES
    '11:30','13:05',    -- JUEVES
    '11:30','13:05',    -- VIERNES
    '00:00','00:00'     -- SABADO
),
(
    12,                 -- ID
    '00:00','00:00',    -- DOMINGO
    '18:00','19:00',    -- LUNES
    '18:00','19:00',    -- MARTES
    '18:00','19:00',    -- MIERCOLES
    '18:00','19:00',    -- JUEVES
    '18:00','19:00',    -- VIERNES
    '00:00','00:00'     -- SABADO
),
(
    13,                 -- ID
    '00:00','00:00',    -- DOMINGO
    '18:00','20:00',    -- LUNES
    '18:00','20:00',    -- MARTES
    '18:00','20:00',    -- MIERCOLES
    '18:00','20:00',    -- JUEVES
    '18:00','20:00',    -- VIERNES
    '00:00','00:00'     -- SABADO
)

INSERT INTO ZonaHorarioCargo
VALUES
(
    1,  -- ID CARGO VENTAS
    10  -- ZONA HORARIA
),
(
    1,  -- ID CARGO VENTAS
    11  -- ZONA HORARIA
),
(
    1,  -- ID CARGO VENTAS
    12  -- ZONA HORARIA
),
(
    23,  -- ID CARGO CALIBRACION
    10  -- ZONA HORARIA
),
(
    23,  -- ID CARGO CALIBRACION
    11  -- ZONA HORARIA
),
(
    23,  -- ID CARGO CALIBRACION
    13  -- ZONA HORARIA
),
(
    3,  -- ID CARGO COACH
    9   -- ZONA HORARIA
)

*/

SELECT 
    A.Cargo,
    C.inMon,C.outMon, -- Lunes
    C.inTue,C.outTue, -- Martes
    C.inWen,C.outWen, -- Mercoles
    C.inThu,C.outThu, -- Jueves
    C.inFri,C.outFri, -- Viernes
    C.inSat,C.outsat, -- Sabado
    C.inSun,C.outSun  -- Domingo
FROM Cargo A
INNER JOIN ZONAHORARIOCARGO B ON A.Id = B.CARGO
INNER JOIN ZONAHORARIARELOJ C ON B.ZonaHorariaReloj = C.ID