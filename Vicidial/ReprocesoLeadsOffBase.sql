
	CREATE PROCEDURE EliminarNewLeadsOffBase()
	BEGIN
			DELETE a FROM vicidial_list as a INNER JOIN vicidial_lists as b ON a.list_id = b.list_id WHERE a.`status` = 'NEW' AND b.active = 'N';
	END;