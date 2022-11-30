version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Figure A2 and Table A11", clear

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

** lnhc1-lnshc7
* log(1+number of individuals in labor force beloning to each of the following classes):
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
/////// Figure A2 and Table A11: Regression Results for Absolute Growth of Occupational Groups

** run regressions and save results for esttab table and figure

foreach var of varlist lnhc1-lnhc7 {
xtreg `var' i.year iline iline_owl i.irail L10.llabforce L10.shc2-shc7 i.county_id#i.year, fe vce(cluster parish_code)
est sto `var'

* save results for figure

gen b_`var'=_b[iline]
gen cih_`var'=_b[iline] + (1.96 * _se[iline])
gen cil_`var'=_b[iline] - (1.96 * _se[iline])

}

* create regression table with results
esttab lnhc1 lnhc2 lnhc3 lnhc4 lnhc5 lnhc6 lnhc7, drop(*.year *year _cons) s(N , labels("Observations")) ///
mlabels("(1) Elite" "(2) White collar" "(3) Foremen" "(4) Medium skilled" "(5) Farmers" "(6) Lower skilled" "(7) Unskilled") se

* graph regression results (figure a2)
keep b_* cih_* cil_*
keep if _n==1
gen i=1

reshape long b_ cih_ cil_, i(i) j(var, string)

gen hc=_n

twoway (scatter hc b_) (rcap cih_ cil_ hc, horizontal lcolor(black)), xline(0) ///
ylabel(1 "1. Elite" 2 "2. White collar" 3 "3. Foremen" 4 "4. Medium skilled" 5 "5. Farmers" 6 "6. Lower skilled" 7 "7. Unskilled", angle(0) labsize(medium)) yscale(reverse) ytitle("") xtitle("Change (%)", size(medium)) ///
legend(off) xlabel(-40(10)40, labsize(medium)) ysize(12) xsize(20)

	
