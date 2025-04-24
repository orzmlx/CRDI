--liquibase formatted sql

-- CALL ccb_allTablesClear();
--changeset ericsson:3.2.0-base-ccb_common
DROP PROCEDURE IF EXISTS `ccb_allTablesClear`;
--changeset ericsson:3.2.0-base-ccb_common1 splitStatements:false
CREATE PROCEDURE `ccb_allTablesClear`()
 BEGIN

	SET @startTime := now();

	SET @outputType := 'NrToNr';
	CALL ccb_allTablesDrop();

	SET @outputType := 'NrToLte';
	CALL ccb_allTablesDrop();

	SET @outputType := 'LteToNr';
	CALL ccb_allTablesDrop();	

	SET @outputType := 'LteToLte';
	CALL ccb_allTablesDrop();

	SET @endTime := now();
 	DROP TABLE if exists ccb_voronoiVersion;
	CREATE TABLE ccb_voronoiVersion (
		`versionVoronoiScripts` varchar(255) NOT NULL, 
		`versionMariaDB` varchar(255) NOT NULL,
		`timeSpan` INT NOT NULL,
 		`startTime` varchar(30) NOT NULL,
 		`endTime` varchar(30) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET = utf8;
	insert into ccb_voronoiVersion (versionVoronoiScripts,versionMariaDB,timeSpan,startTime,endTime) 
	values ('2022/3/11', version(), TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);

 	DROP TABLE if exists ccb_voronoiScriptTime;
	CREATE TABLE ccb_voronoiScriptTime (
		`city` varchar(255) NOT NULL,
		`sqlScript` varchar(255) NOT NULL,
		`voronoiType` varchar(255) NOT NULL,
		`timeSpan` INT NOT NULL,
 		`startTime` varchar(30) NOT NULL,
 		`endTime` varchar(30) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET = utf8;

 END;

--changeset ericsson:3.2.0-base-ccb_common2
DROP PROCEDURE IF EXISTS `ccb_allTablesDrop`;
--changeset ericsson:3.2.0-base-ccb_common3 splitStatements:false
CREATE PROCEDURE `ccb_allTablesDrop`()
 BEGIN
	
	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCell;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerBandNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;	
	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;	
	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicDistribution;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;	

 END;

--changeset ericsson:3.2.0-base-ccb_common4
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerBandNeigh`;
--changeset ericsson:3.2.0-base-ccb_common5 splitStatements:false
CREATE PROCEDURE `ccb_createTablePerCellPerBandNeigh`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerBandNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerBandNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerBandNeigh ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		,@scgi," varchar(30) NOT NULL,"
		,@sNBId_sCId," varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `cntNeighbor` INT NOT NULL,"
		," `cntOutdoor` INT NOT NULL,"
		," `cntIndoor` INT NOT NULL,"
		," `cntOther` INT NOT NULL,"
		," INDEX `",@sNBId_sCId,"` (`",@sNBId_sCId,"`) USING BTREE,"
 		," INDEX `bandNeigh` ( `bandNeigh` ) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8 COMMENT '",@noteComment,"(每小区按邻区band)'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common6
DROP PROCEDURE IF EXISTS `ccb_createTablePerCell`;
--changeset ericsson:3.2.0-base-ccb_common7 splitStatements:false
CREATE PROCEDURE `ccb_createTablePerCell`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCell"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCell;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCell ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		,@scgi," varchar(30) NOT NULL,"
		,@sNBId_sCId," varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `cntNeighbor` INT NOT NULL,"
		," `cntOutdoor` INT NOT NULL,"
		," `cntIndoor` INT NOT NULL,"
		," `cntOther` INT NOT NULL,"
 		," INDEX `",@sNBId_sCId,"` (`",@sNBId_sCId,"`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8 COMMENT '",@noteComment,"(每小区)'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common8
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerFreqNeigh`;
--changeset ericsson:3.2.0-base-ccb_common9 splitStatements:false
CREATE PROCEDURE `ccb_createTablePerCellPerFreqNeigh`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerFreqNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerFreqNeigh ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		,@scgi," varchar(30) NOT NULL,"
		,@sNBId_sCId," varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `cntNeighbor` INT NOT NULL,"
		," `cntOutdoor` INT NOT NULL,"
		," `cntIndoor` INT NOT NULL,"
		," `cntOther` INT NOT NULL,"
 		," INDEX `",@sNBId_sCId,"_freqNeigh` (`",@sNBId_sCId,"`, `freqNeigh` ) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8 COMMENT '",@noteComment,"(每小区按邻区频点)'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common10
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh`;
--changeset ericsson:3.2.0-base-ccb_common11 splitStatements:false
CREATE PROCEDURE `ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		,@scgi," varchar(30) NOT NULL,"
		,@sNBId_sCId," varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `cntNeighbor` INT NOT NULL,"
 		," INDEX `",@sNBId_sCId,"` (`",@sNBId_sCId,"`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8 COMMENT '",@noteComment,"(每小区按邻区频点cellType)'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common12
DROP PROCEDURE IF EXISTS `ccb_createTableDistribution`;
--changeset ericsson:3.2.0-base-ccb_common13 splitStatements:false
CREATE PROCEDURE `ccb_createTableDistribution`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicDistribution"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicDistribution;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicDistribution ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `cntNeighbor` INT NOT NULL,"
		," `cnt` INT NOT NULL"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8 COMMENT '",@noteComment,"(邻区个数统计)'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common14
DROP PROCEDURE IF EXISTS `ccb_createTableLteToLte`;
--changeset ericsson:3.2.0-base-ccb_common15 splitStatements:false
CREATE PROCEDURE `ccb_createTableLteToLte`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `ecgi` varchar(30) NOT NULL,"
		," `eNBId_cellId` varchar(30) NOT NULL,"
		," `eNBId` INT(11) NOT NULL,"
		," `cellId` INT(11) NOT NULL,"
		," `longitude` varchar(30) NOT NULL,"
		," `latitude` varchar(30) NOT NULL,"
		," `dir` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `pci` varchar(30) NOT NULL,"
		," `rsi` varchar(30) NOT NULL,"
		," `tac` varchar(30) NOT NULL,"
		," `sourceNeigh` varchar(30) NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `ecgiNeigh` varchar(30) NOT NULL,"
		," `eNBIdNeigh` INT(11) NOT NULL,"
		," `cellIdNeigh` INT(11) NOT NULL,"
		," `longitudeNeigh` varchar(30) NOT NULL,"
		," `latitudeNeigh` varchar(30) NOT NULL,"
		," `dirNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `pciNeigh` varchar(30) NOT NULL,"
		," `rsiNeigh` varchar(30) NOT NULL,"
		," `tacNeigh` varchar(30) NOT NULL,"
		," `voronoiTier` INT DEFAULT NULL,"
		," `assistedTier` INT DEFAULT NULL,"
		," `tier` varchar(30) NOT NULL,"
		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
-- 		," INDEX `eNBId_cellId` (`eNBId_cellId`) USING BTREE,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common16
DROP PROCEDURE IF EXISTS `ccb_createTableLteToNr`;
--changeset ericsson:3.2.0-base-ccb_common17 splitStatements:false
CREATE PROCEDURE `ccb_createTableLteToNr`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `ecgi` varchar(30) NOT NULL,"
		," `eNBId_cellId` varchar(30) NOT NULL,"
		," `eNBId` INT(11) NOT NULL,"
		," `cellId` INT(11) NOT NULL,"
		," `longitude` varchar(30) NOT NULL,"
		," `latitude` varchar(30) NOT NULL,"
		," `dir` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `pci` varchar(30) NOT NULL,"
		," `rsi` varchar(30) NOT NULL,"
		," `tac` varchar(30) NOT NULL,"
		," `sourceNeigh` varchar(30) NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `cgiNeigh` varchar(30) NOT NULL,"
		," `gNBIdNeigh` INT(11) NOT NULL,"
		," `cellLocalIdNeigh` INT(11) NOT NULL,"
		," `longitudeNeigh` varchar(30) NOT NULL,"
		," `latitudeNeigh` varchar(30) NOT NULL,"
		," `dirNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `pciNeigh` varchar(30) NOT NULL,"
		," `rsiNeigh` varchar(30) NOT NULL,"
		," `tacNeigh` varchar(30) NOT NULL,"
		," `voronoiTier` INT DEFAULT NULL,"
		," `assistedTier` INT DEFAULT NULL,"
		," `tier` varchar(30) NOT NULL,"
		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
-- 		," INDEX `eNBId_cellId` (`eNBId_cellId`) USING BTREE,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common18
DROP PROCEDURE IF EXISTS `ccb_createTableNrToLte`;
--changeset ericsson:3.2.0-base-ccb_common19 splitStatements:false
CREATE PROCEDURE `ccb_createTableNrToLte`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `cgi` varchar(30) NOT NULL,"
		," `gNBId_cellLocalId` varchar(30) NOT NULL,"
		," `gNBId` INT(11) NOT NULL,"
		," `cellLocalId` INT(11) NOT NULL,"
		," `longitude` varchar(30) NOT NULL,"
		," `latitude` varchar(30) NOT NULL,"
		," `dir` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `pci` varchar(30) NOT NULL,"
		," `rsi` varchar(30) NOT NULL,"
		," `tac` varchar(30) NOT NULL,"
		," `sourceNeigh` varchar(30) NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `ecgiNeigh` varchar(30) NOT NULL,"
		," `eNBIdNeigh` INT(11) NOT NULL,"
		," `cellIdNeigh` INT(11) NOT NULL,"
		," `longitudeNeigh` varchar(30) NOT NULL,"
		," `latitudeNeigh` varchar(30) NOT NULL,"
		," `dirNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `pciNeigh` varchar(30) NOT NULL,"
		," `rsiNeigh` varchar(30) NOT NULL,"
		," `tacNeigh` varchar(30) NOT NULL,"
		," `voronoiTier` INT DEFAULT NULL,"
		," `assistedTier` INT DEFAULT NULL,"
		," `tier` varchar(30) NOT NULL,"
		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
-- 		," INDEX `gNBId_cellLocalId` (`gNBId_cellLocalId`) USING BTREE,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common20
DROP PROCEDURE IF EXISTS `ccb_createTableNrToNr`;
--changeset ericsson:3.2.0-base-ccb_common21 splitStatements:false
CREATE PROCEDURE `ccb_createTableNrToNr`()
 BEGIN

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(30) NOT NULL,"
		," `voronoiType` varchar(30) NOT NULL,"
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `cgi` varchar(30) NOT NULL,"
 		," `gNBId_cellLocalId` varchar(30) NOT NULL,"
		," `gNBId` INT(11) NOT NULL,"
		," `cellLocalId` INT(11) NOT NULL,"
		," `longitude` varchar(30) NOT NULL,"
		," `latitude` varchar(30) NOT NULL,"
		," `dir` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `pci` varchar(30) NOT NULL,"
		," `rsi` varchar(30) NOT NULL,"
		," `tac` varchar(30) NOT NULL,"
		," `sourceNeigh` varchar(30) NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `cgiNeigh` varchar(30) NOT NULL,"
		," `gNBIdNeigh` INT(11) NOT NULL,"
		," `cellLocalIdNeigh` INT(11) NOT NULL,"
		," `longitudeNeigh` varchar(30) NOT NULL,"
		," `latitudeNeigh` varchar(30) NOT NULL,"
		," `dirNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `pciNeigh` varchar(30) NOT NULL,"
		," `rsiNeigh` varchar(30) NOT NULL,"
		," `tacNeigh` varchar(30) NOT NULL,"
		," `voronoiTier` INT DEFAULT NULL,"
		," `assistedTier` INT DEFAULT NULL,"
		," `tier` varchar(30) NOT NULL,"
		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
-- 		," INDEX `gNBId_cellLocalId` (`gNBId_cellLocalId`) USING BTREE,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

 END;

--changeset ericsson:3.2.0-base-ccb_common22
DROP PROCEDURE IF EXISTS `ccb_SourceToTarget`;
--changeset ericsson:3.2.0-base-ccb_common23 splitStatements:false
CREATE PROCEDURE `ccb_SourceToTarget`(source varchar(30), target varchar(30), nameVoronoiType varchar(30), voronoiType varchar(30))
 BEGIN

	SET @source := source;
	SET @target := target;
	SET @nameVoronoiType := nameVoronoiType;
	SET @voronoiType := voronoiType;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`cgi` varchar(30) NOT NULL,
		`source` varchar(30) NOT NULL,
		 UNIQUE `cgi` (`cgi` ) USING BTREE,
		 INDEX `source` (`source` ) USING BTREE
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;
		
	if @source='Nr' then
		insert ignore into temp0
		select cgi, 'Ericsson' as source from commoncore.COMMON_SITENR where city=@city;
	else
		insert ignore into temp0
		select ecgi, 'Ericsson' as source from commoncore.COMMON_SITELTE where city=@city;	
	end if;

	drop table if exists temp0b;
	CREATE TEMPORARY TABLE temp0b like temp0;
	if @target='Nr' then
		insert ignore into temp0b
		select cgi, 'Ericsson' as source from commoncore.COMMON_SITENR where city=@city;
 		insert ignore into temp0b
 		select cgi, 'Other' as source from commoncore.COMMON_SITENROTHER where city=@city;
	else
		insert ignore into temp0b
		select ecgi, 'Ericsson' as source from commoncore.COMMON_SITELTE where city=@city;
 		insert ignore into temp0b
 		select ecgi, 'Other' as source from commoncore.COMMON_SITELTEOTHER where city=@city;	
	end if;	
	
	drop table if exists temp1;	
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp1 ("
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `cgi` varchar(30) NOT NULL,"
		," `longitude` float NOT NULL,"
		," `latitude` float NOT NULL,"
		," `voronoi` INT NOT NULL,"
 		," `source` varchar(30) NOT NULL,"
		," INDEX `voronoi` (`voronoi` ) USING BTREE,"
 		," INDEX `source` (`source` ) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into temp1"
		," SELECT"
		," a.siteName, a.cellName, a.cgi,"
		," a.longitude, a.latitude,"
		," a.voronoi AS voronoi,"
		," b.source AS source"
		," FROM voronoi_cell a"
		," left join temp0 b on a.cgi=b.cgi"
		," WHERE a.city=@city AND a.voronoiType=@voronoiType"
 		," and not(isnull(b.cgi))"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists temp1b;
	CREATE TEMPORARY TABLE temp1b like temp1;
	SET @CMD:=CONCAT("insert into temp1b"
		," SELECT"
		," a.siteName, a.cellName, a.cgi,"
		," a.longitude, a.latitude,"
		," a.voronoi AS voronoi,"
		," b.source AS source"
		," FROM voronoi_cell a"
		," left join temp0b b on a.cgi=b.cgi"
		," WHERE a.city=@city AND a.voronoiType=@voronoiType"
 		," and not(isnull(b.cgi))"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists temp2;	
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp2 ("
		," `voronoi` INT NOT NULL,"
		," `voronoiNeigh` INT NOT NULL,"
		," `tier` INT NOT NULL"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into temp2"
		," SELECT"
		," voronoi, voronoiNeigh, tier"
		," FROM voronoi_tier a"
		," WHERE a.city=@city AND a.voronoiType=@voronoiType"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("drop table if exists ",@source,'To',@target,'On',@nameVoronoiType,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE ",@source,'To',@target,'On',@nameVoronoiType," ("
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `cgi` varchar(30) NOT NULL,"
		," `voronoi` INT NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `cgiNeigh` varchar(30) NOT NULL,"
		," `voronoiNeigh` INT NOT NULL,"
		," `distance` DECIMAL (10, 4) NOT NULL,"
		," `tier` INT NOT NULL,"
		," `voronoiType` varchar(255) NOT NULL,"
		," `city` varchar(255) NOT NULL"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
	SET @CMD:=CONCAT("insert into ",@source,'To',@target,'On',@nameVoronoiType
		," select"
		," siteName, cellName, cgi, voronoi,"
		," siteNameNeigh, cellNameNeigh, cgiNeigh, voronoiNeigh,"
		," distance,"
		," 0 AS tier,"
		," @voronoiType as voronoiType,"
		," @city as city"
		," from ("
		," SELECT"
		," a.siteName, a.cellName, a.cgi,"
		," a.longitude AS lng1, a.latitude AS lat1,"
		," a.voronoi AS voronoi,"
		," b.siteName AS siteNameNeigh, b.cellName AS cellNameNeigh, b.cgi AS cgiNeigh,"
		," b.longitude AS lng2, b.latitude AS lat2,"
		," b.voronoi AS voronoiNeigh,"
		,"	cast(6378138*2*ASIN(SQRT(POW(SIN((a.latitude*PI()/180-b.latitude*PI()/180)/2),2)+COS(a.latitude*PI()/180)*COS(b.latitude*PI()/180)*POW(SIN((a.longitude*PI()/180-b.longitude*PI()/180)/2),2))) AS DECIMAL (10, 4)) AS distance"		
		," FROM temp1 a" 
		," LEFT JOIN temp1b b ON a.voronoi=b.voronoi"
		," WHERE a.cgi != b.cgi"
		," ) t2a"
		," where distance<",@vDistance
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ",@source,'To',@target,'On',@nameVoronoiType
		," select *,"
		," @voronoiType as voronoiType,"
		," @city as city"
		," from ("
		," select"
		," t1b.siteName, t1b.cellName, t1b.cgi, t1a.voronoi,"
		," t1c.siteName as siteNameNeigh, t1c.cellName as cellNameNeigh, t1c.cgi as cgiNeigh, t1a.voronoiNeigh,"
		,"	cast(6378138*2*ASIN(SQRT(POW(SIN((t1b.latitude*PI()/180-t1c.latitude*PI()/180)/2),2)+COS(t1b.latitude*PI()/180)*COS(t1c.latitude*PI()/180)*POW(SIN((t1b.longitude*PI()/180-t1c.longitude*PI()/180)/2),2))) AS DECIMAL (10, 4)) AS distance,"
		," t1a.tier"
		," from temp2 t1a"
		," left join temp1 t1b on t1a.voronoi=t1b.voronoi"
		," left join temp1b t1c on t1a.voronoiNeigh=t1c.voronoi"
		," ) t2a"
		," where distance<",@vDistance
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

 END;


-- ----------------- --
-- 			temp5				-
-- ------- --------- --

--changeset ericsson:3.2.0-base-ccb_common24
DROP PROCEDURE IF EXISTS `ccb_createTemp5`;
--changeset ericsson:3.2.0-base-ccb_common25 splitStatements:false
CREATE PROCEDURE `ccb_createTemp5`()
 BEGIN

	SET @CMD:=CONCAT("drop table if exists temp5;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
	
-- TEMPORARY 	
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp5 ("
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `siteName` varchar(255) NOT NULL,"
		," `cellName` varchar(255) NOT NULL,"
		," `cgi` varchar(30) NOT NULL,"
 		," `NBId_cellId` varchar(30) NOT NULL,"
		," `NBId` INT(11) NOT NULL,"
		," `cellId` INT(11) NOT NULL,"
		," `longitude` varchar(30) NOT NULL,"
		," `latitude` varchar(30) NOT NULL,"
		," `dir` varchar(30) NOT NULL,"
		," `cellType` varchar(30) NOT NULL,"
		," `band` varchar(30) NOT NULL,"
		," `freq` varchar(30) NOT NULL,"
		," `pci` varchar(30) NOT NULL,"
		," `rsi` varchar(30) NOT NULL,"
		," `tac` varchar(30) NOT NULL,"
		," `sourceNeigh` varchar(30) NOT NULL,"
		," `siteNameNeigh` varchar(255) NOT NULL,"
		," `cellNameNeigh` varchar(255) NOT NULL,"
		," `cgiNeigh` varchar(30) NOT NULL,"
		," `NBIdNeigh` INT(11) NOT NULL,"
		," `cellIdNeigh` INT(11) NOT NULL,"
		," `longitudeNeigh` varchar(30) NOT NULL,"
		," `latitudeNeigh` varchar(30) NOT NULL,"
		," `dirNeigh` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `bandNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `pciNeigh` varchar(30) NOT NULL,"
		," `rsiNeigh` varchar(30) NOT NULL,"
		," `tacNeigh` varchar(30) NOT NULL,"
		," `tier` varchar(30) NOT NULL,"
-- 		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `distance` double DEFAULT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"

 		," `assistedTier` INT DEFAULT NULL,"
 		," `angularRingA` INT DEFAULT NULL,"
 		," `angularRingB` INT DEFAULT NULL"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

 END;

--changeset ericsson:3.2.0-base-ccb_common26
DROP PROCEDURE IF EXISTS `newsite_calRing`;
--changeset ericsson:3.2.0-base-ccb_common27 splitStatements:false
CREATE PROCEDURE `newsite_calRing`()
 BEGIN

update temp5 set angularRingA = ((floor((360+angle-dir)/45)+8) mod 8)+1 where distance>100 and longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0; 

update temp5 set angularRingA = angularRingA-9 where angularRingA>4 and angularRingA<90; 

update temp5 set angularRingB = ((floor(((360+angle-dir)+22.5)/45)+8) mod 8) where distance>100 and longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0; 

update temp5 set angularRingB = angularRingB-8 where angularRingB>4 and angularRingB<90;

 END;

--changeset ericsson:3.2.0-base-ccb_common28
DROP PROCEDURE IF EXISTS `newsite_rectifyOnCgi`;
--changeset ericsson:3.2.0-base-ccb_common29 splitStatements:false
CREATE PROCEDURE `newsite_rectifyOnCgi`()
 BEGIN

	drop table if exists temp6;
	CREATE TEMPORARY TABLE temp6 like temp5;
	insert into temp6
	select * from temp5 
	order by cgi, angularRingA, distance;

	drop table if exists `temp7`;
	CREATE TEMPORARY TABLE `temp7` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
 		`NBId_cellId` varchar(30) NOT NULL,
		`NBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`sourceNeigh` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`NBIdNeigh` INT(11) NOT NULL,
		`cellIdNeigh` INT(11) NOT NULL,
		`longitudeNeigh` varchar(30) NOT NULL,
		`latitudeNeigh` varchar(30) NOT NULL,
		`dirNeigh` varchar(30) NOT NULL,
		`cellTypeNeigh` varchar(30) NOT NULL,
		`bandNeigh` varchar(30) NOT NULL,
		`freqNeigh` varchar(30) NOT NULL,
		`pciNeigh` varchar(30) NOT NULL,
		`rsiNeigh` varchar(30) NOT NULL,
		`tacNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double DEFAULT NULL,
		`angle` VARCHAR (30) DEFAULT NULL,
		`diff0` VARCHAR (30) DEFAULT NULL,
		`diff1` VARCHAR (30) DEFAULT NULL,
		`cLon` VARCHAR(30) NOT NULL,
		`cLat` VARCHAR(30) NOT NULL,
		`remark0` varchar(30) NOT NULL,
		`remark0a` varchar(100) NOT NULL,
		`assistedTier` INT DEFAULT NULL,
		`angularRingA` INT DEFAULT NULL,
		`angularRingB` INT DEFAULT NULL,
		`angularRingDistA` INT NOT NULL,
		`angularRingTempA` varchar(1) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;
	
	SET @i:=0;
 	SET @marginDist:=170;
	SET @aDist:=0;
	SET @sca:='xxx';
	insert into temp7
	select *,	
		if(@sca<>concat(t1a.cgi,':',t1a.angularRingA),
				if(cellTypeNeigh='outdoor',@aDist:=t1a.distance,@aDist:=0),
				if(cellTypeNeigh='outdoor',if(distance<@aDist+@marginDist,@aDist:=@aDist+0,@aDist:=t1a.distance),@aDist:=@aDist+0)
			),
		left(@sca:=concat(t1a.cgi,':',t1a.angularRingA),1)
	from temp6 t1a;

	drop table if exists `temp8`;
	CREATE TEMPORARY TABLE `temp8` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
 		`NBId_cellId` varchar(30) NOT NULL,
		`NBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`sourceNeigh` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`NBIdNeigh` INT(11) NOT NULL,
		`cellIdNeigh` INT(11) NOT NULL,
		`longitudeNeigh` varchar(30) NOT NULL,
		`latitudeNeigh` varchar(30) NOT NULL,
		`dirNeigh` varchar(30) NOT NULL,
		`cellTypeNeigh` varchar(30) NOT NULL,
		`bandNeigh` varchar(30) NOT NULL,
		`freqNeigh` varchar(30) NOT NULL,
		`pciNeigh` varchar(30) NOT NULL,
		`rsiNeigh` varchar(30) NOT NULL,
		`tacNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double DEFAULT NULL,
		`angle` VARCHAR (30) DEFAULT NULL,
		`diff0` VARCHAR (30) DEFAULT NULL,
		`diff1` VARCHAR (30) DEFAULT NULL,
		`cLon` VARCHAR(30) NOT NULL,
		`cLat` VARCHAR(30) NOT NULL,
		`remark0` varchar(30) NOT NULL,
		`remark0a` varchar(100) NOT NULL,
		`assistedTier` INT DEFAULT NULL,
		`angularRingA` INT DEFAULT NULL,
		`angularRingB` INT DEFAULT NULL,
		`angularRingDistA` INT NOT NULL,
		`angularRingTempA` varchar(1) NOT NULL,
		`angularRingPriorityA` INT NOT NULL,
		`angularRingTemp1A` varchar(1) NOT NULL,
		`angularRingTemp2A` varchar(1) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @i:=0;
	SET @sca:='xxx';
	SET @scad:='xxxx';
	insert into temp8
	select *,
		if(@sca=concat(t1a.cgi,':',t1a.angularRingA),if(@scad=concat(t1a.cgi,':',t1a.angularRingA,':',t1a.angularRingDistA),@i:=@i+0,@i:=@i+1), if(t1a.cellTypeNeigh='outdoor',@i:=1,@i:=0)),
		left(@sca:=concat(t1a.cgi,':',t1a.angularRingA),1),
		left(@scad:=concat(t1a.cgi,':',t1a.angularRingA,':',t1a.angularRingDistA),1)
	from temp7 t1a;

	drop table if exists temp6;
	CREATE TEMPORARY TABLE temp6 like temp8;
	insert into temp6
	select * from temp8
	order by cgi, angularRingB, distance;

	drop table if exists `temp7`;
	CREATE TEMPORARY TABLE `temp7` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
 		`NBId_cellId` varchar(30) NOT NULL,
		`NBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`sourceNeigh` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`NBIdNeigh` INT(11) NOT NULL,
		`cellIdNeigh` INT(11) NOT NULL,
		`longitudeNeigh` varchar(30) NOT NULL,
		`latitudeNeigh` varchar(30) NOT NULL,
		`dirNeigh` varchar(30) NOT NULL,
		`cellTypeNeigh` varchar(30) NOT NULL,
		`bandNeigh` varchar(30) NOT NULL,
		`freqNeigh` varchar(30) NOT NULL,
		`pciNeigh` varchar(30) NOT NULL,
		`rsiNeigh` varchar(30) NOT NULL,
		`tacNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double DEFAULT NULL,
		`angle` VARCHAR (30) DEFAULT NULL,
		`diff0` VARCHAR (30) DEFAULT NULL,
		`diff1` VARCHAR (30) DEFAULT NULL,
		`cLon` VARCHAR(30) NOT NULL,
		`cLat` VARCHAR(30) NOT NULL,
		`remark0` varchar(30) NOT NULL,
		`remark0a` varchar(100) NOT NULL,
		`assistedTier` INT DEFAULT NULL,
		`angularRingA` INT DEFAULT NULL,
		`angularRingB` INT DEFAULT NULL,
		`angularRingDistA` INT NOT NULL,
		`angularRingTempA` varchar(1) NOT NULL,
		`angularRingPriorityA` INT NOT NULL,
		`angularRingTemp1A` varchar(1) NOT NULL,
		`angularRingTemp2A` varchar(1) NOT NULL,
		`angularRingDistB` INT NOT NULL,
		`angularRingTempB` varchar(1) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;
	
	SET @i:=0;
 	SET @marginDist:=170;
	SET @aDist:=0;
	SET @sca:='xxx';
	insert into temp7
	select *,
		if(@sca<>concat(t1a.cgi,':',t1a.angularRingB),
				if(cellTypeNeigh='outdoor',@aDist:=t1a.distance,@aDist:=0),
				if(cellTypeNeigh='outdoor',if(distance<@aDist+@marginDist,@aDist:=@aDist+0,@aDist:=t1a.distance),@aDist:=@aDist+0)
			),
		left(@sca:=concat(t1a.cgi,':',t1a.angularRingB),1)
	from temp6 t1a;

	drop table if exists `temp8`;
	CREATE TEMPORARY TABLE `temp8` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
 		`NBId_cellId` varchar(30) NOT NULL,
		`NBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`sourceNeigh` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`NBIdNeigh` INT(11) NOT NULL,
		`cellIdNeigh` INT(11) NOT NULL,
		`longitudeNeigh` varchar(30) NOT NULL,
		`latitudeNeigh` varchar(30) NOT NULL,
		`dirNeigh` varchar(30) NOT NULL,
		`cellTypeNeigh` varchar(30) NOT NULL,
		`bandNeigh` varchar(30) NOT NULL,
		`freqNeigh` varchar(30) NOT NULL,
		`pciNeigh` varchar(30) NOT NULL,
		`rsiNeigh` varchar(30) NOT NULL,
		`tacNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double DEFAULT NULL,
		`angle` VARCHAR (30) DEFAULT NULL,
		`diff0` VARCHAR (30) DEFAULT NULL,
		`diff1` VARCHAR (30) DEFAULT NULL,
		`cLon` VARCHAR(30) NOT NULL,
		`cLat` VARCHAR(30) NOT NULL,
		`remark0` varchar(30) NOT NULL,
		`remark0a` varchar(100) NOT NULL,
		`assistedTier` INT DEFAULT NULL,
		`angularRingA` INT DEFAULT NULL,
		`angularRingB` INT DEFAULT NULL,
		`angularRingDistA` INT NOT NULL,
		`angularRingTempA` varchar(1) NOT NULL,
		`angularRingPriorityA` INT NOT NULL,
		`angularRingTemp1A` varchar(1) NOT NULL,
		`angularRingTemp2A` varchar(1) NOT NULL,
		`angularRingDistB` INT NOT NULL,
		`angularRingTempB` varchar(1) NOT NULL,
		`angularRingPriorityB` INT NOT NULL,
		`angularRingTemp1B` varchar(1) NOT NULL,
		`angularRingTemp2B` varchar(1) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @i:=0;
	SET @sca:='xxx';
	SET @scad:='xxxx';
	insert into temp8
	select *,
		if(@sca=concat(t1a.cgi,':',t1a.angularRingB),if(@scad=concat(t1a.cgi,':',t1a.angularRingB,':',t1a.angularRingDistB),@i:=@i+0,@i:=@i+1), if(t1a.cellTypeNeigh='outdoor',@i:=1,@i:=0)),
		left(@sca:=concat(t1a.cgi,':',t1a.angularRingB),1),
		left(@scad:=concat(t1a.cgi,':',t1a.angularRingB,':',t1a.angularRingDistB),1)
	from temp7 t1a;

	drop table if exists temp6;
	CREATE TEMPORARY TABLE temp6 (
		`rk` varchar(255) NOT NULL,
		`angularRingDist1stA` INT NOT NULL,
 		`angularRingDist2ndA` INT NOT NULL,
		`angularRingDist3rdA` INT NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	insert into temp6
	select concat(cgi,':',angularRingA) as rk, 
	max(if(angularRingPriorityA=1,angularRingDistA,0)) as max1st, 
	max(if(angularRingPriorityA=2,angularRingDistA,0)) as max2nd,
	max(if(angularRingPriorityA=3,angularRingDistA,0)) as max3rd
	from temp8
	group by concat(cgi,':',angularRingA);

	ALTER TABLE temp6 ADD INDEX `rk` ( `rk` ) USING BTREE;

	drop table if exists temp7;
	CREATE TEMPORARY TABLE temp7 (
		`rk` varchar(255) NOT NULL,
		`angularRingDist1stB` INT NOT NULL,
 		`angularRingDist2ndB` INT NOT NULL,
		`angularRingDist3rdB` INT NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	insert into temp7
	select concat(cgi,':',angularRingB) as rk, 
	max(if(angularRingPriorityB=1,angularRingDistB,0)) as max1st, 
	max(if(angularRingPriorityB=2,angularRingDistB,0)) as max2nd,
	max(if(angularRingPriorityB=3,angularRingDistB,0)) as max3rd
	from temp8
	group by concat(cgi,':',angularRingB);
	
	ALTER TABLE temp7 ADD INDEX `rk` ( `rk` ) USING BTREE;

	drop table if exists temp9;
	CREATE TEMPORARY TABLE temp9 (
		`cgi` varchar(30) NOT NULL,
		`cntFront` INT NOT NULL,
 		`cntSideBack` INT NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	insert into temp9
	select cgi, sum(if(ringType='front',1,0)) as cntFront, sum(if(ringType='front',0,1)) as cntSideBack
	from (
	select cgi, siteNameNeigh, if(abs(angularRingB)<=1,'front','sideback') as ringType 
	from temp8
	where cellTypeNeigh='outdoor'
	group by cgi, siteNameNeigh 
	) t2a
	group by cgi;

	ALTER TABLE temp9 ADD INDEX `cgi` ( `cgi` ) USING BTREE;

	CALL ccb_createTemp5RectifyOnCgi();

	insert into temp5
	select t1a.*,
			t1b.angularRingDist1stA,
			t1b.angularRingDist2ndA,
			t1b.angularRingDist3rdA,
			t1c.angularRingDist1stB,
			t1c.angularRingDist2ndB,
			t1c.angularRingDist3rdB,
			ifnull(t1d.cntFront,0) as cntFront,
			ifnull(t1d.cntSideBack,0) as cntSideBack
		from temp8 t1a
		left join temp6 t1b
		on concat(t1a.cgi,':',t1a.angularRingA)=t1b.rk
		left join temp7 t1c
		on concat(t1a.cgi,':',t1a.angularRingB)=t1c.rk
		left join temp9 t1d
		on t1a.cgi=t1d.cgi;

  update temp5 set angularRingPriorityA=1 
 	where angularRingPriorityA=2 and distance<least(angularRingDist1stA*1.3,angularRingDist1stA+300);

  update temp5 set angularRingPriorityA=3 
 	where angularRingPriorityA=4 and distance<least(angularRingDist3rdA*1.1,angularRingDist3rdA+300);

  update temp5 set angularRingPriorityB=1 
 	where angularRingPriorityB=2 and distance<least(angularRingDist1stB*1.3,angularRingDist1stB+300);

  update temp5 set angularRingPriorityB=3 
 	where angularRingPriorityB=4 and distance<least(angularRingDist3rdB*1.1,angularRingDist3rdB+300);

  update temp5 set angularRingPriorityA=4
 	where angularRingPriorityA=3 and angularRingDist3rdA>angularRingDist2ndA*1.5;

  update temp5 set angularRingPriorityB=4
 	where angularRingPriorityB=3 and angularRingDist3rdB>angularRingDist2ndB*1.5;

  update temp5 set angularRingPriorityA=1 
 	where angularRingPriorityA=2 and not(abs(angularRingA)<=2) and cntFront<=3 and distance<angularRingDist1stA*2.5;

  update temp5 set angularRingPriorityB=1 
 	where angularRingPriorityB=2 and not(abs(angularRingB)<=1) and cntFront<=3 and distance<angularRingDist1stB*2.5;

  update temp5 set angularRingPriorityA=1 
 	where angularRingPriorityA=2 and not(abs(angularRingA)<=1) and cntFront<=3 and distance<angularRingDist1stA*2.0;

  update temp5 set angularRingPriorityA=1 
 	where angularRingPriorityA=3 and not(abs(angularRingA)<=2) and cntFront<=3 and distance<angularRingDist1stA*2.0;

  update temp5 set angularRingPriorityB=1 
 	where angularRingPriorityB=3 and not(abs(angularRingB)<=1) and cntFront<=3 and distance<angularRingDist1stB*2.0;

 	update temp5 set angularRingPriorityA=2
  	where cellTypeNeigh='indoor' and angularRingPriorityA=1 and distance>(angularRingDist1stA+angularRingDist2ndA)/2 
		and angularRingDist1stA>0 and angularRingDist2ndA>0;

 	update temp5 set angularRingPriorityA=1
  	where cellTypeNeigh='indoor' and angularRingPriorityA=0 and distance>angularRingDist1stA/2 
		and angularRingDist1stA>0;

 	update temp5 set angularRingPriorityB=2
  	where cellTypeNeigh='indoor' and angularRingPriorityB=1 and distance>(angularRingDist1stB+angularRingDist2ndB)/2 
		and angularRingDist1stB>0 and angularRingDist2ndB>0;

 	update temp5 set angularRingPriorityB=1
  	where cellTypeNeigh='indoor' and angularRingPriorityB=0 and distance>angularRingDist1stB/2 
		and angularRingDist1stB>0;

	update temp5 set angularRingPriorityA=0, angularRingPriorityB=0 where angularRingA=99;
	update temp5 set assistedTier=greatest(angularRingPriorityA,angularRingPriorityB);

 	update temp5 set assistedTier=2 where assistedTier=3;
	
 	update temp5 set assistedTier=3 where assistedTier between 4 and 5;
	
 	update temp5 set assistedTier=4 where assistedTier>=6;

 END;

--changeset ericsson:3.2.0-base-ccb_common30
DROP PROCEDURE IF EXISTS `ccb_createTemp5RectifyOnCgi`;
--changeset ericsson:3.2.0-base-ccb_common31 splitStatements:false
CREATE PROCEDURE `ccb_createTemp5RectifyOnCgi`()
 BEGIN

	drop table if exists `temp5`;
	CREATE TEMPORARY TABLE `temp5` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
 		`NBId_cellId` varchar(30) NOT NULL,
		`NBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`sourceNeigh` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`NBIdNeigh` INT(11) NOT NULL,
		`cellIdNeigh` INT(11) NOT NULL,
		`longitudeNeigh` varchar(30) NOT NULL,
		`latitudeNeigh` varchar(30) NOT NULL,
		`dirNeigh` varchar(30) NOT NULL,
		`cellTypeNeigh` varchar(30) NOT NULL,
		`bandNeigh` varchar(30) NOT NULL,
		`freqNeigh` varchar(30) NOT NULL,
		`pciNeigh` varchar(30) NOT NULL,
		`rsiNeigh` varchar(30) NOT NULL,
		`tacNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double DEFAULT NULL,
		`angle` VARCHAR (30) DEFAULT NULL,
		`diff0` VARCHAR (30) DEFAULT NULL,
		`diff1` VARCHAR (30) DEFAULT NULL,
		`cLon` VARCHAR(30) NOT NULL,
		`cLat` VARCHAR(30) NOT NULL,
		`remark0` varchar(30) NOT NULL,
		`remark0a` varchar(100) NOT NULL,
		`assistedTier` INT DEFAULT NULL,
		`angularRingA` INT DEFAULT NULL,
		`angularRingB` INT DEFAULT NULL,
		`angularRingDistA` INT NOT NULL,
		`angularRingTempA` varchar(1) NOT NULL,
		`angularRingPriorityA` INT NOT NULL,
		`angularRingTemp1A` varchar(1) NOT NULL,
		`angularRingTemp2A` varchar(1) NOT NULL,
		`angularRingDistB` INT NOT NULL,
		`angularRingTempB` varchar(1) NOT NULL,
		`angularRingPriorityB` INT NOT NULL,
		`angularRingTemp1B` varchar(1) NOT NULL,
		`angularRingTemp2B` varchar(1) NOT NULL,
		`angularRingDist1stA` INT NOT NULL,
  	`angularRingDist2ndA` INT NOT NULL,
 		`angularRingDist3rdA` INT NOT NULL,
 		`angularRingDist1stB` INT NOT NULL,
  	`angularRingDist2ndB` INT NOT NULL,
 		`angularRingDist3rdB` INT NOT NULL,
		`cntFront` INT NOT NULL,
 		`cntSideBack` INT NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

 END;

