version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Table 4", clear

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

** lline_c
* log(1+variable measuring the number of western line electricity grid lines in the parish)

** lline_l
* log(1+variable measuring the length of western line electricity grid lines in the parish)

** iline_owl
* dummy variable denoting if parish has an electricity connection outside the western line electricity grid

** lstrikes/lstrikesoff/lstrikesdef/lstrikingworkers
* log(1+total number of strikes)
* log(1+number of offensive strikes) 
* log(1+number of defensive strikes)
* log(1+number of striking workers)

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
/////// Table 4: Alternative Measurement of Treatment

** run regressions and save results for esttab table 

*** Log(1+No. of grid lines, Western line)

** (1) Log(1+Total Strikes)	
xtreg lstrikes i.year lline_c iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikes_c

** (2) Log(1+Offensive Strikes)	
xtreg lstrikesoff i.year lline_c iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesoff_c

** (3) Log(1+Defensive Strikes)	
xtreg lstrikesdef i.year lline_c iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesdef_c

** (4) Log(1+No. of striking workers)	
xtreg lstrikingworkers i.year lline_c iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikingworkers_c

* create regression table with results
esttab lstrikes_c lstrikesoff_c lstrikesdef_c lstrikingworkers_c, drop(*.year *year _cons) s(N , labels("Observations")) ///
mlabels("Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)" "Log(1+No. of striking workers)") se


*** Log(1+Length of grid lines, Western line)

** (1) Log(1+Total Strikes)	
xtreg lstrikes i.year lline_l iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikes_l

** (2) Log(1+Offensive Strikes)	
xtreg lstrikesoff i.year lline_l iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesoff_l

** (3) Log(1+Defensive Strikes)	
xtreg lstrikesdef i.year lline_l iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesdef_l

** (4) Log(1+No. of striking workers)	
xtreg lstrikingworkers i.year lline_l iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikingworkers_l

* create regression table with results
esttab lstrikes_c lstrikesoff_c lstrikesdef_c lstrikingworkers_c lstrikes_l lstrikesoff_l lstrikesdef_l lstrikingworkers_l, drop(*.year *year _cons) s(N , labels("Observations")) order(lline_c lline_l) ///
mlabels("Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)" "Log(1+No. of striking workers)" "Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)" "Log(1+No. of striking workers)") se






