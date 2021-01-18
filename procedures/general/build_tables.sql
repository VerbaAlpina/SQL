DELIMITER $$

DROP PROCEDURE IF EXISTS build_tables$$

CREATE PROCEDURE build_tables ()
begin
   call buildSimilarityTable();
   CALL buildQuantifyTables();
   CALL buildCatTagList();
   CALL buildTagValues();
   CALL zling();
   CALL computeTypeOccurances();
   CALL zgeo();
   call zbib();
   call zconcepts();
END$$

DELIMITER ;