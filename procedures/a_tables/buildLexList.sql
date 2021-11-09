DELIMITER $$

DROP PROCEDURE IF EXISTS buildLexList$$

CREATE PROCEDURE buildLexList ()
BEGIN

DELETE FROM a_lex_list;

INSERT INTO a_lex_list
SELECT GROUP_CONCAT(DISTINCT Id_Type ORDER BY Type ASC, Gender ASC SEPARATOR '+'), Type, Type_Lang, POS, '' AS Gender, Affix 
FROM Z_Ling 
WHERE Type_Kind = 'L' AND Source_Typing = 'VA' GROUP BY Type, Type_Lang, POS;

END$$

DELIMITER ;