# Formål: Lage data om befolkningsutvikling i norske kommuner 1990-2023.
# Kommunestrukturen har vært endret i perioden, og i denne analysen kan befolkningen slås sammen når kommunene slås sammen.
# Om formålet i stedet var å analysere politisk utvikling må alle sammenslåinger utelates.

# devtools::unload("MASS")
library(tidyverse)
library(rio)


# 1. import koblingsnøkkel -----------------------------------------------------
setwd("~/Library/CloudStorage/OneDrive-OsloMet/R/Kommunedata") # directory
key <- import("koblingsnokkel_kommuneendringer_1990_2024.xlsx")
str(key)

# mellom 1990 og 1994 var det små endringer i kommunestrukturen, og i hovedsak ble bare småkommuner innlemmet i Arendal, Fredrikstad og Sarpsborg. 
# lager korresponderende kommunenumre for alle kommuner som er geografisk uendret siden 1990

# prep koblingsnøkkel
# trenger følgende info i koblingsnøkkel: gammel id, ny id, endringstidspunkt. 
df_key <- key %>%
  # velg tidsrom for endringer i kommunestruktur:
  filter(maal_gyldig_fra %in% 1990:2023) %>%  # utelater 2024-endringer her
  # filter(TypeOfChange %in% c("Sammenslåing", "Kodeendring")) %>%
  mutate(id_gammel = as.character(id_gammel)) %>%  # kommunenummer som starter på 0 må beholdes som de er
  select(id_gammel, id_ny, endring_tid = maal_gyldig_fra, endring = TypeOfChange, kommune = maal_kommune, kommune_old = kilde_kommune)

# prepare key
df_key_deling <- df_key %>% filter(endring %in% c("Deling", "Deling, sammenslåing"))  # i 2020 ble 6 kommuner delt, og 2 kommuner ble delt i 2017.
df_key <- df_key %>% filter(!endring %in% c("Navneendring", "Deling", "Deling, sammenslåing"))  # for å gjøre dette riktig må disse utelates enn så lenge
# navneendring er jo egentlig irrelevant -- det påvirker ikke befolkning eller id. 
# deling er mer komplekst -- her kan vi ikke lage tidsserier hvor det ser ut som kommunene har stupt i befolkningsstørrelse. disse 8 må holdes utenfor

# hvordan håndterer vi befolkningsvekst i kommuner som er sammenslått? forslag: se på endringer i mellomperioder (særlig før 2020-sammenslåinger).
# dette burde være uproblematisk, siden kommunevalget var i 2019 og sammenslåinger skjedde 1.1.2020.



# 2. import historisk befolkningsdata i kommuner -------------------------------
df <- import("~/Library/CloudStorage/OneDrive-OsloMet/R/Kommunedata/Historiske data/Befolkning kommuner 1990-2023.xlsx")

# split info i kolonnene
df <- df %>%
  mutate(
    id = str_extract(kommune, "^\\d+"),  # extract numerisk id i starten
    tid = str_extract(kommune, "\\d{4}-\\d{4}|-\\d{4}"),  # extract numerisk tidsperiode i YYYY-YYYY format
    kommune = str_replace(kommune, "^\\d+\\s+", ""),  # fjern id fra starten
    kommune = str_replace(kommune, "\\s*\\(\\d{4}-\\d{4}\\)$", ""),  # fjern tidsperiode i parantes fra ende
    kommune = str_replace(kommune, "\\s*\\(-\\d{4}\\)$", ""),  # fjern tidsperiode i parantes fra ende
    kommune = str_replace_all(kommune, "\\s*\\([^)]*\\)$", "")  # fjern spor av tekst i paranteser
  ) %>%
  mutate(id = as.character(id)) %>% 
  relocate(tid, .after = kommune)

# rens data -- dropp rader med bare 0
df <- df %>% 
  rowwise() %>%
  filter(any(c_across(`1990`:`2023`) != 0)) %>%
  ungroup()

# rename pop-variabler (befolkning)
df <- df %>% 
  rename_with(~ paste0("pop_", .), .cols = `1990`:`2023`) %>% 
  mutate(kommune_old = NA)  # lag tom variabel for å gjøre datasett identiske med det transformerte datasettet

