version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Table 1", clear

/////////////////////////////////////////
/////// Variable definitions

** strikes
* total number of strikes in year

** strikesoff
* number of offensive strikes in year

** strikesdef
* number of defensive strikes in year

** strikesunionrec
* number of strikes over union recognition in year

/////////////////////////////////////////
/////// Create period variable and collapse data by period

* generate period variable
gen year_period="1891–1895" if inrange(year,1891,1895)
replace year_period="1896–1900" if inrange(year,1896,1900)
replace year_period="1901–1905" if inrange(year,1901,1905)
replace year_period="1906–1910" if inrange(year,1906,1910)
replace year_period="1911–1915" if inrange(year,1911,1915)
replace year_period="1916–1920" if inrange(year,1916,1920)

* collapse data
collapse (sum) strikes strikesoff strikesdef strikesunionrec, by(year_period)
* generate variable for the number of strikes with other causes
gen strikes_allother=strikes-(strikesoff+strikesdef+strikesunionrec)

* generate variable measuring category's share of all strikes
foreach var of varlist strikesoff strikesdef strikesunionrec strikes_allother {
gen s_`var'=round(`var'/strikes*100,1)
}

/////////////////////////////////////////
/////// Table 1: Number of Strikes and Strikes by Cause

* create table
tabstat strikes s_strikesoff s_strikesdef s_strikesunionrec s_strikes_allother, by(year) nototal
