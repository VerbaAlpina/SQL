DELIMITER $$

DROP PROCEDURE IF EXISTS buildSubConceptsExtended$$

CREATE PROCEDURE buildSubConceptsExtended ()
BEGIN
	DELETE FROM A_Ueberkonzepte_Erweitert;
	DROP TEMPORARY TABLE IF EXISTS UK_Temp;
	CREATE TEMPORARY TABLE UK_Temp (Id INT UNSIGNED, UeId INT UNSIGNED) ENGINE=MEMORY;
	INSERT INTO UK_Temp SELECT Id_Konzept, Id_Ueberkonzept FROM Ueberkonzepte WHERE Id_Ueberkonzept != 707;
	SELECT count(*) FROM UK_Temp INTO @rest;
	WHILE @rest > 0 DO
		SELECT Id, UeId FROM UK_Temp LIMIT 1 INTO @ck, @cuk;
		INSERT INTO A_Ueberkonzepte_Erweitert VALUES(@ck, @cuk);
		INSERT INTO UK_Temp (SELECT u.Id_Konzept, @cuk FROM Ueberkonzepte u WHERE u.Id_Ueberkonzept = @ck);
		SET @rest = @rest + row_count() - 1;
		DELETE FROM UK_Temp WHERE Id = @ck AND UeId = @cuk;
	END WHILE;
	
	DROP TEMPORARY TABLE IF EXISTS UK_Temp;
END$$

DELIMITER ;