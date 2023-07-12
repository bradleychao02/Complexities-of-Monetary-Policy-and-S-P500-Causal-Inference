/* Romer-Romer Monetary Policy Shock .do file
 * Purpose: Runs Oscar Jorda local projections with Newey-West standard errors
 * to generate impulse response functions (IRF) graph
 * Author: Bradley Chao
 * Date: 4/20/23
 * Credits: Professor ChaeWon Baek and Johannes Wieland
 */
 
/******************************************************************************/
*							   House Keeping 

clear all
set more off
global path "/Users/bradleychao/Desktop/EC15_Research/Data_Manip"
capture log close _all

log using "$path/R&R_MPS.log", replace
*******************************************************************************/


* Import 2 Datasets:
* (1) R&R OG 1960-1996

use "$path/original_dataset.dta", clear

* Adjust for date compatibility issue between Stata and Python
gen monthseq = _n - 1

scalar basedate = mdy(1, 1, 1969)
gen date = mofd(basedate) + monthseq

* Clean Data
drop monthseq

order index date Romer log_SP500

format date %tm
tsset date, monthly

gen fdiff_l500 = d.log_SP500

local hmax = 24

* Cumulative
forvalues h = 0/`hmax' {
	gen dep`h' = f`h'.log_SP500 - l.log_SP500
}

gen Years = _n-1 if _n<= `hmax'
gen Zero = 0 if _n<=`hmax'
gen b = 0
gen u = 0
gen d = 0

local lag=12

* Compute Lag for Romer
forvalues h = 0/`hmax' {
    newey dep`h' L(0/`lag').Romer L(1/`lag').fdiff_l500, lag(`h') 
	* Multiply by log-level coefficient by 100 to get dY%/dX
    replace b = 100*_b[Romer]                     if _n == `h'+1
	* Use 90% confidence interval
    replace u = 100*(_b[Romer] + 1.645* _se[Romer]) if _n == `h'+1
    replace d = 100*(_b[Romer] - 1.645* _se[Romer]) if _n == `h'+1
    eststo
}

twoway ///
(rarea u d  Years,  ///
fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) ///
(line Zero Years, lcolor(black)), legend(off) ///
title("Original Cumulative Response of S&P 500 to 1pp R&R MP shock", color(black) size(medsmall)) ///
ytitle("Percent Change S&P500", size(medsmall)) xtitle("Months After Shock", size(medsmall)) ///
graphregion(color(white)) plotregion(color(white))

graph export "$path/og_irf.png", replace

* Now run the original data which uses Wielan's updated dataset to 2007
use "$path/full_dataset.dta", replace


gen monthseq = _n - 1

scalar basedate = mdy(1, 1, 1969)
gen date = mofd(basedate) + monthseq

drop monthseq

order index date Romer log_SP500

format date %tm
tsset date, monthly

gen fdiff_l500 = d.log_SP500

local hmax = 24

forvalues h = 0/`hmax' {
	gen dep`h' = f`h'.log_SP500 - l.log_SP500
}

gen Years = _n-1 if _n<= `hmax'
gen Zero = 0 if _n<=`hmax'
gen b = 0
gen u = 0
gen d = 0

local lag=12

forvalues h = 0/`hmax' {
    newey dep`h' L(0/`lag').Romer L(1/`lag').fdiff_l500, lag(`h') 
    replace b = 100*_b[Romer]                     if _n == `h'+1
    replace u = 100*(_b[Romer] + 1.645* _se[Romer]) if _n == `h'+1
    replace d = 100*(_b[Romer] - 1.645* _se[Romer]) if _n == `h'+1
    eststo
}

twoway ///
(rarea u d  Years,  ///
fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) ///
(line Zero Years, lcolor(black)), legend(off) ///
title("Full Cumulative Response of S&P 500 to 1pp R&R MP shock", color(black) size(medsmall)) ///
ytitle("Percent Change S&P500", size(medsmall)) xtitle("Months After Shock", size(medsmall)) ///
graphregion(color(white)) plotregion(color(white))

graph export "$path/full_irf.png", replace
