
-- Cedulas con el formato correcto 7432
-- Cedulas unicas 7382
-- Cedulas unicas en nuestro universo 1078

;with cte_Cedulas 
as
(
    select a.[Cédula Miembro] [Cedula] From BasesRecibidas.dbo.FIL_DB_13052019 a where a.[Cédula Miembro] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-z]'
), cte_Unicas_Dirty
as
(
    select a.Cedula, ROW_NUMBER() over (partition by a.Cedula order by a.Cedula) [Catalogo] from cte_Cedulas a
), cte_Universo
as
(
    select a.Cedula from BaseControl.dbo.Persona a group by a.Cedula
)

select a.Cedula from (
    select a.Cedula from cte_Unicas_Dirty a where a.Catalogo = 1
    except
    select b.Cedula from cte_Universo b
) a group by a.Cedula
