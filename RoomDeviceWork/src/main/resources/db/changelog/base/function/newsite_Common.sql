--liquibase formatted sql

-- show procedure status;
--changeset ericsson:3.2.0-base-newsite_common
DROP PROCEDURE IF EXISTS `newsite_calAvgDist`;
--changeset ericsson:3.2.0-base-newsite_common1 splitStatements:false
CREATE DEFINER=`root`@`%` PROCEDURE `newsite_calAvgDist`()
 BEGIN

	drop table if exists `temp4`;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp4 ("
		,"`cellName` varchar(255) NOT NULL,"
		,"`avgDist` varchar(30) NOT NULL"
		,") ENGINE = MyISAM DEFAULT CHARSET = utf8;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into temp4"
		," select cellName, avg(distance) as avgDist"
		," from temp5"
		," where remark0a<>''"
		,@filter
		," group by cellName"
		," ;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	ALTER TABLE temp4 ADD INDEX `cellName` ( `cellName` ) USING BTREE;

 END;

--changeset ericsson:3.2.0-base-newsite_common2
DROP PROCEDURE IF EXISTS `newsite_calPciConflict2`;
--changeset ericsson:3.2.0-base-newsite_common3 splitStatements:false
CREATE PROCEDURE `newsite_calPciConflict2`()
 BEGIN

	drop table if exists `temp7`;
	CREATE TEMPORARY TABLE `temp7` (
		`rk` varchar(255) NOT NULL
	) ENGINE = MyISAM DEFAULT CHARSET=utf8;

	SET @CMD:=CONCAT("insert into temp7"
		," select concat(cellName,'-',freqNeigh,'-',pciNeigh) as rk"
		," from temp5 t1a"
		," where remark0a<>''"
		," and freqNeigh<>'' and pciNeigh<>''"
		,@filter
		," group by cellName,freqNeigh,pciNeigh"
		," having count(*) > 1"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	ALTER TABLE temp7 ADD INDEX `rk` ( `rk` ) USING BTREE;

	drop table if exists `temp6`;
	SET @CMD:=CONCAT("CREATE TEMPORARY TABLE temp6 ("
		,"`rk` varchar(255) NOT NULL,"
		,"`cellNameNeighGroup` varchar(255) NOT NULL"
		,") ENGINE = MyISAM DEFAULT CHARSET = utf8;");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @CMD:=CONCAT("insert into temp6"
		," select rk,"
		," GROUP_CONCAT(t2a.cellNameNeigh,'(',cast(cast(t2a.distance as UNSIGNED) as char),'m)'"
				," order by cast(t2a.distance as double) SEPARATOR ';') as cellNameNeighGroup"
		," from ("
		," select t1b.rk, t1a.cellNameNeigh, t1a.distance"
		," from temp5 t1a"
		," left join temp7 t1b"
		," on concat(t1a.cellName,'-',t1a.freqNeigh,'-',t1a.pciNeigh)=t1b.rk"
		," where remark0a<>''"
		," and freqNeigh<>'' and pciNeigh<>''"
		,@filter
		," and not(isnull(t1b.rk))"
		," ) t2a"
		," group by rk"
		,";");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	ALTER TABLE temp6 ADD INDEX `rk` ( `rk` ) USING BTREE;

 END;

--changeset ericsson:3.2.0-base-newsite_common4
DROP PROCEDURE IF EXISTS `newsite_calAngle`;
--changeset ericsson:3.2.0-base-newsite_common5 splitStatements:false
CREATE PROCEDURE `newsite_calAngle`()
 BEGIN

update temp5 set cLon=0.01/round(6378.138*2*asin(sqrt( cos(latitude*pi()/180)*cos(latitude*pi()/180)*pow(sin((0.01)*pi()/180/2),2))),6), cLat=0.01/round(6378.138*2*asin(sin((0.01)*pi()/180/2)),6) 
where latitude>0 and longitude>0;

update temp5 set angle=
if(longitudeNeigh=longitude,if(latitudeNeigh<latitude,180,0),if(longitudeNeigh>longitude,90.0-ATAN(((latitudeNeigh-latitude)/cLat)/((longitudeNeigh-longitude)/cLon))/pi()*180.0,270.0-ATAN(((latitudeNeigh-latitude)/cLat)/((longitudeNeigh-longitude)/cLon))/pi()*180.0))
where longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

update temp5 set diff0 = 180-((540+dir-angle) mod 360), diff1 = ((360+dirNeigh-angle) mod 360)-180
where longitude>0 and latitude>0 and longitudeNeigh>0 and latitudeNeigh>0;

 END;

--changeset ericsson:3.2.0-base-newsite_common6
DROP PROCEDURE IF EXISTS `newsite_calWeight`;
--changeset ericsson:3.2.0-base-newsite_common7 splitStatements:false
CREATE PROCEDURE `newsite_calWeight`()
 BEGIN
 
-- Priority

SET @nrPrioDistBoost_km := 0.05;
SET @nrPrioDistBoost_ratio := 0.01;
update temp5 set ordPart = 1,
											stepDist = dist Div 0.2, 
											ordDist = if(dist<=@nrPrioDistBoost_km, @nrPrioDistBoost_km*@nrPrioDistBoost_ratio, dist), 
											angDev = least(abs(dir-dirNeigh),abs(dir+360-dirNeigh),abs(dir-360-dirNeigh));

SET @nrPrioDistSuppressed_km := 0.05;
update temp5 set diff = abs(diff0-diff1),
							ordpart = if(cellType like '%outdoor%' and cellTypeNeigh like '%outdoor%' and dist<=@nrPrioDistSuppressed_km,
														if(angDev>90,
																0.2,
																if(angDev>80,0.3,if(angDev>70,0.4,if(angDev>60,0.5,ordPart)))
															),
														ordPart
													);

update temp5 set ordPart = 
		  case 
				when diff< 20 and abs(diff0)< 30 and abs(diff1)< 30 then 1.3
				when diff< 40 and abs(diff0)< 60 and abs(diff1)< 60 then 1.25
				when diff< 90 and abs(diff0)< 60 and abs(diff1)< 60 then 1.2	
				when diff< 60 and abs(diff0)< 90 and abs(diff1)< 90 then 1.15
				when diff< 90 and abs(diff0)< 90 and abs(diff1)< 90 then 1.1
				when diff<120 and abs(diff0)<120 and abs(diff1)<120 then 1.05
				else ordPart
			end
		where cellType like '%outdoor%' and cellTypeNeigh like '%outdoor%'
		and dist>@nrPrioDistBoost_km;

update temp5 set ordPart =
		  case
				when dist>0.40 and diff>180 then 0.30
				when dist>0.40 and diff>150 then 0.50
				when dist>0.40 and diff>120 then 0.60
				when dist>0.30 and diff>100 then 0.70
				when dist<0.30 and diff<120 and abs(diff0)<120 and abs(diff1)<120 then 6.0
				when dist<0.50 and diff< 65 and abs(diff0)< 65 and abs(diff1)< 65 then 4.5
				when dist<0.50 and diff< 90 and abs(diff0)< 45 and abs(diff1)< 45 then 4.0
				when dist<0.70 and diff<120 and abs(diff0)<120 and abs(diff1)<120 then 3.0
				when dist<0.80 and diff< 20 and abs(diff0)< 30 and abs(diff1)< 30 then 2.0
				when dist<1.00 and diff< 20 and abs(diff0)< 30 and abs(diff1)< 30 then 1.6
				when dist<1.10 and diff< 20 and abs(diff0)< 30 and abs(diff1)< 30 then 1.5
				when dist<1.25 and diff< 20 and abs(diff0)< 30 and abs(diff1)< 30 then 1.4
				when dist>2.0 and diff<20 and abs(diff0)<40 and abs(diff1)<40 then 1.6
				when dist>1.4 and diff<70 and abs(diff0)<70 and abs(diff1)<70 then 1.4
				else ordPart
			end
		where cellType like '%outdoor%' and cellTypeNeigh like '%outdoor%'  
		and dist>@nrPrioDistBoost_km;

update temp5 set ordPart = 1 where siteName=siteNameNeigh;

	SET @olapRate := 1.000;
	SET @nrForgetFactorOutdoor := 1.5;
-- 	SET @nrForgetFactorIndoor := 6.0;
	SET @nrForgetFactorIndoor := 2.0;
	SET @nrForgetWidthIndoor := 1.0;
	SET @nrForgetWidthIndoorThr := 60;
	SET @oi1_hdeg := 150/2;

if 1=1 then

update temp5 set ordWeight = ordPart*@olapRate/power((10*ordDist),@nrForgetFactorOutdoor) 
		where cellType like '%outdoor%' and cellTypeNeigh like '%outdoor%';

update temp5 set ordWeight = if(abs(diff0)<@nrForgetWidthIndoorThr,
									1/power((10*ordDist),@nrForgetFactorIndoor),
									1/power((10*ordDist),@nrForgetFactorIndoor)*power(abs((@oi1_hdeg*1.1-abs(diff0))/@oi1_hdeg/1.1),@nrForgetWidthIndoor)
								)
		where cellType like '%outdoor%' and cellTypeNeigh like '%indoor%';

update temp5 set ordWeight = if(abs(diff1)<@nrForgetWidthIndoorThr,
									1/power((10*ordDist),@nrForgetFactorIndoor),
									1/power((10*ordDist),@nrForgetFactorIndoor)*power(abs((@oi1_hdeg*1.1-abs(diff1))/@oi1_hdeg/1.1),@nrForgetWidthIndoor)
								)
		where cellType like '%indoor%' and cellTypeNeigh like '%outdoor%';

update temp5 set ordWeight = 1/(10*ordDist)
		where cellType like '%indoor%' and cellTypeNeigh like '%indoor%';

else

update temp5 set ordWeight = 
		if(cellType like '%outdoor%',
					if(cellTypeNeigh like '%outdoor%',
							ordPart*@olapRate/power((10*ordDist),@nrForgetFactorOutdoor),
							if(abs(diff0)<@nrForgetWidthIndoorThr,
									1/power((10*ordDist),@nrForgetFactorIndoor),
									1/power((10*ordDist),@nrForgetFactorIndoor)*power(abs((@oi1_hdeg*1.1-abs(diff0))/@oi1_hdeg/1.1),@nrForgetWidthIndoor)
								)
						),
					1/(10*ordDist)
			);

end if;

 END;

--changeset ericsson:3.2.0-base-newsite_common8
DROP PROCEDURE IF EXISTS `newsite_selectNeighborBasic`;
--changeset ericsson:3.2.0-base-newsite_common9 splitStatements:false
CREATE PROCEDURE `newsite_selectNeighborBasic`()
 BEGIN
  
 SET @algType := "基本";

 -- OUTDOOR<>OUTDOOR

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

-- 

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

-- 

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

-- 宏站小区在第0/1/2/3圈且两小区互相在对方正负

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
-- 

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

-- OUTDOOR<>INDOOR

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

-- INDOOR<>INDOOR

SET @indoorDist := 20;
update temp5 set remark0=@algType, remark0a=concat('[条件D1]两室分在',cast(@indoorDist as char),'米内!')
		where distance>=0 and distance <=@indoorDist
				and (instr(UPPER(cellType),'INDOOR')>0 or instr(cellType,'室分')>0)
				and (instr(UPPER(cellTypeNeigh),'INDOOR')>0 or instr(cellTypeNeigh,'室分')>0)
		and remark0a=''
		and angle<>'';

 END;

-- CALL newsite_UserDefinedRules();

--changeset ericsson:3.2.0-base-newsite_common10
DROP PROCEDURE IF EXISTS `newsite_UserDefinedRules`;
--changeset ericsson:3.2.0-base-newsite_common11 splitStatements:false
CREATE PROCEDURE `newsite_UserDefinedRules`()
 BEGIN

if not(exists(select 1 from information_schema.TABLES where table_schema=@dbOutputName and TABLE_NAME='UserDefinedRules')) then

	SET @CMD:=CONCAT("CREATE TABLE ", @dbOutput,"`UserDefinedRules` ("
		,"`id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,"
		,"`userName` varchar(50) NOT NULL,"	
		,"`neighborType` varchar(50) NOT NULL,"
		,"`algorithmName` varchar(50) NOT NULL,"
		,"`tier` varchar(30) NOT NULL,"
		,"`distance` varchar(30) NOT NULL,"
		,"`dir与基站连线之差` varchar(30) NOT NULL,"
		,"`dirNeigh与基站连线之差` varchar(30) NOT NULL,"
 		,"`cellType` varchar(30) NOT NULL,"
		,"`cellTypeNeigh` varchar(30) NOT NULL,"
		,"`remark[筛选类型]` varchar(30) NOT NULL,"
		,"`remark[筛选条件]` varchar(100) NOT NULL,"		
		," INDEX `userName` (`userName`) USING BTREE,"
		," INDEX `neighborType` (`neighborType`) USING BTREE,"
		," PRIMARY KEY (`id`) USING BTREE"
		,") ENGINE = MyISAM DEFAULT CHARSET = utf8 COMMENT '用户自定义邻区规则表';");
	PREPARE STATEMENT from @CMD;
	EXECUTE STATEMENT;

	SET @algType := '用户自定义';

-- NrToNr

	SET @remarkNote := '[用户自定义条件1]目标NR宏站小区位于原NR宏站小区第0/1/2/3圈且250米内全选!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','250','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件2]目标NR宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且650米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'2','650','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件3]目标NR宏站小区在第0/1/2/3圈且两小区互相在对方正负65度扇叶范围内对打且1200米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','1200','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件4]目标NR宏站小区在第0/1/2/3圈且两小区互相在对方正负75度扇叶范围内对打且1000米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','1000','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件5]目标NR宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于40度且基站连线与目标NR宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件6]目标NR宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于100度且基站连线与目标NR宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);
