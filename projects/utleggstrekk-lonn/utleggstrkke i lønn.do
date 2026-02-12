
				***UTLEGGSTREKK I LØNN***


* 1, Årmnd fil
* 2, Årsfil som summerer antall mnd med utteggstrekk per år (2015-2022). wide og long


* * 1, Årmnd fil

import delimited "N:\durable\solvens-data\01_rawdata_2024\sifo_solvens_utleggstrekk_lonn_databricks.csv", varnames(1)

drop _rescued_data 
save "N:\durable\solvens-data\01_rawdata_2024\utleggstrekk_lonn.dta", replace



*Lager nye datovariabler 
* Fra string til datoformat

gen registreringsdato_d = date(registreringsdato, "YMD")
format registreringsdato_d %td

gen slettedato_d = date(slettedato, "YMD")
format slettedato_d %td


* År og mnd variabler
gen registrering_aar= year(registreringsdato_d)
gen registrering_mnd= month(registreringsdato_d)

gen sletting_aar= year(slettedato_d)
gen sletting_mnd= month(slettedato_d)

*Finner ut antall år 

tab registrering_aar


*Konstruerer ny registeringsdato 

gen reg_dato= 0

forvalues i=2015/2022 { 
replace reg_dato=`i'01 if registrering_aar==`i' & registrering_mnd==1 
replace reg_dato=`i'02 if registrering_aar==`i' & registrering_mnd==2 
replace reg_dato=`i'03 if registrering_aar==`i' & registrering_mnd==3 
replace reg_dato=`i'04 if registrering_aar==`i' & registrering_mnd==4 
replace reg_dato=`i'05 if registrering_aar==`i' & registrering_mnd==5 
replace reg_dato=`i'06 if registrering_aar==`i' & registrering_mnd==6 
replace reg_dato=`i'07 if registrering_aar==`i' & registrering_mnd==7 
replace reg_dato=`i'08 if registrering_aar==`i' & registrering_mnd==8
replace reg_dato=`i'09 if registrering_aar==`i' & registrering_mnd==9
replace reg_dato=`i'10 if registrering_aar==`i' & registrering_mnd==10
replace reg_dato=`i'11 if registrering_aar==`i' & registrering_mnd==11
replace reg_dato=`i'12 if registrering_aar==`i' & registrering_mnd==12

}

*Konstruerer ny slettedato 

gen slette_dato= 0

forvalues i=2015/2022 { 
replace slette_dato=`i'01 if sletting_aar==`i' & sletting_mnd==1 
replace slette_dato=`i'02 if sletting_aar==`i' & sletting_mnd==2 
replace slette_dato=`i'03 if sletting_aar==`i' & sletting_mnd==3 
replace slette_dato=`i'04 if sletting_aar==`i' & sletting_mnd==4 
replace slette_dato=`i'05 if sletting_aar==`i' & sletting_mnd==5 
replace slette_dato=`i'06 if sletting_aar==`i' & sletting_mnd==6 
replace slette_dato=`i'07 if sletting_aar==`i' & sletting_mnd==7 
replace slette_dato=`i'08 if sletting_aar==`i' & sletting_mnd==8
replace slette_dato=`i'09 if sletting_aar==`i' & sletting_mnd==9
replace slette_dato=`i'10 if sletting_aar==`i' & sletting_mnd==10
replace slette_dato=`i'11 if sletting_aar==`i' & sletting_mnd==11
replace slette_dato=`i'12 if sletting_aar==`i' & sletting_mnd==12

}


*Lager variabler med måneder utleggstrekk i lønn. Får verdi 1 hvis utleggstrekk i den gitte måneden
* Slettedato 0 betyr at utlegget fortsatt pågår 

