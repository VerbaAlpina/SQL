DELIMITER $$

DROP PROCEDURE IF EXISTS buildConceptDepthTable$$

CREATE PROCEDURE `buildConceptDepthTable` ()
BEGIN
	DELETE FROM A_Konzept_Tiefen;

	DROP TEMPORARY TABLE IF EXISTS concept_levels;
	CREATE TEMPORARY TABLE concept_levels (Id INT unsigned, Lev INT unsigned) ENGINE=MEMORY;
	
	INSERT INTO concept_levels VALUES (707, 0);
	SET @c = 1;
	
	WHILE @c > 0 DO
		SELECT Id, Lev FROM concept_levels LIMIT 0,1 INTO @i, @l;
		DELETE FROM concept_levels WHERE Id = @i;
		INSERT INTO A_Konzept_Tiefen (Id_Konzept, Tiefe) VALUES (@i, @l);
		
		INSERT INTO concept_levels SELECT Id_Konzept, @l + 1 FROM Ueberkonzepte WHERE Id_Konzept != 707 AND Id_Ueberkonzept = @i;
		
		SELECT count(*) FROM concept_levels INTO @c;
	END WHILE;
	
	DROP TEMPORARY TABLE concept_levels;
END$$

DELIMITER ;