--
	SET @remarkNote := '[用户自定义条件7a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[用户自定义条件7b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[用户自定义条件8]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','基本扩展算法',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);	

if 1=1 then

	SET @remarkNote := '[自定条件1]宏站小区第0圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件2]宏站小区第1圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'1','','180','180','outdoor','outdoor',
						@algType,@remarkNote);
						
	SET @remarkNote := '[自定条件3]宏站小区500米范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'','500','180','180','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件4]目标NR宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'2','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件5]目标NR宏站小区在第3圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'3','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件6]目标NR宏站小区在第2圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'2','','65','65','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件7]目标NR宏站小区在第3圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'3','','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件8]目标NR宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于40度且基站连线与目标NR宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件9]目标NR宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于100度且基站连线与目标NR宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件10a]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件10b]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'0','','180','180','indoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[自定条件12]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToNrNeighbor','宽松(说明用途)',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

end if;


-- LteToLte

	SET @remarkNote := '[用户自定义条件1]目标LTE宏站小区位于原LTE宏站小区第0/1/2/3圈且250米内全选!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','250','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件2]目标LTE宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且650米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'2','650','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件3]目标LTE宏站小区在第0/1/2/3圈且两小区互相在对方正负65度扇叶范围内对打且1200米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','1200','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件4]目标LTE宏站小区在第0/1/2/3圈且两小区互相在对方正负75度扇叶范围内对打且1000米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','1000','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件5]目标LTE宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于40度且基站连线与目标LTE宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件6]目标LTE宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于100度且基站连线与目标LTE宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);
