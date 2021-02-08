DELIMITER $$

DROP PROCEDURE IF EXISTS computeTypeOccurances$$

CREATE PROCEDURE computeTypeOccurances ()
BEGIN
	DELETE FROM A_Typ_Vorkommen;

	INSERT INTO A_Typ_Vorkommen
		SELECT CONCAT('B', Id_Base_Type) AS Id, SUM(Alpine_Convention) > 0 AS Vorkommen_AK FROM z_ling WHERE Base_Type IS NOT NULL GROUP BY Id_Base_Type
			UNION
		SELECT CONCAT('L', Id_Type) AS Id, SUM(Alpine_Convention) > 0 AS Vorkommen_AK FROM z_ling WHERE Type IS NOT NULL AND Type_Kind = 'L' AND Source_Typing = 'VA' GROUP BY Id_Type, Type_Kind
--			UNION
--		SELECT CONCAT('P', Id_Type) AS Id, SUM(Alpine_Convention) > 0 AS Vorkommen_AK FROM z_ling WHERE Type IS NOT NULL AND Type_Kind = 'P' AND Source_Typing = 'VA' GROUP BY Id_Type, Type_Kind;
END$$

DELIMITER ;