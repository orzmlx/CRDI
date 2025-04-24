--liquibase formatted sql

-- 是否CU/CT/CM都是按两个原则:1> FDD1800必选, 2>全城NR定过的频点必选
-- 不是的, CU/CT不是FDD1800
-- 先用10，加个comment提醒，以后按情况调改。

-- CALL ccb_4gTo4gAll();

--changeset ericsson:3.2.0-base-ccb_4gTo4g
DROP PROCEDURE IF EXISTS `ccb_4gTo4gAll`;
--changeset ericsson:3.2.0-base-ccb_4gTo4g1 splitStatements:false
CREATE PROCEDURE `ccb_4gTo4gAll`()
 BEGIN
-- CALL ccb_allTablesClear();

	CALL ccb_4gTo4g('zhenjiang'); -- [2/28]6900s (543235)
	CALL ccb_4gTo4g('changzhou'); --
	CALL ccb_4gTo4g('nantong'); 	--
	CALL ccb_4gTo4g('suzhou'); 		--
	CALL ccb_4gTo4g('wuxi'); 			--

 END;

--changeset ericsson:3.2.0-base-ccb_4gTo4g2
DROP PROCEDURE IF EXISTS `ccb_4gTo4g`;
--changeset ericsson:3.2.0-base-ccb_4gTo4g3 splitStatements:false
CREATE PROCEDURE `ccb_4gTo4g`(s varchar(50))
 BEGIN

		SET @startTime := now();
		SET @scriptName := 'ccb_4gTo4g';

		SET @city := s;
-- 	SET @city := 'zhenjiang';

		SET @dbOutput := '';
		SET @dbOutputName := database();
		SET @tableReset := 0;

if 1=2 then
		drop table if exists UserDefinedRules;
		CALL newsite_UserDefinedRules();
end if;

		SET @dBVoronoiSetting := 'kgetsetting.';
		SET @dbVoronoi := 'Voronoi.';
		SET @dbSite := 'commoncore.';
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
 		SET @t_BaseFromSource := concat(@dbSite,'COMMON_SITELTE');
		SET @t_BaseFromTarget := concat(@dbSite,'COMMON_SITELTE');

 		SET @t_BaseFromSourceOther := concat(@dbSite,'COMMON_SITELTEOTHER');
		SET @t_BaseFromTargetOther := concat(@dbSite,'COMMON_SITELTEOTHER');

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
													('n41',499200,537999);

	ALTER TABLE ccb_FreqBand ADD INDEX `mix` (`freqStart`,`freqEnd`) USING BTREE;

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
		`source` varchar(30) NOT NULL
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
		," 'Ericsson' as source"
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
		," 'Other' as source"
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
	CALL ccb_4gTo4g_VoronoiType();

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;

	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		SET @voronoiTypeJoin := 'LteVoronoi';
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`)
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;

 END;

--changeset ericsson:3.2.0-base-ccb_4gTo4g4
DROP PROCEDURE IF EXISTS `ccb_4gTo4g_VoronoiType`;
--changeset ericsson:3.2.0-base-ccb_4gTo4g5 splitStatements:false
CREATE PROCEDURE `ccb_4gTo4g_VoronoiType`()
 BEGIN

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

-- Initial Values (Wuhan Location)
	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	CALL ccb_createTemp5();
	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.ecgi,'-',-2),':',substring_index(t1a.ecgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.ecgi,"
		," t1b.eNBId_cellId,"
		," t1b.eNBId,t1b.cellId,"
		," t1b.longitude,t1b.latitude,t1b.dir,t1b.cellType,"
		," ifnull(t1b.band,'?') as band,"
		," t1b.freq, t1b.pci, t1b.rsi, t1b.tac,"		
		," t1c.source as sourceNeigh,"
		," t1a.siteNameNeigh,"
		," t1a.cellNameNeigh,"
		," t1a.ecgiNeigh,"
		," t1c.eNBId as eNBIdNeigh,"
		," t1c.cellId as cellIdNeigh,"
		," t1c.Longitude,t1c.Latitude,t1c.Dir,t1c.cellType,"	
		," ifnull(t1c.band,'?') as bandNeigh,"
		," t1c.freq as freqNeigh, t1c.pci as pciNeigh, t1c.rsi as rsiNeigh, t1c.tac as tacNeigh,"
		," t1a.tier, t1a.distance,"
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
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	CALL newsite_calRing();
	CALL newsite_rectifyOnCgi();

	CALL newsite_selectNeighborBasic();

	SET @algType := "同站小区"; 
	update temp5 set remark0=@algType, remark0a='[条件E1]站内小区(siteName=siteNameNeigh)!'
		where siteName = siteNameNeigh
		and remark0a=''
		and angle<>'';

	update temp5 set remark0='', remark0a=''
		where cgi = cgiNeigh;

	CALL ccb_createTableLteToLte();
	SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
		," select"
		," @city, @voronoiType, rk,"
		," source, siteName, cellName, cgi,"
 		," NBId_cellId, NBId, cellId,"
		," longitude, latitude, dir,"
		," cellType, band, freq, pci, rsi, tac,"
		," sourceNeigh, siteNameNeigh, cellNameNeigh, cgiNeigh,"
		," NBIdNeigh, cellIdNeigh,"
		," longitudeNeigh, latitudeNeigh, dirNeigh,"
		," cellTypeNeigh, bandNeigh, freqNeigh, pciNeigh, rsiNeigh, tacNeigh,"
		," tier, assistedTier,"
		," tier, distance, angle, diff0, diff1, cLon, cLat,"
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