--
	SET @remarkNote := '[用户自定义条件7a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[用户自定义条件7b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[用户自定义条件8]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','基本扩展算法',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);	


if 1=1 then

	SET @remarkNote := '[自定条件1]宏站小区第0圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件2]宏站小区第1圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'1','','180','180','outdoor','outdoor',
						@algType,@remarkNote);
						
	SET @remarkNote := '[自定条件3]宏站小区500米范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'','500','180','180','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件4]目标LTE宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'2','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件5]目标LTE宏站小区在第3圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'3','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件6]目标LTE宏站小区在第2圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'2','','65','65','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件7]目标LTE宏站小区在第3圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'3','','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件8]目标LTE宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于40度且基站连线与目标LTE宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件9]目标LTE宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于100度且基站连线与目标LTE宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件10a]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件10b]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'0','','180','180','indoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[自定条件12]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToLteNeighbor','宽松(说明用途)',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

end if;

-- NrToLte

	SET @remarkNote := '[用户自定义条件1]目标LTE宏站小区位于原NR宏站小区第0/1/2/3圈且250米内全选!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','250','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件2]目标LTE宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且650米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'2','650','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件3]目标LTE宏站小区在第0/1/2/3圈且两小区互相在对方正负65度扇叶范围内对打且1200米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','1200','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件4]目标LTE宏站小区在第0/1/2/3圈且两小区互相在对方正负75度扇叶范围内对打且1000米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','1000','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件5]目标LTE宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于40度且基站连线与目标LTE宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件6]目标LTE宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于100度且基站连线与目标LTE宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);
