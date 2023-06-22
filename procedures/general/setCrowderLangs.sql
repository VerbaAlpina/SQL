DELIMITER $$

DROP PROCEDURE IF EXISTS setCrowderLangs$$

CREATE PROCEDURE setCrowderLangs ()
BEGIN
	DECLARE i int;

	DROP TEMPORARY TABLE IF EXISTS new_informants;

	CREATE TEMPORARY TABLE new_informants AS
		SELECT Id_Informant, Id_Ort, Ortsname, o.Alpenkonvention FROM informanten i JOIN orte o ON Id_Ort = Id_Gemeinde WHERE i.Sprache = '';
	
	SET i = 0;
	SET @c = 0;
	SELECT count(*) INTO @sum FROM new_informants;
	WHILE i < @sum DO
		SET @lang = NULL;
	
		SELECT Id_Informant, Id_Ort, Ortsname, Alpenkonvention INTO @id_informant, @id_ort, @comm, @ak FROM new_informants LIMIT i, 1;
		
		SELECT Wert INTO @country FROM Orte_Tags WHERE Id_Ort = @id_ort AND Tag = 'LAND';
		
		CASE
		WHEN @country = 'deu' OR @country = 'aut' THEN
			SET @lang = 'gem';
		WHEN @country = 'ita' AND NOT @ak THEN 
			SET @lang = 'rom';
		ELSE
			SELECT Sprachfamilie INTO @lang FROM gemeinden_ak WHERE Referenz_Orte = @id_ort;
		END CASE;
		
		IF @lang IS NULL THEN
			SELECT 'NOT FOUND:', @comm, @country, @ak, @lang;
		ELSE
			UPDATE informanten SET Sprache = @lang WHERE id_informant = @id_informant;
			SET @c = @c + 1;
		END IF;
		
		SET i = i + 1;
	END WHILE;
	
	SELECT CONCAT(@c, ' rows updated.');
	
	DROP TEMPORARY TABLE new_informants;
END$$

DELIMITER ;