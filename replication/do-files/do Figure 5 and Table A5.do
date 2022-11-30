version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Figure 5 and Table A5", clear

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

** iind
* dummy variable denoting if parish was among the 50 percent of parishes with the highest share of industry in total employment in 1900

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
/////// Figure 5 and Table A5: Results for Strikes by Type of Parish: Non-Industrial/Industrial

** run regressions and save results for esttab table 

* (1) Log(1+Total Strikes)	
xtreg lstrikes i.year iline#iind iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikes
* calculate margins for figure
margins, dydx(1.iline) at(iind=(0 1) iline=0) noestimcheck

* (2) Log(1+Offensive Strikes)	
xtreg lstrikesoff i.year iline#iind iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesoff
* calculate margins for figure
margins, dydx(1.iline) at(iind=(0 1) iline=0) noestimcheck

* (3) Log(1+Defensive Strikes)	
xtreg lstrikesdef i.year iline#iind iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto lstrikesdef
* calculate margins for figure
margins, dydx(1.iline) at(iind=(0 1) iline=0) noestimcheck

* create regression table with results
esttab lstrikes lstrikesoff lstrikesdef, drop(*.year *year _cons 1.iline#1.*) s(N , labels("Observations")) ///
mlabels("Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)") se

** graph regression results (figure 5)

clear
set obs 8

gen id=_n


* numbers from margins command
		// strikes
gen b=.7589999 if id==1
gen cil=-4.351407 if id==1
gen cih=5.869407 if id==1
replace b=17.78956 if id==2
replace cil=7.858562 if id==2
replace cih=27.72056 if id==2
		// strikeswage
replace b=1.537606 if id==4
replace cil=-3.16129  if id==4
replace cih=6.236501 if id==4
replace b=15.43445 if id==5
replace cil=5.383212 if id==5
replace cih=25.48569 if id==5
		// strikesdef
replace b=.0745102 if id==7
replace cil=-.990535 if id==7
replace cih=1.139555 if id==7
replace b=5.634054 if id==8
replace cil=1.425653 if id==8
replace cih=9.842455 if id==8

twoway (scatter id b if inlist(id,1,4,7)) (rcap cih cil id  if inlist(id,1,4,7), horizontal lcolor(black)) ///
(scatter id b if inlist(id,2,5,8), msymbol(Oh) color(black*0.5) lwidth(*1) msize(small)) (rcap cih cil id  if inlist(id,2,5,8), horizontal color(black*0.5)), xline(0) ///
ylabel(0 "{bf:Strikes}" 1 "Non-industrial" 2 "Industrial" 3 "{bf:Offensive strikes}" 4 "Non-industrial" 5 "Industrial" 6 "{bf:Defensive strikes}" 7 "Non-industrial" 8 "Industrial", angle(0) labsize(medium)) yscale(reverse) ytitle("") xtitle("Change (%)", size(medium)) ///
legend(off) xlabel(-10(10)40, labsize(medium)) ysize(12) xsize(20) ///
text("")