# fiks tid i df
df <- df %>% mutate(tid = as.numeric(str_extract(tid, "(\\d{4})$")) + 1)  # -1991 would become 1992

## Prinsipper: Iterasjon over år (tid). I hvert steg vil vi 1) join ny id, og 2) reframe.
# table(df$tid)
sort(unique(na.omit(df$tid)))  # år som itereres over



# 3. merge befolkningsdata -----------------------------------------------------
# koper dataframe: gjør prosessen repeterbar
agg_df <- df %>% 
  mutate(tid = ifelse(tid == 2024, 2020, tid))  # reset merger-tid for å korrespondere med key (koblingsnøkkel)

# sort(unique(na.omit(df$tid)))  # kommunens siste eksisterende tidspunkt + 1
# sort(unique(na.omit(df_key$endring_tid)))  # året endring tredde i kraft

#### iterasjon over år (tid)
for (year in sort(unique(na.omit(df$tid)))) {

  # steg 1: add id to merge on
  agg_df <- agg_df %>%
    select(-any_of("id_ny")) %>%                      # fjern kolonnenid_ny hvis den eksisterer
    left_join(df_key[df_key$endring_tid == year,],    # spesifiser år (loopes over)
              by = c("id" = "id_gammel")) %>%         # join by kommunenummer før/etter
    mutate(kommune = coalesce(kommune.y, kommune.x),  # navn på kommune er det nye navnet, kommune.y (joinet fra koblingsnøkkel). 
           kommune_old = coalesce(kommune_old.y, kommune_old.x),
           .keep = "unused") %>%                   # kommuner uberørt av endring dette året får beholde sitt gamle navn, kommune.x
    relocate(id_ny, .after = id) %>% 
    relocate(starts_with("kommune"), .after = id_ny)
  
  
  # steg 2: grupper etter mapping-indikator & reframing
  agg_df2 <- agg_df %>% 
    mutate(merge_group = if_else(endring_tid == year,     # årsvariabel her.
                                 coalesce(id_ny, id), NA_character_)) %>% 
    filter(!is.na(merge_group)) %>%          # kun berørte kommuner skal merges hvert år
    group_by(merge_group) %>%
    reframe(
      id = coalesce(id_ny),
      kommune = coalesce(kommune),
      kommune_old = paste(unique(na.omit(c(kommune_old))), collapse = "/"),  # splicer navn
      tid = ifelse(is.na(tid), 0, max(tid)),  # valgte enheter bør ha tidsinformasjon -- bare uberørte kommuner mangler (hvis de er i datasettet settes det til 0)
      across(pop_1990:pop_2023, ~sum(.x, na.rm = TRUE))) %>% 
    ungroup() %>% 
    select(-merge_group) %>%
    unique()
  
  cat("Number of new units after merging:", nrow(agg_df2), "in year:", year)
  
  # steg 3: legg sammen sammenslåtte og uberørte rader (kommuner) i ny dataframe
  agg_df2 <- agg_df %>%
    filter(is.na(id_ny)) %>%
    bind_rows(agg_df2) %>% 
    select(-c(id_ny, endring, endring_tid)) # disse kolonnene er tomme nå
  
  # output
  paste0("Reframing eliminated ", nrow(agg_df) - nrow(agg_df2), " rows")
  
  # endrede rader:
  print(anti_join(agg_df, agg_df2, 
                  by = intersect(names(agg_df), names(agg_df2))))
  
  # noen uønskede duplikater som kan fjernes?:
  print(paste("Duplicate rows in", year, ":", agg_df %>% group_by(id) %>% select(-tid, kommune_old) %>% duplicated() %>% table()))
  
  # reset prosessen før neste iterasjon
  agg_df <- agg_df2
}



## siste del med oppvask -------------------------------------------------------
# sjekk: duplikater som kan fjernes?
# print(paste("Duplicate rows in", year, agg_df %>% group_by(id) %>% select(-tid, kommune_old) %>% duplicated() %>% table()))  # count duplicates
agg_df %>% 
  group_by_at(vars(-tid)) %>% 
  filter(n() > 1)  # 3 duplikat-kommuner

