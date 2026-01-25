library(tidyverse)

`%notin%` = Negate(`%in%`)

####DOF####
#exemption codes
#https://data.cityofnewyork.us/City-Government/Exemption-Classification-Codes/myn9-hwsy/data_preview

exmp_code <- read_csv("Raw Data/Exemption_Classification_Codes_20260125.csv") %>% 
  janitor::clean_names() %>% 
  filter(grepl("421A", legal_ref) &
           !grepl("-C", exempt_code)) #just looking at 421a, ignoring construction

exmp_421a16 = c("5119","5120", "5121", "5122", "5123")

#for the pre-421a16 codes
#https://www.nyc.gov/assets/finance/downloads/pdf/03pdf/421a.pdf
phase_out = data.frame(exmp_code = c("5110","5113", "5114","5116","5117","5118"),
                       phase_out_start = c(3, 12, 22, 13, 3, 12))

#this is pre-filtered to just 421a based on col NYS_EXMP_CODE, if that is equal to 48806
#https://data.cityofnewyork.us/City-Government/Property-Exemption-Detail/muvi-b6kx/data_preview 
dof <- read_csv("Raw Data/Property_Exemption_Detail_20260125.csv") %>% 
  janitor::clean_names() %>%
  select(parid, boro, block, lot, exmp_code,
         year, period,
         benftstart, eff_date, no_years,
         condo_number, condo_sfx, coop_num) %>% 
  filter(period == 3 & #period = 3 values as of the final roll, which I assume is all I should care about
           is.na(condo_sfx)) %>% #just looking at the entire condo, don't care about individual units
  group_by(parid) %>% 
  slice_max(year, with_ties = F) %>% #assuming we only care about the most recent year
  ungroup() %>% 
  mutate(exmp_code = as.character(exmp_code)) %>% 
  left_join(select(exmp_code, exempt_code, description), by = c("exmp_code"="exempt_code"))

dof_year <- dof %>% 
  left_join(phase_out, by = "exmp_code") %>% 
  select(!c(no_years, eff_date)) %>% 
  mutate(benefit_year = case_when(!grepl("EXT", description) ~ as.numeric(str_extract(description, "(..)(?=\\s?YR)")),
                                  grepl("10 YR EXT", description) ~ as.numeric(str_extract(description, "(..)(?=\\s?YR)")) + 10,
                                  grepl("15 YR EXT", description) ~ as.numeric(str_extract(description, "(..)(?=\\s?YR)")) + 15),
         exmp_end = benftstart + benefit_year - 1, #because year 0 is year 1 of benefit
         current_benefit_year = case_when(exmp_end >= year(Sys.Date()) ~ as.character(year(Sys.Date()) + 1 - benftstart),
                                          exmp_end < year(Sys.Date()) ~ "Expired"),
         flag_421a16 = if_else(exmp_code %in% exmp_421a16, "Yes","No"), #can't collect surcharge
         flag_phasing = case_when(flag_421a16 == "Yes" ~ NA,
                                  current_benefit_year == "Expired" ~ NA,
                                  as.numeric(current_benefit_year) >= phase_out_start ~ "Yes",
                                  as.numeric(current_benefit_year) < phase_out_start ~ "No"))
         

#dof_year %>% write_csv("Created Data/dof_421a_detail.csv")


###checking DOF data####
#there are 19 exemptions where no of years is equal to 0, which feels random 
sum(dof$no_years==0)

sum(is.na(dof$benftstart))

sum(dof$benftstart==0)
#one random exemption where benftstart is 0, but there's always a value of some sort 
#so im going to assume this is a reliable enough column to work off of 

#filter(benefit_year != no_years) 
#about 6k exemptions where DOF's no of years does not equal benefit years, why is that?
#going to ignore no of years as a result 



####construction start dates####
#my understanding is that this based off of permit issuance dates 
#source: https://data.cityofnewyork.us/Housing-Development/DOB-Job-Application-Filings/ic3t-wcy2/data_preview
#pre-filtered to job types of NB and doc # 01

lots_421a <- read_csv("Created Data/dof_421a_detail.csv")

dob <- read_csv("Raw Data/DOB_Job_Application_Filings_20260125.csv") %>% 
  janitor::clean_names() 

#i really need 1 job per BBL
#okay presumably a permit will happen before the exemption start date
#so i need to find the job permit with a date that comes after that and hopefully that works
hdb <- read_csv("Raw Data/HousingDB_post2010.csv") %>% 
  janitor::clean_names() %>% 
  filter(job_type == "New Building" & job_status %notin% c("1. Filed Application",
                                                           "2. Approved Application"),
         bbl %in% c(lots_421a$parid))

hdb_small <- hdb %>% 
  select(job_number,
         job_status, permit_year, complt_year, class_a_net, bbl, address_num, address_st, date_permit) %>% 
  group_by(bbl) %>% 
  slice_min(date_permit, with_ties = F) %>% 
  ungroup() 

hdb_joined <- lots_421a %>% 
  left_join(hdb_small, by = c("parid"="bbl")) #4201 unmatched


