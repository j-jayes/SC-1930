version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Figure 2 and Table A2", clear

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
/////// Figure 2 and Table A2: Main Results with Check for Pre-Trend

** run regressions and save results for esttab table and figure

foreach var of varlist lstrikes lstrikesoff lstrikesdef lstrikingworkers {
xtreg `var' i.year iline forw_iline iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto `var'

* save results for figure

gen b2_`var'=_b[iline]
gen cih2_`var'=_b[iline] + (1.96 * _se[iline])
gen cil2_`var'=_b[iline] - (1.96 * _se[iline])

gen b1_`var'=_b[forw_iline]
gen cih1_`var'=_b[forw_iline] + (1.96 * _se[forw_iline])
gen cil1_`var'=_b[forw_iline] - (1.96 * _se[forw_iline])

}

* create regression table with results
esttab lstrikes lstrikesoff lstrikesdef lstrikingworkers, drop(*.year *year _cons) s(N , labels("Observations")) ///
mlabels("Log(1+Total Strikes)" "Log(1+Offensive Strikes)" "Log(1+Defensive Strikes)" "Log(1+No. of striking workers)") se

** graph regression results (figure 2)

keep b1_* cih1_* cil1_* b2_* cih2_* cil2_*
keep if _n==1

gen i=1

reshape long b1_ cih1_ cil1_ b2_ cih2_ cil2_, i(i) j(var, string)
reshape long b cih cil, i(var) j(time, string)
replace time=substr(time,1,1)
destring(time), replace 

replace time=time-0.2 if var=="lstrikes"
replace time=time+0.2 if var=="lstrikesdef"
replace time=time+0.4 if var=="lstrikingworkers"

set obs 12
replace b=75 if inrange(_n,9,12)
gen b2=-45 if inrange(_n,9,12) 
replace time=.6 if _n==9
replace time=1.5 if _n==10
replace time=1.5 if _n==11
replace time=2.5 if _n==12

twoway (rarea b b2 time if inrange(_n,9,10), color(black*0.2%10)) ///
(rarea b b2 time if inrange(_n,11,12), color(black*0.2%30)) ///
(scatter b time if var=="lstrikes", msymbol(Oh) color(black) lwidth(*1) msize(small)) ///
(rcap cih cil time if var=="lstrikes", color(black)) ///
(scatter b time if var=="lstrikesoff", msymbol(Oh) color(black*0.5) lwidth(*1) msize(small)) ///
(rcap cih cil time if var=="lstrikesoff", color(black*0.5)) ///
(scatter b time if var=="lstrikesdef", msymbol(Oh) color(black*0.3) lwidth(*1) msize(small)) ///
(rcap cih cil time if var=="lstrikesdef",  color(black*0.3)) ///
(scatter b time if var=="lstrikingworkers", msymbol(Oh) color(black*0.3) lwidth(*1) msize(small)) ///
(rcap cih cil time if var=="lstrikingworkers",  color(black*0.3)) ///
, yline(0, lcolor(black)) xline(1.5, lpattern(solid) lcolor(black))  ///
ysize(10) xsize(20) legend(ring(0) pos(5) row(2)) xlabel(0.6 " " 1 " " 2 " " 2.5 " ") ///
xtitle("") ytitle("Point Estimate & 95% CI") ylabel(-40(10)70) legend(off) ///
text(24 1.8 "Strikes") text(24 2.05 "Offensive strikes") text(9.2 2.2 "Defensive strikes") ///
text(41 2.27 "Striking workers") ///
text(11 0.8 "Strikes") text(13 1.05 "Offensive strikes") text(6 1.2 "Defensive strikes") ///
text(20 1.36 "Striking workers")  text(65 1 "Pre-treatment period", size(huge)) ///
text(65 2 "Treatment period", size(huge))