# fjern duplikater (spesifikt de med missing tid
agg_df <- agg_df %>%
  arrange(is.na(tid)) %>%  
  distinct(across(-tid), .keep_all = TRUE)

## siste: merge nummer-endringer i 2020
agg_df <- agg_df %>% 
  group_by(id) %>%
  # en siste reframe
  reframe(
    kommune = coalesce(kommune),
    kommune_old = paste(unique(na.omit(c(kommune_old))), collapse = "/"),  # splicer navn
    tid = ifelse(is.na(tid), 0, max(tid)),      # nå får alle enheter tid = 0, NAs kan droppes
    across(pop_1990:pop_2023, ~sum(.x, na.rm = TRUE))) %>% 
  ungroup() %>% 
  unique() %>% 
  filter(!is.na(tid))

# kontroller mot hele landets befolkning, hentet fra SSB
sjekk_ssb <- tribble(
  ~id, ~pop_1990, ~pop_1999, ~pop_2015, ~pop_2019, ~pop_2020,
  "Hele landet", 4233116, 4445329, 5165802, 5328212, 5367580)

# sjekk summen 
sjekk_agg_df <- agg_df %>% 
  summarise(across(pop_1990:pop_2023, ~sum(.x, na.rm = TRUE))) %>% 
  select(pop_1990, pop_1999, pop_2015, pop_2019, pop_2020) %>% 
  mutate(id = "Resultat")

sjekk <- bind_rows(sjekk_agg_df, sjekk_ssb)  # avviket mellom resultatet og reelle SSB-tall er rundt 6700-8300 for mange

# dropp 6 delte kommuner, inkl. Snillfjord og Stokke
agg_df <- agg_df %>% 
  filter(pop_2023 > 0, 
         pop_1990 > 0)



# 4. kontroll: antall riktige beregninger --------------------------------------
# sjekk mot fasit 2023: 
fasit <- df %>%  # df er det originale datasettet med befolkningstall for alle historiske kommuner
  filter(pop_2023>0) %>% 
  mutate(kontroll = pop_2023) 

# så sjekker vi befolkningen i de aggregerte/harmoniserte kommunene. 
# er befolkningen riktig summert i sammenslåtte kommuner?
matcher <- agg_df %>% 
  left_join(select(fasit, kontroll, id), by = "id", suffix = c("test", "fasit")) %>% 
  arrange(id) %>% 
  mutate(kontroll = as.numeric(kontroll))

# sjekk avvik mellom fasit og aggregerte tall
table(matcher$pop_2023 == matcher$kontroll, useNA = "always")  # 357 matcher, 0 NA (pga delte kommuner er utelatt!)

# dvs. at ingen kommuner har blitt aggregert/splicet på en måte som gir feil befolkningstall i 2020.
# likevel er det et lite avvik på ca. 6-8k hvert år, når en sjekker mot summen av kolonnene før merging (og SSBs befolkningsdata for hele landet)



# 5. output --------------------------------------------------------------------

# eksporter
export(agg_df, "historisk_befolkning_kommuner2020.rds")



# 6. kart ----------------------------------------------------------------------
# sjekk på kart: gir tallene mening?
library(tmap)  # kart
library(sf)    # import geodata
library(rmapshaper)  # reduserer filstørrelse kart
options(scipen = 999)  # scientific notation penalty (ikke print typ 1e6)

# shapes (sf objects) validitetssjekkes med st_is_valid og fikses med st_make_valid:
tmap_options(check.and.fix = TRUE)  

# kommunegrenser
no_geo_municipalities <- st_read("kommuner2021_simplified.geojson")

# join borders to population data
geodata <- left_join(no_geo_municipalities, agg_df, by = c("Kommunenummer" = "id"))

# tmap_mode("view") # Aktiver interaktiv plotting med leaflet: Layers can be turned on and off!
ttm() # toggles interactive on/off!

# test plotting
tm_shape(shp = geodata) + 
  tm_borders() + 
  tm_polygons(col = c("pop_change90_20"), palette = "viridis", alpha = 0.7,
              popup.vars = c("Kommunenavn", "Befolkningsendring 1990-2020" = "pop_change90_20"),
              breaks = c(0, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2, Inf)
              ) +
  tm_facets(as.layers = TRUE)


