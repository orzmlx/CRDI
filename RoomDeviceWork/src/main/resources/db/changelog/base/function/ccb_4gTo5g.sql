--liquibase formatted sql

-- 是否CU/CT/CM都是按两个原则:1> FDD1800必选, 2>全城NR定过的频点必选
-- 不是的, CU/CT不是FDD1800
-- 先用10，加个comment提醒，以后按情况调改。

-- CALL ccb_4gTo5gAll();

--changeset ericsson:3.2.0-base-ccb_4gTo5g
DROP PROCEDURE IF EXISTS `ccb_4gTo5gAll`;
--changeset ericsson:3.2.0-base-ccb_4gTo5g1 splitStatements:false
CREATE PROCEDURE `ccb_4gTo5gAll`()
 BEGIN
-- CALL ccb_allTablesClear();

-- select city, count(*) as cnt from ccb_LteToNrBasic group by city;

	CALL ccb_4gTo5g('zhenjiang');	-- [3/11] 1585s(143233)
 	CALL ccb_4gTo5g('changzhou'); -- [2/28]10265s(500084)
	CALL ccb_4gTo5g('nantong');		-- 
 	CALL ccb_4gTo5g('suzhou');		-- 
 	CALL ccb_4gTo5g('wuxi');			-- 

 END;

--changeset ericsson:3.2.0-base-ccb_4gTo5g2
DROP PROCEDURE IF EXISTS `ccb_4gTo5g`;
--changeset ericsson:3.2.0-base-ccb_4gTo5g3 splitStatements:false
CREATE PROCEDURE `ccb_4gTo5g`(s varchar(50))
 BEGIN

		SET @startTime := now();
		SET @scriptName := 'ccb_4gTo5g';
		
		SET @city := s;
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
		
		SET @t_siteNR 				:= concat(@dbSite,'COMMON_SITENR');
		SET @t_siteNROther 		:= concat(@dbSite,'COMMON_SITENROTHER');
		SET @t_siteLTE 				:= concat(@dbSite,'COMMON_SITELTE');
		SET @t_siteLTEOther		:= concat(@dbSite,'COMMON_SITELTEOTHER');
		
		SET @t_BaseFromLTE 			:= @t_siteLTE;
 		SET @t_BaseFromNR 			:= @t_siteNR;
		SET @t_BaseFromLTEOther	:= @t_siteLTEOther;
 		SET @t_BaseFromNROther 	:= @t_siteNROther;
		
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
		," ifnull(t1b.band,'?') as band,"
		," earfcn,"
		," pci, rsi, tac,"
		," 'Ericsson' as source"
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
		`source` varchar(30) NOT NULL
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
		," 'Ericsson' as source"
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
		," 'Other' as source"
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

	CALL ccb_4gTo5g_VoronoiType();

	SET @endTime := now();
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiVersion') then
		select STR_TO_DATE(startTime,'%Y-%m-%d %H:%i:%s') from (select startTime from ccb_voronoiVersion limit 1) t1a into @startTimeVersion;
		update ccb_voronoiVersion set endTime=@endTime;
		update ccb_voronoiVersion set timeSpan=TIMESTAMPDIFF(SECOND,@startTimeVersion,@endTime);
	end if;
	
	if exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='ccb_voronoiScriptTime') then
		SET @voronoiTypeJoin := 'LteOnNsaVoronoi';
		insert into ccb_voronoiScriptTime (`city`,`sqlScript`,`voronoiType`,`timeSpan`,`startTime`,`endTime`) 
												values (@city, @scriptName,@voronoiTypeJoin,TIMESTAMPDIFF(SECOND,@startTime,@endTime),@startTime,@endTime);
	end if;
	
	 END;

--changeset ericsson:3.2.0-base-ccb_4gTo5g4
DROP PROCEDURE IF EXISTS `ccb_4gTo5g_VoronoiType`;
--changeset ericsson:3.2.0-base-ccb_4gTo5g5 splitStatements:false
CREATE PROCEDURE `ccb_4gTo5g_VoronoiType`()
 BEGIN

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
-- Initial Values (Wuhan Location)
	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.ecgi,'-',-2),':',substring_index(t1a.cgiNeigh,'-',-2)) as rk,"
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
		," t1a.cgiNeigh,"
		," t1c.gNBId as gNBIdNeigh,"
		," t1c.cellLocalId as cellLocalIdNeigh,"
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
 		," left join t_BASE_LTE t1b"
 		," on t1a.ecgi=t1b.ecgi"
 		," left join t_BASE_NR t1c"
 		," on t1a.cgiNeigh=t1c.cgi"
		," where not(isnull(t1b.ecgi)) and not(isnull(t1c.cgi))" 
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL newsite_calAngle();
	
	if 1=2 then
		CALL newsite_calRing();
		CALL newsite_rectifyOnCgi();
	end if;
	
	CALL newsite_selectNeighborBasic();

--

	CALL ccb_createTableLteToNr();
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