--
	SET @remarkNote := '[用户自定义条件7a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[用户自定义条件7b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[用户自定义条件8]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','基本扩展算法',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

if 1=1 then

	SET @remarkNote := '[自定条件1]宏站小区第0圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件2]宏站小区第1圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'1','','180','180','outdoor','outdoor',
						@algType,@remarkNote);
						
	SET @remarkNote := '[自定条件3]宏站小区500米范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'','500','180','180','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件4]目标LTE宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'2','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件5]目标LTE宏站小区在第3圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'3','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件6]目标LTE宏站小区在第2圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'2','','65','65','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件7]目标LTE宏站小区在第3圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'3','','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件8]目标LTE宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于40度且基站连线与目标LTE宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件9]目标LTE宏站小区在第0/1/2/3圈且基站连线与原NR宏站小区方向之差少于100度且基站连线与目标LTE宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件10a]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件10b]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'0','','180','180','indoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[自定条件12]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','NrToLteNeighbor','宽松(说明用途)',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

end if;

-- LteToGsm

	SET @remarkNote := '[用户自定义条件1]目标GSM宏站小区位于原LTE宏站小区第0/1/2/3圈且250米内全选!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','250','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件2]目标GSM宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且650米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'2','650','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件3]目标GSM宏站小区在第0/1/2/3圈且两小区互相在对方正负65度扇叶范围内对打且1200米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','1200','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件4]目标GSM宏站小区在第0/1/2/3圈且两小区互相在对方正负75度扇叶范围内对打且1000米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','1000','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件5]目标GSM宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于40度且基站连线与目标LTE宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[用户自定义条件6]目标GSM宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于100度且基站连线与目标LTE宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);
