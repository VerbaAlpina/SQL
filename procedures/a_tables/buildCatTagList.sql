DELIMITER $$

DROP PROCEDURE IF EXISTS buildCatTagList$$

CREATE PROCEDURE buildCatTagList ()

BEGIN
	DECLARE i INT UNSIGNED;

	DELETE FROM A_Kategorie_Tag_Werte;

	DROP TEMPORARY TABLE IF EXISTS tagList;
   	CREATE TEMPORARY TABLE tagList AS SELECT DISTINCT Id_Kategorie, Tag FROM Orte JOIN Orte_Tags USING (Id_Ort);
	
	SET i = 0;
	SELECT count(*) FROM tagList INTO @num;
	
	WHILE i < @num DO
		SELECT Id_Kategorie, Tag FROM tagList LIMIT i,1 INTO @idc, @tag;
		INSERT INTO A_Kategorie_Tag_Werte (Id_Kategorie, Tag, Wert, Alpenkonvention)
			SELECT @idc, @tag, IFNULL(Wert, 'EMPTY'), sum(Alpenkonvention) > 0 FROM Orte o LEFT JOIN Orte_Tags t ON t.Id_Ort = o.Id_Ort AND Tag = @tag WHERE Id_Kategorie = @idc GROUP BY Wert;
		SET i = i + 1;
	END WHILE;
	
	
	DROP TEMPORARY TABLE tagList;
END$$

DELIMITER ;