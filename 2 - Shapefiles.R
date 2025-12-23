library(tidyverse)
library(sf)

#dof_year <- read_csv("dof_421a_detail.csv")
permit_lots <- read_csv("permit_phase_lots_updated.csv")

pluto <- st_read("nyc_mappluto_25v3_1_shp/MapPLUTO.shp")

####need to update this to show units
pluto_small_permit <- pluto %>% 
  filter(BBL %in% permit_lots$parid) %>% 
  select(BBL, Address, UnitsRes, Latitude, Longitude, Shape_Leng, Shape_Area, geometry) %>% 
  left_join(permit_lots, by = c("BBL"="parid")) %>% 
  rename(rs_inc = rent_stab_status_inc,
         rs_mr = rent_stab_status_mr)

#I should do this in a different way
#pluto_small_permit %>% st_write("pluto_small_permit_updated_v2.shp")




#okay there's 184 NA's here
#wonder why these BBLs arent matching to anything on pluto
#im going to ignore these for now but feel bad about it 