--
	SET @remarkNote := '[用户自定义条件7a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[用户自定义条件7b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[用户自定义条件8]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','基本扩展算法',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

if 1=1 then

	SET @remarkNote := '[自定条件1]宏站小区第0圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件2]宏站小区第1圈范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'1','','180','180','outdoor','outdoor',
						@algType,@remarkNote);
						
	SET @remarkNote := '[自定条件3]宏站小区500米范围内所有宏站小区全选!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'','500','180','180','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件4]目标GSM宏站小区在第2圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'2','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件5]目标GSM宏站小区在第3圈且两小区互相在对方正负75度扇叶范围内对打且1200米内!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'3','1200','75','75','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件6]目标GSM宏站小区在第2圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'2','','65','65','outdoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件7]目标GSM宏站小区在第3圈且两小区互相在对方正负65度扇叶范围内对打!!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'3','','65','65','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件8]目标GSM宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于40度且基站连线与目标GSM宏站小区方向之差少于100度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'','800','40','100','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件9]目标GSM宏站小区在第0/1/2/3圈且基站连线与原LTE宏站小区方向之差少于100度且基站连线与目标GSM宏站小区方向之差少于40度内对打且800米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'','800','100','40','outdoor','outdoor',
						@algType,@remarkNote);

	SET @remarkNote := '[自定条件10a]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'0','','180','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件10b]室分小区位于宏站小区第0圈!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'0','','180','180','indoor','outdoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11a]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'1','500','75','180','outdoor','indoor',
						@algType,@remarkNote);	

	SET @remarkNote := '[自定条件11b]室分小区位于宏站小区第1圈且500米内且正负75度扇叶范围内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'1','500','180','75','indoor','outdoor',
						@algType,@remarkNote);	
