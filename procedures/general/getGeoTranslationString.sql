DELIMITER $$

DROP FUNCTION IF EXISTS getGeoTranslationString$$

CREATE FUNCTION getGeoTranslationString(id INT) RETURNS varchar(100)
BEGIN 
	SELECT GROUP_CONCAT(CONCAT(Sprache, ':', Name) SEPARATOR '###') INTO @str FROM Orte_Uebersetzungen WHERE Id_Ort = id;
	IF @str IS NULL THEN
		RETURN '';
	ELSE
		RETURN CONCAT('###', @str);
	END IF;
END$$

DELIMITER ;