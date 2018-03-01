libname lib '/folders/myfolders/';

/*importing flights  */
proc import datafile= '/folders/myfolders/lib/flights.csv'
out= flights replace
dbms = csv;
getnames= yes;
guessingrows= 1000;

/* importing weather  */
proc import datafile= '/folders/myfolders/lib/weather.csv'
out= weather replace
dbms = csv;
getnames= yes;
guessingrows= 1000;

/* importing planes */
proc import datafile= '/folders/myfolders/lib/planes.csv'
out= planes replace
dbms = csv;
getnames= yes;
guessingrows= 3322;

/*Year from Date variable  */
/* Month from Date variable */
/* Day  from Date variable */
data flights;
set flights;
year_from_date = year(date);
month_from_date = month(date);
day_from_date = day(date);
run;

data flights;
set flights;
if sched_dep_time = . then delete;
if dep_time = . then delete;
run;

/* Transforming Time variables */
/* copying data from flights into flights1 dataset */
data flights1(drop = sched_dep_time dep_time sched_arr_time arr_time h:);
set flights;
hour = put(sched_dep_time,z4.);
h1 = substr(hour,1,2);
h2 = substr(hour,3,2);
h3 = catx(':',h1,h2);
h4 = input(h3,hhmmss4.);
hour1 = put(dep_time,z4.);
h5 = substr(hour1,1,2);
h6 = substr(hour1,3,2);
h7 = catx(':',h5,h6);
h8 = input(h7,hhmmss4.);
hour2 = put(sched_arr_time,z4.);
h9 = substr(hour2,1,2);
h10 = substr(hour2,3,2);
h11 = catx(':',h9,h10);
h12 = input(h11,hhmmss4.);
hour3 = put(arr_time,z4.);
h13 = substr(hour3,1,2);
h14 = substr(hour3,3,2);
h15 = catx(':',h13,h14);
h16 = input(h15,hhmmss4.);
format h12 timeAMPM8.;
format h16 timeAMPM8.;
format h8 timeAMPM8.;
format h4 timeAMPM8.; 
rename h4 = scheduled_dep_time;
rename h8 = departure_time;
rename h12 = scheduled_arr_time;
rename h16 = arrival_time;
run;

/* hour from sched dep time var  */
data flights1;
set flights1;
hour=hour(scheduled_dep_time);
run;

/* Departure Delay and Arrival Delay calculation */
data flights1;
set flights1;
if(hour(scheduled_dep_time)- hour(departure_time) > 12)
then departure_delay = intck('minute',scheduled_dep_time,('24:00't +departure_time));
else
departure_delay = intck('minute',scheduled_dep_time,departure_time);
if(hour(scheduled_arr_time)- hour(arrival_time) > 12)
then  arrival_delay= intck('minute',scheduled_arr_time,('24:00't + arrival_time));
else
arrival_delay = intck('minute',scheduled_arr_time,arrival_time);
run;


/* question 2  */
/* taing out hour from weather */
data weather1(drop=time hour);
set weather;
hour1 = input(scan(time,1,':'),2.);
rename origin = origin1;
rename date = date1;
format pressure D.;
run;

/* adding 2 new variables in plane dataset */
data planes;
set planes;
years_use = 2013 - manufacturing_year;
no_of_years_old = 2018 - manufacturing_year;
run;

/* joining flights and weather data  */
proc sql;
create table flights_weather_join as
select a.*, b.*
from flights1 as a left join weather1 as b on a.hour = b.hour1 
and a.origin=b.origin1 and a.date = b.date1;
quit;

/* joining the above table with planes data  */
proc sql;
create table flights_planes_weather as
select a.*, b.*
from flights_weather_join as 
a inner join planes as b on a.tailnum = b.plane;
quit;


/* question 3  */
/* missing values in flights dataset 		 */
/* first part  */ 
/* creation of format  */
proc format;
 value $missing_char
    'NA' = 'Missing'
    other = 'Present'
    ;
 value missing_num
    . = 'Missing'
    other = 'Present'
    ;
run;

proc freq data= flights1;
tables _all_/missing;
format _character_ $missing_char. _numeric_ missing_num.;
run;

/* second part  */
 
data flights1;
set flights1;
if missing(departure_time) then delete;
if missing(tailnum) then delete;
if missing(arrival_time) then delete;
run;

/*replace missing values by average for specific route  */

proc sql;
create table flights1 as
select *, coalesce(air_time, mean(air_time)) as air_time1 from flights1 
group by carrier, origin, dest;
quit;

/*  to do - simple step, question is done */
data flights1(drop = air_time);
set  flights1;
rename air_time1 = air_time;
run;

/*in weather dataset  */
/* first part */
proc freq data= weather;
tables _all_/missing;
format _character_ $missing_char. _numeric_ missing_num.;
run;

data weather;
set weather;
array C_MISS[*] _CHARACTER_;
	do i=1 to dim(C_MISS);
	if C_MISS[i]= "NA" then C_MISS[i]= 0;
	end;
	drop i;

data weather(drop = pressure);
set weather;
pressure1 = input(pressure,D.);
run;

data weather;
set weather;
rename pressure1 = pressure;

/* second part */
proc sql;
create table weather1 as
select *, coalesce(temp, mean(temp)) as temp1, coalesce(dewp, mean(dewp)) as dewp1 ,coalesce(humid, mean(humid))as humid1,
coalesce(wind_gust, mean(wind_gust))as wind_gust1, coalesce(pressure,mean(pressure)) as pressure1
from weather 
group by origin, date;
quit;

data weather1(drop = temp dewp humid wind_gust pressure);
set weather1;
run;

/*  missing values in planes dataset */
/* first part  */
proc freq data= planes;
tables _all_/missing;
format _character_ $missing_char. _numeric_ missing_num.;
run;

/* Speed  variable has more than 70% values as missing values.*/
/* delete variable that has more then 70% of values missing  */

data planes(drop = speed);
set planes;
run;

/* third part - remove all observations with missing values  */
data planes;
set planes;
array N_MISS[*] _numeric_;
	do i=1 to dim(N_MISS);
	if N_MISS[i]= . then delete;
	end;
	drop i;
	
	
array C_MISS[*] _CHARACTER_;
	do i=1 to dim(C_MISS);
	if C_MISS[i]= "NA" then delete;
	end;
	drop i;
run;



/* question 4  */
/*format  */
/* part - 1 */
data flights;
set flights;
label date = "date of departure";
label dep_time = "Actual departure time";
label arr_time = "Actual arrival time";
label sched_dep_time = "Scheduled departure time";
label sched_arr_time = "Scheduled arrival time";
label carrier = "Two letter carrier abbreviation";
label flight = "Flight number";
label tailnum = "Plane tail number";
label origin = "Origin";
label dest = "destination";
label distance = "Distance flown";
label air_time = "Amount of time spent in the air, in minutes";
run;

data planes;
set planes;
label  plane = "Tail number" ;
label year=	"Year manufactured";
label type	="Type of plane";
label engines="Number of engines";
label seats="Number of seats";
label  speed = "Average cruising speed in mph";
label engine = "Type of engine";
label fuel_cc = "Average annual fuel consumption cost";
run;

data weather;
set weather;
label visib = "Visibility in miles";
label pressure = "Sea level pressure in millibars";
label precip = "Preciptation, in inches";
label wind_dir = "Wind direction (in degrees)";
label wind_speed = "speed";
label wind_gust = "gust speed (in mph)";
label humid = "Relative humidity";
label temp = "temperature";
label dewp = "dewpoint";
label date = "date of recording";
label time = "time of recording";
run;

proc import datafile= '/folders/myfolders/lib/airports.csv'
out= airports replace
dbms = csv;
getnames= yes;

proc import datafile= '/folders/myfolders/lib/airlines.csv'
out= airlines replace
dbms = csv;
getnames= yes;

data airports;
set airports;
label faa = "FAA airport code";
label name = "Usual name of the aiport";
label lat = "location of airport";
label lon = "location of airport";
run;

data airlines;
set airlines;
label carrier = "Two letter abbreviation";
label name = "Full name";
run;

/* part - 2  */
data planes;
set planes;
fuel_cc = round(fuel_cc,1);
run;

/* part - 3  */
proc format lib = work;
value $odes
'9E' = "Endeavor Air Inc."
'AA' = "American Airlines Inc."
'AS' = "Alaska Airlines Inc."
'B6' = "JetBlue Airways"
'DL' = "Delta Air Lines Inc."
'EV' = "ExpressJet Airlines Inc."
'F9' = "Frontier Airlines Inc."
'FL' = "AirTran Airways Corporation"
'HA' = "Hawaiian Airlines Inc."
'MQ'  = "Envoy Air"
'OO' = "SkyWest Airlines Inc."
'UA' = "United Air Lines Inc."
'US' = "US Airways Inc."
'VX' = "Virgin America"
'WN' = "Southwest Airlines Co."
'YV' = "Mesa Airlines Inc."
;
run;
 
data flights1;
set flights1;
format carrier odes.;
run;

