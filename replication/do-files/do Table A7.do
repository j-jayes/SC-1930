version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Table A7", clear

/////////////////////////////////////////
/////// Variable definitions

** parish_name
* name of parish

** parish_code 
* numerical identifier of parish

** county_id 
* numerical identifier of swedish counties:
* 1	Stockholms län
* 2	Uppsala län
* 3	Södermanlands län
* 4	Östergötlands län
* 5	Jönköpings län
* 6	Kronobergs län
* 7	Kalmar län
* 8	Gotlands län
* 9	Blekinge län
* 10 Kristianstads län
* 11 Malmöhus län
* 12 Hallands län
* 13 Göteborgs och Bohus län
* 14 Älvsborgs län
* 15 Skaraborgs län
* 16 Värmlands län
* 17 Örebro län
* 18 Västmanlands län
* 19 Kopparbergs län
* 20 Gävleborgs län
* 21 Västernorrlands län
* 22 Jämtlands län
* 23 Västerbottens län
* 24 Norbottens län

** iline
* dummy variable denoting if parish is connected to the western line electricity grid

** iline_owl
* dummy variable denoting if parish has an electricity connection outside the western line electricity grid

** lstrikesoff_inclother
* log(1+number of offensive strikes when including strikes with other causes) 

** irail
* dummy variable denoting if parish has access to the railroad network

** shc1-shc7
* variables measuring the share (in percent) of the labor force beloning to each of the following classes:
* 1. Elite
* 2. White collar
* 3. Foremen
* 4. Medium skilled
* 5. Farmers
* 6. Lower-skilled
* 7. Unskilled

** llabforce
* log(1+number of individuals in labor force)

/////////////////////////////////////////
/////// Xtset data

xtset parish_code year

/////////////////////////////////////////
/////// Table A7: Effect on Offensive Strikes when Including Strikes for Other Causes

** run regression and save results for esttab table 

* (1) Log(1+Offensive+other strikes)
xtreg lstrikesoff_inclother i.year iline iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesoff_inclother

* create regression table with results
esttab lstrikesoff_inclother, drop(*.year *year _cons) s(N , labels("Observations")) ///
mlabels("Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)" "Log(1+No. of striking workers)") se