forvalues i=2015/2022 { 
gen Utlegg_lonn_`i'_01 = 0 
replace Utlegg_lonn_`i'_01 = 1 if reg_dato<=`i'01 & (slette_dato>=`i'01 | slette_dato== 0)
gen Utlegg_lonn_`i'_02 = 0 
replace Utlegg_lonn_`i'_02 = 1 if reg_dato<=`i'02 & (slette_dato>=`i'02 | slette_dato== 0)
gen Utlegg_lonn_`i'_03 = 0 
replace Utlegg_lonn_`i'_03 = 1 if reg_dato<=`i'03 & (slette_dato>=`i'03 | slette_dato== 0) 
gen Utlegg_lonn_`i'_04 = 0 
replace Utlegg_lonn_`i'_04 = 1 if reg_dato<=`i'04 & (slette_dato>=`i'04 | slette_dato== 0) 
gen Utlegg_lonn_`i'_05 = 0 
replace Utlegg_lonn_`i'_05 = 1 if reg_dato<=`i'05 & (slette_dato>=`i'05 | slette_dato== 0)
gen Utlegg_lonn_`i'_06 = 0 
replace Utlegg_lonn_`i'_06 = 1 if reg_dato<=`i'06 & (slette_dato>=`i'06 | slette_dato== 0)
gen Utlegg_lonn_`i'_07 = 0 
replace Utlegg_lonn_`i'_07 = 1 if reg_dato<=`i'07 & (slette_dato>=`i'07 | slette_dato== 0)
gen Utlegg_lonn_`i'_08 = 0 
replace Utlegg_lonn_`i'_08 = 1 if reg_dato<=`i'08 & (slette_dato>=`i'08 | slette_dato== 0)
gen Utlegg_lonn_`i'_09 = 0 
replace Utlegg_lonn_`i'_09 = 1 if reg_dato<=`i'09 & (slette_dato>=`i'09 | slette_dato== 0) 
gen Utlegg_lonn_`i'_10 = 0 
replace Utlegg_lonn_`i'_10 = 1 if reg_dato<=`i'10 & (slette_dato>=`i'10 | slette_dato== 0)
gen Utlegg_lonn_`i'_11 = 0 
replace Utlegg_lonn_`i'_11 = 1 if reg_dato<=`i'11 & (slette_dato>=`i'11 | slette_dato== 0)
gen Utlegg_lonn_`i'_12 = 0 
replace Utlegg_lonn_`i'_12 = 1 if reg_dato<=`i'12 & (slette_dato>=`i'12 | slette_dato== 0)

}


* Noen kan ha flere utleggstrekk samtidig
* Finner alle månedsregisteringer innen samme person og lager nye variabler som angir totalen

