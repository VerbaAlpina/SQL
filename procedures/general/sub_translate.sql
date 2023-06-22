DROP FUNCTION IF EXISTS sub_translate;
DELIMITER $$

CREATE FUNCTION sub_translate (str VARCHAR(5000), lang CHAR(1)) RETURNS VARCHAR(5000)
BEGIN
	SET @ind = LOCATE('Ue[', str);
	WHILE @ind != 0 DO
		SET @endt = LOCATE(']', str, @ind);
		SET @subst = SUBSTR(str, @ind + 3, @endt - @ind - 3);
		
		SET @transl = NULL;
		SELECT CASE lang
			WHEN 'F' THEN Begriff_F
			WHEN 'I' THEN Begriff_I
			WHEN 'L' THEN Begriff_L
			WHEN 'R' THEN Begriff_R
			WHEN 'E' THEN Begriff_E
			WHEN 'S' THEN Begriff_S
			ELSE Begriff_D END
			FROM Uebersetzungen WHERE Schluessel = @subst INTO @transl;
		SET str = CONCAT(SUBSTRING(str, 1, @ind - 1), IF(@transl IS NULL, @subst, @transl), SUBSTRING(str, @endt + 1));
		
		SET @ind = LOCATE('Ue[', str);
	END WHILE;
	
	RETURN str;
END$$

DELIMITER ;