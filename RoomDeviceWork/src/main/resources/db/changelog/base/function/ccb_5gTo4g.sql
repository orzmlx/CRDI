--liquibase formatted sql

-- 是否CU/CT/CM都是按两个原则:1> FDD1800必选, 2>全城NR定过的频点必选
-- 不是的, CU/CT不是FDD1800
-- 先用10，加个comment提醒，以后按情况调改。

-- CALL ccb_5gTo4gAll();

--changeset ericsson:3.2.0-base-ccb_5gTo4g
DROP PROCEDURE IF EXISTS `ccb_5gTo4gAll`;
--changeset ericsson:3.2.0-base-ccb_5gTo4g1 splitStatements:false
CREATE PROCEDURE `ccb_5gTo4gAll`()
 BEGIN
-- CALL ccb_allTablesClear();

-- select city, count(*) as cnt from ccb_NrToLteBasic group by city;

	CALL ccb_5gTo4g('zhenjiang'); -- [3/11](109194)
 	CALL ccb_5gTo4g('changzhou');	-- 
	CALL ccb_5gTo4g('nantong');		-- 
 	CALL ccb_5gTo4g('suzhou');		-- 
 	CALL ccb_5gTo4g('wuxi');			-- 

 END;

--changeset ericsson:3.2.0-base-ccb_5gTo4g2
DROP PROCEDURE IF EXISTS `ccb_5gTo4g`;
--changeset ericsson:3.2.0-base-ccb_5gTo4g3 splitStatements:false
CREATE PROCEDURE `ccb_5gTo4g`(s varchar(50))
 BEGIN

		SET @startTime := now();
		SET @scriptName := 'ccb_5gTo4g';

		SET @city := 'zhenjiang';
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
		
		SET @outputType := 'NrToLte';
 		SET @vDistance := 6000;
 		SET @vDistance := 2500;

		SET @scgi := 'cgi';
		SET @sNBId_sCId := 'gNBId_cellLocalId';
		
		SET @sCell := 'NR';
		SET @tCell := 'LTE';
		SET @freqType := 'ssbFrequency';
		SET @freqTypeNeigh := 'earfcn';
		
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
		," 'Other' as source"
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
		-- NRinnerLTE
		-- NRouterLTE
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
			--
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
			," and (t1a.tier='0' or t1a.tier='1')"
			," order by t1a.tier"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
		
		drop table if exists temp6;
		SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp6 like ccb_",@outputType,"Basic;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;
		
		SET @CMD:=CONCAT("insert into temp6"
			," select"
			," @city, @voronoiTypeJoin, t2a.rk,"
			," t2a.source, t2a.siteName, t2a.cellName, t2a.cgi,"
			," t2a.gNBId_cellLocalId, t2a.gNBId, t2a.cellLocalId,"
			," t2a.longitude, t2a.latitude, t2a.dir,"
			," t2a.cellType, t2a.band, t2a.freq, t2a.pci, t2a.rsi, t2a.tac,"
			," t2a.sourceNeigh, t2a.siteNameNeigh, t2a.cellNameNeigh, t2a.ecgiNeigh,"
			," t2a.eNBIdNeigh, t2a.cellIdNeigh,"
			," t2a.longitudeNeigh, t2a.latitudeNeigh, t2a.dirNeigh,"
			," t2a.cellTypeNeigh, t2a.bandNeigh, t2a.freqNeigh, t2a.pciNeigh, t2a.rsiNeigh, t2a.tacNeigh,"
			," t2a.tier, t2a.assistedTier,"
			," t2a.tier, t2a.distance, t2a.angle, t2a.diff0, t2a.diff1, t2a.cLon, t2a.cLat,"
			," t2a.remark0, t2a.remark0a"
			," from temp7 t2a"			
			," group by rk"
			," ;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;

		SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
			," select * from temp6;");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT;	

		SET @CMD:=CONCAT("delete from ccb_",@outputType,"Basic where voronoiType='NrVoronoi' or voronoiType='LteVoronoi';");
		PREPARE STATEMENT from @CMD;
		EXECUTE STATEMENT; 

	CALL ccb_createTablePerCellPerBandNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerBandNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, cellType, freq, band, bandNeigh,"
		," count(cgi) as cntNeighbor,"
		," sum(if(cellTypeNeigh='outdoor',1,0)) as cntOutdoor,"
		," sum(if(cellTypeNeigh='indoor',1,0)) as cntIndoor,"
		," sum(if(not(cellTypeNeigh='outdoor' or cellTypeNeigh='indoor'),1,0)) as cntOther"
		," from ccb_",@outputType,"Basic"
		," where remark0='基本'"
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
		," where remark0='基本'"
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
		," where remark0='基本'"
		," and voronoiType=@voronoiTypeJoin"
		," group by gNBId_cellLocalId, freqNeigh"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	CALL ccb_createTablePerCellPerFreqNeighPerCelltypeNeigh();
	SET @CMD:=CONCAT("INSERT INTO ccb_",@outputType,"BasicPerCellPerFreqNeighPerCelltypeNeigh"
		," select @city, @voronoiTypeJoin, siteName, cellName, cgi, gNBId_cellLocalId, freq, cellType, freqNeigh, cellTypeNeigh, count(cellTypeNeigh) as cnt"
		," from ccb_",@outputType,"Basic"
		," where remark0='基本'"
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

--changeset ericsson:3.2.0-base-ccb_5gTo4g4
DROP PROCEDURE IF EXISTS `ccb_5gTo4g_VoronoiType`;
--changeset ericsson:3.2.0-base-ccb_5gTo4g5 splitStatements:false
CREATE PROCEDURE `ccb_5gTo4g_VoronoiType`()
 BEGIN

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

-- Initial Values (Wuhan Location)
	SET @cLon :=(0.03432-0.02387);
	SET @cLat :=(0.06310-0.05411);

	CALL ccb_createTemp5();
	SET @CMD:=CONCAT("insert into temp5"
		," select"
		," concat(substring_index(t1a.cgi,'-',-2),':',substring_index(t1a.ecgiNeigh,'-',-2)) as rk,"
		," t1b.source,"
		," t1a.siteName,"
		," t1a.cellName,"
		," t1a.cgi,"
		," t1b.gNBId_cellLocalId,"
		," t1b.gNBId,t1b.cellLocalId,"
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
 		," left join t_BASE_NR t1b"
 		," on t1a.cgi=t1b.cgi"
 		," left join t_BASE_LTE t1c"
 		," on t1a.ecgiNeigh=t1c.ecgi"
		," where not(isnull(t1b.cgi)) and not(isnull(t1c.ecgi))" 
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

	CALL ccb_createTableNrToLte();
	SET @CMD:=CONCAT("insert into ccb_",@outputType,"Basic"
		," select"
		," @city, @voronoiTypeJoin, rk,"
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

