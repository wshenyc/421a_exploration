library(tidyverse)
library(sf)

###setting up data####
permit_lots <- read_csv("Created Data/permit_phase_lots_updated.csv")

pluto <- st_read("Raw Data/nyc_mappluto_25v3_1_shp/MapPLUTO.shp")

gea <- read_csv("Created Data/df_gea.csv") %>% 
  mutate(gea_flag = "Yes")

subsidy <- read_csv("Raw Data/FC_SHD_bbl_analysis_2025-05-13.csv")
subsidy_names <- read_csv("Raw Data/subsidy_names.csv")

###subsidy cleaning up####
subsidy_clean <- subsidy %>% 
  filter(bbl %in% c(permit_lots$parid)) %>% 
  select(bbl, starts_with("prog_")) %>% 
  rowwise() %>% 
  mutate(
    program_summary = {
      vals  <- c_across(starts_with("prog_"))
      nms  <- names(pick(starts_with("prog_")))
      
      active_progs <- nms[vals == 1]
      
      if (length(active_progs) == 0) {
        NA_character_
      } else {
          paste(
            subsidy_names$description[
              match(active_progs, subsidy_names$prog)
            ],
            collapse = ", "
          )
      }
    }
  ) %>%
  ungroup() %>% 
  select(bbl, program_summary)


####shapefile####
pluto_small_permit <- pluto %>% 
  filter(BBL %in% permit_lots$parid) %>% 
  select(BBL, Address, UnitsRes, Latitude, Longitude, Shape_Leng, Shape_Area, geometry) %>% 
  left_join(permit_lots, by = c("BBL"="parid")) %>% 
  left_join(subsidy_clean, by = c("BBL"="bbl")) %>% 
  left_join(gea, by = "BBL") %>% 
  rename(rs_inc = rent_stab_status_inc,
         rs_mr = rent_stab_status_mr) %>% 
  mutate(gea_flag = case_when(is.na(gea_flag) & substr(BBL,1,1) == "1" ~ "Yes", #all of MN is GEA
                              is.na(gea_flag) ~ "No",
                              TRUE ~ gea_flag),
         BBL = as.character(BBL))


#pluto_small_permit %>% st_write("Created Data/pluto_421a_20260125.shp")




#okay there's 184 NA's here
#wonder why these BBLs arent matching to anything on pluto
#im going to ignore these for now 

###need to convert shapefiles to geojson
# Example data: read a built-in shapefile to create an sf object
pluto_small_permit <- st_read("Created Data/pluto_421a_20260125.shp")

boro <- st_read("/Users/winnieshen/Documents/GitHub/421a_exploration/Data/nybb.shp")

#reproject to 4326

pluto_small_permit <- st_transform(pluto_small_permit, 4326)

boro <- st_transform(boro, 4326)


# Write the sf object to a GeoJSON file

#sst_write(pluto_small_permit, dsn = "Created Data/lots_421a.geojson")

#st_write(boro, dsn = "/Users/winnieshen/Documents/GitHub/421a_exploration/data/boro.geojson")


