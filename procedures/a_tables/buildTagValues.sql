DELIMITER $$

DROP PROCEDURE IF EXISTS buildTagValues$$

CREATE PROCEDURE buildTagValues ()
BEGIN
	delete from a_tag_werte;
	
	insert into a_tag_werte (Id_Kategorie, Id_Ort, Tag, Wert) 
		SELECT o.Id_Kategorie, o.Id_Ort, a.Tag, IFNULL(Wert, 'EMPTY')
		FROM Orte o
		JOIN (SELECT DISTINCT Id_Kategorie, Tag FROM a_kategorie_tag_werte) a USING(Id_Kategorie)
		LEFT JOIN orte_tags t ON o.Id_Ort = t.Id_Ort and a.Tag = t.Tag;
	
END$$

DELIMITER ;