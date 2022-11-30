version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Figure 4 and Table A4", clear

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

** forw_iline
* dummy variable denoting if parish is connected to the western line electricity grid in the subsequent period

** iline_owl
* dummy variable denoting if parish has an electricity connection outside the western line electricity grid

** lstrikes_ag/lstrikesoff_ag/lstrikesdef_ag/lstrikingworkers_ag
* log(1+total number of strikes in agriculture)
* log(1+number of offensive strikes in agriculture) 
* log(1+number of defensive strikes in agriculture)
* log(1+number of striking workers in agriculture)

** lstrikes_indserv/lstrikesoff_indserv/lstrikesdef_indserv/lstrikingworkers_indserv
* log(1+total number of strikes in industry and services)
* log(1+number of offensive strikes in industry and services) 
* log(1+number of defensive strikes in industry and services)
* log(1+number of striking workers in industry and services)

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
/////// Figure 4 and Table A4: Regression Results for Strikes by Sector

** run regressions and save results for esttab table and figure

foreach var of varlist lstrikes_ag lstrikesoff_ag lstrikesdef_ag lstrikes_indserv lstrikesoff_indserv lstrikesdef_indserv {
xtreg `var' i.year iline iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto `var'

* save results for figure

gen b_`var'=_b[iline]
gen cih_`var'=_b[iline] + (1.96 * _se[iline])
gen cil_`var'=_b[iline] - (1.96 * _se[iline])

}

* create regression table with results
esttab lstrikes_ag lstrikesoff_ag lstrikesdef_ag lstrikes_indserv lstrikesoff_indserv lstrikesdef_indserv, drop(*.year *year _cons) s(N , labels("Observations")) ///
mlabels("") se

* graph regression results (figure 4)

keep b_* cih_* cil_*
keep if _n==1
gen i=1

reshape long b_ cih_ cil_, i(i) j(var, string)

gen id=1 if _n==1
replace id=2 if _n==5
replace id=3 if _n==3
replace id=5 if _n==2
replace id=6 if _n==6
replace id=7 if _n==4

sort id

twoway (scatter id b_ if inlist(id,1,5), msymbol(Oh) color(black) lwidth(*1) msize(small)) ///
(rcap cih_ cil_ id if inlist(id,1,5), horizontal lcolor(black)) ///
(scatter id b_ if inlist(id,2,6), msymbol(Oh) color(black*0.5) lwidth(*1) msize(small)) ///
(rcap cih_ cil_ id if inlist(id,2,6), color(black*0.5) horizontal) ///
(scatter id b_ if inlist(id,3,7), msymbol(Oh) color(black*0.3) lwidth(*1) msize(small)) ///
 (rcap cih_ cil_ id if inlist(id,3,7), horizontal lcolor(black*0.3)) ///
, xline(0) ///
ylabel(0 "{bf:Agriculture}" 1 "Total strikes" 2 "Offensive" 3 "Defensive" 4 "{bf:Industry and services}" 5 "Total strikes" 6 "Offensive" 7 "Defensive", angle(0) labsize(medium)) yscale(reverse) ytitle("") xtitle("Change (%)", size(medium)) ///
legend(off) xlabel(-5(5)15, labsize(medium)) ysize(12) xsize(20) ///
yline(3.5, lpattern(solid))
