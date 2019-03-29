

INSERT INTO Persona 
(IdProcedencia,Nombre,Cedula,Domicilio,Departamento,Municipios,Salario,Sexo)
SELECT 
    1,A.Nombres,A.Cedula,A.domicilio,A.departamento,A.municipio,CAST(A.salario AS MONEY),IIF(A.sexo = 'MASCULINO',1,0)
FROM 
    BasesRecibidas.dbo.DB_CREDEX_25032019 A
    LEFT JOIN Persona B ON A.Cedula = B.Cedula
WHERE 
    B.IdPersona IS NULL


;WITH  cte_Telefonos
AS
(
    SELECT UPVT.Cedula,Cast(UPVT.Tel AS float) [Tel] FROM BasesRecibidas.dbo.DB_CREDEX_25032019 A UNPIVOT (Tel FOR Reg IN(A.Telefono,A.Telefono1)) UPVT WHERE STR(UPVT.Tel,8,0) LIKE '[2,5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),cte_Data
AS
(
    SELECT B.IdPersona,A.Tel FROM cte_Telefonos A INNER JOIN dbo.Persona B ON A.Cedula = B.Cedula
)
insert into dbo.Telefonos (IdPersona,Telefono,IdProcedencia,Estado)
select A.IdPersona,B.Telefono,1,1 from cte_Data A left join dbo.Telefonos B on A.Tel = b.Telefono where b.IdPersona is null

;with cte_TelefonosPrefijos
as
(
    select SUBSTRING(STR(a.Telefono,8,0),1,4) [Prefijos],A.IdTelefono from Telefonos a
)

update a set a.Operadora = c.operador from Telefonos a inner join cte_TelefonosPrefijos b on a.IdTelefono = b.IdTelefono inner join BasePrefijos c on c.prefijo = b.Prefijos

;alter table dbo.Persona add StatusCredex varchar(50);


select A.EstadoCust from BasesRecibidas.dbo.DB_CREDEX_CONSULTA A GROUP BY A.EstadoCust
;with cte_CredexStatus (statusCredex,Cedula)
as
(
    select
        case
            when a.EstadoCust like 'Proce%' then 'En Proceso'
            when a.EstadoCust like 'Cancela%' then 'Cancelado'
            when a.EstadoCust like 'Aproba%' then 'Aprobado Credex'
            when a.EstadoCust like 'Inact%' then 'Linea Inactiva'
            when a.EstadoCust like 'Verifica%' then 'Verificado'
            when a.EstadoCust like 'Autoriz%' then 'Linea Autorizada'
            when a.EstadoCust like 'Rechaza%' then 'Linea Rechazada'
            when a.EstadoCust like 'Bloquea%' then 'Linea Bloqueada'
            when a.EstadoCust like 'Suspend%' then 'Linea Suspendida'
            else null
        end,
        replace(replace(a.cedula,'-',''),' ','') 
    from 
        BasesRecibidas.dbo.DB_CREDEX_CONSULTA a 
    where 
        a.cedula is not null
)

update b set b.StatusCredex = a.statusCredex from cte_CredexStatus a inner join dbo.Persona b on a.Cedula = b.Cedula 


select a.StatusCredex,count(1) [Registros]from Persona a where a.StatusCredex is not null group by a.StatusCredex