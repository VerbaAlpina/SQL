DELIMITER $$

DROP PROCEDURE IF EXISTS buildClusterData$$

CREATE PROCEDURE buildClusterData ()
BEGIN
	SET @num = 0;

	delete from a_punkt_index;
	
	insert into a_punkt_index (Geodaten, Nummer) 
		select Geo, @num := @num + 1 from
		(select distinct Geodaten as Geo from orte where GeometryType(Geodaten) = 'POINT'
			union
		select distinct Georeferenz as Geo from informanten WHERE Georeferenz != '' AND Georeferenz IS NOT NULL) t;
	
END$$

DELIMITER ;