proc format lib = work;
value $route
"	04G	"	=	"	LansdowneAirport	"
"	06A	"	=	"	MotonFieldMunicipalAirport	"
"	06C	"	=	"	SchaumburgRegional	"
"	06N	"	=	"	RandallAirport	"
"	09J	"	=	"	JekyllIslandAirport	"
"	0A9	"	=	"	ElizabethtonMunicipalAirport	"
"	0G6	"	=	"	WilliamsCountyAirport	"
"	0G7	"	=	"	FingerLakesRegionalAirport	"
"	0P2	"	=	"	ShoestringAviationAirfield	"
"	0S9	"	=	"	JeffersonCountyIntl	"
"	0W3	"	=	"	HarfordCountyAirport	"
"	10C	"	=	"	GaltFieldAirport	"
"	17G	"	=	"	PortBucyrus-CrawfordCountyAirport	"
"	19A	"	=	"	JacksonCountyAirport	"
"	1A3	"	=	"	MartinCampbellFieldAirport	"
"	1B9	"	=	"	MansfieldMunicipal	"
"	1C9	"	=	"	FrazierLakeAirpark	"
"	1CS	"	=	"	ClowInternationalAirport	"
"	1G3	"	=	"	KentStateAirport	"
"	1OH	"	=	"	FortmanAirport	"
"	1RL	"	=	"	PointRobertsAirpark	"
"	24C	"	=	"	LowellCityAirport	"
"	24J	"	=	"	SuwanneeCountyAirport	"
"	25D	"	=	"	ForestLakeAirport	"
"	29D	"	=	"	GroveCityAirport	"
"	2A0	"	=	"	MarkAntonAirport	"
"	2G2	"	=	"	JeffersonCountyAirpark	"
"	2G9	"	=	"	SomersetCountyAirport	"
"	2J9	"	=	"	QuincyMunicipalAirport	"
"	369	"	=	"	AtmautluakAirport	"
"	36U	"	=	"	HeberCityMunicipalAirport	"
"	38W	"	=	"	LyndenAirport	"
"	3D2	"	=	"	Ephraim-GibraltarAirport	"
"	3G3	"	=	"	WadsworthMunicipal	"
"	3G4	"	=	"	AshlandCountyAirport	"
"	3J1	"	=	"	RidgelandAirport	"
"	3W2	"	=	"	Put-in-BayAirport	"
"	40J	"	=	"	Perry-FoleyAirport	"
"	41N	"	=	"	BracevilleAirport	"
"	47A	"	=	"	CherokeeCountyAirport	"
"	49A	"	=	"	GilmerCountyAirport	"
"	49X	"	=	"	ChemehueviValley	"
"	4A4	"	=	"	PolkCountyAirport-CorneliusMooreField	"
"	4A7	"	=	"	ClaytonCountyTaraField	"
"	4A9	"	=	"	IsbellFieldAirport	"
"	4B8	"	=	"	RobertsonField	"
"	4G0	"	=	"	Pittsburgh-MonroevilleAirport	"
"	4G2	"	=	"	HamburgIncAirport	"
"	4G4	"	=	"	YoungstownElserMetroAirport	"
"	4I7	"	=	"	PutnamCountyAirport	"
"	4U9	"	=	"	DellFlightStrip	"
"	52A	"	=	"	MadisonGAMunicipalAirport	"
"	54J	"	=	"	DeFuniakSpringsAirport	"
"	55J	"	=	"	FernandinaBeachMunicipalAirport	"
"	57C	"	=	"	EastTroyMunicipalAirport	"
"	60J	"	=	"	OceanIsleBeachAirport	"
"	6A2	"	=	"	Griffin-SpaldingCountyAirport	"
"	6K8	"	=	"	TokJunctionAirport	"
"	6S0	"	=	"	BigTimberAirport	"
"	6S2	"	=	"	Florence	"
"	6Y8	"	=	"	WelkeAirport	"
"	70J	"	=	"	Cairo-GradyCountyAirport	"
"	70N	"	=	"	SpringHillAirport	"
"	7A4	"	=	"	FosterField	"
"	7D9	"	=	"	GermackAirport	"
"	7N7	"	=	"	SpitfireAerodrome	"
"	8M8	"	=	"	GarlandAirport	"
"	93C	"	=	"	RichlandAirport	"
"	99N	"	=	"	BambergCountyAirport	"
"	9A1	"	=	"	CovingtonMunicipalAirport	"
"	9A5	"	=	"	BarwickLafayetteAirport	"
"	A39	"	=	"	PhoenixRegionalAirport	"
"	AAF	"	=	"	ApalachicolaRegionalAirport	"
"	ABE	"	=	"	LehighValleyIntl	"
"	ABI	"	=	"	AbileneRgnl	"
"	ABL	"	=	"	AmblerAirport	"
"	ABQ	"	=	"	AlbuquerqueInternationalSunport	"
"	ABR	"	=	"	AberdeenRegionalAirport	"
"	ABY	"	=	"	SouthwestGeorgiaRegionalAirport	"
"	ACK	"	=	"	NantucketMem	"
"	ACT	"	=	"	WacoRgnl	"
"	ACV	"	=	"	Arcata	"
"	ACY	"	=	"	AtlanticCityIntl	"
"	ADK	"	=	"	AdakAirport	"
"	ADM	"	=	"	ArdmoreMuni	"
"	ADQ	"	=	"	Kodiak	"
"	ADS	"	=	"	Addison	"
"	ADW	"	=	"	AndrewsAfb	"
"	AET	"	=	"	AllakaketAirport	"
"	AEX	"	=	"	AlexandriaIntl	"
"	AFE	"	=	"	KakeAirport	"
"	AFW	"	=	"	FortWorthAllianceAirport	"
"	AGC	"	=	"	AlleghenyCountyAirport	"
"	AGN	"	=	"	AngoonSeaplaneBase	"
"	AGS	"	=	"	AugustaRgnlAtBushFld	"
"	AHN	"	=	"	AthensBenEppsAirport	"
"	AIA	"	=	"	AllianceMunicipalAirport	"
"	AIK	"	=	"	MunicipalAirport	"
"	AIN	"	=	"	WainwrightAirport	"
"	AIZ	"	=	"	LeeCFineMemorialAirport	"
"	AKB	"	=	"	AtkaAirport	"
"	AKC	"	=	"	AkronFultonIntl	"
"	AKI	"	=	"	AkiakAirport	"
"	AKK	"	=	"	AkhiokAirport	"
"	AKN	"	=	"	KingSalmon	"
"	AKP	"	=	"	AnaktuvukPassAirport	"
"	ALB	"	=	"	AlbanyIntl	"
"	ALI	"	=	"	AliceIntl	"
"	ALM	"	=	"	AlamogordoWhiteSandsRegionalAirport	"
"	ALO	"	=	"	WaterlooRegionalAirport	"
"	ALS	"	=	"	SanLuisValleyRegionalAirport	"
"	ALW	"	=	"	WallaWallaRegionalAirport	"
"	ALX	"	=	"	Alexandria	"
"	ALZ	"	=	"	AlitakSeaplaneBase	"
"	AMA	"	=	"	RickHusbandAmarilloIntl	"
"	ANB	"	=	"	AnnistonMetro	"
"	ANC	"	=	"	TedStevensAnchorageIntl	"
"	AND	"	=	"	AndersonRgnl	"
"	ANI	"	=	"	AniakAirport	"
"	ANN	"	=	"	AnnetteIsland	"
"	ANP	"	=	"	LeeAirport	"
"	ANQ	"	=	"	Tri-StateSteubenCountyAirport	"
"	ANV	"	=	"	AnvikAirport	"
"	AOH	"	=	"	LimaAllenCountyAirport	"
"	AOO	"	=	"	AltoonaBlairCo	"
"	AOS	"	=	"	AmookBaySeaplaneBase	"
"	APA	"	=	"	Centennial	"
"	APC	"	=	"	NapaCountyAirport	"
"	APF	"	=	"	NaplesMuni	"
"	APG	"	=	"	PhillipsAaf	"
"	APN	"	=	"	AlpenaCountyRegionalAirport	"
"	AQC	"	=	"	KlawockSeaplaneBase	"
"	ARA	"	=	"	AcadianaRgnl	"
"	ARB	"	=	"	AnnArborMunicipalAirport	"
"	ARC	"	=	"	ArcticVillageAirport	"
"	ART	"	=	"	WatertownIntl	"
"	ARV	"	=	"	Lakeland	"
"	ASE	"	=	"	AspenPitkinCountySardyField	"
"	ASH	"	=	"	BoireFieldAirport	"
"	AST	"	=	"	AstoriaRegionalAirport	"
"	ATK	"	=	"	AtqasukEdwardBurnellSrMemorialAirport	"
"	ATL	"	=	"	HartsfieldJacksonAtlantaIntl	"
"	ATT	"	=	"	CampMabryAustinCity	"
"	ATW	"	=	"	Appleton	"
"	ATY	"	=	"	WatertownRegionalAirport	"
"	AUG	"	=	"	AugustaState	"
"	AUK	"	=	"	AlakanukAirport	"
"	AUS	"	=	"	AustinBergstromIntl	"
"	AUW	"	=	"	WausauDowntownAirport	"
"	AVL	"	=	"	AshevilleRegionalAirport	"
"	AVO	"	=	"	Executive	"
"	AVP	"	=	"	WilkesBarreScrantonIntl	"
"	AVW	"	=	"	MaranaRegional	"
"	AVX	"	=	"	Avalon	"
"	AZA	"	=	"	Phoenix-MesaGateway	"
"	AZO	"	=	"	Kalamazoo	"
"	BAB	"	=	"	BealeAfb	"
"	BAD	"	=	"	BarksdaleAfb	"
"	BAF	"	=	"	BarnesMunicipal	"
"	BBX	"	=	"	WingsField	"
"	BCE	"	=	"	BryceCanyon	"
"	BCT	"	=	"	BocaRaton	"
"	BDE	"	=	"	BaudetteIntl	"
"	BDL	"	=	"	BradleyIntl	"
"	BDR	"	=	"	IgorISikorskyMem	"
"	BEC	"	=	"	BeechFactoryAirport	"
"	BED	"	=	"	LaurenceGHanscomFld	"
"	BEH	"	=	"	SouthwestMichiganRegionalAirport	"
"	BET	"	=	"	Bethel	"
"	BFD	"	=	"	BradfordRegionalAirport	"
"	BFF	"	=	"	WesternNebraskaRegionalAirport	"
"	BFI	"	=	"	BoeingFldKingCoIntl	"
"	BFL	"	=	"	MeadowsFld	"
"	BFM	"	=	"	MobileDowntown	"
"	BFP	"	=	"	BeaverFalls	"
"	BFT	"	=	"	Beaufort	"
"	BGE	"	=	"	DecaturCountyIndustrialAirPark	"
"	BGM	"	=	"	GreaterBinghamtonEdwinALinkFld	"
"	BGR	"	=	"	BangorIntl	"
"	BHB	"	=	"	HancockCounty-BarHarbor	"
"	BHM	"	=	"	BirminghamIntl	"
"	BID	"	=	"	BlockIslandStateAirport	"
"	BIF	"	=	"	BiggsAaf	"
"	BIG	"	=	"	AllenAaf	"
"	BIL	"	=	"	BillingsLoganInternationalAirport	"
"	BIS	"	=	"	BismarckMunicipalAirport	"
"	BIV	"	=	"	TulipCityAirport	"
"	BIX	"	=	"	KeeslerAfb	"
"	BJC	"	=	"	RockyMountainMetropolitanAirport	"
"	BJI	"	=	"	BemidjiRegionalAirport	"
"	BKC	"	=	"	BucklandAirport	"
"	BKD	"	=	"	StephensCo	"
"	BKF	"	=	"	BuckleyAfb	"
"	BKG	"	=	"	BransonLLC	"
"	BKH	"	=	"	BarkingSandsPmrf	"
"	BKL	"	=	"	BurkeLakefrontAirport	"
"	BKW	"	=	"	RaleighCountyMemorialAirport	"
"	BKX	"	=	"	BrookingsRegionalAirport	"
"	BLD	"	=	"	BoulderCityMunicipalAirport	"
"	BLF	"	=	"	MercerCountyAirport	"
"	BLH	"	=	"	BlytheAirport	"
"	BLI	"	=	"	BellinghamIntl	"
"	BLV	"	=	"	ScottAfbMidamerica	"
"	BMC	"	=	"	BrighamCity	"
"	BMG	"	=	"	MonroeCountyAirport	"
"	BMI	"	=	"	CentralIllinoisRgnl	"
"	BMX	"	=	"	BigMountainAfs	"
"	BNA	"	=	"	NashvilleIntl	"
"	BOI	"	=	"	BoiseAirTerminal	"
"	BOS	"	=	"	GeneralEdwardLawrenceLoganIntl	"
"	BOW	"	=	"	BartowMunicipalAirport	"
"	BPT	"	=	"	SoutheastTexasRgnl	"
"	BQK	"	=	"	BrunswickGoldenIslesAirport	"
"	BRD	"	=	"	BrainerdLakesRgnl	"
"	BRL	"	=	"	SoutheastIowaRegionalAirport	"
"	BRO	"	=	"	BrownsvilleSouthPadreIslandIntl	"
"	BRW	"	=	"	WileyPostWillRogersMem	"
"	BSF	"	=	"	BradshawAaf	"
"	BTI	"	=	"	BarterIslandLrrs	"
"	BTM	"	=	"	BertMooneyAirport	"
"	BTR	"	=	"	BatonRougeMetroRyanFld	"
"	BTT	"	=	"	Bettles	"
"	BTV	"	=	"	BurlingtonIntl	"
"	BUF	"	=	"	BuffaloNiagaraIntl	"
"	BUR	"	=	"	BobHope	"
"	BUU	"	=	"	MunicipalAirport	"
"	BUY	"	=	"	Burlington-AlamanceRegionalAirport	"
"	BVY	"	=	"	BeverlyMunicipalAirport	"
"	BWD	"	=	"	KBWD	"
"	BWG	"	=	"	BowlingGreen-WarrenCountyRegionalAirport	"
"	BWI	"	=	"	BaltimoreWashingtonIntl	"
"	BXK	"	=	"	BuckeyeMunicipalAirport	"
"	BXS	"	=	"	BorregoValleyAirport	"
"	BYH	"	=	"	ArkansasIntl	"
"	BYS	"	=	"	BicycleLakeAaf	"
"	BYW	"	=	"	BlakelyIslandAirport	"
"	BZN	"	=	"	GallatinField	"
"	C02	"	=	"	GrandGenevaResortAirport	"
"	C16	"	=	"	FrascaField	"
"	C47	"	=	"	PortageMunicipalAirport	"
"	C65	"	=	"	PlymouthMunicipalAirport	"
"	C89	"	=	"	SylvaniaAirport	"
"	C91	"	=	"	DowagiacMunicipalAirport	"
"	CAE	"	=	"	ColumbiaMetropolitan	"
"	CAK	"	=	"	AkronCantonRegionalAirport	"
"	CAR	"	=	"	CaribouMuni	"
"	CBE	"	=	"	GreaterCumberlandRgnl.	"
"	CBM	"	=	"	ColumbusAfb	"
"	CCO	"	=	"	CowetaCountyAirport	"
"	CCR	"	=	"	BuchananFieldAirport	"
"	CDB	"	=	"	ColdBay	"
"	CDC	"	=	"	CedarCityRgnl	"
"	CDI	"	=	"	CambridgeMunicipalAirport	"
"	CDK	"	=	"	CedarKey	"
"	CDN	"	=	"	WoodwardField	"
"	CDR	"	=	"	ChadronMunicipalAirport	"
"	CDS	"	=	"	ChildressMuni	"
"	CDV	"	=	"	MerleKMudholeSmith	"
"	CDW	"	=	"	CaldwellEssexCountyAirport	"
"	CEC	"	=	"	DelNorteCountyAirport	"
"	CEF	"	=	"	WestoverArbMetropolitan	"
"	CEM	"	=	"	CentralAirport	"
"	CEU	"	=	"	Clemson	"
"	CEW	"	=	"	BobSikes	"
"	CEZ	"	=	"	CortezMuni	"
"	CFD	"	=	"	CoulterFld	"
"	CGA	"	=	"	CraigSeaplaneBase	"
"	CGF	"	=	"	CuyahogaCounty	"
"	CGI	"	=	"	CapeGirardeauRegionalAirport	"
"	CGX	"	=	"	MeigsField	"
"	CGZ	"	=	"	CasaGrandeMunicipalAirport	"
"	CHA	"	=	"	LovellFld	"
"	CHI	"	=	"	AllAirports	"
"	CHO	"	=	"	Charlottesville-Albemarle	"
"	CHS	"	=	"	CharlestonAfbIntl	"
"	CHU	"	=	"	ChuathbalukAirport	"
"	CIC	"	=	"	ChicoMuni	"
"	CID	"	=	"	CedarRapids	"
"	CIK	"	=	"	ChalkyitsikAirport	"
"	CIL	"	=	"	CouncilAirport	"
"	CIU	"	=	"	ChippewaCountyInternationalAirport	"
"	CKB	"	=	"	HarrisonMarionRegionalAirport	"
"	CKD	"	=	"	CrookedCreekAirport	"
"	CKF	"	=	"	CrispCountyCordeleAirport	"
"	CKV	"	=	"	Clarksville-MontgomeryCountyRegionalAirport	"
"	CLC	"	=	"	ClearLakeMetroport	"
"	CLD	"	=	"	McClellan-PalomarAirport	"
"	CLE	"	=	"	ClevelandHopkinsIntl	"
"	CLL	"	=	"	EasterwoodFld	"
"	CLM	"	=	"	WilliamRFairchildInternationalAirport	"
"	CLT	"	=	"	CharlotteDouglasIntl	"
"	CLW	"	=	"	ClearwaterAirPark	"
"	CMH	"	=	"	PortColumbusIntl	"
"	CMI	"	=	"	Champaign	"
"	CMX	"	=	"	HoughtonCountyMemorialAirport	"
"	CNM	"	=	"	CavernCityAirTerminal	"
"	CNW	"	=	"	TstcWaco	"
"	CNY	"	=	"	CanyonlandsField	"
"	COD	"	=	"	YellowstoneRgnl	"
"	COF	"	=	"	PatrickAfb	"
"	CON	"	=	"	ConcordMunicipal	"
"	COS	"	=	"	CityOfColoradoSpringsMuni	"
"	COT	"	=	"	CotullaLasalleCo	"
"	COU	"	=	"	ColumbiaRgnl	"
"	CPR	"	=	"	NatronaCoIntl	"
"	CPS	"	=	"	St.LouisDowntownAirport	"
"	CRE	"	=	"	GrandStrandAirport	"
"	CRP	"	=	"	CorpusChristiIntl	"
"	CRW	"	=	"	Yeager	"
"	CSG	"	=	"	ColumbusMetropolitanAirport	"
"	CTB	"	=	"	CutBankMuni	"
"	CTH	"	=	"	ChesterCountyGOCarlsonAirport	"
"	CTJ	"	=	"	WestGeorgiaRegionalAirport-OVGrayField	"
"	CTY	"	=	"	CrossCity	"
"	CVG	"	=	"	CincinnatiNorthernKentuckyIntl	"
"	CVN	"	=	"	ClovisMuni	"
"	CVS	"	=	"	CannonAfb	"
"	CVX	"	=	"	CharlevoixMunicipalAirport	"
"	CWA	"	=	"	CentralWisconsin	"
"	CWI	"	=	"	ClintonMunicipal	"
"	CXF	"	=	"	ColdfootAirport	"
"	CXL	"	=	"	CalexicoIntl	"
"	CXO	"	=	"	LoneStarExecutive	"
"	CXY	"	=	"	CapitalCityAirport	"
"	CYF	"	=	"	ChefornakAirport	"
"	CYM	"	=	"	ChathamSeaplaneBase	"
"	CYS	"	=	"	CheyenneRgnlJerryOlsonFld	"
"	CYT	"	=	"	YakatagaAirport	"
"	CZF	"	=	"	CapeRomanzofLrrs	"
"	CZN	"	=	"	ChisanaAirport	"
"	DAB	"	=	"	DaytonaBeachIntl	"
"	DAL	"	=	"	DallasLoveFld	"
"	DAY	"	=	"	JamesMCoxDaytonIntl	"
"	DBQ	"	=	"	DubuqueRgnl	"
"	DCA	"	=	"	RonaldReaganWashingtonNatl	"
"	DDC	"	=	"	DodgeCityRegionalAirport	"
"	DEC	"	=	"	Decatur	"
"	DEN	"	=	"	DenverIntl	"
"	DET	"	=	"	ColemanAYoungMuni	"
"	DFW	"	=	"	DallasFortWorthIntl	"
"	DGL	"	=	"	DouglasMunicipalAirport	"
"	DHN	"	=	"	DothanRgnl	"
"	DHT	"	=	"	DalhartMuni	"
"	DIK	"	=	"	DickinsonTheodoreRooseveltRegionalAirport	"
"	DKB	"	=	"	DeKalbTaylorMunicipalAirport	"
"	DKK	"	=	"	ChautauquaCounty-DunkirkAirport	"
"	DKX	"	=	"	KnoxvilleDowntownIslandAirport	"
"	DLF	"	=	"	LaughlinAfb	"
"	DLG	"	=	"	Dillingham	"
"	DLH	"	=	"	DuluthIntl	"
"	DLL	"	=	"	BarabooWisconsinDellsAirport	"
"	DMA	"	=	"	DavisMonthanAfb	"
"	DNL	"	=	"	DanielFieldAirport	"
"	DNN	"	=	"	DaltonMunicipalAirport	"
"	DOV	"	=	"	DoverAfb	"
"	DPA	"	=	"	Dupage	"
"	DQH	"	=	"	DouglasMunicipalAirport	"
"	DRG	"	=	"	DeeringAirport	"
"	DRI	"	=	"	BeauregardRgnl	"
"	DRM	"	=	"	DrummondIslandAirport	"
"	DRO	"	=	"	DurangoLaPlataCo	"
"	DRT	"	=	"	DelRioIntl	"
"	DSM	"	=	"	DesMoinesIntl	"
"	DTA	"	=	"	DeltaMunicipalAirport	"
"	DTS	"	=	"	Destin	"
"	DTW	"	=	"	DetroitMetroWayneCo	"
"	DUC	"	=	"	HalliburtonFieldAirport	"
"	DUG	"	=	"	BisbeeDouglasIntl	"
"	DUJ	"	=	"	DuBoisRegionalAirport	"
"	DUT	"	=	"	Unalaska	"
"	DVL	"	=	"	DevilsLakeRegionalAirport	"
"	DVT	"	=	"	DeerValleyMunicipalAirport	"
"	DWA	"	=	"	YoloCountyAirport	"
"	DWH	"	=	"	DavidWayneHooksField	"
"	DWS	"	=	"	Orlando	"
"	DXR	"	=	"	DanburyMunicipalAirport	"
"	DYS	"	=	"	DyessAfb	"
"	E25	"	=	"	WickenburgMunicipalAirport	"
"	E51	"	=	"	BagdadAirport	"
"	E55	"	=	"	OceanRidgeAirport	"
"	E63	"	=	"	GilaBendMunicipalAirport	"
"	E91	"	=	"	ChinleMunicipalAirport	"
"	EAA	"	=	"	EagleAirport	"
"	EAR	"	=	"	KearneyMunicipalAirport	"
"	EAT	"	=	"	PangbornField	"
"	EAU	"	=	"	ChippewaValleyRegionalAirport	"
"	ECA	"	=	"	IoscoCounty	"
"	ECG	"	=	"	ElizabethCityCgasRgnl	"
"	ECP	"	=	"	PanamaCity-NWFloridaBea.	"
"	EDF	"	=	"	ElmendorfAfb	"
"	EDW	"	=	"	EdwardsAfb	"
"	EEK	"	=	"	EekAirport	"
"	EEN	"	=	"	DillantHopkinsAirport	"
"	EET	"	=	"	ShelbyCountyAirport	"
"	EFD	"	=	"	EllingtonFld	"
"	EGA	"	=	"	EagleCountyAirport	"
"	EGE	"	=	"	EagleCoRgnl	"
"	EGT	"	=	"	WellingtonMunicipal	"
"	EGV	"	=	"	EagleRiver	"
"	EGX	"	=	"	EgegikAirport	"
"	EHM	"	=	"	CapeNewenhamLrrs	"
"	EIL	"	=	"	EielsonAfb	"
"	EKI	"	=	"	ElkhartMunicipal	"
"	EKN	"	=	"	ElkinsRandolphCoJenningsRandolph	"
"	EKO	"	=	"	ElkoRegionalAirport	"
"	ELD	"	=	"	SouthArkansasRgnlAtGoodwinFld	"
"	ELI	"	=	"	ElimAirport	"
"	ELM	"	=	"	ElmiraCorningRgnl	"
"	ELP	"	=	"	ElPasoIntl	"
"	ELV	"	=	"	ElfinCoveSeaplaneBase	"
"	ELY	"	=	"	ElyAirport	"
"	EMK	"	=	"	EmmonakAirport	"
"	EMP	"	=	"	EmporiaMunicipalAirport	"
"	ENA	"	=	"	KenaiMuni	"
"	END	"	=	"	VanceAfb	"
"	ENV	"	=	"	Wendover	"
"	ENW	"	=	"	KenoshaRegionalAirport	"
"	EOK	"	=	"	KeokukMunicipalAirport	"
"	EPM	"	=	"	EastportMunicipalAirport	"
"	EQY	"	=	"	MonroeReqionalAirport	"
"	ERI	"	=	"	ErieIntlTomRidgeFld	"
"	ERV	"	=	"	KerrvilleMunicipalAirport	"
"	ERY	"	=	"	LuceCountyAirport	"
"	ESC	"	=	"	DeltaCountyAirport	"
"	ESD	"	=	"	OrcasIslandAirport	"
"	ESF	"	=	"	EslerRgnl	"
"	ESN	"	=	"	Easton-NewnamFieldAirport	"
"	EUG	"	=	"	MahlonSweetFld	"
"	EVV	"	=	"	EvansvilleRegional	"
"	EWB	"	=	"	NewBedfordRegionalAirport	"
"	EWN	"	=	"	CravenCoRgnl	"
"	EWR	"	=	"	NewarkLibertyIntl	"
"	EXI	"	=	"	ExcursionInletSeaplaneBase	"
"	EYW	"	=	"	KeyWestIntl	"
"	F57	"	=	"	SeaplaneBase	"
"	FAF	"	=	"	FelkerAaf	"
"	FAI	"	=	"	FairbanksIntl	"
"	FAR	"	=	"	HectorInternationalAirport	"
"	FAT	"	=	"	FresnoYosemiteIntl	"
"	FAY	"	=	"	FayettevilleRegionalGrannisField	"
"	FBG	"	=	"	FredericksburgAmtrakStation	"
"	FBK	"	=	"	LaddAaf	"
"	FBS	"	=	"	FridayHarborSeaplaneBase	"
"	FCA	"	=	"	GlacierParkIntl	"
"	FCS	"	=	"	ButtsAaf	"
"	FDY	"	=	"	FindlayAirport	"
"	FFA	"	=	"	FirstFlightAirport	"
"	FFC	"	=	"	AtlantaRegionalAirport-FalconField	"
"	FFO	"	=	"	WrightPattersonAfb	"
"	FFT	"	=	"	CapitalCityAirport	"
"	FFZ	"	=	"	MesaFalconField	"
"	FHU	"	=	"	SierraVistaMuniLibbyAaf	"
"	FIT	"	=	"	FitchburgMunicipalAirport	"
"	FKL	"	=	"	Franklin	"
"	FLD	"	=	"	FondDuLacCountyAirport	"
"	FLG	"	=	"	FlagstaffPulliamAirport	"
"	FLL	"	=	"	FortLauderdaleHollywoodIntl	"
"	FLO	"	=	"	FlorenceRgnl	"
"	FLV	"	=	"	ShermanAaf	"
"	FME	"	=	"	Tipton	"
"	FMH	"	=	"	OtisAngb	"
"	FMN	"	=	"	FourCornersRgnl	"
"	FMY	"	=	"	PageFld	"
"	FNL	"	=	"	FortCollinsLovelandMuni	"
"	FNR	"	=	"	FunterBaySeaplaneBase	"
"	FNT	"	=	"	BishopInternational	"
"	FOD	"	=	"	FortDodgeRgnl	"
"	FOE	"	=	"	ForbesFld	"
"	FOK	"	=	"	FrancisSGabreski	"
"	FRD	"	=	"	FridayHarborAirport	"
"	FRI	"	=	"	MarshallAaf	"
"	FRN	"	=	"	BryantAhp	"
"	FRP	"	=	"	StLucieCountyInternationalAirport	"
"	FSD	"	=	"	SiouxFalls	"
"	FSI	"	=	"	HenryPostAaf	"
"	FSM	"	=	"	FortSmithRgnl	"
"	FST	"	=	"	FortStocktonPecosCo	"
"	FTK	"	=	"	GodmanAaf	"
"	FTW	"	=	"	FortWorthMeachamIntl	"
"	FTY	"	=	"	FultonCountyAirportBrownField	"
"	FUL	"	=	"	FullertonMunicipalAirport	"
"	FWA	"	=	"	FortWayne	"
"	FXE	"	=	"	FortLauderdaleExecutive	"
"	FYU	"	=	"	FortYukon	"
"	FYV	"	=	"	DrakeFld	"
"	FZG	"	=	"	FitzgeraldMunicipalAirport	"
"	GAD	"	=	"	NortheastAlabamaRegionalAirport	"
"	GAI	"	=	"	MontgomeryCountyAirpark	"
"	GAL	"	=	"	EdwardGPitkaSr	"
"	GAM	"	=	"	GambellAirport	"
"	GBN	"	=	"	GreatBendMunicipal	"
"	GCC	"	=	"	Gillette-CampbellCountyAirport	"
"	GCK	"	=	"	GardenCityRgnl	"
"	GCN	"	=	"	GrandCanyonNationalParkAirport	"
"	GCW	"	=	"	GrandCanyonWestAirport	"
"	GDV	"	=	"	DawsonCommunityAirport	"
"	GDW	"	=	"	GladwinZettelMemorialAirport	"
"	GED	"	=	"	SussexCo	"
"	GEG	"	=	"	SpokaneIntl	"
"	GEU	"	=	"	GlendaleMunicipalAirport	"
"	GFK	"	=	"	GrandForksIntl	"
"	GGE	"	=	"	GeorgetownCountyAirport	"
"	GGG	"	=	"	EastTexasRgnl	"
"	GGW	"	=	"	WokalFieldGlasgowInternationalAirport	"
"	GHG	"	=	"	MarshfieldMunicipalAirport	"
"	GIF	"	=	"	GilbertAirport	"
"	GJT	"	=	"	GrandJunctionRegional	"
"	GKN	"	=	"	Gulkana	"
"	GKY	"	=	"	ArlingtonMunicipal	"
"	GLD	"	=	"	RennerFld	"
"	GLH	"	=	"	MidDeltaRegionalAirport	"
"	GLS	"	=	"	ScholesIntlAtGalveston	"
"	GLV	"	=	"	GolovinAirport	"
"	GNT	"	=	"	GrantsMilanMuni	"
"	GNU	"	=	"	GoodnewsAirport	"
"	GNV	"	=	"	GainesvilleRgnl	"
"	GON	"	=	"	GrotonNewLondon	"
"	GPT	"	=	"	Gulfport-Biloxi	"
"	GPZ	"	=	"	GrandRapidsItascaCounty	"
"	GQQ	"	=	"	GalionMunicipalAirport	"
"	GRB	"	=	"	AustinStraubelIntl	"
"	GRF	"	=	"	GrayAaf	"
"	GRI	"	=	"	CentralNebraskaRegionalAirport	"
"	GRK	"	=	"	RobertGrayAaf	"
"	GRM	"	=	"	GrandMaraisCookCountyAirport	"
"	GRR	"	=	"	GeraldRFordIntl	"
"	GSB	"	=	"	SeymourJohnsonAfb	"
"	GSO	"	=	"	PiedmontTriad	"
"	GSP	"	=	"	Greenville-SpartanburgInternational	"
"	GST	"	=	"	GustavusAirport	"
"	GTB	"	=	"	WheelerSackAaf	"
"	GTF	"	=	"	GreatFallsIntl	"
"	GTR	"	=	"	GoldenTriangleRegionalAirport	"
"	GTU	"	=	"	GeorgetownMunicipalAirport	"
"	GUC	"	=	"	Gunnison-CrestedButte	"
"	GUP	"	=	"	GallupMuni	"
"	GUS	"	=	"	GrissomArb	"
"	GVL	"	=	"	LeeGilmerMemorialAirport	"
"	GVQ	"	=	"	GeneseeCountyAirport	"
"	GVT	"	=	"	Majors	"
"	GWO	"	=	"	GreenwoodLeflore	"
"	GYY	"	=	"	GaryChicagoInternationalAirport	"
"	HBG	"	=	"	HattiesburgBobbyL.ChainMunicipalAirport	"
"	HBR	"	=	"	HobartMuni	"
"	HCC	"	=	"	ColumbiaCounty	"
"	HCR	"	=	"	HolyCrossAirport	"
"	HDH	"	=	"	Dillingham	"
"	HDI	"	=	"	HardwickFieldAirport	"
"	HDN	"	=	"	YampaValley	"
"	HDO	"	=	"	HondoMunicipalAirport	"
"	HFD	"	=	"	HartfordBrainard	"
"	HGR	"	=	"	HagerstownRegionalRichardAHensonField	"
"	HHH	"	=	"	HiltonHead	"
"	HHI	"	=	"	WheelerAaf	"
"	HHR	"	=	"	JackNorthropFldHawthorneMuni	"
"	HIB	"	=	"	ChisholmHibbing	"
"	HIF	"	=	"	HillAfb	"
"	HII	"	=	"	LakeHavasuCityAirport	"
"	HIO	"	=	"	PortlandHillsboro	"
"	HKB	"	=	"	HealyRiverAirport	"
"	HKY	"	=	"	HickoryRgnl	"
"	HLG	"	=	"	WheelingOhioCountyAirport	"
"	HLN	"	=	"	HelenaRgnl	"
"	HLR	"	=	"	HoodAaf	"
"	HMN	"	=	"	HollomanAfb	"
"	HNH	"	=	"	HoonahAirport	"
"	HNL	"	=	"	HonoluluIntl	"
"	HNM	"	=	"	Hana	"
"	HNS	"	=	"	HainesAirport	"
"	HOB	"	=	"	LeaCoRgnl	"
"	HOM	"	=	"	Homer	"
"	HON	"	=	"	HuronRgnl	"
"	HOP	"	=	"	CampbellAaf	"
"	HOT	"	=	"	MemorialField	"
"	HOU	"	=	"	WilliamPHobby	"
"	HPB	"	=	"	HooperBayAirport	"
"	HPN	"	=	"	WestchesterCo	"
"	HQM	"	=	"	BowermanField	"
"	HQU	"	=	"	McDuffieCountyAirport	"
"	HRL	"	=	"	ValleyIntl	"
"	HRO	"	=	"	BooneCo	"
"	HRT	"	=	"	HurlburtFld	"
"	HSH	"	=	"	HendersonExecutiveAirport	"
"	HSL	"	=	"	HusliaAirport	"
"	HST	"	=	"	HomesteadArb	"
"	HSV	"	=	"	HuntsvilleInternationalAirport-CarlTJonesField	"
"	HTL	"	=	"	RoscommonCo	"
"	HTS	"	=	"	TriStateMiltonJFergusonField	"
"	HUA	"	=	"	RedstoneAaf	"
"	HUF	"	=	"	TerreHauteIntlHulmanFld	"
"	HUL	"	=	"	HoultonIntl	"
"	HUS	"	=	"	HughesAirport	"
"	HUT	"	=	"	HutchinsonMunicipalAirport	"
"	HVN	"	=	"	Tweed-NewHavenAirport	"
"	HVR	"	=	"	HavreCityCo	"
"	HWD	"	=	"	HaywardExecutiveAirport	"
"	HWO	"	=	"	NorthPerry	"
"	HXD	"	=	"	HiltonHeadAirport	"
"	HYA	"	=	"	BarnstableMuniBoardmanPolandoFld	"
"	HYG	"	=	"	HydaburgSeaplaneBase	"
"	HYL	"	=	"	HollisSeaplaneBase	"
"	HYS	"	=	"	HaysRegionalAirport	"
"	HZL	"	=	"	HazletonMunicipal	"
"	IAB	"	=	"	McConnellAfb	"
"	IAD	"	=	"	WashingtonDullesIntl	"
"	IAG	"	=	"	NiagaraFallsIntl	"
"	IAH	"	=	"	GeorgeBushIntercontinental	"
"	IAN	"	=	"	BobBakerMemorialAirport	"
"	ICT	"	=	"	WichitaMidContinent	"
"	ICY	"	=	"	IcyBayAirport	"
"	IDA	"	=	"	IdahoFallsRgnl	"
"	IDL	"	=	"	IdlewildIntl	"
"	IFP	"	=	"	Laughlin-BullheadIntl	"
"	IGG	"	=	"	IgiugigAirport	"
"	IGM	"	=	"	KingmanAirport	"
"	IGQ	"	=	"	LansingMunicipal	"
"	IJD	"	=	"	WindhamAirport	"
"	IKK	"	=	"	GreaterKankakee	"
"	IKO	"	=	"	NikolskiAirStation	"
"	IKR	"	=	"	KirtlandAirForceBase	"
"	IKV	"	=	"	AnkenyReglAirport	"
"	ILG	"	=	"	NewCastle	"
"	ILI	"	=	"	Iliamna	"
"	ILM	"	=	"	WilmingtonIntl	"
"	ILN	"	=	"	WilmingtonAirborneAirpark	"
"	IMM	"	=	"	Immokalee	"
"	IMT	"	=	"	FordAirport	"
"	IND	"	=	"	IndianapolisIntl	"
"	INJ	"	=	"	HillsboroMuni	"
"	INK	"	=	"	WinklerCo	"
"	INL	"	=	"	FallsIntl	"
"	INS	"	=	"	CreechAfb	"
"	INT	"	=	"	SmithReynolds	"
"	INW	"	=	"	Winslow-LindberghRegionalAirport	"
"	IOW	"	=	"	IowaCityMunicipalAirport	"
"	IPL	"	=	"	ImperialCo	"
"	IPT	"	=	"	WilliamsportRgnl	"
"	IRC	"	=	"	CircleCityAirport	"
"	IRK	"	=	"	KirksvilleRegionalAirport	"
"	ISM	"	=	"	KissimmeeGatewayAirport	"
"	ISN	"	=	"	SloulinFldIntl	"
"	ISO	"	=	"	KinstonRegionalJetport	"
"	ISP	"	=	"	LongIslandMacArthur	"
"	ISW	"	=	"	AlexanderFieldSouthWoodCountyAirport	"
"	ITH	"	=	"	IthacaTompkinsRgnl	"
"	ITO	"	=	"	HiloIntl	"
"	IWD	"	=	"	GogebicIronCountyAirport	"
"	IWS	"	=	"	WestHouston	"
"	IYK	"	=	"	InyokernAirport	"
"	JAC	"	=	"	JacksonHoleAirport	"
"	JAN	"	=	"	JacksonEversIntl	"
"	JAX	"	=	"	JacksonvilleIntl	"
"	JBR	"	=	"	JonesboroMuni	"
"	JCI	"	=	"	NewCenturyAirCenterAirport	"
"	JEF	"	=	"	JeffersonCityMemorialAirport	"
"	JES	"	=	"	Jesup-WayneCountyAirport	"
"	JFK	"	=	"	JohnFKennedyIntl	"
"	JGC	"	=	"	GrandCanyonHeliport	"
"	JHM	"	=	"	Kapalua	"
"	JHW	"	=	"	ChautauquaCounty-Jamestown	"
"	JKA	"	=	"	JackEdwardsAirport	"
"	JLN	"	=	"	JoplinRgnl	"
"	JMS	"	=	"	JamestownRegionalAirport	"
"	JNU	"	=	"	JuneauIntl	"
"	JOT	"	=	"	RegionalAirport	"
"	JRA	"	=	"	West30thSt.Heliport	"
"	JRB	"	=	"	WallStreetHeliport	"
"	JST	"	=	"	JohnMurthaJohnstown-CambriaCountyAirport	"
"	JVL	"	=	"	SouthernWisconsinRegionalAirport	"
"	JXN	"	=	"	ReynoldsField	"
"	JYL	"	=	"	PlantationAirpark	"
"	JYO	"	=	"	LeesburgExecutiveAirport	"
"	JZP	"	=	"	PickensCountyAirport	"
"	K03	"	=	"	WainwrightAs	"
"	KAE	"	=	"	KakeSeaplaneBase	"
"	KAL	"	=	"	KaltagAirport	"
"	KBC	"	=	"	BirchCreekAirport	"
"	KBW	"	=	"	ChignikBaySeaplaneBase	"
"	KCC	"	=	"	CoffmanCoveSeaplaneBase	"
"	KCL	"	=	"	ChignikLagoonAirport	"
"	KCQ	"	=	"	ChignikLakeAirport	"
"	KEH	"	=	"	KenmoreAirHarborIncSeaplaneBase	"
"	KEK	"	=	"	EkwokAirport	"
"	KFP	"	=	"	FalsePassAirport	"
"	KGK	"	=	"	KoliganekAirport	"
"	KGX	"	=	"	GraylingAirport	"
"	KKA	"	=	"	KoyukAlfredAdamsAirport	"
"	KKB	"	=	"	KitoiBaySeaplaneBase	"
"	KKH	"	=	"	KongiganakAirport	"
"	KLG	"	=	"	KalskagAirport	"
"	KLL	"	=	"	LevelockAirport	"
"	KLN	"	=	"	LarsenBayAirport	"
"	KLS	"	=	"	KelsoLongview	"
"	KLW	"	=	"	KlawockAirport	"
"	KMO	"	=	"	ManokotakAirport	"
"	KMY	"	=	"	MoserBaySeaplaneBase	"
"	KNW	"	=	"	NewStuyahokAirport	"
"	KOA	"	=	"	KonaIntlAtKeahole	"
"	KOT	"	=	"	KotlikAirport	"
"	KOY	"	=	"	OlgaBaySeaplaneBase	"
"	KOZ	"	=	"	OuzinkieAirport	"
"	KPB	"	=	"	PointBakerSeaplaneBase	"
"	KPC	"	=	"	PortClarenceCoastGuardStation	"
"	KPN	"	=	"	KipnukAirport	"
"	KPR	"	=	"	PortWilliamsSeaplaneBase	"
"	KPV	"	=	"	PerryvilleAirport	"
"	KPY	"	=	"	PortBaileySeaplaneBase	"
"	KQA	"	=	"	AkutanSeaplaneBase	"
"	KSM	"	=	"	StMarysAirport	"
"	KTB	"	=	"	ThorneBaySeaplaneBase	"
"	KTN	"	=	"	KetchikanIntl	"
"	KTS	"	=	"	BrevigMissionAirport	"
"	KUK	"	=	"	KasiglukAirport	"
"	KVC	"	=	"	KingCoveAirport	"
"	KVL	"	=	"	KivalinaAirport	"
"	KWK	"	=	"	KwigillingokAirport	"
"	KWN	"	=	"	QuinhagakAirport	"
"	KWP	"	=	"	WestPointVillageSeaplaneBase	"
"	KWT	"	=	"	KwethlukAirport	"
"	KYK	"	=	"	KarulukAirport	"
"	KYU	"	=	"	KoyukukAirport	"
"	KZB	"	=	"	ZacharBaySeaplaneBase	"
"	L06	"	=	"	FurnaceCreek	"
"	L35	"	=	"	BigBearCity	"
"	LAA	"	=	"	LamarMuni	"
"	LAF	"	=	"	PurudeUniversityAirport	"
"	LAL	"	=	"	LakelandLinderRegionalAirport	"
"	LAM	"	=	"	LosAlamosAirport	"
"	LAN	"	=	"	CapitalCity	"
"	LAR	"	=	"	LaramieRegionalAirport	"
"	LAS	"	=	"	McCarranIntl	"
"	LAW	"	=	"	Lawton-FortSillRegionalAirport	"
"	LAX	"	=	"	LosAngelesIntl	"
"	LBB	"	=	"	LubbockPrestonSmithIntl	"
"	LBE	"	=	"	ArnoldPalmerRegionalAirport	"
"	LBF	"	=	"	NorthPlatteRegionalAirportLeeBirdField	"
"	LBL	"	=	"	LiberalMuni	"
"	LBT	"	=	"	MunicipalAirport	"
"	LCH	"	=	"	LakeCharlesRgnl	"
"	LCK	"	=	"	RickenbackerIntl	"
"	LCQ	"	=	"	LakeCityMunicipalAirport	"
"	LDJ	"	=	"	LindenAirport	"
"	LEB	"	=	"	LebanonMunicipalAirport	"
"	LEW	"	=	"	LewistonMaine	"
"	LEX	"	=	"	BlueGrass	"
"	LFI	"	=	"	LangleyAfb	"
"	LFK	"	=	"	AngelinaCo	"
"	LFT	"	=	"	LafayetteRgnl	"
"	LGA	"	=	"	LaGuardia	"
"	LGB	"	=	"	LongBeach	"
"	LGC	"	=	"	LaGrange-CallawayAirport	"
"	LGU	"	=	"	Logan-Cache	"
"	LHD	"	=	"	LakeHoodSeaplaneBase	"
"	LHV	"	=	"	WilliamT.PiperMem.	"
"	LHX	"	=	"	LaJuntaMuni	"
"	LIH	"	=	"	Lihue	"
"	LIT	"	=	"	AdamsFld	"
"	LIV	"	=	"	LivingoodAirport	"
"	LKE	"	=	"	KenmoreAirHarborSeaplaneBase	"
"	LKP	"	=	"	LakePlacidAirport	"
"	LMT	"	=	"	KlamathFallsAirport	"
"	LNA	"	=	"	PalmBeachCoPark	"
"	LNK	"	=	"	Lincoln	"
"	LNN	"	=	"	LostNationMunicipalAirport	"
"	LNR	"	=	"	Tri-CountyRegionalAirport	"
"	LNS	"	=	"	LancasterAirport	"
"	LNY	"	=	"	Lanai	"
"	LOT	"	=	"	LewisUniversityAirport	"
"	LOU	"	=	"	BowmanFld	"
"	LOZ	"	=	"	London-CorbinAirport-MaGeeField	"
"	LPC	"	=	"	LompocAirport	"
"	LPR	"	=	"	LorainCountyRegionalAirport	"
"	LPS	"	=	"	LopezIslandAirport	"
"	LRD	"	=	"	LaredoIntl	"
"	LRF	"	=	"	LittleRockAfb	"
"	LRU	"	=	"	LasCrucesIntl	"
"	LSE	"	=	"	LaCrosseMunicipal	"
"	LSF	"	=	"	LawsonAaf	"
"	LSV	"	=	"	NellisAfb	"
"	LTS	"	=	"	AltusAfb	"
"	LUF	"	=	"	LukeAfb	"
"	LUK	"	=	"	CincinnatiMuniLunkenFld	"
"	LUP	"	=	"	KalaupapaAirport	"
"	LUR	"	=	"	CapeLisburneLrrs	"
"	LVK	"	=	"	LivermoreMunicipal	"
"	LVM	"	=	"	MissionFieldAirport	"
"	LVS	"	=	"	LasVegasMuni	"
"	LWA	"	=	"	SouthHavenAreaRegionalAirport	"
"	LWB	"	=	"	GreenbrierValleyAirport	"
"	LWC	"	=	"	LawrenceMunicipal	"
"	LWM	"	=	"	LawrenceMunicipalAirport	"
"	LWS	"	=	"	LewistonNezPerceCo	"
"	LWT	"	=	"	LewistownMunicipalAirport	"
"	LXY	"	=	"	Mexia-LimestoneCountyAirport	"
"	LYH	"	=	"	LynchburgRegionalPrestonGlennField	"
"	LYU	"	=	"	ElyMunicipal	"
"	LZU	"	=	"	GwinnettCountyAirport-BriscoeField	"
"	MAE	"	=	"	MaderaMunicipalAirport	"
"	MAF	"	=	"	MidlandIntl	"
"	MBL	"	=	"	ManisteeCounty-BlackerAirport	"
"	MBS	"	=	"	MbsIntl	"
"	MCC	"	=	"	McClellanAfld	"
"	MCD	"	=	"	MackinacIslandAirport	"
"	MCE	"	=	"	MercedMunicipalAirport	"
"	MCF	"	=	"	MacdillAfb	"
"	MCG	"	=	"	McGrathAirport	"
"	MCI	"	=	"	KansasCityIntl	"
"	MCK	"	=	"	McCookRegionalAirport	"
"	MCL	"	=	"	McKinleyNationalParkAirport	"
"	MCN	"	=	"	MiddleGeorgiaRgnl	"
"	MCO	"	=	"	OrlandoIntl	"
"	MCW	"	=	"	MasonCityMunicipal	"
"	MDT	"	=	"	HarrisburgIntl	"
"	MDW	"	=	"	ChicagoMidwayIntl	"
"	ME5	"	=	"	BanksAirport	"
"	MEI	"	=	"	KeyField	"
"	MEM	"	=	"	MemphisIntl	"
"	MER	"	=	"	Castle	"
"	MFD	"	=	"	MansfieldLahmRegional	"
"	MFE	"	=	"	McAllenMillerIntl	"
"	MFI	"	=	"	MarshfieldMunicipalAirport	"
"	MFR	"	=	"	RogueValleyIntlMedford	"
"	MGC	"	=	"	MichiganCityMunicipalAirport	"
"	MGE	"	=	"	DobbinsArb	"
"	MGJ	"	=	"	OrangeCountyAirport	"
"	MGM	"	=	"	MontgomeryRegionalAirport	"
"	MGR	"	=	"	MoultrieMunicipalAirport	"
"	MGW	"	=	"	MorgantownMuniWalterLBillHartFld	"
"	MGY	"	=	"	Dayton-WrightBrothersAirport	"
"	MHK	"	=	"	ManhattanReigonal	"
"	MHM	"	=	"	MinchuminaAirport	"
"	MHR	"	=	"	SacramentoMather	"
"	MHT	"	=	"	ManchesterRegionalAirport	"
"	MHV	"	=	"	Mojave	"
"	MIA	"	=	"	MiamiIntl	"
"	MIB	"	=	"	MinotAfb	"
"	MIE	"	=	"	DelawareCountyAirport	"
"	MIV	"	=	"	MillvilleMuni	"
"	MKC	"	=	"	Downtown	"
"	MKE	"	=	"	GeneralMitchellIntl	"
"	MKG	"	=	"	MuskegonCountyAirport	"
"	MKK	"	=	"	Molokai	"
"	MKL	"	=	"	McKellarSipesRgnl	"
"	MKO	"	=	"	DavisFld	"
"	MLB	"	=	"	MelbourneIntl	"
"	MLC	"	=	"	McAlesterRgnl	"
"	MLD	"	=	"	MaladCity	"
"	MLI	"	=	"	QuadCityIntl	"
"	MLJ	"	=	"	BaldwinCountyAirport	"
"	MLL	"	=	"	MarshallDonHunterSr.Airport	"
"	MLS	"	=	"	FrankWileyField	"
"	MLT	"	=	"	MillinocketMuni	"
"	MLU	"	=	"	MonroeRgnl	"
"	MLY	"	=	"	ManleyHotSpringsAirport	"
"	MMH	"	=	"	MammothYosemiteAirport	"
"	MMI	"	=	"	McMinnCo	"
"	MMU	"	=	"	MorristownMunicipalAirport	"
"	MMV	"	=	"	McMinnvilleMuni	"
"	MNM	"	=	"	MenomineeMarinetteTwinCo	"
"	MNT	"	=	"	MintoAirport	"
"	MOB	"	=	"	MobileRgnl	"
"	MOD	"	=	"	ModestoCityCoHarrySham	"
"	MOT	"	=	"	MinotIntl	"
"	MOU	"	=	"	MountainVillageAirport	"
"	MPB	"	=	"	MiamiSeaplaneBase	"
"	MPI	"	=	"	MariposaYosemite	"
"	MPV	"	=	"	EdwardFKnappState	"
"	MQB	"	=	"	MacombMunicipalAirport	"
"	MQT	"	=	"	SawyerInternationalAirport	"
"	MRB	"	=	"	EasternWVRegionalAirport	"
"	MRI	"	=	"	MerrillFld	"
"	MRK	"	=	"	MarcoIslands	"
"	MRN	"	=	"	FoothillsRegionalAirport	"
"	MRY	"	=	"	MontereyPeninsula	"
"	MSL	"	=	"	NorthwestAlabamaRegionalAirport	"
"	MSN	"	=	"	DaneCoRgnlTruaxFld	"
"	MSO	"	=	"	MissoulaIntl	"
"	MSP	"	=	"	MinneapolisStPaulIntl	"
"	MSS	"	=	"	MassenaIntlRichardsFld	"
"	MSY	"	=	"	LouisArmstrongNewOrleansIntl	"
"	MTC	"	=	"	SelfridgeAngb	"
"	MTH	"	=	"	FloridaKeysMarathonAirport	"
"	MTJ	"	=	"	MontroseRegionalAirport	"
"	MTM	"	=	"	MetlakatlaSeaplaneBase	"
"	MUE	"	=	"	WaimeaKohala	"
"	MUI	"	=	"	MuirAaf	"
"	MUO	"	=	"	MountainHomeAfb	"
"	MVL	"	=	"	MorrisvilleStoweStateAirport	"
"	MVY	"	=	"	Martha\\'sVineyard	"
"	MWA	"	=	"	WilliamsonCountryRegionalAirport	"
"	MWC	"	=	"	LawrenceJTimmermanAirport	"
"	MWH	"	=	"	GrantCoIntl	"
"	MWL	"	=	"	MineralWells	"
"	MWM	"	=	"	WindomMunicipalAirport	"
"	MXF	"	=	"	MaxwellAfb	"
"	MXY	"	=	"	McCarthyAirport	"
"	MYF	"	=	"	MontgomeryField	"
"	MYL	"	=	"	McCallMunicipalAirport	"
"	MYR	"	=	"	MyrtleBeachIntl	"
"	MYU	"	=	"	MekoryukAirport	"
"	MYV	"	=	"	YubaCountyAirport	"
"	MZJ	"	=	"	PinalAirpark	"
"	N53	"	=	"	Stroudsburg-PoconoAirport	"
"	N69	"	=	"	StormvilleAirport	"
"	N87	"	=	"	Trenton-RobbinsvilleAirport	"
"	NBG	"	=	"	NewOrleansNasJrb	"
"	NBU	"	=	"	NavalAirStation	"
"	NCN	"	=	"	ChenegaBayAirport	"
"	NEL	"	=	"	LakehurstNaes	"
"	NFL	"	=	"	FallonNas	"
"	NGF	"	=	"	KaneoheBayMcaf	"
"	NGP	"	=	"	CorpusChristiNAS	"
"	NGU	"	=	"	NorfolkNs	"
"	NGZ	"	=	"	NASAlameda	"
"	NHK	"	=	"	PatuxentRiverNas	"
"	NIB	"	=	"	NikolaiAirport	"
"	NID	"	=	"	ChinaLakeNaws	"
"	NIP	"	=	"	JacksonvilleNas	"
"	NJK	"	=	"	ElCentroNaf	"
"	NKT	"	=	"	CherryPointMcas	"
"	NKX	"	=	"	MiramarMcas	"
"	NLC	"	=	"	LemooreNas	"
"	NLG	"	=	"	NelsonLagoon	"
"	NME	"	=	"	NightmuteAirport	"
"	NMM	"	=	"	MeridianNas	"
"	NNL	"	=	"	NondaltonAirport	"
"	NOW	"	=	"	PortAngelesCgas	"
"	NPA	"	=	"	PensacolaNas	"
"	NPZ	"	=	"	PorterCountyMunicipalAirport	"
"	NQA	"	=	"	MillingtonRgnlJetport	"
"	NQI	"	=	"	KingsvilleNas	"
"	NQX	"	=	"	KeyWestNas	"
"	NSE	"	=	"	WhitingFldNasNorth	"
"	NTD	"	=	"	PointMuguNas	"
"	NTU	"	=	"	OceanaNas	"
"	NUI	"	=	"	NuiqsutAirport	"
"	NUL	"	=	"	NulatoAirport	"
"	NUP	"	=	"	NunapitchukAirport	"
"	NUQ	"	=	"	MoffettFederalAfld	"
"	NUW	"	=	"	WhidbeyIslandNas	"
"	NXP	"	=	"	TwentyninePalmsEaf	"
"	NXX	"	=	"	WillowGroveNasJrb	"
"	NY9	"	=	"	LongLake	"
"	NYC	"	=	"	AllAirports	"
"	NYG	"	=	"	QuanticoMcaf	"
"	NZC	"	=	"	CecilField	"
"	NZJ	"	=	"	ElToro	"
"	NZY	"	=	"	NorthIslandNas	"
"	O03	"	=	"	MorgantownAirport	"
"	O27	"	=	"	OakdaleAirport	"
"	OAJ	"	=	"	AlbertJEllis	"
"	OAK	"	=	"	MetropolitanOaklandIntl	"
"	OAR	"	=	"	MarinaMuni	"
"	OBE	"	=	"	County	"
"	OBU	"	=	"	KobukAirport	"
"	OCA	"	=	"	KeyLargo	"
"	OCF	"	=	"	InternationalAirport	"
"	OEB	"	=	"	BranchCountyMemorialAirport	"
"	OFF	"	=	"	OffuttAfb	"
"	OGG	"	=	"	Kahului	"
"	OGS	"	=	"	OgdensburgIntl	"
"	OKC	"	=	"	WillRogersWorld	"
"	OLF	"	=	"	LMClaytonAirport	"
"	OLH	"	=	"	OldHarborAirport	"
"	OLM	"	=	"	OlympiaRegionalAirpor	"
"	OLS	"	=	"	NogalesIntl	"
"	OLV	"	=	"	OliveBranchMuni	"
"	OMA	"	=	"	EppleyAfld	"
"	OME	"	=	"	Nome	"
"	OMN	"	=	"	OrmondBeachmunicipalAirport	"
"	ONH	"	=	"	OneontaMunicipalAirport	"
"	ONP	"	=	"	NewportMunicipalAirport	"
"	ONT	"	=	"	OntarioIntl	"
"	OOK	"	=	"	ToksookBayAirport	"
"	OPF	"	=	"	OpaLocka	"
"	OQU	"	=	"	QuonsetStateAirport	"
"	ORD	"	=	"	ChicagoOhareIntl	"
"	ORF	"	=	"	NorfolkIntl	"
"	ORH	"	=	"	WorcesterRegionalAirport	"
"	ORI	"	=	"	PortLionsAirport	"
"	ORL	"	=	"	Executive	"
"	ORT	"	=	"	Northway	"
"	ORV	"	=	"	RobertCurtisMemorialAirport	"
"	OSC	"	=	"	OscodaWurtsmith	"
"	OSH	"	=	"	WittmanRegionalAirport	"
"	OSU	"	=	"	OhioStateUniversityAirport	"
"	OTH	"	=	"	SouthwestOregonRegionalAirport	"
"	OTS	"	=	"	AnacortesAirport	"
"	OTZ	"	=	"	RalphWienMem	"
"	OWB	"	=	"	OwensboroDaviessCountyAirport	"
"	OWD	"	=	"	NorwoodMemorialAirport	"
"	OXC	"	=	"	Waterbury-OxfordAirport	"
"	OXD	"	=	"	MiamiUniversityAirport	"
"	OXR	"	=	"	Oxnard-VenturaCounty	"
"	OZA	"	=	"	OzonaMuni	"
"	P08	"	=	"	CoolidgeMunicipalAirport	"
"	P52	"	=	"	CottonwoodAirport	"
"	PAE	"	=	"	SnohomishCo	"
"	PAH	"	=	"	BarkleyRegionalAirport	"
"	PAM	"	=	"	TyndallAfb	"
"	PAO	"	=	"	PaloAltoAirportofSantaClaraCounty	"
"	PAQ	"	=	"	PalmerMuni	"
"	PBF	"	=	"	GriderFld	"
"	PBG	"	=	"	PlattsburghIntl	"
"	PBI	"	=	"	PalmBeachIntl	"
"	PBV	"	=	"	StGeorge	"
"	PBX	"	=	"	PikeCountyAirport-HatcherField	"
"	PCW	"	=	"	Erie-OttawaRegionalAirport	"
"	PCZ	"	=	"	WaupacaMunicipalAirport	"
"	PDB	"	=	"	PedroBayAirport	"
"	PDK	"	=	"	Dekalb-PeachtreeAirport	"
"	PDT	"	=	"	EasternOregonRegionalAirport	"
"	PDX	"	=	"	PortlandIntl	"
"	PEC	"	=	"	PelicanSeaplaneBase	"
"	PEQ	"	=	"	PecosMunicipalAirport	"
"	PFN	"	=	"	PanamaCityBayCoIntl	"
"	PGA	"	=	"	PageMunicipalAirport	"
"	PGD	"	=	"	CharlotteCounty-PuntaGordaAirport	"
"	PGV	"	=	"	Pitt-GreenvilleAirport	"
"	PHD	"	=	"	HarryCleverFieldAirport	"
"	PHF	"	=	"	NewportNewsWilliamsburgIntl	"
"	PHK	"	=	"	PahokeeAirport	"
"	PHL	"	=	"	PhiladelphiaIntl	"
"	PHN	"	=	"	StClairCoIntl	"
"	PHO	"	=	"	PointHopeAirport	"
"	PHX	"	=	"	PhoenixSkyHarborIntl	"
"	PIA	"	=	"	PeoriaRegional	"
"	PIB	"	=	"	HattiesburgLaurelRegionalAirport	"
"	PIE	"	=	"	StPetersburgClearwaterIntl	"
"	PIH	"	=	"	PocatelloRegionalAirport	"
"	PIM	"	=	"	HarrisCountyAirport	"
"	PIP	"	=	"	PilotPointAirport	"
"	PIR	"	=	"	PierreRegionalAirport	"
"	PIT	"	=	"	PittsburghIntl	"
"	PIZ	"	=	"	PointLayLrrs	"
"	PKB	"	=	"	Mid-OhioValleyRegionalAirport	"
"	PLN	"	=	"	PellstonRegionalAirportofEmmetCountyAirport	"
"	PMB	"	=	"	PembinaMuni	"
"	PMD	"	=	"	PalmdaleRgnlUsafPlt42	"
"	PML	"	=	"	PortMollerAirport	"
"	PMP	"	=	"	PompanoBeachAirpark	"
"	PNC	"	=	"	PoncaCityRgnl	"
"	PNE	"	=	"	NortheastPhiladelphia	"
"	PNM	"	=	"	PrincetonMuni	"
"	PNS	"	=	"	PensacolaRgnl	"
"	POB	"	=	"	PopeField	"
"	POC	"	=	"	BrackettField	"
"	POE	"	=	"	PolkAaf	"
"	POF	"	=	"	PoplarBluffMunicipalAirport	"
"	PPC	"	=	"	ProspectCreekAirport	"
"	PPV	"	=	"	PortProtectionSeaplaneBase	"
"	PQI	"	=	"	NorthernMaineRgnlAtPresqueIsle	"
"	PQS	"	=	"	PilotStationAirport	"
"	PRC	"	=	"	ErnestALoveFld	"
"	PSC	"	=	"	TriCitiesAirport	"
"	PSG	"	=	"	PetersburgJamesA.Johnson	"
"	PSM	"	=	"	PeaseInternationalTradeport	"
"	PSP	"	=	"	PalmSpringsIntl	"
"	PSX	"	=	"	PalaciosMuni	"
"	PTB	"	=	"	DinwiddieCountyAirport	"
"	PTH	"	=	"	PortHeidenAirport	"
"	PTK	"	=	"	OaklandCo.Intl	"
"	PTU	"	=	"	Platinum	"
"	PUB	"	=	"	PuebloMemorial	"
"	PUC	"	=	"	CarbonCountyRegional-BuckDavisField	"
"	PUW	"	=	"	Pullman-MoscowRgnl	"
"	PVC	"	=	"	ProvincetownMuni	"
"	PVD	"	=	"	TheodoreFrancisGreenState	"
"	PVU	"	=	"	ProvoMunicipalAirport	"
"	PWK	"	=	"	ChicagoExecutive	"
"	PWM	"	=	"	PortlandIntlJetport	"
"	PWT	"	=	"	BremertonNational	"
"	PYM	"	=	"	PlymouthMunicipalAirport	"
"	PYP	"	=	"	Centre-Piedmont-CherokeeCountyRegionalAirport	"
"	R49	"	=	"	FerryCountyAirport	"
"	RAC	"	=	"	JohnH.BattenAirport	"
"	RAL	"	=	"	RiversideMuni	"
"	RAP	"	=	"	RapidCityRegionalAirport	"
"	RBD	"	=	"	DallasExecutiveAirport	"
"	RBK	"	=	"	FrenchValleyAirport	"
"	RBM	"	=	"	RobinsonAaf	"
"	RBN	"	=	"	FortJefferson	"
"	RBY	"	=	"	RubyAirport	"
"	RCA	"	=	"	EllsworthAfb	"
"	RCE	"	=	"	RocheHarborSeaplaneBase	"
"	RCZ	"	=	"	RichmondCountyAirport	"
"	RDD	"	=	"	ReddingMuni	"
"	RDG	"	=	"	ReadingRegionalCarlASpaatzField	"
"	RDM	"	=	"	RobertsFld	"
"	RDR	"	=	"	GrandForksAfb	"
"	RDU	"	=	"	RaleighDurhamIntl	"
"	RDV	"	=	"	RedDevilAirport	"
"	REI	"	=	"	RedlandsMunicipalAirport	"
"	RFD	"	=	"	ChicagoRockfordInternationalAirport	"
"	RHI	"	=	"	RhinelanderOneidaCountyAirport	"
"	RIC	"	=	"	RichmondIntl	"
"	RID	"	=	"	RichmondMunicipalAirport	"
"	RIF	"	=	"	RichfieldMinicipalAirport	"
"	RIL	"	=	"	GarfieldCountyRegionalAirport	"
"	RIR	"	=	"	FlabobAirport	"
"	RIU	"	=	"	RanchoMurieta	"
"	RIV	"	=	"	MarchArb	"
"	RIW	"	=	"	RivertonRegional	"
"	RKD	"	=	"	KnoxCountyRegionalAirport	"
"	RKH	"	=	"	RockHillYorkCoBryantAirport	"
"	RKP	"	=	"	AransasCountyAirport	"
"	RKS	"	=	"	RockSpringsSweetwaterCountyAirport	"
"	RME	"	=	"	GriffissAfld	"
"	RMG	"	=	"	RichardBRussellAirport	"
"	RMP	"	=	"	RampartAirport	"
"	RMY	"	=	"	BrooksFieldAirport	"
"	RND	"	=	"	RandolphAfb	"
"	RNM	"	=	"	RamonaAirport	"
"	RNO	"	=	"	RenoTahoeIntl	"
"	RNT	"	=	"	Renton	"
"	ROA	"	=	"	RoanokeRegional	"
"	ROC	"	=	"	GreaterRochesterIntl	"
"	ROW	"	=	"	RoswellIntlAirCenter	"
"	RSH	"	=	"	RussianMissionAirport	"
"	RSJ	"	=	"	RosarioSeaplaneBase	"
"	RST	"	=	"	Rochester	"
"	RSW	"	=	"	SouthwestFloridaIntl	"
"	RUT	"	=	"	RutlandStateAirport	"
"	RVS	"	=	"	RichardLloydJonesJrAirport	"
"	RWI	"	=	"	RockyMountWilsonRegionalAirport	"
"	RWL	"	=	"	RawlinsMunicipalAirport-HarveyField	"
"	RYY	"	=	"	CobbCountyAirport-McCollumField	"
"	S46	"	=	"	PortO\\'ConnorAirfield	"
"	SAA	"	=	"	ShivelyFieldAirport	"
"	SAC	"	=	"	SacramentoExecutive	"
"	SAD	"	=	"	SaffordRegionalAirport	"
"	SAF	"	=	"	SantaFeMuni	"
"	SAN	"	=	"	SanDiegoIntl	"
"	SAT	"	=	"	SanAntonioIntl	"
"	SAV	"	=	"	SavannahHiltonHeadIntl	"
"	SBA	"	=	"	SantaBarbaraMuni	"
"	SBD	"	=	"	SanBernardinoInternationalAirport	"
"	SBM	"	=	"	SheboyganCountyMemorialAirport	"
"	SBN	"	=	"	SouthBendRgnl	"
"	SBO	"	=	"	EmanuelCo	"
"	SBP	"	=	"	SanLuisCountyRegionalAirport	"
"	SBS	"	=	"	SteamboatSpringsAirport-BobAdamsField	"
"	SBY	"	=	"	SalisburyOceanCityWicomicoRgnl	"
"	SCC	"	=	"	Deadhorse	"
"	SCE	"	=	"	UniversityParkAirport	"
"	SCH	"	=	"	StrattonANGB-SchenectadyCountyAirpor	"
"	SCK	"	=	"	StocktonMetropolitan	"
"	SCM	"	=	"	ScammonBayAirport	"
"	SDC	"	=	"	Williamson-SodusAirport	"
"	SDF	"	=	"	LouisvilleInternationalAirport	"
"	SDM	"	=	"	BrownFieldMunicipalAirport	"
"	SDP	"	=	"	SandPointAirport	"
"	SDX	"	=	"	Sedona	"
"	SDY	"	=	"	Sidney-RichlandMunicipalAirport	"
"	SEA	"	=	"	SeattleTacomaIntl	"
"	SEE	"	=	"	Gillespie	"
"	SEF	"	=	"	Regional-HendricksAAF	"
"	SEM	"	=	"	CraigFld	"
"	SES	"	=	"	SelfieldAirport	"
"	SFB	"	=	"	OrlandoSanfordIntl	"
"	SFF	"	=	"	FeltsFld	"
"	SFM	"	=	"	SanfordRegional	"
"	SFO	"	=	"	SanFranciscoIntl	"
"	SFZ	"	=	"	NorthCentralState	"
"	SGF	"	=	"	SpringfieldBransonNatl	"
"	SGH	"	=	"	Springfield-BecklyMunicipalAirport	"
"	SGJ	"	=	"	St.AugustineAirport	"
"	SGR	"	=	"	SugarLandRegionalAirport	"
"	SGU	"	=	"	StGeorgeMuni	"
"	SGY	"	=	"	SkagwayAirport	"
"	SHD	"	=	"	ShenandoahValleyRegionalAirport	"
"	SHG	"	=	"	ShungnakAirport	"
"	SHH	"	=	"	ShishmarefAirport	"
"	SHR	"	=	"	SheridanCountyAirport	"
"	SHV	"	=	"	ShreveportRgnl	"
"	SHX	"	=	"	ShagelukAirport	"
"	SIK	"	=	"	SikestonMemorialMunicipal	"
"	SIT	"	=	"	SitkaRockyGutierrez	"
"	SJC	"	=	"	NormanYMinetaSanJoseIntl	"
"	SJT	"	=	"	SanAngeloRgnlMathisFld	"
"	SKA	"	=	"	FairchildAfb	"
"	SKF	"	=	"	LacklandAfbKellyFldAnnex	"
"	SKK	"	=	"	ShaktoolikAirport	"
"	SKY	"	=	"	GriffingSandusky	"
"	SLC	"	=	"	SaltLakeCityIntl	"
"	SLE	"	=	"	McNaryField	"
"	SLK	"	=	"	AdirondackRegionalAirport	"
"	SLN	"	=	"	SalinaMunicipalAirport	"
"	SLQ	"	=	"	SleetmuteAirport	"
"	SMD	"	=	"	SmithFld	"
"	SME	"	=	"	LakeCumberlandRegionalAirport	"
"	SMF	"	=	"	SacramentoIntl	"
"	SMK	"	=	"	St.MichaelAirport	"
"	SMN	"	=	"	LemhiCountyAirport	"
"	SMO	"	=	"	SantaMonicaMunicipalAirport	"
"	SMX	"	=	"	SantaMariaPubCptGAllanHancockAirport	"
"	SNA	"	=	"	JohnWayneArptOrangeCo	"
"	SNP	"	=	"	StPaulIsland	"
"	SNY	"	=	"	SidneyMuniAirport	"
"	SOP	"	=	"	MooreCountyAirport	"
"	SOW	"	=	"	ShowLowRegionalAirport	"
"	SPB	"	=	"	ScappooseIndustrialAirpark	"
"	SPF	"	=	"	BlackHillsAirport-ClydeIceField	"
"	SPG	"	=	"	AlbertWhitted	"
"	SPI	"	=	"	AbrahamLincolnCapital	"
"	SPS	"	=	"	SheppardAfbWichitaFallsMuni	"
"	SPW	"	=	"	SpencerMuni	"
"	SPZ	"	=	"	SilverSpringsAirport	"
"	SQL	"	=	"	SanCarlosAirport	"
"	SRQ	"	=	"	SarasotaBradentonIntl	"
"	SRR	"	=	"	SierraBlancaRegionalAirport	"
"	SRV	"	=	"	StonyRiver2Airport	"
"	SSC	"	=	"	ShawAfb	"
"	SSI	"	=	"	McKinnonAirport	"
"	STC	"	=	"	SaintCloudRegionalAirport	"
"	STE	"	=	"	StevensPointMunicipalAirport	"
"	STG	"	=	"	St.GeorgeAirport	"
"	STJ	"	=	"	RosecransMem	"
"	STK	"	=	"	SterlingMunicipalAirport	"
"	STL	"	=	"	LambertStLouisIntl	"
"	STS	"	=	"	CharlesMSchulzSonomaCo	"
"	SUA	"	=	"	WithamFieldAirport	"
"	SUE	"	=	"	DoorCountyCherrylandAirport	"
"	SUN	"	=	"	FriedmanMem	"
"	SUS	"	=	"	SpiritOfStLouis	"
"	SUU	"	=	"	TravisAfb	"
"	SUX	"	=	"	SiouxGatewayColBudDayFld	"
"	SVA	"	=	"	SavoongaAirport	"
"	SVC	"	=	"	GrantCountyAirport	"
"	SVH	"	=	"	RegionalAirport	"
"	SVN	"	=	"	HunterAaf	"
"	SVW	"	=	"	SparrevohnLrrs	"
"	SWD	"	=	"	SewardAirport	"
"	SWF	"	=	"	StewartIntl	"
"	SXP	"	=	"	SheldonPointAirport	"
"	SXQ	"	=	"	SoldotnaAirport	"
"	SYA	"	=	"	EarecksonAs	"
"	SYB	"	=	"	SealBaySeaplaneBase	"
"	SYR	"	=	"	SyracuseHancockIntl	"
"	SZL	"	=	"	WhitemanAfb	"
"	TAL	"	=	"	TananaAirport	"
"	TAN	"	=	"	TauntonMunicipalAirport-KingField	"
"	TBN	"	=	"	WaynesvilleRgnlArptAtForneyFld	"
"	TCC	"	=	"	TucumcariMuni	"
"	TCL	"	=	"	TuscaloosaRgnl	"
"	TCM	"	=	"	McChordAfb	"
"	TCS	"	=	"	TruthOrConsequencesMuni	"
"	TCT	"	=	"	TakotnaAirport	"
"	TEB	"	=	"	Teterboro	"
"	TEK	"	=	"	TatitlekAirport	"
"	TEX	"	=	"	Telluride	"
"	TIK	"	=	"	TinkerAfb	"
"	TIW	"	=	"	TacomaNarrowsAirport	"
"	TKA	"	=	"	Talkeetna	"
"	TKE	"	=	"	TenakeeSeaplaneBase	"
"	TKF	"	=	"	Truckee-TahoeAirport	"
"	TKI	"	=	"	CollinCountyRegionalAirportatMcKinney	"
"	TLA	"	=	"	TellerAirport	"
"	TLH	"	=	"	TallahasseeRgnl	"
"	TLJ	"	=	"	TatalinaLrrs	"
"	TLT	"	=	"	TuluksakAirport	"
"	TMA	"	=	"	HenryTiftMyersAirport	"
"	TMB	"	=	"	KendallTamiamiExecutive	"
"	TNC	"	=	"	TinCityLRRSAirport	"
"	TNK	"	=	"	TununakAirport	"
"	TNT	"	=	"	DadeCollierTrainingAndTransition	"
"	TNX	"	=	"	TonopahTestRange	"
"	TOA	"	=	"	ZamperiniFieldAirport	"
"	TOC	"	=	"	ToccoaRGLetourneauFieldAirport	"
"	TOG	"	=	"	TogiakAirport	"
"	TOL	"	=	"	Toledo	"
"	TOP	"	=	"	PhilipBillardMuni	"
"	TPA	"	=	"	TampaIntl	"
"	TPL	"	=	"	DraughonMillerCentralTexasRgnl	"
"	TRI	"	=	"	Tri-CitiesRegionalAirport	"
"	TRM	"	=	"	JacquelineCochranRegionalAirport	"
"	TSS	"	=	"	East34thStreetHeliport	"
"	TTD	"	=	"	PortlandTroutdale	"
"	TTN	"	=	"	TrentonMercer	"
"	TUL	"	=	"	TulsaIntl	"
"	TUP	"	=	"	TupeloRegionalAirport	"
"	TUS	"	=	"	TucsonIntl	"
"	TVC	"	=	"	CherryCapitalAirport	"
"	TVF	"	=	"	ThiefRiverFalls	"
"	TVI	"	=	"	ThomasvilleRegionalAirport	"
"	TVL	"	=	"	LakeTahoeAirport	"
"	TWA	"	=	"	TwinHillsAirport	"
"	TWD	"	=	"	JeffersonCountyIntl	"
"	TWF	"	=	"	MagicValleyRegionalAirport	"
"	TXK	"	=	"	TexarkanaRgnlWebbFld	"
"	TYE	"	=	"	TyonekAirport	"
"	TYR	"	=	"	TylerPoundsRgnl	"
"	TYS	"	=	"	McGheeTyson	"
"	U76	"	=	"	MountainHomeMunicipalAirport	"
"	UDD	"	=	"	BermudaDunesAirport	"
"	UDG	"	=	"	DarlingtonCountyJetport	"
"	UES	"	=	"	WaukeshaCountyAirport	"
"	UGN	"	=	"	WaukeganRgnl	"
"	UIN	"	=	"	QuincyRegionalBaldwinField	"
"	UMP	"	=	"	IndianapolisMetropolitanAirport	"
"	UNK	"	=	"	UnalakleetAirport	"
"	UPP	"	=	"	Upolu	"
"	UST	"	=	"	St.AugustineAirport	"
"	UTM	"	=	"	TunicaMunicipalAirport	"
"	UTO	"	=	"	IndianMountainLrrs	"
"	UUK	"	=	"	Ugnu-KuparukAirport	"
"	UUU	"	=	"	NewportState	"
"	UVA	"	=	"	GarnerField	"
"	VAD	"	=	"	MoodyAfb	"
"	VAK	"	=	"	ChevakAirport	"
"	VAY	"	=	"	SouthJerseyRegionalAirport	"
"	VBG	"	=	"	VandenbergAfb	"
"	VCT	"	=	"	VictoriaRegionalAirport	"
"	VCV	"	=	"	SouthernCaliforniaLogistics	"
"	VDF	"	=	"	TampaExecutiveAirport	"
"	VDZ	"	=	"	ValdezPioneerFld	"
"	VEE	"	=	"	VenetieAirport	"
"	VEL	"	=	"	VernalRegionalAirport	"
"	VGT	"	=	"	NorthLasVegasAirport	"
"	VIS	"	=	"	VisaliaMunicipalAirport	"
"	VLD	"	=	"	ValdostaRegionalAirport	"
"	VNW	"	=	"	VanWertCountyAirport	"
"	VNY	"	=	"	VanNuys	"
"	VOK	"	=	"	VolkFld	"
"	VPC	"	=	"	CartersvilleAirport	"
"	VPS	"	=	"	EglinAfb	"
"	VRB	"	=	"	VeroBeachMuni	"
"	VSF	"	=	"	HartnessState	"
"	VYS	"	=	"	IllinoisValleyRegional	"
"	W13	"	=	"	Eagle'sNestAirport	"
"	WAA	"	=	"	WalesAirport	"
"	WAL	"	=	"	WallopsFlightFacility	"
"	WAS	"	=	"	AllAirports	"
"	WBB	"	=	"	StebbinsAirport	"
"	WBQ	"	=	"	BeaverAirport	"
"	WBU	"	=	"	BoulderMunicipal	"
"	WBW	"	=	"	Wilkes-BarreWyomingValleyAirport	"
"	WDR	"	=	"	BarrowCountyAirport	"
"	WFB	"	=	"	KetchikanharborSeaplaneBase	"
"	WFK	"	=	"	NorthernAroostookRegionalAirport	"
"	WHD	"	=	"	HyderSeaplaneBase	"
"	WHP	"	=	"	WhitemanAirport	"
"	WIH	"	=	"	WishramAmtrakStation	"
"	WKK	"	=	"	AleknagikAirport	"
"	WKL	"	=	"	WaikoloaHeliport	"
"	WLK	"	=	"	SelawikAirport	"
"	WMO	"	=	"	WhiteMountainAirport	"
"	WRB	"	=	"	RobinsAfb	"
"	WRG	"	=	"	WrangellAirport	"
"	WRI	"	=	"	McGuireAfb	"
"	WRL	"	=	"	WorlandMunicipalAirport	"
"	WSD	"	=	"	CondronAaf	"
"	WSJ	"	=	"	SanJuan-UganikSeaplaneBase	"
"	WSN	"	=	"	SouthNaknekAirport	"
"	WST	"	=	"	WesterlyStateAirport	"
"	WSX	"	=	"	WestsoundSeaplaneBase	"
"	WTK	"	=	"	NoatakAirport	"
"	WTL	"	=	"	TuntutuliakAirport	"
"	WWD	"	=	"	CapeMayCo	"
"	WWP	"	=	"	NorthWhaleSeaplaneBase	"
"	WWT	"	=	"	NewtokAirport	"
"	WYS	"	=	"	YellowstoneAirport	"
"	X01	"	=	"	EvergladesAirpark	"
"	X07	"	=	"	LakeWalesMunicipalAirport	"
"	X21	"	=	"	ArthurDunnAirpark	"
"	X39	"	=	"	TampaNorthAeroPark	"
"	X49	"	=	"	SouthLakelandAirport	"
"	XFL	"	=	"	FlaglerCountyAirport	"
"	XNA	"	=	"	NWArkansasRegional	"
"	XZK	"	=	"	AmherstAmtrakStationAMM	"
"	Y51	"	=	"	MunicipalAirport	"
"	Y72	"	=	"	BloyerField	"
"	YAK	"	=	"	Yakutat	"
"	YIP	"	=	"	WillowRun	"
"	YKM	"	=	"	YakimaAirTerminalMcAllisterField	"
"	YKN	"	=	"	ChanGurney	"
"	YNG	"	=	"	YoungstownWarrenRgnl	"
"	YUM	"	=	"	YumaMcasYumaIntl	"
"	Z84	"	=	"	Clear	"
"	ZBP	"	=	"	PennStation	"
"	ZFV	"	=	"	Philadelphia30thStStation	"
"	ZPH	"	=	"	MunicipalAirport	"
"	ZRA	"	=	"	AtlanticCityRailTerminal	"
"	ZRD	"	=	"	TrainStation	"
"	ZRP	"	=	"	NewarkPennStation	"
"	ZRT	"	=	"	HartfordUnionStation	"
"	ZRZ	"	=	"	NewCarrolltonRailStation	"
"	ZSF	"	=	"	SpringfieldAmtrakStation	"
"	ZSY	"	=	"	ScottsdaleAirport	"
"	ZTF	"	=	"	StamfordAmtrakStation	"
"	ZTY	"	=	"	BostonBackBayStation	"
"	ZUN	"	=	"	BlackRock	"
"	ZVE	"	=	"	NewHavenRailStation	"
"	ZWI	"	=	"	WilmingtonAmtrakStation	"
"	ZWU	"	=	"	WashingtonUnionStation	"
"	ZYP	"	=	"	PennStation	"
;
run;

