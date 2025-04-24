--liquibase formatted sql
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_freqBand`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi1 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_freqBand`()
 BEGIN
 SET @ver := '23/10/9';

	DROP TABLE if exists ccb_FreqBand;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE ccb_FreqBand ("
		,"`band` varchar(30) NOT NULL,"
		,"`freqStart` INT NOT NULL,"
		,"`freqEnd` INT NOT NULL"
		") ENGINE = MyISAM DEFAULT CHARSET = utf8;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	insert into ccb_FreqBand (band, freqStart, freqEnd)
									values 	('Band3',1200,1949),
													('Band8',3450,3799),
													('Band34',36200,36349),
													('Band37',37550,37749),
													('Band38',37750,38249),
													('Band39',38250,38649),
													('Band40',38650,39649),
													('Band41',39650,41589),
													('n28',151600,160600),	-- 	CM
													('n41',499200,537999),	-- CM.2.515-2.675GHz
													('n78',620000,653333),	-- CT.3.4-3.5GHz/CU.3.5-3.6GHz
													('n79',693333,733333);	-- 	(TDD) -- CM.4.8-4.9GHz

	ALTER TABLE ccb_FreqBand ADD INDEX `mix` (`freqStart`,`freqEnd`) USING BTREE;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi2 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_5gTo5g`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi3 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_5gTo5g`(s varchar(50))
 BEGIN
 SET @ver := '23/10/9';

		SET @startTime := now();
		SET @scriptName := 'ccb_5gTo5g';

 		SET @dBSite := concat(database(),'.');
		SET @sitePrefix := '';

		SET @city := s;
		SET @dbOutput := '';
 		SET @dbLocal := database();
		SET @dbOutputName := database();
		SET @tableReset := 0;

		CALL ccb_freqBand();

if 1=2 then
		drop table if exists UserDefinedRules;
		CALL newsite_UserDefinedRules();
end if;

		SET @dBVoronoiSetting := 'kgetsetting.';
		SET @dbVoronoi := 'Voronoi.';
-- 		SET @dbSite := 'commoncore.';
		SET @noteDistance := '基站数据库缺数据!';

		SET @NrToNrOnBasic :=1;
		SET @NrToNrOnUser='none';

		SET @outputType := 'NrToNr';
 		SET @vDistance := 6000;
 		SET @vDistance := 3000;

		SET @scgi := 'cgi';
		SET @sNBId_sCId := 'gNBId_cellLocalId';

		SET @sCell := '原NR';
		SET @tCell := '目标NR';
		SET @freqType := 'ssbFrequency';
		SET @freqTypeNeigh := 'ssbFrequency';

		SET @t_siteNR 			:= concat(@dbSite,@sitePrefix,'SITENR');
		SET @t_siteNROther 		:= concat(@dbSite,@sitePrefix,'SITENROTHER');
		SET @t_siteLTE 			:= concat(@dbSite,@sitePrefix,'SITELTE');
		SET @t_siteLTEOther		:= concat(@dbSite,@sitePrefix,'SITELTEOTHER');

 		SET @t_BaseFromSource 		:= @t_siteNR;
		SET @t_BaseFromTarget 		:= @t_siteNR;
 		SET @t_BaseFromSourceOther	:= @t_siteNROther;
		SET @t_BaseFromTargetOther	:= @t_siteNROther;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
		`gNBId_cellLocalId` varchar(30) NOT NULL,
		`gNBId` INT(11) NOT NULL,
		`cellLocalId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (cgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, CGI,"
		," substring_index(CGI, '-', -2) as gNBId_cellLocalId,"
		," substring_index(substring_index(CGI, '-', -2),'-',1) as gNBId,"
		," substring_index(CGI, '-', -1) as cellLocalId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," NRFrequencySSB as freq,"
		," nRPCI, nRRSI as rsi, nRTAC,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromSource," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.NRFrequencySSB) between t1b.freqStart and t1b.freqEnd"
		," where CGI<>'#REF!'"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists t_BASE_SVR;
	CREATE TEMPORARY TABLE t_BASE_SVR like temp0;
	insert into t_BASE_SVR select * from temp0;

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, CGI,"
		," substring_index(CGI, '-', -2) as gNBId_cellLocalId,"
		," substring_index(substring_index(CGI, '-', -2),'-',1) as gNBId,"
		," substring_index(CGI, '-', -1) as cellLocalId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," ssbFrequency as freq,"
		," nRPCI, rsi, nRTAC,"
		," 'Other' as source, city"
		," from ",@t_BaseFromTargetOther," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.ssbFrequency) between t1b.freqStart and t1b.freqEnd"
		," where CGI<>'#REF!'"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists t_BASE_NEIGH;
	CREATE TEMPORARY TABLE t_BASE_NEIGH like temp0;
	insert into t_BASE_NEIGH select * from temp0;

if (exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBVoronoiSetting,'.',1) and TABLE_NAME='ccb_voronoiSetting')) then

	if 1=2 then
		SET @typeSelected := 'NR';
		SET @CMD:=CONCAT("select if(NRtoNR like '%NR%' and NRtoNR like '%LTE%','NRLTE',if(NRtoNR like '%LTE%','LTE','NR'))"
			," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
			," where city=@city"
			," group by city"
			," into @typeSelected"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	else
		SET @typeSelected := 'NR';
		SET @CMD:=CONCAT("select if(NRtoNR like '%LTE%','LTE','NR')"
			," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
			," where city=@city"
			," group by city"
			," into @typeSelected"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	end if;

end if;

	SET @typeSelected := 'NR';

if @typeSelected='NRLTE' then
	CALL ccb_SourceToTarget('Nr','Nr','Nr','NrLteVoronoi');
	SET @voronoiType := 'NrLteVoronoi';
	SET @nameVoronoiType :='Nr';
	SET @noteVoronoiType :='NR';
	SET @noteComment := 'NrToNr邻区采用NR+LTE泰森';
else
	if @typeSelected='NR' then
		CALL ccb_SourceToTarget('Nr','Nr','Nr','NrVoronoi');
		SET @voronoiType := 'NrVoronoi';
		SET @nameVoronoiType :='Nr';
		SET @noteVoronoiType :='NR';
		SET @noteComment := 'NrToNr邻区采用NR泰森';
	else
		CALL ccb_SourceToTarget('Nr','Nr','Lte','LteVoronoi');
		SET @voronoiType := 'LteVoronoi';
		SET @nameVoronoiType :='Lte';
		SET @noteVoronoiType :='LTE';
		SET @noteComment := 'NrToNr邻区采用LTE泰森';
	end if;
end if;

	SET @voronoiTypeJoin := @voronoiType;

	CALL ccb_5gTo5g_VoronoiType();

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;

	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`)
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi4 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_5gTo5g_VoronoiType`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi5 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_5gTo5g_VoronoiType`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists `t_Vor`;
	CREATE TEMPORARY TABLE `t_Vor` (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @CMD:=CONCAT("insert into t_Vor"
		," select t1a.siteName, t1a.cellName, t1a.cgi,"
		," t1a.siteNameNeigh, t1a.cellNameNeigh, t1a.cgiNeigh,"
		," tier, distance"
		," from ",@dbVoronoi,"NrToNrOn",@nameVoronoiType," t1a"
		," where distance<@vDistance"
		," and voronoiType=@voronoiType"
		," and city=@city"
		," and cgi<>'' and cgiNeigh<>''"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	CALL ccb_createTemp5();
	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.cgi,'-',-2),':',substring_index(t1a.cgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1b.city,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.cgi,"
		," t1b.gNBId_cellLocalId,"
		," t1b.gNBId,t1b.cellLocalId,"
		," t1b.longitude,t1b.latitude,t1b.dir,t1b.cellType,"
		," ifnull(t1b.band,'?') as band,"
		," t1b.freq, t1b.pci, t1b.rsi, t1b.tac,"
		," t1c.source as sourceNeigh,"
		," t1c.city as cityNeigh,"
		," t1a.siteNameNeigh,"
		," t1a.cellNameNeigh,"
		," t1a.cgiNeigh,"
		," t1c.gNBId as gNBIdNeigh,"
		," t1c.cellLocalId as cellLocalIdNeigh,"
		," t1c.Longitude,t1c.Latitude,t1c.Dir,t1c.cellType,"
		," ifnull(t1c.band,'?') as bandNeigh,"
		," t1c.freq as freqNeigh, t1c.pci as pciNeigh, t1c.rsi as rsiNeigh, t1c.tac as tacNeigh,"
		," t1a.tier, t1a.tier, t1a.distance,"
		," '' as angle, '' as diff0, '' as diff1,"
		,@cLon," as cLon, ",@cLat," as cLat,"
		," '' as remark0,"
		," '' as remark0a,"
 		," 99 as assistedTier, 99 as angularRingA, 99 as angularRingB"
		," from t_Vor t1a"
 		," left join t_BASE_SVR t1b"
 		," on t1a.cgi=t1b.cgi"
 		," left join t_BASE_NEIGH t1c"
 		," on t1a.cgiNeigh=t1c.cgi"
		," where not(isnull(t1b.cgi)) and not(isnull(t1c.cgi))"
		," and ("
		," (t1b.cellType='outdoor' and t1c.cellType='outdoor')"
		," or ( ((t1b.cellType='outdoor' and t1c.cellType='indoor') or (t1b.cellType='indoor' and t1c.cellType='outdoor'))"
		," and t1a.distance<=500 )"
		," or ( (t1b.cellType='indoor' and t1c.cellType='indoor')"
		," and t1a.distance<=20 )"
		," )"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	CALL newsite_calRing();
	CALL newsite_rectifyOnCgi();
	update temp5 set tier=greatest(voronoiTier, assistedTier);
	CALL newsite_selectNeighborBasic();

	SET @algType := "同站小区";
	update temp5 set remark0=@algType, remark0a='[条件E1]站内小区(siteName=siteNameNeigh)!'
		where siteName = siteNameNeigh
		and remark0a=''
		and angle<>'';

	update temp5 set remark0='', remark0a=''
		where cgi = cgiNeigh;

	CALL ccb_createTableNrToNr();
	CALL ccb_insertTable();
	CALL ccb_updateTableRank();

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi6 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTableNrToNr`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi7 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTableNrToNr`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(50) NOT NULL,"
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
		," `cityNeigh` varchar(50) NOT NULL,"
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
		," `rankPerCellTypeNeighPerFreqNeigh` INT NOT NULL,"
		," `rankPerCellTypeNeigh` INT NOT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi8 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_4gTo4g`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi9 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_4gTo4g`(s varchar(50))
 BEGIN
 SET @ver := '23/10/9';

		SET @city := s;

		SET @startTime := now();
		SET @scriptName := 'ccb_4gTo4g';

 		SET @dBSite := concat(database(),'.');
		SET @sitePrefix := '';

		SET @city := s;

		SET @dbOutput := '';
		SET @dbOutputName := database();
		SET @tableReset := 0;

		CALL ccb_freqBand();

if 1=2 then
		drop table if exists UserDefinedRules;
		CALL newsite_UserDefinedRules();
end if;

		SET @dBVoronoiSetting := 'kgetsetting.';
		SET @dbVoronoi := 'Voronoi.';
-- 		SET @dbSite := 'commoncore.';
		SET @noteDistance := '基站数据库缺数据!';

		SET @LteToLteOnBasic :=1;
		SET @LteToLteOnUser='none';

		SET @outputType := 'LteToLte';
 		SET @vDistance := 6000;
 		SET @vDistance := 3000;

		CALL ccb_SourceToTarget('Lte','Lte','Lte', 'LteVoronoi');

		SET @scgi := 'ecgi';
		SET @sNBId_sCId := 'eNBId_cellId';

		SET @sCell := '原LTE';
		SET @tCell := '目标LTE';
		SET @freqType := 'earfcn';
		SET @freqTypeNeigh := 'earfcn';
 		SET @t_BaseFromSource := concat(@dbSite,@sitePrefix,'SITELTE');
		SET @t_BaseFromTarget := concat(@dbSite,@sitePrefix,'SITELTE');

 		SET @t_BaseFromSourceOther := concat(@dbSite,@sitePrefix,'SITELTEOTHER');
		SET @t_BaseFromTargetOther := concat(@dbSite,@sitePrefix,'SITELTEOTHER');

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`ecgi` varchar(30) NOT NULL,
		`eNBId_cellId` varchar(255) NOT NULL,
		`eNBId` INT(11) NOT NULL,
		`cellId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`duplexMode` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (ecgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, ECGI,"
		," substring_index(ECGI, '-', -2) as eNBId_cellId,"
		," substring_index(substring_index(ECGI, '-', -2),'-',1) as eNBId,"
		," substring_index(ECGI, '-', -1) as cellId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," duplexMode,"
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromSource," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.earfcn) between t1b.freqStart and t1b.freqEnd"
		," where not(ECGI='#REF!' or duplexMode like '%NB%')"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_SVR`;
	CREATE TEMPORARY TABLE t_BASE_SVR like temp0;
	insert into t_BASE_SVR select * from temp0;

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, ECGI,"
		," substring_index(ECGI, '-', -2) as eNBId_cellId,"
		," substring_index(substring_index(ECGI, '-', -2),'-',1) as eNBId,"
		," substring_index(ECGI, '-', -1) as cellId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," duplexMode,"
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Other' as source, city"
		," from ",@t_BaseFromTargetOther," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.earfcn) between t1b.freqStart and t1b.freqEnd"
		," where not(ECGI='#REF!' or duplexMode like '%NB%')"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_NEIGH`;
	CREATE TEMPORARY TABLE t_BASE_NEIGH like temp0;
	insert into t_BASE_NEIGH select * from temp0;

	SET @voronoiType := 'LteVoronoi';
	SET @nameVoronoiType :='Lte';
	SET @noteVoronoiType :='LTE';
	SET @noteComment := 'LteToLte邻区采用LTE泰森';

	SET @voronoiTypeJoin := @voronoiType;

	CALL ccb_4gTo4g_VoronoiType();

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;

	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`)
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi10 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_4gTo4g_VoronoiType`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi11 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_4gTo4g_VoronoiType`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists `t_Vor`;
	CREATE TEMPORARY TABLE `t_Vor` (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`ecgi` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`ecgiNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @CMD:=CONCAT("insert into t_Vor"
		," select t1a.siteName, t1a.cellName, t1a.cgi,"
		," t1a.siteNameNeigh, t1a.cellNameNeigh, t1a.cgiNeigh,"
		," tier, distance"
		," from ",@dbVoronoi,"LteToLteOn",@nameVoronoiType," t1a"
		," where distance<@vDistance"
		," and voronoiType=@voronoiType"
		," and city=@city"
		," and cgi<>'' and cgiNeigh<>''"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	CALL ccb_createTemp5();
	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.ecgi,'-',-2),':',substring_index(t1a.ecgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1b.city,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.ecgi,"
		," t1b.eNBId_cellId,"
		," t1b.eNBId,t1b.cellId,"
		," t1b.longitude,t1b.latitude,t1b.dir,t1b.cellType,"
		," ifnull(t1b.band,'?') as band,"
		," t1b.freq, t1b.pci, t1b.rsi, t1b.tac,"
		," t1c.source as sourceNeigh,"
		," t1c.city as cityNeigh,"
		," t1a.siteNameNeigh,"
		," t1a.cellNameNeigh,"
		," t1a.ecgiNeigh,"
		," t1c.eNBId as eNBIdNeigh,"
		," t1c.cellId as cellIdNeigh,"
		," t1c.Longitude,t1c.Latitude,t1c.Dir,t1c.cellType,"
		," ifnull(t1c.band,'?') as bandNeigh,"
		," t1c.freq as freqNeigh, t1c.pci as pciNeigh, t1c.rsi as rsiNeigh, t1c.tac as tacNeigh,"
		," t1a.tier, t1a.tier, t1a.distance,"
		," '' as angle, '' as diff0, '' as diff1,"
		,@cLon," as cLon, ",@cLat," as cLat,"
		," '' as remark0,"
		," '' as remark0a,"
		," 99 as assistedTier, 99 as angularRingA, 99 as angularRingB"
		," from t_Vor t1a"
 		," left join t_BASE_SVR t1b"
 		," on t1a.ecgi=t1b.ecgi"
 		," left join t_BASE_NEIGH t1c"
 		," on t1a.ecgiNeigh=t1c.ecgi"
		," where not(isnull(t1b.ecgi)) and not(isnull(t1c.ecgi))"
		," and ("
		," (t1b.cellType='outdoor' and t1c.cellType='outdoor')"
		," or ( ((t1b.cellType='outdoor' and t1c.cellType='indoor') or (t1b.cellType='indoor' and t1c.cellType='outdoor'))"
		," and t1a.distance<=500 )"
		," or ( (t1b.cellType='indoor' and t1c.cellType='indoor')"
		," and t1a.distance<=20 )"
		," )"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	CALL newsite_calRing();
	CALL newsite_rectifyOnCgi();

	update temp5 set tier=greatest(voronoiTier, assistedTier);

	CALL newsite_selectNeighborBasic();

	SET @algType := "同站小区";
	update temp5 set remark0=@algType, remark0a='[条件E1]站内小区(siteName=siteNameNeigh)!'
		where siteName = siteNameNeigh
		and remark0a=''
		and angle<>'';

	update temp5 set remark0='', remark0a=''
		where cgi = cgiNeigh;

	CALL ccb_createTableLteToLte();
	CALL ccb_insertTable();
	CALL ccb_updateTableRank();

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi12 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTableLteToLte`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi13 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTableLteToLte`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(50) NOT NULL,"
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
		," `cityNeigh` varchar(50) NOT NULL,"
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
		," `rankPerCellTypeNeighPerFreqNeigh` INT NOT NULL,"
		," `rankPerCellTypeNeigh` INT NOT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi14 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_5gTo4g`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi15 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_5gTo4g`(s varchar(50))
 BEGIN
 SET @ver := '23/10/9';

		SET @startTime := now();
		SET @scriptName := 'ccb_5gTo4g';

 		SET @dBSite := concat(database(),'.');
		SET @sitePrefix := '';

		SET @city := s;
		SET @dbOutput := '';
		SET @dbOutputName := database();
		SET @tableReset := 0;

		CALL ccb_freqBand();

if 1=2 then
		drop table if exists UserDefinedRules;
		CALL newsite_UserDefinedRules();
end if;

		SET @dBVoronoiSetting := 'kgetsetting.';
		SET @dbVoronoi := 'Voronoi.';
-- 		SET @dbSite := 'commoncore.';
		SET @noteDistance := '基站数据库缺数据!';

		SET @NrToLteOnBasic :=1;
		SET @NrToLteOnUser='none';

		SET @outputType := 'NrToLte';
 		SET @vDistance := 6000;
 		SET @vDistance := 2500;

		SET @scgi := 'cgi';
		SET @sNBId_sCId := 'gNBId_cellLocalId';

		SET @sCell := 'NR';
		SET @tCell := 'LTE';
		SET @freqType := 'ssbFrequency';
		SET @freqTypeNeigh := 'earfcn';

		SET @t_siteNR 				:= concat(@dbSite,@sitePrefix,'SITENR');
		SET @t_siteNROther 			:= concat(@dbSite,@sitePrefix,'SITENROTHER');
		SET @t_siteLTE 				:= concat(@dbSite,@sitePrefix,'SITELTE');
		SET @t_siteLTEOther			:= concat(@dbSite,@sitePrefix,'SITELTEOTHER');

		SET @t_BaseFromLTE 			:= @t_siteLTE;
 		SET @t_BaseFromNR 			:= @t_siteNR;
		SET @t_BaseFromLTEOther		:= @t_siteLTEOther;
 		SET @t_BaseFromNROther 		:= @t_siteNROther;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
		`gNBId_cellLocalId` varchar(255) NOT NULL,
		`gNBId` INT(11) NOT NULL,
		`cellLocalId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (cgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, cgi,"
		," substring_index(CGI, '-', -2) as gNBId_cellLocalId,"
		," substring_index(substring_index(CGI, '-', -2),'-',1) as gNBId,"
		," substring_index(CGI, '-', -1) as cellLocalId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," NRFrequencySSB as freq,"
		," nRPCI, nRRSI as rsi, nRTAC,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromNR," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.NRFrequencySSB) between t1b.freqStart and t1b.freqEnd"
		," where CGI<>'#REF!'"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_NR`;
	CREATE TEMPORARY TABLE t_BASE_NR like temp0;
	insert into t_BASE_NR select * from temp0;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`ecgi` varchar(30) NOT NULL,
		`eNBId_cellId` varchar(255) NOT NULL,
		`eNBId` INT(11) NOT NULL,
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
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (ecgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, ECGI,"
		," substring_index(ECGI, '-', -2) as eNBId_cellId,"
		," substring_index(substring_index(ECGI, '-', -2),'-',1) as eNBId,"
		," substring_index(ECGI, '-', -1) as cellId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromLTE," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.earfcn) between t1b.freqStart and t1b.freqEnd"
		," where not(ECGI='#REF!' or duplexMode like '%NB%')"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, ECGI,"
		," substring_index(ECGI, '-', -2) as eNBId_cellId,"
		," substring_index(substring_index(ECGI, '-', -2),'-',1) as eNBId,"
		," substring_index(ECGI, '-', -1) as cellId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Other' as source, city"
		," from ",@t_BaseFromLTEOther," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.earfcn) between t1b.freqStart and t1b.freqEnd"
		," where not(ECGI='#REF!' or duplexMode like '%NB%')"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_LTE`;
	CREATE TEMPORARY TABLE t_BASE_LTE like temp0;
	insert into t_BASE_LTE select * from temp0;

if (exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBVoronoiSetting,'.',1) and TABLE_NAME='ccb_voronoiSetting')) then

	if 1=1 then
		SET @typeSelected := 'NRouterLTE';
		SET @CMD:=CONCAT("select if(NRtoLTE like '%NR%' and NRtoLTE like '%LTE%',if(NRtoLTE like '%outer%','NRouterLTE','NRinnerLTE'),if(NRtoLTE like '%LTE%','LTE','NR'))"
		," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
		," where city=@city"
		," group by city"
		," into @typeSelected"
		," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	else
		SET @typeSelected := 'NR';
		SET @CMD:=CONCAT("select if(NRtoLTE like '%LTE%','LTE','NR')"
		," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
		," where city=@city"
		," group by city"
		," into @typeSelected"
		," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	end if;

end if;

	if @typeSelected='NRinnerLTE' then
 		CALL ccb_SourceToTarget('Nr','Lte','Nr','NrLteVoronoi');
		SET @voronoiType := 'NrLteVoronoi';
		SET @voronoiTypeJoin := 'NrLteVoronoi(inner)';
		SET @nameVoronoiType :='Nr';
		SET @noteVoronoiType :='NR';
		SET @noteComment := 'NrToLte邻区采用NR+LTE泰森(inner)';
		CALL ccb_5gTo4g_VoronoiType();
	else
		if @typeSelected='NRouterLTE' then
			CALL ccb_SourceToTarget('Nr','Lte','Nr','NrVoronoi');
			SET @voronoiType := 'NrVoronoi';
			SET @voronoiTypeJoin := 'NrVoronoi';
			SET @nameVoronoiType :='Nr';
			SET @noteVoronoiType :='NR';
			SET @noteComment := 'NrToLte邻区采用NR泰森';
			CALL ccb_5gTo4g_VoronoiType();

			CALL ccb_SourceToTarget('Nr','Lte','Lte','LteVoronoi');
			SET @voronoiType := 'LteVoronoi';
			SET @voronoiTypeJoin := 'LteVoronoi';
			SET @nameVoronoiType :='Lte';
			SET @noteVoronoiType :='LTE';
			SET @noteComment := 'NrToLte邻区采用LTE泰森';
			CALL ccb_5gTo4g_VoronoiType();
		else
			if @typeSelected='NR' then
				CALL ccb_SourceToTarget('Nr','Lte','Nr','NrVoronoi');
				SET @voronoiType := 'NrVoronoi';
				SET @voronoiTypeJoin := 'NrVoronoi';
				SET @nameVoronoiType :='Nr';
				SET @noteVoronoiType :='NR';
				SET @noteComment := 'NrToLte邻区采用NR泰森';
				CALL ccb_5gTo4g_VoronoiType();
			else
				CALL ccb_SourceToTarget('Nr','Lte','Lte','LteVoronoi');
				SET @voronoiType := 'LteVoronoi';
				SET @voronoiTypeJoin := 'LteVoronoi';
				SET @nameVoronoiType :='Lte';
				SET @noteVoronoiType :='LTE';
				SET @noteComment := 'NrToLte邻区采用LTE泰森';
				CALL ccb_5gTo4g_VoronoiType();
			end if;
		end if;
	end if;

	SET @voronoiTypeJoin := @voronoiType;

	if @typeSelected='NRouterLTE' then

		SET @voronoiTypeJoin := 'NrLteVoronoi(outer)';

		drop table if exists temp7;
		SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp7 like ccb_",@outputType,"Basic;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert into temp7"
			," select t1a.*"
			," from ccb_",@outputType,"Basic t1a"
			," where t1a.city=@city and (t1a.voronoiType='NrVoronoi' or t1a.voronoiType='LteVoronoi')"
-- 			," and (t1a.tier='0' or t1a.tier='1')"
 			," and (t1a.tier='0' or t1a.tier='1' or distance<1000)"
			," order by round(t1a.distance,1), t1a.tier, t1a.voronoiType desc"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		drop table if exists temp5;
		SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp5 like ccb_",@outputType,"Basic;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert into temp5"
			," select"
			," @city, @voronoiTypeJoin, t2a.rk,"
			," t2a.source, t2a.siteName, t2a.cellName, t2a.cgi,"
			," t2a.gNBId_cellLocalId, t2a.gNBId, t2a.cellLocalId,"
			," t2a.longitude, t2a.latitude, t2a.dir,"
			," t2a.cellType, t2a.band, t2a.freq, t2a.pci, t2a.rsi, t2a.tac,"
			," t2a.sourceNeigh, t2a.cityNeigh, t2a.siteNameNeigh, t2a.cellNameNeigh, t2a.ecgiNeigh,"
			," t2a.eNBIdNeigh, t2a.cellIdNeigh,"
			," t2a.longitudeNeigh, t2a.latitudeNeigh, t2a.dirNeigh,"
			," t2a.cellTypeNeigh, t2a.bandNeigh, t2a.freqNeigh, t2a.pciNeigh, t2a.rsiNeigh, t2a.tacNeigh,"
			," 99, 99, t2a.assistedTier, 99, 99,"
			," t2a.tier, t2a.distance,"
			," 999,999,"
			," t2a.angle, t2a.diff0, t2a.diff1, t2a.cLon, t2a.cLat,"
			," concat(t2a.voronoiType,':',t2a.remark0), t2a.remark0a"
			," from temp7 t2a"
			," group by rk"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

if 1=1 then

		SET @voronoiTypeJoin := 'NrLteVoronoi(union)';

		drop table if exists temp7;
		CREATE TEMPORARY TABLE `temp7` (
			`rk` varchar(255) NOT NULL,
			`voronoiTierNr` INT DEFAULT NULL,
			KEY `rk` (`rk`) USING BTREE
		) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

		SET @CMD:=CONCAT("insert ignore into temp7"
			," select t1a.rk, t1a.voronoiTierA"
			," from ccb_",@outputType,"Basic t1a"
			," where t1a.city=@city and t1a.voronoiType='NrVoronoi'"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		update temp5 t1a set t1a.voronoiTierA=ifnull((select voronoiTierNr from temp7 t1b where t1b.rk=t1a.rk limit 1),t1a.voronoiTierA);

		drop table if exists temp7;
		CREATE TEMPORARY TABLE `temp7` (
			`rk` varchar(255) NOT NULL,
			`voronoiTierLte` INT DEFAULT NULL,
			KEY `rk` (`rk`) USING BTREE
		) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

		SET @CMD:=CONCAT("insert ignore into temp7"
			," select t1a.rk, t1a.voronoiTierA"
			," from ccb_",@outputType,"Basic t1a"
			," where t1a.city=@city and t1a.voronoiType='LteVoronoi'"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		update temp5 t1a set t1a.voronoiTierB=ifnull((select voronoiTierLte from temp7 t1b where t1b.rk=t1a.rk limit 1),t1a.voronoiTierB);

		update temp5 set voronoiType=@voronoiTypeJoin;

		update temp5 set guardTierB=if(voronoiTierB=99,assistedTier,
				greatest(voronoiTierB,assistedTier));

		update temp5 set guardTierA=guardTierB
			where cellType='outdoor' and cellTypeNeigh='outdoor'
-- 				and ((voronoiTierA<=2 and guardTierB<=2) or guardTierB<=1);
				and ((voronoiTierA<=3 and guardTierB<=3) or guardTierB<=2);

		update temp5 set guardTierA=guardTierB
			where ((cellType='outdoor' and cellTypeNeigh='indoor') or (cellType='indoor' and cellTypeNeigh='outdoor'))
				and guardTierB<=1 and distance<500;

		update temp5 set guardTierA=guardTierB
			where (cellType='indoor' and cellTypeNeigh='indoor')
				and guardTierB=0;

		update temp5 set tier=guardTierA;

		update temp5 set remark0='', remark0a='';
		CALL newsite_selectNeighborBasic();

end if;

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"Basic where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
			," select *"
			," from temp5"
			," where remark0='基本'"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

	CALL ccb_updateTableRank();

	CALL ccb_createTablePerCellPerBandNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerBandNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, cellType, freq, band, bandNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from ccb_",@outputType,"Basic"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," and remark0='基本'"
		," and voronoiType=@voronoiTypeJoin"
		," group by gNBId_cellLocalId, bandNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCell();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCell"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, cellType,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from ccb_",@outputType,"Basic"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," and remark0='基本'"
		," and voronoiType=@voronoiTypeJoin"
		," group by gNBId_cellLocalId"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, cellType,"
		," freq, freqNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from ccb_",@outputType,"Basic"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," and remark0='基本'"
		," and voronoiType=@voronoiTypeJoin"
		," group by gNBId_cellLocalId, freqNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, freq, cellType, freqNeigh, cellTypeNeigh, count(cellTypeNeigh) as cnt"
		," from ccb_",@outputType,"Basic"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," and remark0='基本'"
		," group by gNBId_cellLocalId, freq, cellType, freqNeigh, cellTypeNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTableDistribution();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicDistribution"
		," select @city, @voronoiTypeJoin, freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor, count(cellTypeNeigh) as cnt"
		," from ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," group by freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	end if;

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;

	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`)
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi16 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_5gTo4g_VoronoiType`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi17 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_5gTo4g_VoronoiType`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists `t_Vor`;
	CREATE TEMPORARY TABLE `t_Vor` (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`ecgiNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @CMD:=CONCAT("insert into t_Vor"
		," select t1a.siteName, t1a.cellName, t1a.cgi,"
		," t1a.siteNameNeigh, t1a.cellNameNeigh, t1a.cgiNeigh,"
		," tier, distance"
		," from ",@dbVoronoi,"NrToLteOn",@nameVoronoiType," t1a"
		," where distance<@vDistance"
		," and voronoiType=@voronoiType"
		," and city=@city"
		," and cgi<>'' and cgiNeigh<>''"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	CALL ccb_createTemp5();
	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.cgi,'-',-2),':',substring_index(t1a.ecgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1b.city,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.cgi,"
		," t1b.gNBId_cellLocalId,"
		," t1b.gNBId,t1b.cellLocalId,"
		," t1b.longitude,t1b.latitude,t1b.dir,t1b.cellType,"
		," ifnull(t1b.band,'?') as band,"
		," t1b.freq, t1b.pci, t1b.rsi, t1b.tac,"
		," t1c.source as sourceNeigh,"
		," t1c.city as cityNeigh,"
		," t1a.siteNameNeigh,"
		," t1a.cellNameNeigh,"
		," t1a.ecgiNeigh,"
		," t1c.eNBId as eNBIdNeigh,"
		," t1c.cellId as cellIdNeigh,"
		," t1c.Longitude,t1c.Latitude,t1c.Dir,t1c.cellType,"
		," ifnull(t1c.band,'?') as bandNeigh,"
		," t1c.freq as freqNeigh, t1c.pci as pciNeigh, t1c.rsi as rsiNeigh, t1c.tac as tacNeigh,"
		," t1a.tier, t1a.tier, t1a.distance,"
		," '' as angle, '' as diff0, '' as diff1,"
		,@cLon," as cLon, ",@cLat," as cLat,"
		," '' as remark0,"
		," '' as remark0a,"
		," 99 as assistedTier, 99 as angularRingA, 99 as angularRingB"
		," from t_Vor t1a"
 		," left join t_BASE_NR t1b"
 		," on t1a.cgi=t1b.cgi"
 		," left join t_BASE_LTE t1c"
 		," on t1a.ecgiNeigh=t1c.ecgi"
		," where not(isnull(t1b.cgi)) and not(isnull(t1c.ecgi))"
		," and ("
		," (t1b.cellType='outdoor' and t1c.cellType='outdoor')"
		," or ( ((t1b.cellType='outdoor' and t1c.cellType='indoor') or (t1b.cellType='indoor' and t1c.cellType='outdoor'))"
		," and t1a.distance<=500 )"
		," or ( (t1b.cellType='indoor' and t1c.cellType='indoor')"
		," and t1a.distance<=20 )"
		," )"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	CALL newsite_calRing();
	CALL newsite_rectifyOnCgi();

	CALL newsite_selectNeighborBasic();

	CALL ccb_createTableNrToLte();
	SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
		," select"
		," @city, @voronoiTypeJoin, rk,"
		," source, siteName, cellName, cgi,"
 		," NBId_cellId, NBId, cellId,"
		," longitude, latitude, dir,"
		," cellType, band, freq, pci, rsi, tac,"
		," sourceNeigh, cityNeigh, siteNameNeigh, cellNameNeigh, cgiNeigh,"
		," NBIdNeigh, cellIdNeigh,"
		," longitudeNeigh, latitudeNeigh, dirNeigh,"
		," cellTypeNeigh, bandNeigh, freqNeigh, pciNeigh, rsiNeigh, tacNeigh,"
		," tier, tier, assistedTier, 99, 99,"
		," tier, distance,"
		," 999,999,"
		," angle, diff0, diff1, cLon, cLat,"
		," remark0, remark0a"
		," from temp5"
		," where remark0='基本'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

if @typeSelected<>'NRouterLTE' then

	CALL ccb_createTablePerCellPerBandNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerBandNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, NBId_cellId, cellType, freq, band, bandNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, bandNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCell();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCell"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, NBId_cellId, cellType,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, NBId_cellId, cellType,"
		," freq, freqNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, freqNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, NBId_cellId, freq, cellType, freqNeigh, cellTypeNeigh, count(cellTypeNeigh) as cnt"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, freq, cellType, freqNeigh, cellTypeNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTableDistribution();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicDistribution"
		," select @city, @voronoiTypeJoin, freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor, count(cellTypeNeigh) as cnt"
		," from ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," where city=@city and voronoiType=@voronoiTypeJoin"
		," group by freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi18 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTableNrToLte`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi19 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTableNrToLte`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(50) NOT NULL,"
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
		," `cityNeigh` varchar(50) NOT NULL,"
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
		," `voronoiTierA` INT DEFAULT NULL,"
		," `voronoiTierB` INT DEFAULT NULL,"
		," `assistedTier` INT DEFAULT NULL,"
		," `guardTierA` INT DEFAULT NULL,"
		," `guardTierB` INT DEFAULT NULL,"
		," `tier` varchar(30) NOT NULL,"
		," `distance` VARCHAR (30) DEFAULT NULL,"
		," `rankPerCellTypeNeighPerFreqNeigh` INT NOT NULL,"
		," `rankPerCellTypeNeigh` INT NOT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi20 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_4gTo5g`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi21 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_4gTo5g`(s varchar(50))
 BEGIN
 SET @ver := '23/10/9';

		SET @startTime := now();
		SET @scriptName := 'ccb_4gTo5g';

 		SET @dBSite := concat(database(),'.');
		SET @sitePrefix := '';

		SET @city := s;
		SET @dbOutput := '';
		SET @dbOutputName := database();
		SET @tableReset := 0;

		CALL ccb_freqBand();

if 1=2 then
		drop table if exists UserDefinedRules;
		CALL newsite_UserDefinedRules();
end if;

		SET @dBVoronoiSetting := 'kgetsetting.';
		SET @dbVoronoi := 'Voronoi.';
-- 		SET @dbSite := 'commoncore.';
		SET @noteDistance := '基站数据库缺数据!';

		SET @NrToLteOnBasic :=1;
		SET @NrToLteOnUser='none';

		SET @outputType := 'LteToNr';
 		SET @vDistance := 6000;
 		SET @vDistance := 3000;

		SET @scgi := 'ecgi';
		SET @sNBId_sCId := 'eNBId_cellId';

		SET @sCell := 'LTE';
		SET @tCell := 'NR';
		SET @freqType := 'earfcn';
		SET @freqTypeNeigh := 'ssbFrequency';

		SET @t_siteNR 				:= concat(@dbSite,@sitePrefix,'SITENR');
		SET @t_siteNROther 			:= concat(@dbSite,@sitePrefix,'SITENROTHER');
		SET @t_siteLTE 				:= concat(@dbSite,@sitePrefix,'SITELTE');
		SET @t_siteLTEOther			:= concat(@dbSite,@sitePrefix,'SITELTEOTHER');

		SET @t_BaseFromLTE 			:= @t_siteLTE;
 		SET @t_BaseFromNR 			:= @t_siteNR;
		SET @t_BaseFromLTEOther		:= @t_siteLTEOther;
 		SET @t_BaseFromNROther 		:= @t_siteNROther;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`ecgi` varchar(30) NOT NULL,
		`eNBId_cellId` varchar(255) NOT NULL,
		`eNBId` INT(11) NOT NULL,
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
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (ecgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, ECGI,"
		," substring_index(ECGI, '-', -2) as eNBId_cellId,"
		," substring_index(substring_index(ECGI, '-', -2),'-',1) as eNBId,"
		," substring_index(ECGI, '-', -1) as cellId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromLTE," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.earfcn) between t1b.freqStart and t1b.freqEnd"
		," where not(ECGI='#REF!' or duplexMode like '%NB%')"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_LTE`;
	CREATE TEMPORARY TABLE t_BASE_LTE like temp0;
	insert into t_BASE_LTE select * from temp0;

	drop table if exists temp0;
	CREATE TEMPORARY TABLE temp0 (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`cgi` varchar(30) NOT NULL,
		`gNBId_cellLocalId` varchar(255) NOT NULL,
		`gNBId` INT(11) NOT NULL,
		`cellLocalId` INT(11) NOT NULL,
		`longitude` varchar(30) NOT NULL,
		`latitude` varchar(30) NOT NULL,
		`dir` varchar(30) NOT NULL,
		`cellType` varchar(30) NOT NULL,
		`band` varchar(30) NOT NULL,
		`freq` varchar(30) NOT NULL,
		`pci` varchar(30) NOT NULL,
		`rsi` varchar(30) NOT NULL,
		`tac` varchar(30) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	ALTER TABLE temp0 ADD UNIQUE (cgi);

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, cgi,"
		," substring_index(CGI, '-', -2) as gNBId_cellLocalId,"
		," substring_index(substring_index(CGI, '-', -2),'-',1) as gNBId,"
		," substring_index(CGI, '-', -1) as cellLocalId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," NRFrequencySSB as freq,"
		," nRPCI, nRRSI as rsi, nRTAC,"
		," 'Ericsson' as source, city"
		," from ",@t_BaseFromNR," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.NRFrequencySSB) between t1b.freqStart and t1b.freqEnd"
		," where CGI<>'#REF!'"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert ignore into temp0"
		," select siteName, cellName, CGI,"
		," substring_index(CGI, '-', -2) as gNBId_cellLocalId,"
		," substring_index(substring_index(CGI, '-', -2),'-',1) as gNBId,"
		," substring_index(CGI, '-', -1) as cellLocalId,"
		," longitude, latitude, Direction as dir,"
		," if(cellType='','outdoor',cellType) as cellType,"
		," ifnull(t1b.band,'?') as band,"
		," ssbFrequency as freq,"
		," nRPCI, rsi, nRTAC,"
		," 'Other' as source, city"
		," from ",@t_BaseFromNROther," t1a"
		," left join ccb_FreqBand t1b"
		," on round(t1a.ssbFrequency) between t1b.freqStart and t1b.freqEnd"
		," where CGI<>'#REF!'"
		," and city=@city"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists `t_BASE_NR`;
	CREATE TEMPORARY TABLE t_BASE_NR like temp0;
	insert into t_BASE_NR select * from temp0;

if (exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBVoronoiSetting,'.',1) and TABLE_NAME='ccb_voronoiSetting')) then

	if 1=1 then
		SET @typeSelected := 'LTE';
		SET @CMD:=CONCAT("select if(LTEtoNR like '%NR%' and LTEtoNR like '%LTE%','NRLTE',if(LTEtoNR like '%LTE%','LTE','NR'))"
			," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
			," where city=@city"
			," group by city"
			," into @typeSelected"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	else
		SET @typeSelected := 'LTE';
		SET @CMD:=CONCAT("select if(LTEtoNR like '%NR%','NR','LTE')"
			," from ",@dBVoronoiSetting,"ccb_voronoiSetting"
			," where city=@city"
			," group by city"
			," into @typeSelected"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	end if;

end if;

	SET @typeSelected := 'LTE';

if @typeSelected='NRLTE' then
	CALL ccb_SourceToTarget('Lte','Nr','Nr','NrLteVoronoi');
	SET @voronoiType := 'NrLteVoronoi';
	SET @nameVoronoiType :='Nr';
	SET @noteVoronoiType :='NR';
	SET @noteComment := 'LteToNr邻区采用NR+LTE泰森';
else
	if @typeSelected='NR' then
		CALL ccb_SourceToTarget('Lte','Nr','Nr', 'NrVoronoi');
		SET @voronoiType := 'NrVoronoi';
		SET @nameVoronoiType :='Nr';
		SET @noteVoronoiType :='NR';
		SET @noteComment := 'LteToNr邻区采用NR泰森';
	else
		CALL ccb_SourceToTarget('Lte','Nr','Lte','LteOnNsaVoronoi');
		SET @voronoiType := 'LteOnNsaVoronoi';
		SET @nameVoronoiType :='Lte';
		SET @noteVoronoiType :='LTE';
		SET @noteComment := 'LteToNr邻区采用LTE锚点泰森';
	end if;
end if;

	SET @voronoiTypeJoin := @voronoiType;

	CALL ccb_4gTo5g_VoronoiType();

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;

	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`)
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;

  END;

--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi22 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_4gTo5g_VoronoiType`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi23 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_4gTo5g_VoronoiType`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists `t_Vor`;
	CREATE TEMPORARY TABLE `t_Vor` (
		`siteName` varchar(255) NOT NULL,
		`cellName` varchar(255) NOT NULL,
		`ecgi` varchar(30) NOT NULL,
		`siteNameNeigh` varchar(255) NOT NULL,
		`cellNameNeigh` varchar(255) NOT NULL,
		`cgiNeigh` varchar(30) NOT NULL,
		`tier` varchar(30) NOT NULL,
		`distance` double
		) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @CMD:=CONCAT("insert into t_Vor"
		," select t1a.siteName, t1a.cellName, t1a.cgi,"
		," t1a.siteNameNeigh, t1a.cellNameNeigh, t1a.cgiNeigh,"
		," tier, distance"
		," from ",@dbVoronoi,"LteToNrOn",@nameVoronoiType," t1a"
		," where distance<@vDistance"
		," and voronoiType=@voronoiType"
		," and city=@city"
		," and cgi<>'' and cgiNeigh<>''"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTemp5();

	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.ecgi,'-',-2),':',substring_index(t1a.cgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1b.city,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.ecgi,"
		," t1b.eNBId_cellId,"
		," t1b.eNBId,t1b.cellId,"
		," t1b.longitude,t1b.latitude,t1b.dir,t1b.cellType,"
		," ifnull(t1b.band,'?') as band,"
		," t1b.freq, t1b.pci, t1b.rsi, t1b.tac,"
		," t1c.source as sourceNeigh,"
		," t1c.city as cityNeigh,"
		," t1a.siteNameNeigh,"
		," t1a.cellNameNeigh,"
		," t1a.cgiNeigh,"
		," t1c.gNBId as gNBIdNeigh,"
		," t1c.cellLocalId as cellLocalIdNeigh,"
		," t1c.Longitude,t1c.Latitude,t1c.Dir,t1c.cellType,"
		," ifnull(t1c.band,'?') as bandNeigh,"
		," t1c.freq as freqNeigh, t1c.pci as pciNeigh, t1c.rsi as rsiNeigh, t1c.tac as tacNeigh,"
		," t1a.tier, t1a.tier, t1a.distance,"
		," '' as angle, '' as diff0, '' as diff1,"
		,@cLon," as cLon, ",@cLat," as cLat,"
		," '' as remark0,"
		," '' as remark0a,"
		," 99 as assistedTier, 99 as angularRingA, 99 as angularRingB"
		," from t_Vor t1a"
 		," left join t_BASE_LTE t1b"
 		," on t1a.ecgi=t1b.ecgi"
 		," left join t_BASE_NR t1c"
 		," on t1a.cgiNeigh=t1c.cgi"
		," where not(isnull(t1b.ecgi)) and not(isnull(t1c.cgi))"
		," and ("
		," (t1b.cellType='outdoor' and t1c.cellType='outdoor')"
		," or ( ((t1b.cellType='outdoor' and t1c.cellType='indoor') or (t1b.cellType='indoor' and t1c.cellType='outdoor'))"
		," and t1a.distance<=500 )"
		," or ( (t1b.cellType='indoor' and t1c.cellType='indoor')"
		," and t1a.distance<=20 )"
		," )"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	CALL newsite_calRing();
	CALL newsite_rectifyOnCgi();
	update temp5 set tier=greatest(voronoiTier, assistedTier);
	CALL newsite_selectNeighborBasic();

	CALL ccb_createTableLteToNr();
	CALL ccb_insertTable();
	CALL ccb_updateTableRank();

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi24 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTableLteToNr`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi25 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTableLteToNr`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"Basic"))) then

	SET @CMD:=CONCAT("drop table if exists `ccb_",@outputType,"Basic`;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"Basic ("
		," `city` varchar(50) NOT NULL,"
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
		," `cityNeigh` varchar(50) NOT NULL,"
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
		," `rankPerCellTypeNeighPerFreqNeigh` INT NOT NULL,"
		," `rankPerCellTypeNeigh` INT NOT NULL,"
		," `angle` VARCHAR (30) DEFAULT NULL,"
		," `diff0` VARCHAR (30) DEFAULT NULL,"
		," `diff1` VARCHAR (30) DEFAULT NULL,"
		," `cLon` VARCHAR(30) NOT NULL,"
		," `cLat` VARCHAR(30) NOT NULL,"
		," `remark0` varchar(30) NOT NULL,"
		," `remark0a` varchar(100) NOT NULL,"
 		," INDEX `rk` (`rk`) USING BTREE"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

end if;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi26 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_insertTable`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi27 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_insertTable`()
 BEGIN
 SET @ver := '23/10/9';

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"Basic where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
		," select"
		," @city, @voronoiType, rk,"
		," source, siteName, cellName, cgi,"
 		," NBId_cellId, NBId, cellId,"
		," longitude, latitude, dir,"
		," cellType, band, freq, pci, rsi, tac,"
		," sourceNeigh, cityNeigh, siteNameNeigh, cellNameNeigh, cgiNeigh,"
		," NBIdNeigh, cellIdNeigh,"
		," longitudeNeigh, latitudeNeigh, dirNeigh,"
		," cellTypeNeigh, bandNeigh, freqNeigh, pciNeigh, rsiNeigh, tacNeigh,"
		," voronoiTier, assistedTier,"
		," tier, distance,"
		," 999,999,"
		," angle, diff0, diff1, cLon, cLat,"
		," remark0, remark0a"
		," from temp5"
		," where remark0='基本'"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerBandNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerBandNeigh"
		," select @city, @voronoiType, siteName, cellName, cgi, NBId_cellId, cellType, freq, band, bandNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, bandNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCell();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCell"
		," select @city, @voronoiType, siteName, cellName, cgi, NBId_cellId, cellType,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeigh"
		," select @city, @voronoiType, siteName, cellName, cgi, NBId_cellId, cellType,"
		," freq, freqNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, freqNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," select @city, @voronoiType, siteName, cellName, cgi, NBId_cellId, freq, cellType, freqNeigh, cellTypeNeigh, count(cellTypeNeigh) as cnt"
		," from temp5"
		," where remark0='基本'"
		," group by NBId_cellId, freq, cellType, freqNeigh, cellTypeNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTableDistribution();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicDistribution"
		," select @city, @voronoiType, freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor, count(cellTypeNeigh) as cnt"
		," from ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," where city=@city and voronoiType=@voronoiType"
		," group by freq, cellType, freqNeigh, cellTypeNeigh, cntNeighbor"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi28 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_updateTableRank`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi29 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_updateTableRank`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists temp1;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp1 ("
 		," `rk` varchar(255) NOT NULL,"
 		," `NBId_cellId` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `freqNeigh` varchar(30) NOT NULL,"
		," `distance` float DEFAULT NULL,"
		," `diff1` float DEFAULT NULL,"
 		," unique (`rk`)"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert ignore into temp1"
 		," select rk, ",@sNBId_sCId,", cellTypeNeigh, freqNeigh, distance, diff1"
 		," from ccb_",@outputType,"Basic"
 		," where city=@city and voronoiType=@voronoiTypeJoin"
 		," order by ",@sNBId_sCId,", cellTypeNeigh, freqNeigh, round(distance,1), abs(round(diff1,1))"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists temp2;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp2 ("
 		," `rk` varchar(255) NOT NULL,"
		," `rankPerCellTypeNeighPerFreqNeigh` INT NOT NULL,"
		," `dummy1` varchar(1) NOT NULL,"
 		," unique (`rk`)"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @i:=0;
	SET @neigh:='xxx';
	SET @CMD:=CONCAT("insert ignore into temp2"
		," select "
		," t1.rk,"
 		," if(@neigh!=concat(t1.NBId_cellId,'-',t1.cellTypeNeigh,'-',t1.freqNeigh),@i:=1,@i:=@i+1) as rank,"
 		," left(@neigh := concat(t1.NBId_cellId,'-',t1.cellTypeNeigh,'-',t1.freqNeigh),1) as dummy1"
		," from temp1 t1"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("update ccb_",@outputType,"Basic t1a"
		," set t1a.rankPerCellTypeNeighPerFreqNeigh="
		," ifnull((select rankPerCellTypeNeighPerFreqNeigh from temp2 t1b"
 		," where t1b.rk=t1a.rk),t1a.rankPerCellTypeNeighPerFreqNeigh)"
 		," where t1a.city=@city and t1a.voronoiType=@voronoiTypeJoin"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists temp1;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp1 ("
 		," `rk` varchar(255) NOT NULL,"
 		," `NBId_cellId` varchar(30) NOT NULL,"
		," `cellTypeNeigh` varchar(30) NOT NULL,"
		," `distance` float DEFAULT NULL,"
		," `diff1` float DEFAULT NULL,"
 		," unique (`rk`)"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert ignore into temp1"
		," select rk,",@sNBId_sCId,", cellTypeNeigh, distance, diff1"
		," from ccb_",@outputType,"Basic"
 		," where city=@city and voronoiType=@voronoiTypeJoin"
		," order by ",@sNBId_sCId,", cellTypeNeigh, round(distance,1), abs(round(diff1,1))"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	drop table if exists temp2;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp2 ("
 		," `rk` varchar(255) NOT NULL,"
		," `rankPerCellTypeNeigh` INT NOT NULL,"
		," `dummy1` varchar(1) NOT NULL,"
 		," unique (`rk`)"
		," ) ENGINE = MyISAM DEFAULT CHARSET=utf8"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @i:=0;
	SET @neigh:='xxx';
	SET @CMD:=CONCAT("insert ignore into temp2"
		," select "
		," t1.rk,"
 		," if(@neigh!=concat(t1.NBId_cellId,'-',t1.cellTypeNeigh),@i:=1,@i:=@i+1) as rank,"
 		," left(@neigh := concat(t1.NBId_cellId,'-',t1.cellTypeNeigh),1) as dummy1"
		," from temp1 t1"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("update ccb_",@outputType,"Basic t1a"
		," set t1a.rankPerCellTypeNeigh="
		," ifnull((select rankPerCellTypeNeigh from temp2 t1b"
		," where t1b.rk=t1a.rk),t1a.rankPerCellTypeNeigh)"
 		," where t1a.city=@city and t1a.voronoiType=@voronoiTypeJoin"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi30 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_SourceToTarget`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi31 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_SourceToTarget`(source varchar(30), target varchar(30), nameVoronoiType varchar(30), voronoiType varchar(30))
 BEGIN
 SET @ver := '23/10/9';

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
		SET @CMD:=CONCAT("insert ignore into temp0"
			," select cgi, 'Ericsson' as source from ",@dBSite,@sitePrefix,"SITENR where city=@city"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	else
		SET @CMD:=CONCAT("insert ignore into temp0"
			," select ecgi, 'Ericsson' as source from ",@dBSite,@sitePrefix,"SITELTE where city=@city"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
	end if;

	drop table if exists temp0b;
	CREATE TEMPORARY TABLE temp0b like temp0;
	if @target='Nr' then

		SET @CMD:=CONCAT("insert ignore into temp0b"
			," select cgi, 'Ericsson' as source from ",@dBSite,@sitePrefix,"SITENR where city=@city"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert ignore into temp0b"
			," select cgi, 'Other' as source from ",@dBSite,@sitePrefix,"SITENROTHER where city=@city"
 			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

	else

		SET @CMD:=CONCAT("insert ignore into temp0b"
			," select ecgi, 'Ericsson' as source from ",@dBSite,@sitePrefix,"SITELTE where city=@city"
 			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert ignore into temp0b"
			," select ecgi, 'Other' as source from ",@dBSite,@sitePrefix,"SITELTEOTHER where city=@city"
  			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

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
		," `voronoiType` varchar(30) NOT NULL,"
		," `city` varchar(50) NOT NULL"
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


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi32 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_allTablesClear`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi33 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_allTablesClear`()
 BEGIN
 SET @ver := '23/10/9';

	SET @startTime := now();

 	SET @dBSite := concat(database(),'.');
	SET @sitePrefix := '';

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
   		`startTime` TIMESTAMP NOT NULL,
 		`endTime` TIMESTAMP NOT NULL
		) ENGINE = MyISAM DEFAULT CHARSET = utf8;
	insert into ccb_voronoiVersion (versionVoronoiScripts,versionMariaDB,timeSpan,startTime,endTime)
	values (@ver, version(), TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);

 	DROP TABLE if exists ccb_voronoiScriptTime;
	CREATE TABLE ccb_voronoiScriptTime (
		id bigint(20)  UNSIGNED NOT NULL AUTO_INCREMENT,
		`city` varchar(255) NOT NULL,
		`sqlScript` varchar(255) NOT NULL,
		`voronoiType` varchar(255) NOT NULL,
		`timeSpan` INT NOT NULL,
  		`startTime` TIMESTAMP NOT NULL,
 		`endTime` TIMESTAMP NOT NULL,
 		`note` VARCHAR(100) DEFAULT '',
 		PRIMARY KEY (`id`) USING BTREE
		) ENGINE = MyISAM DEFAULT CHARSET = utf8;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values ('voronoi.versionMariaDB','','',0,now(),now(),version());");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values ('voronoi.ccb_voronoiScriptTime.versionSql','','',0,now(),now(),@ver);");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_outputUsedVoronoi();
	CALL ccb_outputUsedSiteNR();
	CALL ccb_outputUsedSiteLTE();
	CALL ccb_outputUsedSiteStatusNR();
	CALL ccb_outputUsedSiteStatusLTE();
	CALL ccb_outputUsedSiteValidAnchorCellLTE();

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi34 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedVoronoi`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi35 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedVoronoi`()
 BEGIN
 SET @ver := '23/10/9';

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME='voronoi_cell' into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,'voronoi_cell.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,'voronoi_cell.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME='voronoi_tier' into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,'voronoi_tier.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,'voronoi_tier.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi36 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedSiteNR`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi37 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedSiteNR`()
 BEGIN
 SET @ver := '23/10/9';

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITENR') into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitenr.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitenr.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITENROTHER') into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitenrother.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitenrother.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi38 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedSiteLTE`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi39 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedSiteLTE`()
 BEGIN
 SET @ver := '23/10/9';

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITELTE') into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitelte.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitelte.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:="SELECT CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITELTEOTHER') into @CREATE_TIME, @UPDATE_TIME";
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitelteother.CREATE_TIME'),'','',0,now(),now(),ifnull(@CREATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`) values (concat(@dBSite,@sitePrefix,'sitelteother.UPDATE_TIME'),'','',0,now(),now(),ifnull(@UPDATE_TIME,'NULL'));");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi40 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedSiteStatusNR`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi41 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedSiteStatusNR`()
 BEGIN
 SET @ver := '23/10/9';

if exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITENR')) then
	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitenr.manageStatus'),"
		," '','',0, now(), now(), concat('city=ALL;manageStatus=',manageStatus_adjusted,';count=',cnt)"
		," from ("
		," select ifnull(manageStatus,'NULL') as manageStatus_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITENR')
		," group by manageStatus_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitenr.manageStatus'),"
		," '','',0, now(), now(), concat('city=',t2a.city,';manageStatus=',manageStatus_adjusted,';count=',cnt)"
		," from ("
		," select city, ifnull(manageStatus,'NULL') as manageStatus_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITENR')
		," group by city, manageStatus_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
end if;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi42 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedSiteStatusLTE`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi43 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedSiteStatusLTE`()
 BEGIN
 SET @ver := '23/10/9';

if exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITELTE')) then
	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitelte.status'),"
		," '','',0, now(), now(), concat('city=ALL;status=',status_adjusted,';count=',cnt)"
		," from ("
		," select ifnull(status,'NULL') as status_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITELTE')
		," group by status_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitelte.status'),"
		," '','',0, now(), now(), concat('city=',t2a.city,';status=',status_adjusted,';count=',cnt)"
		," from ("
		," select city, ifnull(status,'NULL') as status_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITELTE')
		," group by city, status_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
end if;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi44 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_outputUsedSiteValidAnchorCellLTE`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi45 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_outputUsedSiteValidAnchorCellLTE`()
 BEGIN
 SET @ver := '23/10/9';

if exists(select 1 from information_schema.TABLES where table_schema=substring_index(@dBSite,'.',1) and TABLE_NAME=concat(@sitePrefix,'SITELTE')) then
	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitelte.validAnchorCell'),"
		," '','',0, now(), now(), concat('city=ALL;validAnchorCell=',validAnchorCell_adjusted,';status=',status_adjusted,';count=',cnt)"
		," from ("
		," select ifnull(validAnchorCell,'NULL') as validAnchorCell_adjusted, ifnull(status,'NULL') as status_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITELTE')
		," group by validAnchorCell_adjusted, status_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into ccb_voronoiScriptTime"
		," (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`,`note`)"
		," select concat(@dBSite,@sitePrefix,'sitelte.validAnchorCell'),"
		," '','',0, now(), now(), concat('city=',t2a.city,';validAnchorCell=',validAnchorCell_adjusted,';status=',status_adjusted,';count=',cnt)"
		," from ("
		," select city, ifnull(validAnchorCell,'NULL') as validAnchorCell_adjusted, ifnull(status,'NULL') as status_adjusted, count(*) as cnt"
		," from ",@dBSite,concat(@sitePrefix,'SITELTE')
		," group by city, validAnchorCell_adjusted, status_adjusted"
		," ) t2a"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;
end if;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi46 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTemp5`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi47 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTemp5`()
 BEGIN
 SET @ver := '23/10/9';

	SET @CMD:=CONCAT("drop table if exists temp5;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp5 ("
		," `rk` varchar(255) NOT NULL,"
		," `source` varchar(30) NOT NULL,"
		," `city` varchar(50) NOT NULL,"
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
		," `cityNeigh` varchar(50) NOT NULL,"
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
		," `voronoiTier` varchar(30) NOT NULL,"
		," `tier` varchar(30) NOT NULL,"
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


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi48 splitStatements:false
DROP PROCEDURE IF EXISTS `newsite_rectifyOnCgi`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi49 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `newsite_rectifyOnCgi`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists temp6;
	CREATE TEMPORARY TABLE temp6 like temp5;
	insert into temp6
	select * from temp5
	order by cgi, angularRingA, distance;

	drop table if exists `temp7`;
	CREATE TEMPORARY TABLE `temp7` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL,
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
		`cityNeigh` varchar(50) NOT NULL,
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
		`voronoiTier` varchar(30) NOT NULL,
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
		`city` varchar(50) NOT NULL,
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
		`cityNeigh` varchar(50) NOT NULL,
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
		`voronoiTier` varchar(30) NOT NULL,
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
		`city` varchar(50) NOT NULL,
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
		`cityNeigh` varchar(50) NOT NULL,
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
		`voronoiTier` varchar(30) NOT NULL,
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
		`city` varchar(50) NOT NULL,
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
		`cityNeigh` varchar(50) NOT NULL,
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
		`voronoiTier` varchar(30) NOT NULL,
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


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi50 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTemp5RectifyOnCgi`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi51 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTemp5RectifyOnCgi`()
 BEGIN
 SET @ver := '23/10/9';

	drop table if exists `temp5`;
	CREATE TEMPORARY TABLE `temp5` (
		`rk` varchar(255) NOT NULL,
		`source` varchar(30) NOT NULL,
		`city` varchar(50) NOT NULL,
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
		`cityNeigh` varchar(50) NOT NULL,
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
		`voronoiTier` varchar(30) NOT NULL,
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


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi52 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTableDistribution`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi53 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTableDistribution`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicDistribution"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicDistribution;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicDistribution ("
		," `city` varchar(50) NOT NULL,"
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

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"BasicDistribution where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi54 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTablePerCell`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi55 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTablePerCell`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCell"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCell;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCell ("
		," `city` varchar(50) NOT NULL,"
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

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"BasicPerCell where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi56 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerBandNeigh`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi57 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTablePerCellPerBandNeigh`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerBandNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerBandNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerBandNeigh ("
		," `city` varchar(50) NOT NULL,"
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

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"BasicPerCellPerBandNeigh where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi58 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerFreqNeigh`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi59 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTablePerCellPerFreqNeigh`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerFreqNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerFreqNeigh ("
		," `city` varchar(50) NOT NULL,"
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

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"BasicPerCellPerFreqNeigh where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi60 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi61 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh`()
 BEGIN
 SET @ver := '23/10/9';

if @tableReset = 1 or not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME=concat("ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"))) then

	SET @CMD:=CONCAT("drop table if exists ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("CREATE TABLE ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh ("
		," `city` varchar(50) NOT NULL,"
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

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh where city=@city;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi62 splitStatements:false
DROP PROCEDURE IF EXISTS `ccb_allTablesDrop`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi63 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `ccb_allTablesDrop`()
BEGIN
 SET @ver := '23/10/9';

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


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi64 splitStatements:false
DROP PROCEDURE IF EXISTS `newsite_calAngle`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi65 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `newsite_calAngle`()
BEGIN
 SET @ver := '23/10/9';

update temp5 set cLon=0.01/round(6378.138*2*asin(sqrt( cos(latitude*pi()/180)*cos(latitude*pi()/180)*pow(sin((0.01)*pi()/180/2),2))),6), cLat=0.01/round(6378.138*2*asin(sin((0.01)*pi()/180/2)),6)
where latitude>0 and longitude>0;

update temp5 set angle=
if(longitudeNeigh=longitude,if(latitudeNeigh<latitude,180,0),if(longitudeNeigh>longitude,90.0-ATAN(((latitudeNeigh-latitude)/cLat)/((longitudeNeigh-longitude)/cLon))/pi()*180.0,270.0-ATAN(((latitudeNeigh-latitude)/cLat)/((longitudeNeigh-longitude)/cLon))/pi()*180.0))
where longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

update temp5 set diff0 = 180-((540+dir-angle) mod 360), diff1 = ((360+dirNeigh-angle) mod 360)-180
where longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

  END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi66 splitStatements:false
DROP PROCEDURE IF EXISTS `newsite_calRing`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi67 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `newsite_calRing`()
BEGIN
 SET @ver := '23/10/9';

update temp5 set angularRingA = ((floor((360+angle-dir)/45)+8) mod 8)+1 where distance>100 and longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

update temp5 set angularRingA = angularRingA-9 where angularRingA>4 and angularRingA<90;

update temp5 set angularRingB = ((floor(((360+angle-dir)+22.5)/45)+8) mod 8) where distance>100 and longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

update temp5 set angularRingB = angularRingB-8 where angularRingB>4 and angularRingB<90;

   END;


--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi68 splitStatements:false
DROP PROCEDURE IF EXISTS `newsite_selectNeighborBasic`;
--changeset ericsson:3.0.0-update20231009-pci_service30_voronoi69 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `newsite_selectNeighborBasic`()
BEGIN
 SET @ver := '23/10/9';

 SET @algType := "基本";

update temp5 set remark0=@algType, remark0a=concat('[条件A1]',@tCell,'宏站小区在第0圈全选!')
	where (tier=0)
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a='';

SET @hdeg1Front := 75;
SET @hdeg1Back := 75;
update temp5 set remark0=@algType, remark0a=concat('[条件A2a]',@tCell,'宏站小区位于',@sCell,'宏站小区第1圈正面正负',cast(@hdeg1Front as char),'度范围内全选!')
	where (tier=1)
		and abs(((540+angle-dir) mod 360)-180)<=@hdeg1Front
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1SideInward := 120+5;
update temp5 set remark0=@algType, remark0a=concat('[条件A2b]',@tCell,'宏站小区位于',@sCell,'宏站小区第1圈侧面',cast(180-@hdeg1Front-@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1SideInward as char),'度的',@tCell,'小区!')
	where (tier=1)
		and abs(((720+angle-dirNeigh) mod 360)-180)<=@hdeg1SideInward
 		and ( abs(((540+angle-dir) mod 360)-180) between @hdeg1Front and (180-@hdeg1Back) )
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1BackInward := 60+40;
update temp5 set remark0=@algType, remark0a=concat('[条件A2c]',@tCell,'宏站小区位于',@sCell,'宏站小区第1圈背面正负',cast(@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1BackInward as char),'度的',@tCell,'小区!')
	where (tier=1)
		and abs(((720+angle-dirNeigh) mod 360)-180)<=@hdeg1BackInward
		and abs(((540+angle-dir) mod 360)-180)>=@hdeg1Back
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

if 1=1 then

SET @hdeg1Front := 75;
SET @hdeg1Back := 75;
update temp5 set remark0=@algType, remark0a=concat('[条件A2d]',@sCell,'宏站小区位于',@tCell,'宏站小区第1圈正面正负',cast(@hdeg1Front as char),'度范围内全选!')
	where (tier=1)
		and abs(((540+angle+180-dirNeigh) mod 360)-180)<=@hdeg1Front
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1SideInward := 120+5;
update temp5 set remark0=@algType, remark0a=concat('[条件A2e]',@sCell,'宏站小区位于',@tCell,'宏站小区第1圈侧面',cast(180-@hdeg1Front-@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1SideInward as char),'度的',@sCell,'小区!')
	where (tier=1)
		and abs(((720+angle+180-dir) mod 360)-180)<=@hdeg1SideInward
 		and ( abs(((540+angle+180-dirNeigh) mod 360)-180) between @hdeg1Front and (180-@hdeg1Back) )
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1BackInward := 60+40;
update temp5 set remark0=@algType, remark0a=concat('[条件A2f]',@sCell,'宏站小区位于',@tCell,'宏站小区第1圈背面正负',cast(@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1BackInward as char),'度的',@sCell,'小区!')
	where (tier=1)
		and abs(((720+angle+180-dir) mod 360)-180)<=@hdeg1BackInward
		and abs(((540+angle+180-dirNeigh) mod 360)-180)>=@hdeg1Back
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

end if;

SET @hdeg := 65;
update temp5 set remark0=@algType, remark0a= concat('[条件A3a]',@tCell,'宏站小区在第2圈且两小区互相在对方正负',cast(@hdeg as char),'度扇叶范围内对打!')
		where (Tier=2)
			and (abs(((540+angle-dir) mod 360)-180)<@hdeg and abs(((720+angle-dirNeigh) mod 360)-180)<@hdeg)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

if 1=2 then

SET @hdeg := 75;
SET @guardDist := 650;
update temp5 set remark0=@algType, remark0a= concat('[条件A3b]',@tCell,'宏站小区在第2圈且两小区互相在对方正负',cast(@hdeg as char),'度扇叶范围内对打且',cast(@guardDist as char),'米内!')
		where (Tier=2)
			and distance>=0 and distance <=@guardDist
			and (abs(((540+angle-dir) mod 360)-180)<@hdeg and abs(((720+angle-dirNeigh) mod 360)-180)<@hdeg)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

end if;

SET @hdegOut := 40;
SET @hdegIn := 100;
update temp5 set remark0=@algType, remark0a= concat('[条件A3c]',@tCell,'宏站小区在第2圈且基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdegOut as char),'度且基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdegIn as char),'度内对打!')
		where (Tier=2)
			and (abs(((540+angle-dir) mod 360)-180)<@hdegOut and abs(((720+angle-dirNeigh) mod 360)-180)<@hdegIn)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @hdegOut := 100;
SET @hdegIn := 40;
update temp5 set remark0=@algType, remark0a= concat('[条件A3d]',@tCell,'宏站小区在第2圈且基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdegOut as char),'度且基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdegIn as char),'度内对打!')
		where (Tier=2)
			and (abs(((540+angle-dir) mod 360)-180)<@hdegOut and abs(((720+angle-dirNeigh) mod 360)-180)<@hdegIn)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @guardDist := 200;
update temp5 set remark0=@algType, remark0a=concat('[条件A4]',@tCell,'宏站小区位于',@sCell,'宏站小区第0/1/2/3圈且',cast(@guardDist as char),'米内全选!')
 		where distance>=0 and distance <=@guardDist
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @hdeg1Front := 75;
SET @hdeg1Back := 75;
SET @guardDist := 600;
update temp5 set remark0=@algType, remark0a=concat('[条件A5a]',@tCell,'宏站小区在第0/1/2/3圈且位于',@sCell,'宏站小区',cast(@guardDist as char),'米内且正面正负',cast(@hdeg1Front as char),'度范围内全选!')
	where distance>=0 and distance <=@guardDist
		and abs(((540+angle-dir) mod 360)-180)<=@hdeg1Front
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1SideInward := 120+5;
update temp5 set remark0=@algType, remark0a=concat('[条件A5b]',@tCell,'宏站小区在第0/1/2/3圈且位于',@sCell,'宏站小区',cast(@guardDist as char),'米内且侧面',cast(180-@hdeg1Front-@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1SideInward as char),'度的',@tCell,'小区!')
	where distance>=0 and distance <=@guardDist
		and abs(((720+angle-dirNeigh) mod 360)-180)<=@hdeg1SideInward
 		and ( abs(((540+angle-dir) mod 360)-180) between @hdeg1Front and (180-@hdeg1Back) )
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1BackInward := 60+40;
update temp5 set remark0=@algType, remark0a=concat('[条件A5c]',@tCell,'宏站小区在第0/1/2/3圈且位于',@sCell,'宏站小区',cast(@guardDist as char),'米内且背面正负',cast(@hdeg1Back as char),'度范围内,只选基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdeg1BackInward as char),'度的',@tCell,'小区!')
	where distance>=0 and distance <=@guardDist
		and abs(((720+angle-dirNeigh) mod 360)-180)<=@hdeg1BackInward
		and abs(((540+angle-dir) mod 360)-180)>=@hdeg1Back
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

if 1=1 then

SET @hdeg1Front := 75;
SET @hdeg1Back := 75;
SET @guardDist := 600;
update temp5 set remark0=@algType, remark0a=concat('[条件A5d]',@sCell,'宏站小区在第0/1/2/3圈且位于',@tCell,'宏站小区',cast(@guardDist as char),'米内且正面正负',cast(@hdeg1Front as char),'度范围内全选!')
	where distance>=0 and distance <=@guardDist
		and abs(((540+angle+180-dirNeigh) mod 360)-180)<=@hdeg1Front
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1SideInward := 120+5;
update temp5 set remark0=@algType, remark0a=concat('[条件A5e]',@sCell,'宏站小区在第0/1/2/3圈且位于',@tCell,'宏站小区',cast(@guardDist as char),'米内且侧面',cast(180-@hdeg1Front-@hdeg1Back as char),'度范围内,只选基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdeg1SideInward as char),'度的',@sCell,'小区!')
	where distance>=0 and distance <=@guardDist
		and abs(((720+angle+180-dir) mod 360)-180)<=@hdeg1SideInward
 		and ( abs(((540+angle+180-dirNeigh) mod 360)-180) between @hdeg1Front and (180-@hdeg1Back) )
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

SET @hdeg1BackInward := 60+40;
update temp5 set remark0=@algType, remark0a=concat('[条件A5f]',@sCell,'宏站小区在第0/1/2/3圈且位于',@tCell,'宏站小区',cast(@guardDist as char),'米内且背面正负',cast(@hdeg1Back as char),'度范围内,只选基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdeg1BackInward as char),'度的',@sCell,'小区!')
	where distance>=0 and distance <=@guardDist
		and abs(((720+angle+180-dir) mod 360)-180)<=@hdeg1BackInward
		and abs(((540+angle+180-dirNeigh) mod 360)-180)>=@hdeg1Back
		and ( (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
					and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0) )
		and remark0a=''
		and angle<>'';

end if;

if 1=2 then

SET @guardDist := 1200;
SET @hdeg := 65;
update temp5 set remark0=@algType, remark0a= concat('[条件A6a]',@tCell,'宏站小区在第0/1/2/3圈且两小区互相在对方正负',cast(@hdeg as char),'度扇叶范围内对打且',cast(@guardDist as char),'米内!')
		where distance>=0 and distance <=@guardDist
			and (abs(((540+angle-dir) mod 360)-180)<@hdeg and abs(((720+angle-dirNeigh) mod 360)-180)<@hdeg)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @guardDist := 1000;
SET @hdeg := 75;
update temp5 set remark0=@algType, remark0a= concat('[条件A6b]',@tCell,'宏站小区在第0/1/2/3圈且两小区互相在对方正负',cast(@hdeg as char),'度扇叶范围内对打且',cast(@guardDist as char),'米内!')
		where distance>=0 and distance <=@guardDist
			and (abs(((540+angle-dir) mod 360)-180)<@hdeg and abs(((720+angle-dirNeigh) mod 360)-180)<@hdeg)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @guardDist := 800;
SET @hdegOut := 40;
SET @hdegIn := 100;
update temp5 set remark0=@algType, remark0a= concat('[条件A6c]',@tCell,'宏站小区在第0/1/2/3圈且基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdegOut as char),'度且基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdegIn as char),'度内对打且',cast(@guardDist as char),'米内!')
		where distance>=0 and distance <=@guardDist
			and (abs(((540+angle-dir) mod 360)-180)<@hdegOut and abs(((720+angle-dirNeigh) mod 360)-180)<@hdegIn)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

SET @hdegOut := 100;
SET @hdegIn := 40;
update temp5 set remark0=@algType, remark0a= concat('[条件A6d]',@tCell,'宏站小区在第0/1/2/3圈且基站连线与',@sCell,'宏站小区方向之差少于',cast(@hdegOut as char),'度且基站连线与',@tCell,'宏站小区方向之差少于',cast(@hdegIn as char),'度内对打且',cast(@guardDist as char),'米内!')
		where distance>=0 and distance <=@guardDist
			and (abs(((540+angle-dir) mod 360)-180)<@hdegOut and abs(((720+angle-dirNeigh) mod 360)-180)<@hdegIn)
			and (instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
			and (instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
		and remark0a=''
		and angle<>'';

end if;

update temp5 set remark0=@algType, remark0a='[条件B1]室分小区位于宏站小区第0圈!'
		where tier=0
			and (
					((instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
						and (instr(UPPER(cellTypeNeigh),'INDOOR')>0 or instr(cellTypeNeigh,'室分')>0))
 			or ((instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
						and (instr(UPPER(cellType),'INDOOR')>0 or instr(cellType,'室分')>0))
					 )
		and remark0a=''
		and angle<>'';

SET @hdeg := 60;
SET @indoorDist := 500;
update temp5 set remark0=@algType, remark0a=concat('[条件B2]室分小区位于宏站小区第1圈且',cast(@indoorDist as char),'米内且正负',cast(@hdeg as char),'度扇叶范围内!')
		where tier=1
			and distance>=0 and distance <=@indoorDist
			and ( ( abs(((540+angle-dir) mod 360)-180)<@hdeg
						and ((instr(UPPER(cellType),'OUTDOOR')>0 or instr(cellType,'室外')>0 or instr(cellType,'宏')>0)
									and (instr(UPPER(cellTypeNeigh),'INDOOR')>0 or instr(cellTypeNeigh,'室分')>0))
						)
				 or ( abs(((540+180+angle-dirNeigh) mod 360)-180)<@hdeg
						and ((instr(UPPER(cellTypeNeigh),'OUTDOOR')>0 or instr(cellTypeNeigh,'室外')>0 or instr(cellTypeNeigh,'宏')>0)
									and (instr(UPPER(cellType),'INDOOR')>0 or instr(cellType,'室分')>0))
						)
					)
		and remark0a=''
		and angle<>'';

SET @indoorDist := 20;
update temp5 set remark0=@algType, remark0a=concat('[条件D1]两室分在',cast(@indoorDist as char),'米内!')
		where distance>=0 and distance <=@indoorDist
				and (instr(UPPER(cellType),'INDOOR')>0 or instr(cellType,'室分')>0)
				and (instr(UPPER(cellTypeNeigh),'INDOOR')>0 or instr(cellTypeNeigh,'室分')>0)
		and remark0a=''
		and angle<>'';

   END;
