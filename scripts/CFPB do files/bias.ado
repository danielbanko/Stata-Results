/*------------------------------------------------*/
/* Programs to estimate left-digit bias           */
/* Data modified: Mon Jun 26 22:36:44 2017        */
/*------------------------------------------------*/
capture program drop plot_pope
program define plot_pope
    syntax varlist(numeric min=2) [if], [Controls(varlist)]    ///
                                        [NBins(numlist)]       ///
                                        [XBins(varlist)]       ///
                                        [GENerate(string)]     ///
                                        [XTITLE(string)]       ///
                                        [YTITLE(string)]       ///
                                         NCuts(numlist)
    * Mark sample
    marksample touse

    * Parse y and x variables
    local yvar = word("`varlist'", 1)
    local xvar = word("`varlist'", 2)

    * Create bin variables
    tempvar bin tag_bin
    if "`xbins'" != "" {
        gen  `bin'     = `xbins'     if `touse'
        gen  `tag_bin' = tag_`xbins' if `touse'
    }
    else {
        egen `bin'      = cut(`xvar') if `touse', at(`nbins')
        gegen `tag_bin' = tag(`bin')  if `touse'
    }

    * Create mean variable (residualize if controls specified)
    tempvar yresiduals ymean_of_bin fbin
    * If there are controls, residualize
    if "`controls'" != "" {
        gegen `fbin' = group(`bin')
        _regress `yvar' `controls' i.`fbin' if `touse', noheader notable
        _predict `yresiduals' if `touse', xb
        foreach control of varlist `controls' {
            replace `yresiduals' = `yresiduals' - _b[`control'] * `control'
        }
        replace `yresiduals' = `yresiduals' - b[_cons]
        gegen `ymean_of_bin' = mean(`yresiduals') if `touse', by(`bin')
    }
    * If not, just take the mean
    else {
        gegen `ymean_of_bin' = mean(`yvar') if `touse', by(`bin')
    }

    * Extract variable label
    if "`ytitle'" == "" {
        local ytitle "`:var l `yvar''"
        if "`ytitle'" == "" {
          local ytitle "`yvar'"
        }
    }
    if "`controls'" != "" {
        local ytitle "Residual `ytitle'"
    }

    * Make plots
    graph twoway scatter `ymean_of_bin' `bin' if `tag_bin' == 1 & `bin' > 0, ///
        mcolor("44 179 74")                                                  ///
        msize(small)                                                         ///
        xline(`ncuts', lpattern(dash) lcolor(black))                         ///
        xtitle(`xtitle')                                                     ///
        ytitle(`ytitle')                                                     ///
        scheme(s1color)
end

capture program drop plot_aggregate
program define plot_aggregate
    syntax varlist(numeric min=2) [if], [Controls(varlist)]    ///
                                        [NBins(numlist)]       ///
                                        [XBins(varlist)]       ///
                                        [GENerate(string)]     ///
                                        [XTITLE(string)]       ///
                                        [YTITLE(string)]       ///
                                         NCuts(numlist)        ///
                                         CENter(varlist)

    * Mark sample
    marksample touse

    * Parse y and x variables
    local yvar = word("`varlist'", 1)
    local xvar = word("`varlist'", 2)

    * Create bin variables
    tempvar bin tag_bin xcenter
    if "`xbins'" != "" {
        gen  `bin'     = `xbins'     if `touse'
        gen  `tag_bin' = tag_`xbins' if `touse'
    }
    else {
        gen  `xcenter'  = `xvar' - `center' if `touse'
        egen `bin'      = cut(`xcenter')    if `touse', at(`nbins')
        gegen `tag_bin' = tag(`bin')        if `touse'
    }

    * Create mean variable (residualize if controls specified)
    tempvar yresiduals ymean_of_bin fbin
    * If there are controls, residualize
    if "`controls'" != "" {
        gegen `fbin' = group(`bin')
        _regress `yvar' `controls' i.`fbin' if `touse', noheader notable
        _predict `yresiduals' if `touse', xb
        foreach control of varlist `controls' {
            replace `yresiduals' = `yresiduals' - _b[`control'] * `control'
        }
        replace `yresiduals' = `yresiduals' - _b[_cons]
        egen `ymean_of_bin' = mean(`yresiduals') if `touse', by(`bin')
    }
    * If not, just take the mean
    else {
        egen `ymean_of_bin' = mean(`yvar') if `touse', by(`bin')
    }

    * Extract variable label
    if "`ytitle'" == "" {
        local ytitle "`:var l `yvar''"
        if "`ytitle'" == "" {
          local ytitle "`yvar'"
        }
    }
    if "`controls'" != "" {
        local ytitle "Residual `ytitle'"
    }

    * Make plots
    * graph twoway scatter `ymean_of_bin' `bin' if `tag_bin' == 1, ///
    *     mcolor("44 179 74")                                      ///
    *     msize(small)                                             ///
    *     xline(`ncuts', lpattern(dash) lcolor(black))             ///
    *     xtitle(`xtitle')                                         ///
    *     ytitle(`ytitle')                                         ///
    *     scheme(s1color)
    tempvar count_of_bin
    egen `count_of_bin'    = count(`ymean_of_bin'), by(`bin')
    replace `count_of_bin' = round(`count_of_bin' / 1000)

    graph twoway (qfitci `ymean_of_bin' `bin' if `tag_bin' == 1 & `bin' <  0, ///
                        lcolor(black)                                          ///
                        acolor(gs14))                                          ///
                 (qfitci `ymean_of_bin' `bin' if `tag_bin' == 1 & `bin' >= 0, ///
                        lcolor(black)                                          ///
                        acolor(gs14))                                          ///
                 (scatter `ymean_of_bin' `bin' if `tag_bin' == 1,              ///
                       mcolor("44 179 74")                                     ///
                       msymbol(circle)                                         ///
                       msize(small)),                                          ///
        xline(`ncuts', lpattern(dash) lcolor(black))                           ///
        xtitle(`xtitle')                                                       ///
        ytitle(`ytitle')                                                       ///
        legend(off)                                                            ///
        scheme(s1mono)
end


* program define regress_rd
*     syntax varlist(numeric min=2)
* end
