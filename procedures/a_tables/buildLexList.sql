DELIMITER $$

DROP PROCEDURE IF EXISTS buildLexList$$

CREATE PROCEDURE buildLexList ()
BEGIN

CREATE TABLE IF NOT EXISTS a_lex_list (
  `Ids` varchar(100) NOT NULL,
  `Type` varchar(500) NOT NULL,
  `Type_Lang` varchar(3) NOT NULL,
  `POS` varchar(10) NOT NULL,
  `Gender` varchar(1) NOT NULL,
  `Affix` varchar(50) NOT NULL,
  PRIMARY KEY (`Ids`)
);

DELETE FROM a_lex_list;

INSERT INTO a_lex_list
SELECT GROUP_CONCAT(DISTINCT Id_Type ORDER BY Type ASC, Gender ASC SEPARATOR '+'), Type, Type_Lang, POS, '' AS Gender, Affix 
FROM Z_Ling 
WHERE Type_Kind = 'L' AND Source_Typing = 'VA' GROUP BY Type, Type_Lang, POS;

END$$

DELIMITER ;