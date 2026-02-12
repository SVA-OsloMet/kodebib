***************************************
*  EDUCATION in a given calendar year, making broader categories and make variable with education at age 30
***************************************
*Completed education
*Registerdata from SSB

*merging education file with original file
use Prosjektnavn_analysefil
merge 1:1 w21_5590_lopenr_person using W21_5590_BU_UTD.dta
drop _merge
rename bu* education*
foreach var of varlist education* {
    label variable `var' "Educational level (NUS) 1.october given year"
}
save, replace


*broader categories of education
	*include missing in first category
	*Include basic secondary education in first category as well

forvalues i = 1997(1)2020 {
	gen education_level_`i' = substr(education_`i', 1, 1)
	destring education_level_`i', replace
	lab var education_level_`i' "Educational level  1.oct given year"
	label values education_level_`i' educational_level
}


*Education at age 30
gen education_30_cat =.
lab var education_30_cat "Category (4) of highest completed education at 30 years"
forvalues i = 1997(1)2020 {
	replace education_30_cat=education_level_`i' if  `i'==(birthyear + 30)
}
replace education_30_cat = 0 if education_30_cat==0 | education_30_cat==1 | education_30_cat==2 | education_30_cat==3  | education_30_cat==.
replace education_30_cat = 1 if education_30_cat==4 | education_30_cat==5
replace education_30_cat = 2 if education_30_cat==6  
replace education_30_cat = 3 if education_30_cat==7 | education_30_cat==8
label define education_30_catl 0 "No secondary educ"  1 "Completed upper secondary school" 2 "Undergradtate level" 3 "Graduate/postgraduate level" 
label values education_30_cat education_30_catl

save, replace