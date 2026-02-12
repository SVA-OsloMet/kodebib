
*************************************************

* Lager excel-ark med gjennomsnittsverdi på alle likert-spørsmål i en survey**

*************************************************

//Hent inn fil med surveyresultater

use "datafil.dta", clear

// beholde kun de variablene du vil ha med

keep var1-var9
drop varx

// Lager en id-variabel som vi bruker til å telle
// plasser den først i datasettet

gen utvalgn = _n
order utvalgn, before(var1)
gen N = 1
order N, before(var1)

// legg ev bakgrunnsvariabler først, f.eks. hvis man ønsker fordelt på kjønn, alder eller Fylke som her
order Fylke, before (var1)
order Kjonn, before (var1)

** antall som har svart pr fylke
bysort Fylke: egen antall_fylke = count(utvalgn)
tab Fylke antall_fylke


** antall som har svart pr kjønn
bysort Kjonn: egen antall_kjonn = count(utvalgn)
tab Kjonn antall_kjonn


** TOTAL **
preserve
collapse (mean) s_* x_* 
export excel "gjennomsnitt.xlsx", sheet("I alt") firstrow(variables) sheetreplace
restore

** Fylke **
preserve
collapse (mean) s_* x_*, by (Fylke antall_fylke)
export excel "gjennomsnitt.xlsx", sheet("Fylke") firstrow(variables) sheetreplace
restore


** Kjønn **
preserve
collapse (mean) s_* x_*, by (Kjonn antall_kjonn)
export excel "gjennomsnitt.xlsx", sheet("Kjønn") firstrow(variables) sheetreplace
restore