data flights1;
set flights1;
format dest route.;
run;


data flights;
set flights;
format origin route.;
run;

/* changing flight var to character  */
data flights1;
set flights1;
flight1 = put(flight,8.);
drop flight;
rename flight1 = flight;
run;


/* Question 5 - 1  */

proc sort data=flights1 out= flights1; by flight;
run;

proc sql outobs=5;
create table f3 as
select count(flight) as total_flights,origin,dest from flights1 group by origin,dest order by total_flights desc; 
quit;

proc sql;
create table f5 as
select count(flight) as total_flights,carrier from flights1 group by carrier order by total_flights desc; 
quit;


PROC EXPORT DATA= f5  OUTFILE= "/folders/myfolders/question 5 - 1.xls" 
DBMS=xlsx REPLACE;
RUN;

proc sql;
select * from f3 (obs = 1);
quit;


/* JFK  to LAX has the maximum no of flights.. */

/*Question 5 - 2*/

proc sql;
create table f4 as
select flights1.flight as count_flights,f3.origin,f3.dest,flights1.carrier from flights1 inner join f3 on flights1.dest = f3.dest; 
quit;

data f4 (drop= origin dest);
set f4;
route = catx("-",origin,dest);
run;

ODS html body='/folders/myfolders/question5-2.xls'
style= BRICK;
proc tabulate data=f4;
class route carrier;
var count_flights;
table carrier='',(route='' ALL='Overall')*count_flights=''*N=''/Box= 'Count of flights';
run;
ODS html close;

