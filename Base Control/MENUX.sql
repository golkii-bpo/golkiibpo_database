-- select top 1 * from TelefonosPerCampaign where IdCampaign = 'EFNI' and Disponible = 1

-- GO
-- select A.Departamento,
-- C.Banco,
-- COUNT(A.IdPersona) AS [CANTIDAD]
-- from Persona A
-- inner join Tarjetas B ON A.IdPersona = B.IdCliente
-- INNER JOIN BANCOS C ON B.IdBancos = C.IdBancos
-- INNER JOIN Telefonos D ON D.IdPersona = A.IdPersona
-- INNER JOIN TelefonosPerCampaign E ON E.IdTelefono = D.IdTelefono 
-- WHERE 
--     A.DEPARTAMENTO IS NOT NULL
--     AND A.Departamento NOT IN ('Atlantico Sue','Atlantico Norte','')
--     AND E.Disponible = 1
--     AND E.IdCampaign = 'EFNI'
-- GROUP BY C.Banco,A.Departamento
-- ORDER BY A.Departamento

;with cte_telefonosPersona
AS
(
    select IdPersona from TelefonosPerCampaign a inner join telefonos b on a.IdTelefono = b.IdTelefono
    where a.IdCampaign = 'EFNI' and a.Estado = 1 and a.Disponible = 1 and Telefono like '[5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    group by b.IdPersona 
)

select b.Departamento,d.Banco,b.StatusCredex [Credex],COUNT(1) as [cantidad] from cte_telefonosPersona a 
inner join Persona b on a.IdPersona = b.IdPersona 
inner join Tarjetas c on c.IdCliente = b.IdPersona
inner join Bancos d on d.IdBancos = c.IdBancos
where b.Estado = 1 and b.IsWorking = 1 and d.IdBancos between 1 and 5 and b.StatusCredex is not null
group by d.Banco,b.Departamento,b.StatusCredex
order by b.Departamento asc,d.Banco asc