dob_cleaned <- dob %>% 
  select(job_number, doc_number, borough, house_number, street_name,
         block, lot, bin_number, job_status, job_status_descrp,
         approved, fully_permitted, signoff_date) %>% 
  unique() %>% #randomly there's duplicate rows?
  mutate(bbl = paste0(substr(job_number, 1,1), 
                      sprintf("%05d", as.numeric(block)), 
                      sprintf("%04d", as.numeric(lot)))) %>% 
  filter(bbl %in% c(lots_421a$parid))


dob_small <- dob_cleaned %>% 
  mutate(approved = mdy(approved)) %>% #entire job has been approved by the plan examiner, applicant can now pull a permit
  group_by(bbl) %>% #same thing, multiple buildings on a lot, different job numbers
  slice_min(fully_permitted, with_ties = F)

#joining the dob bis and hdb data   
hdb_dob <- hdb_joined %>% 
  mutate(parid_join = as.character(parid)) %>% 
  left_join(select(dob_small,
                   job_number, doc_number,
                   job_status, job_status_descrp,
                   approved,
                   fully_permitted, signoff_date, bbl), by = c("parid_join"="bbl")) %>% #a lot of dates missing
  mutate(signoff_date = mdy(signoff_date),
    likely_pre_2008 = if_else(benftstart <= 2008, "Yes","No"),
         any_date = if_else(is.na(approved) & 
                              is.na(date_permit) &
                              likely_pre_2008 == "No", 
                            "No Date", "Fine"))

#387 rows arent matching to a permit
missing_dates <- hdb_dob %>% 
  filter(any_date == "No Date" & flag_421a16 == "No")  #okay it seems like the problem is sometimes tax lots have merged

#these would be the ones i would want to scrape for tax lot data
#missing_dates %>% write_csv("missing_date.csv")

####surcharge and stabilization flags####
permit_phase_lots_421a <- hdb_dob %>% 
  select(-c(job_number.x:job_status_descrp, any_date)) %>% 
  mutate(year_comp = year(signoff_date),
         year_comp_35 = year_comp + 34, #i have no idea if this is how this works
         approved_display = if_else(is.na(approved) & likely_pre_2008 == "Yes", "Likely pre-2008", as.character(format(approved, "%b %d, %Y"))),
         approved = if_else(is.na(approved) & likely_pre_2008 == "Yes", mdy("01-01-2008"), approved), #BOLD assumption im making here
    rent_stab_status_inc = case_when(flag_421a16 == "No" & approved < mdy("07-01-2008") ~ 
                                      "In buildings that began construction before 7/1/08, income-restricted units built without govt assistance cannot be deregulated until the first vacancy after the benefit expires. Units under a reg agreement remain stabilized until that agreement expires.",
                                      flag_421a16 == "No" & (approved >= mdy("07-01-2008") & approved <= mdy("12-31-2015")) ~
                                        "In buildings that started construction between 7/1/08 and 12/31/15, income-restricted units must remain rent stabilized for 35 years after construction is completed. Tenants in these units may remain rent stabilized as long as they live in the unit.",
                                     flag_421a16 == "Yes" ~ 
                                       "421-a(16) income-restricted units must remain rent stabilized for 35 years after building completion, or 40 years for buildings with 300+ units in certain Enhanced Affordability Areas. Tenants remain rent stabilized for as long as they live in the unit.",
                                     is.na(approved) ~ "Working on finding the permit approved date!",
                                     approved > mdy("12-31-2015") ~ 
                                       "Working on figuring out what a construction start date after Dec 31, 2015 for a 
                                     non-421-a(16) building means for its rent stabilization status!"),
         rent_stab_status_mr = case_when(flag_421a16 == "No"& approved < mdy("07-01-2008") ~ 
                                           "In buildings that began construction before 7/1/08, market-rate units may be deregulated at the first lease renewal after the benefit expires, if prior & renewal leases had a notice stating the unit will be deregulated and a date for the deregulation.",
                                         flag_421a16 == "No" & (approved >= mdy("07-01-2008") & approved <= mdy("12-31-2015")) ~
                                           "In buildings that began construction from 7/1/08 to 12/31/15, market-rate units may be deregulated at the first lease renewal after the benefit ends, if both the prior and renewal leases included a notice of deregulation with its effective date.",
                                         flag_421a16=="Yes"~
                                           "421-a(16) rental units without income restrictions are rent stabilized only if rents are below the vacancy decontrol threshold. If a vacancy occurs during the 421-a(16) benefit period and rents exceed that threshold, the unit may be deregulated.",
                                         is.na(approved) ~ "Working on finding the permit approved date!",
                                         approved > mdy("12-31-2015") ~ 
                                           "Working on figuring out what a construction start date after Dec 31, 2015 for a 
                                     non-421-a(16) building means for its rent stabilization status!"),
    surcharge = case_when(exmp_code %in% c(5110, 5117) ~ "8 increases, not to exceed 17.6%",
                          exmp_code %in% c(5113, 5118) ~ "4 increases, not to exceed 8.8%",
                          exmp_code %in% c(5116) ~ "8 increases, not to exceed 17.6%",
                          exmp_code %in% c(5114) ~ "4 increases, not to exceed 8.8%",
                          exmp_code %in% exmp_421a16 ~ "This is a 421-a(16) benefit, cannot collect surcharges")) 

#permit_phase_lots_421a %>% write_csv("Created Data/permit_phase_lots_updated.csv")