PROC EXPORT DATA= f4  OUTFILE= "/folders/myfolders/one.csv" 
DBMS=csv REPLACE;
sheet= sheet2;
RUN;

/* question - 5 -3  */

Refer to Excel file - question 5 - 3

/* question 6 */
/* busiest time of day for each carrier */

proc sql;
create table f7 as
select count(flight) as total_flights, carrier,hour  from flights1 group by carrier ,
hour order by total_flights desc; 
quit;

proc sort data= f7 out= f7;
by carrier;
run;

data f7;
set f7;
by carrier;
if first.carrier;
run;


ODS html body='/folders/myfolders/question 6-1.xls'
style= BRICK;
proc tabulate data=f7;
class hour carrier;
var total_flights;
table carrier='',(hour='')*total_flights=''*SUM=''/Box= 'Count of flights';
run;
ODS html close;

/* second part  */
proc sql;
create table f5 as
select count(flight) as total_flights, origin,hour  from flights1 where origin in ('JFK','LGA','EWR') group by origin,hour order by total_flights descending; 
quit;

proc sort data= f5 out= f5;
by origin;
run;

data f5;
set f5;	
by origin;
if first.origin;
run;

PROC EXPORT DATA= f5  OUTFILE= "/folders/myfolders/question 6 - 2.csv" 
DBMS=csv REPLACE;
RUN;