forvalues i=2015/2022 {
egen Utlegg_lonn_`i'01= total (Utlegg_lonn_`i'_01), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'02= total (Utlegg_lonn_`i'_02), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'03= total (Utlegg_lonn_`i'_03), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'04= total (Utlegg_lonn_`i'_04), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'05= total (Utlegg_lonn_`i'_05), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'06= total (Utlegg_lonn_`i'_06), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'07= total (Utlegg_lonn_`i'_07), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'08= total (Utlegg_lonn_`i'_08), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'09= total (Utlegg_lonn_`i'_09), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'10= total (Utlegg_lonn_`i'_10), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'11= total (Utlegg_lonn_`i'_11), by (w22_1383_lopenr_person)
egen Utlegg_lonn_`i'12= total (Utlegg_lonn_`i'_12), by (w22_1383_lopenr_person)

}


** Dobbeltsjekker
forvalues i=2015/2022 {
tab Utlegg_lonn_`i'01
tab Utlegg_lonn_`i'02
tab Utlegg_lonn_`i'03
tab Utlegg_lonn_`i'04
tab Utlegg_lonn_`i'05
tab Utlegg_lonn_`i'06
tab Utlegg_lonn_`i'07
tab Utlegg_lonn_`i'08
tab Utlegg_lonn_`i'09
tab Utlegg_lonn_`i'10
tab Utlegg_lonn_`i'11
tab Utlegg_lonn_`i'12
}


* Tillegger observasjoner med samme forløpsdatoer verdien 1 
* Alle får verdi 1, hvis de har uttleggstrekk

forvalues i=2015/2022 {
replace Utlegg_lonn_`i'01= 1 if Utlegg_lonn_`i'01 > 1
replace Utlegg_lonn_`i'02= 1 if Utlegg_lonn_`i'02 > 1 
replace Utlegg_lonn_`i'03= 1 if Utlegg_lonn_`i'03 > 1 
replace Utlegg_lonn_`i'04= 1 if Utlegg_lonn_`i'04 > 1
replace Utlegg_lonn_`i'05= 1 if Utlegg_lonn_`i'05 > 1 
replace Utlegg_lonn_`i'06= 1 if Utlegg_lonn_`i'06 > 1 
replace Utlegg_lonn_`i'07= 1 if Utlegg_lonn_`i'07 > 1 
replace Utlegg_lonn_`i'08= 1 if Utlegg_lonn_`i'08 > 1
replace Utlegg_lonn_`i'09= 1 if Utlegg_lonn_`i'09 > 1 
replace Utlegg_lonn_`i'10= 1 if Utlegg_lonn_`i'10 > 1 
replace Utlegg_lonn_`i'11= 1 if Utlegg_lonn_`i'11 > 1 
replace Utlegg_lonn_`i'12= 1 if Utlegg_lonn_`i'12 > 1

}


*Finner duplikater innen samme person
sort w22_1383_lopenr_person
quietly by w22_1383_lopenr_person :  gen dup = cond(_N==1,0,_n) 
tab dup
drop if dup>1 //beholder kun først observasjon, 1,726,471 observations deleted	 
drop dup	 


* Beholder kun de variablene som trengs videre 
drop reg_dato slette_dato registreringsdato slettedato registreringsdato_d slettedato_d	registrering_aar registrering_mnd sletting_aar sletting_mnd Utlegg_lonn_2015_01 - Utlegg_lonn_2022_12
	
save "N:\durable\solvens-data\02_tidy_nodup\utleggstrekk_lonn_aarmnd_nodup.dta", replace

* 2, Årsfil som summerer antall mnd med utteggstrekk per år

* Lager variabel som summerer antall måneder med uttleggstrekk per år 
egen sum_utlegg_lonn_2015 = rowtotal(Utlegg_lonn_201501 - Utlegg_lonn_201512)
egen sum_utlegg_lonn_2016 = rowtotal(Utlegg_lonn_201601 - Utlegg_lonn_201612)
egen sum_utlegg_lonn_2017 = rowtotal(Utlegg_lonn_201701 - Utlegg_lonn_201712)
egen sum_utlegg_lonn_2018 = rowtotal(Utlegg_lonn_201801 - Utlegg_lonn_201812)
egen sum_utlegg_lonn_2019 = rowtotal(Utlegg_lonn_201901 - Utlegg_lonn_201912)
egen sum_utlegg_lonn_2020 = rowtotal(Utlegg_lonn_202001 - Utlegg_lonn_202012)
egen sum_utlegg_lonn_2021 = rowtotal(Utlegg_lonn_202101 - Utlegg_lonn_202112)
egen sum_utlegg_lonn_2022 = rowtotal(Utlegg_lonn_202201 - Utlegg_lonn_202212)	 
	
	
sum sum_utlegg_lonn_2015-sum_utlegg_lonn_2022

* Beholder kun de variablene som trengs videre 
drop Utlegg_lonn_201501-Utlegg_lonn_202212
duplicates report w22_1383_lopenr_person

save "N:\durable\solvens-data\02_tidy_nodup\utleggstrekk_lonn_aar_nodup.dta", replace

reshape long sum_utlegg_lonn_, i(w22_1383_lopenr_person) j(aar)
sort w22_1383_lopenr_person aar
label variable sum_utlegg_lonn_ "Antall måneder med uttleggstrekk"


* Lager en dikotom variabel for å ha hatt utteggstrekk i det gitte året
gen utlegg_lonn =.
forvalues k = 2015(1)2022 {
	replace utlegg_lonn = sum_utlegg_lonn_ >0 if aar==`k'
}
label variable utlegg_lonn "Utleggstrekk i lønn"

*Finner duplikater innen samme person
sort w22_1383_lopenr_person aar
quietly by w22_1383_lopenr_person aar :  gen dup = cond(_N==1,0,_n) 
tab dup
drop if dup>1 //beholder kun først observasjon	 
drop dup


sort w22_1383_lopenr_person aar
save "N:\durable\solvens-data\02_tidy_nodup\utleggstrekk_lonn_aar_long_nodup.dta", replace
clear all