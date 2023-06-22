DELIMITER $$

DROP FUNCTION IF EXISTS GetLegendName$$

CREATE FUNCTION GetLegendName(Id_Category INT) RETURNS varchar(200)
BEGIN
   DROP TEMPORARY TABLE IF EXISTS levels;
   CREATE TEMPORARY TABLE levels (Num INT, Level VARCHAR(100)) ENGINE = MEMORY;
   SELECT Tiefe_Name INTO @depth FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category;
   INSERT INTO levels (SELECT 1,Ebene_1 FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category);
   INSERT INTO levels (SELECT 2,Ebene_2 FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category);
   INSERT INTO levels (SELECT 3,Ebene_3 FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category);
   INSERT INTO levels (SELECT 4,Ebene_4 FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category);
   INSERT INTO levels (SELECT 5,Ebene_5 FROM Orte_Kategorien WHERE Id_Kategorie = Id_Category);
   DELETE FROM levels WHERE Level = '';

   SELECT Num, Level INTO @n, @l FROM levels ORDER BY Num DESC LIMIT 1;
   SET @result = CONCAT ('Ue[', @l, ']');
   DELETE FROM levels WHERE Num = @n;

   SET @i = 1;
   WHILE @i < @depth DO
     SELECT Num, Level INTO @n, @l FROM levels ORDER BY Num DESC LIMIT 1;
     SET @result = CONCAT('Ue[', @l, '], ', @result);
     DELETE FROM levels WHERE Num = @n;
   SET @i = @i + 1;
   END WHILE;

   DROP TEMPORARY TABLE levels;

   RETURN @result;
END$$

DELIMITER ;