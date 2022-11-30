version 16
clear all
set more off

/* Insert your own pathname here */
* cd "[path]/replication/"

use "data/data Table 2", clear

/////////////////////////////////////////
/////// Variable definitions

** parish_name
* name of parish

** parish_code 
* numerical identifier of parish

** ever_iline
* dummy variable denoting parishes that were connected to the western line electricity grid after 1900

** strikes/strikesoff/strikesdef
* total number of strikes
* number of offensive strikes 
* number of defensive strikes

** labforce
* number of individuals in labor force

** shc1-shc7
* variables measuring the share (in percent) of the labor force beloning to each of the following classes:
* 1. Elite
* 2. White collar
* 3. Foremen
* 4. Medium skilled
* 5. Farmers
* 6. Lower-skilled
* 7. Unskilled

/////////////////////////////////////////
/////// Table 2: Differences Between Connected and Unconnected Parishes Prior to Access to the Grid, 1900

* create table with the mean and standard deviation of each variable by later access to the grid
tabstat labforce shc1 shc2 shc3 shc4 shc5 shc6 shc7 strikes strikesoff strikesdef, by(ever_iline) format(%5.0g) stat(mean sd)

* test for difference-in-means 
foreach var of varlist labforce shc1 shc2 shc3 shc4 shc5 shc6 shc7 strikes strikesoff strikesdef {
ttest `var', by(ever_iline) 
}

