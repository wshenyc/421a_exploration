library(tidyverse)
library(ggplot2)

###Set up####
#first, we're going to identify each 421a building
codes <- read_csv("Exemption_Classification_Codes_20251013.csv")

codes_421a <- codes %>% 
  janitor::clean_names() %>% 
  filter(str_detect(legal_ref, "421A")) %>% 
  select(exempt_code, sdea_code, description) %>% 
  filter(!str_detect(exempt_code, "-C")) %>% #removing the construction ones?
  mutate(exempt_code = as.integer(exempt_code)) 

#okay the problem is I don't really know what all of this means

exemptions <- read.csv("Property_Exemption_Detail_20251013.csv") 
#this is pre-filtered to everything with an exemption code that starts with 5

exemptions_421a <- exemptions %>% 
  janitor::clean_names() %>% 
  filter(exmp_code %in% c(codes_421a$exempt_code)) %>% 
  select(parid, #BBL 
         boro, block, lot, ease, 
         year,  #fiscal year 
         period, # 0 means prior, 1 means tentative, 3 means final?
         exmp_code, exmp_code_suffix, exmp_seq, nys_exmp_code,
         pstatus, #lots of different options
         coop_num, condo_number, condo_sfx, #idk if knowing if something's a coop/condo could be useful?
         cbnexmptrn,#transitional exemption amount, value as of the end of the Change by Notice period
         finexmptrn, #Transitional Exemption Amount, value as of the end of the final period
         curexmptrn, #transitional exemption amount, most current value
         create_date, #exemption creation date YYYYMMDD
         exname, #exemption name
         status, #exemption status code, lots of options
         pypartialpct, #exemption partial percentage factor
         no_years, #number of years per given exemption
         baseyr, #pre-exemption assessment year start and end
         benftstart, #?
         eff_date, #?
         bldg_class,
         fintaxclass) %>% 
  left_join(codes_421a, by = c("exmp_code"="exempt_code"))

###421a SURCHARGES####

####421a (16) buildings####

#okay according to HPD and HCR, no surcharges can be collected from 421-a(16)
codes_16 <- c(5519, 5120, 5121, 5122, 5123)

exemptions_surcharge <- exemptions_421a %>% 
  mutate(surcharge_collectible = case_when(exmp_code %in% codes_16 ~ 
                                             "No, receives 421-a(16)"))

#cannot be collected from aff units built without govt assistance?

#cannot be collected from aff units built with assistance and are subject to 
#a reg agreement

#Geographic Exclusion Area




###421a RENT STABILIZATION####

#then we're going to map it
#which is going to require geocoding