--
	SET @remarkNote := '[自定条件12]两室分在25米内!';
	insert into UserDefinedRules (`id`,`userName`,`neighborType`,`algorithmName`,
				`tier`,`distance`,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTYpeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`) 
		values (0,'admin','LteToGsmNeighbor','宽松(说明用途)',
						'','25','180','180','indoor','indoor',
						@algType,@remarkNote);

end if;

end if;

 END;

--changeset ericsson:3.2.0-base-newsite_common12
DROP PROCEDURE IF EXISTS `newsite_selectNeighborUserDefined`;
--changeset ericsson:3.2.0-base-newsite_common13 splitStatements:false
CREATE PROCEDURE `newsite_selectNeighborUserDefined`()
 BEGIN
 
	DECLARE CMD varchar(512);

	SET @neighborType := concat(@outputType,'Neighbor');

	drop table if exists `temp1`;
	Create Temporary Table temp1 like UserDefinedRules;
	insert into temp1
	select 0, userName,neighborType,algorithmName, 
				tier,distance,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTypeNeigh`,
				`remark[筛选类型]`,`remark[筛选条件]`
	from UserDefinedRules
	where userName=@userNameOnUser and neighborType=@neighborType and algorithmName=@algorithmName;

	select count(*) from temp1 into @numRec;

		SET @i := 0;
		While @i<@numRec Do
			SET @i := @i + 1;
			
			select tier,distance,`dir与基站连线之差`,`dirNeigh与基站连线之差`,`cellType`,`cellTypeNeigh`,`remark[筛选类型]`,`remark[筛选条件]` 
				from temp1 where id=@i 
				into @tier,@distance,@outwardHalfAngle,@inwardHalfAngle,@cellType,@cellTypeNeigh,@remarkType,@remarkNote;

			if not(@tier='' and @distance='' and @outwardHalfAngle='' and @inwardHalfAngle='') 
				and @remarkType<>'' and @remarkNote<>'' then
	
					SET @and := NULL;
					SET CMD := concat("update temp5 set remark0='",concat(@remarkType,'.',@userNameOnUser,'.',@algorithmName),"', remark0a='",@remarkNote,"' where ");
			
					if @tier<>'' then
						SET CMD := concat(CMD,' ',ifnull(@and,''),' tier=',@tier);
						SET @and := ifnull(@and,'and');
					end if;
			
					if @distance<>'' then
						SET CMD := concat(CMD,' ',ifnull(@and,''),' (distance>=0 and distance<=',@distance,')');
						SET @and := ifnull(@and,'and');
					end if;

					if cast(@outwardHalfAngle as UNSIGNED) between 1 and 179 then
						SET CMD := concat(CMD,' ',ifnull(@and,''),' (abs(((540+angle-dir) mod 360)-180)<',cast(@outwardHalfAngle as UNSIGNED),')');
						SET @and := ifnull(@and,'and');
					end if;
			
					if cast(@inwardHalfAngle as UNSIGNED) between 1 and 179 then
						SET CMD := concat(CMD,' ',ifnull(@and,''),' (abs(((720+angle-dirNeigh) mod 360)-180)<',cast(@inwardHalfAngle as UNSIGNED),')');
						SET @and := ifnull(@and,'and');
					end if;
			
					SET @CMD := concat(CMD," and cellType='",@cellType,"' and cellTypeNeigh='",@cellTypeNeigh,"' and remark0a='' and angle<>'';");
					PREPARE STATEMENT from @CMD;
					EXECUTE STATEMENT;

			end if;
			
 		End While;

 END;

