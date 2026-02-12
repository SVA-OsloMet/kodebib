



*************************************************************
* Beholder kun variabler vi skal bruke, lagrer som egen fil * 
*************************************************************


use  "datafil.dta", clear
keep var1-var9 // angi variablene du vil beholde
drop *_txt //fjerner tekstvariabler
drop varx // dropper ev andre variabler
save "datagrunnlag_svarfordelinger.dta", replace

use "datagrunnlag_svarfordelinger.dta", clear

*****************************************************************
* Lag en fil med variablene i riktig rekkefølge i excel *
* Denne vil du trenge senere *

***************************************************************** 
export excel using "variabler_til_sortering.xlsx", firstrow(variables) replace

*** Fikse i excel sånn at det kun er variabelnavnene i filen, som ligger loddrett nedover på første kolonne (kolonne A). 
*** Overskrift for kolonnen skal være Spm
*** Kolonnen B kalles "sortering" og variablene nummereres fra 1 og nedover, så mange antall variabler det er.  
*** Lagre som "variabler_sortering.xlsx". Deretter lage den som stata-fil.

import excel "variabler_sortering.xlsx", sheet("Sheet1") firstrow clear 
save  "variabler_sortering.dta", replace

************************************************************************************************
* Lager svarfordeling, standardavvik og gjennomsnitt for hvert spørsmål *
* dersom man ikke ønsker å ha det i prosent, men i hundredeler, fjerne man *100 i nederste del *
************************************************************************************************



use "datagrunnlag_svarfordelinger.dta", clear


//Sjekk alle variablene og se hva som er maks antall svaralternativer. 
// I eksempelet her er 6 er det meste.
// Lager hjelpevariabler for å beregne prosent

//angi variablene som du vil ha svarfordeling på
foreach y of varlist var1-var9 {  
*Lager svarfordelingsvariabler i prosent
egen c_`y' = count(`y')

egen y_0_`y' = count(`y') if `y' == 0
egen x_0_`y' = max(y_0_`y')
gen _0_`y' = (x_0_`y' / c_`y')*100

egen y_1_`y' = count(`y') if `y' == 1
egen x_1_`y' = max(y_1_`y')
gen _1_`y' = (x_1_`y' / c_`y')*100

egen y_2_`y' = count(`y') if `y' == 2
egen x_2_`y' = max(y_2_`y')
gen _2_`y' = (x_2_`y' / c_`y')*100

egen y_3_`y' = count(`y') if `y' == 3
egen x_3_`y' = max(y_3_`y')
gen _3_`y' = (x_3_`y' / c_`y')*100

egen y_4_`y' = count(`y') if `y' == 4
egen x_4_`y' = max(y_4_`y')
gen _4_`y' = (x_4_`y' / c_`y')*100

egen y_5_`y' = count(`y') if `y' == 5
egen x_5_`y' = max(y_5_`y')
gen _5_`y' = (x_5_`y' / c_`y')*100

egen y_9999_`y' = count(`y') if `y' == 9999 //I dette tilfellet er "vet ikke" kodet til 9999
egen x_9999_`y' = max(y_9999_`y')
gen _9999_`y' = (x_9999_`y' / c_`y')*100

// Hvis du har flere svaralternativer, så lager du det videre her
/*egen y_6_`y' = count(`y') if `y' == 6
egen x_6_`y' = max(y_6_`y')
gen _6_`y' = (x_6_`y' / c_`y')*100

egen y_7_`y' = count(`y') if `y' == 7
egen x_7_`y' = max(y_7_`y')
gen _7_`y' = (x_7_`y' / c_`y')*100

egen y_8_`y' = count(`y') if `y' == 8
egen x_8_`y' = max(y_8_`y')
gen _8_`y' = (x_8_`y' / c_`y')*100

egen y_9_`y' = count(`y') if `y' == 9
egen x_9_`y' = max(y_9_`y')
gen _9_`y' = (x_9_`y' / c_`y')*100

egen y_10_`y' = count(`y') if `y' == 10
egen x_10_`y' = max(y_10_`y')
gen _10_`y' = (x_10_`y' / c_`y')*100
*/

// fjerner hjelpevariablene du lagde
drop c_`y'
drop y_0_`y' y_1_`y'  y_2_`y'  y_3_`y'  y_4_`y'  y_5_`y'  y_9999_`y' // y_6_`y' y_7_`y' y_8_`y' y_9_`y' y_10_`y' 
drop x_0_`y' x_1_`y'  x_2_`y'  x_3_`y'  x_4_`y'  x_5_`y'  x_9999_`y' // x_6_`y' x_7_`y' x_8_`y' x_9_`y' x_10_`y' 

*Lager detaljvariabler

*I antall svarende skal "Vet ikke" (9999) medregnes
egen _as_`y' = count(`y') /*antall svarende*/

*Setter "Vet ikke" lik missing for å unngå at verdien 9999 medregnes i snitt og standardavvik:
* Denne kan fjernes dersom du ønsker at vet ikke skal inngå i beregningen . Isåfall bør ikke vet ikke være 9999
replace `y' = . if `y' == 9999

egen _sn_`y' = mean(`y') /*gjennomsnitt*/
egen _std_`y' = sd(`y') /*standardavvik*/
}

**********************************
* Tar kun vare på en observasjon *
**********************************

generate caseid = _n
keep if caseid == 1

******************************************************************
* Dropper opprinnelige variabler fordi dette er individvariabler *
******************************************************************

drop var1-var9


***************************************
* Lager long-format ut av wide-format *
***************************************

reshape long _0 _1 _2 _3 _4 _5 _9999 _as _sn _std , i(caseid) j(Spm) string
browse

** Ordner variabelnavnene og sletter unødvendige variabler **
gen newvar = substr(Spm, 2, .)
replace Spm = newvar
drop newvar caseid


*****************************************
* Legger variablene i riktig rekkefølge *
*****************************************


merge 1:1 Spm using "variabler_sortering.dta"

sort sortering
browse

drop sortering _merge

**************************************
* Lager mer forståelige variabelnavn *
**************************************

rename Spm Spørsmål
rename _9999 Vet_ikke
rename _as N
rename _sn Gjennomsnitt
rename _std Standardavvik

browse

******************
* Lager excelfil *
******************

export excel using "svarfordelinger.xlsx", firstrow(variables) replace