/* question 7  */
/* first part  */
data f1;
set flights1;
if arrival_delay > 0 and dest ='JFK';
run;

/*  Zero obs in a dataset */
/*second part*/

proc sql;
create table f6 as
select count(flight) as total_flights, dest  from flights1 where arrival_delay > 0 group by 
dest order by total_flights; 
quit;


data f6;
set f6;
if _N_ = 1;
run;

/* PSP is the airport which has least no of delays*/

/* third part */
proc sql;
create table f7 as
select count(flight) as total_flights, dest  from flights1 where arrival_delay > 0 group by dest order by total_flights descending; 
quit;

data f7;
set f7;
if _N_ = 1;
run;

/* ATL destination has highest number of delays  */

/*question 8  */
/* first part */
proc sql;
create table flights_weather_join as
select a.*, b.*
from flights1 as a left join weather1 as b on a.hour = b.hour1 
and a.origin=b.origin1 and a.date = b.date1;
quit;

/* second part */
proc report data = flights_weather_join out= first_inference;
columns month_from_date departure_delay temp dewp pressure visib precip wind_gust wind_speed humid;
define month_from_date/group "Months"; 
define departure_delay/mean "Dep_delay";
define temp/mean "Temp";
define dewp/mean "Dew_point";
define pressure/mean "Pressure" ;
define visib/mean "Visib";
define precip/ mean "precip";
define wind_gust/mean "wind_gust"; 
define wind_speed/mean  "wind_speed"; 
define humid/mean "humidity";
run;

PROC EXPORT DATA= first_inference OUTFILE= "/folders/myfolders/question8.csv" 
DBMS=csv REPLACE;
RUN;

/* question 9 */
proc report data=planes  out=sec_inference;
columns no_of_years_old fuel_cc;
define no_of_years_old/group ;
define fuel_cc/mean "fuel_consumption";
run;

PROC EXPORT DATA= sec_inference OUTFILE= "/folders/myfolders/question9-1.csv" 
DBMS=csv REPLACE;
RUN;

proc sql;
create table report5 as
select avg(fuel_cc) as average_fuel_consumption,seats,type,engines,engine from planes 
group by type,seats,engines,engine
order by average_fuel_consumption;
quit;

PROC EXPORT DATA= report5 OUTFILE= "/folders/myfolders/question 9 - 2.csv" 
DBMS=csv REPLACE;
RUN;

/*question 10  */
proc report data=flights1  out=third_inference;
columns departure_delay hour;
define departure_delay/mean;
define hour/group "hour_of_day";
run;

PROC EXPORT DATA= third_inference OUTFILE= "/folders/myfolders/question10.csv" 
DBMS=csv REPLACE;
RUN;



