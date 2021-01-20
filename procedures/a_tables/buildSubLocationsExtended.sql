DELIMITER $$

DROP PROCEDURE IF EXISTS buildSubLocationsExtended$$

CREATE PROCEDURE buildSubLocationsExtended ()
BEGIN
	DELETE FROM A_Orte_Hierarchien_Erweitert;
	DROP TEMPORARY TABLE IF EXISTS UO_Temp;
	CREATE TEMPORARY TABLE UO_Temp (Id INT UNSIGNED, UeId INT UNSIGNED) ENGINE=MEMORY;
	INSERT INTO UO_Temp SELECT Id_Ort, Id_Ueberort FROM Orte_Hierarchien;
	SELECT count(*) FROM UO_Temp INTO @rest;
	WHILE @rest > 0 DO
		SELECT Id, UeId FROM UO_Temp LIMIT 1 INTO @cl, @cul;
		INSERT INTO A_Orte_Hierarchien_Erweitert VALUES(@cl, @cul);
		INSERT INTO UO_Temp (SELECT u.Id_Ort, @cul FROM Orte_Hierarchien u WHERE u.Id_Ueberort = @cl);
		SET @rest = @rest + row_count() - 1;
		DELETE FROM UO_Temp WHERE Id = @cl AND UeId = @cul;
	END WHILE;
	
	DROP TEMPORARY TABLE IF EXISTS UO_Temp;
END$$

DELIMITER ;