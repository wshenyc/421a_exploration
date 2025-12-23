library(shiny)
library(tidyverse)
library(sf)
library(leaflet)
library(leaflet.extras)
library(mapboxapi)
library(shinydashboard)
library(shinycssloaders)


#data

#lots_421a <- st_read("pluto_421a_.shp")
lots_421a <- st_read("pluto_small_permit_updated_v2.shp")
boro <- st_read("nybb_25d/nybb.shp")

lots_421a <- st_transform(lots_421a, 4326)
boro <- st_transform(boro, 4326)

nyc_bounds <- c(
   -74.25559,  # west
   40.49612,   # south
  -73.70001,  # east
  40.91553    # north
)

nyc_bounds_sf <- st_as_sfc(
  st_bbox(c(
    xmin = -74.25559, # west
    ymin = 40.49612,  # south
    xmax = -73.70001, # east
    ymax = 40.91553   # north
  ), crs = 4326)
)

nyc_bounds_sf <- st_sf(geometry = nyc_bounds_sf)



# UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "421-a Map",
    tags$li(
      actionLink("info_button", label = "", icon = icon("info-circle", class = "fa-lg")),
      class = "dropdown"
    )
  ),
  
  dashboardSidebar(
    disable = T
  ),
  
  dashboardBody(
    fluidRow(
      column(width = 5,
             box(width = NULL, withSpinner
                 (leafletOutput("tax_map", height = "90vh"),
                   caption = "Please wait. Map is loading.")
                 )
                 ), #col closer
      column(width = 3,
             box(width = NULL, 
                 title = "Address Search",
                 status = "primary",
                 background = "light-blue",
                 solidHeader = T,
                 mapboxGeocoderInput("geocoder", 
                                                   access_token = "pk.eyJ1Ijoid3NoZW55YyIsImEiOiJja2w3YjNvd3YxZnc1Mm5wZWp1MnVqZGh2In0.-wG4LWFGN76Nf-AEigxu2A",
                                                   placeholder = "Search for an address",
                                                   search_within = nyc_bounds_sf)),
             box(width = NULL, 
                 title = "Lot Info",
                 status = "primary",
                 solidHeader = T,
                 uiOutput("lot_info"))
                 ),#col closer
      column(width = 4,
             box(width = NULL, 
                 title = "Rent Stabilization Status",
                 status = "primary",
                 solidHeader = T,
                 uiOutput("rs_info")),
             box(width = NULL, 
                 title = "Rent Surcharge",
                 status = "primary",
                 solidHeader = T,
                 uiOutput("surcharge_info"))
      )#col closer
    )
    )
    
  )


######server####
server <- function(input, output, session) {
  
  
  # Info modal
  observeEvent(input$info_button, {
    showModal(modalDialog(
      title = "Overview",
      easyClose = TRUE,
      size = "m",
      tags$ul(
        tags$li("This map shows buildings that have received a 421-a benefit according to DOF's Property Exemption Open Data file.
                It's meant to serve as a starting place for a tenant to understand whether they may see a surcharge
                added to their rent or if their stabilization status may be ending."),
        tags$li("Because of the various iterations of the 421-a program, this map is not meant to provide definitive proof 
          for whether a building owner is able to collect a rent surcharge or if a building's rent stabilization status is ending."),
        tags$li("Information was pulled from", 
          a("HCR's fact sheet", href = "https://hcr.ny.gov/surcharges-and-fees", target = "_blank"),
        " and ",
        a("HPD's somewhat confusing fact sheet", href = "https://www.nyc.gov/assets/hpd/downloads/pdfs/services/421-a-tenant-fact-sheet.pdf", target = "_blank"), "."
        )),
    ))
  })
  
  
  #421a map 
  output$tax_map <- renderLeaflet({
    leaflet() %>%
      # Set initial view to NYC
      addProviderTiles(providers$CartoDB.Positron) %>%
      addPolygons(
        data = boro,
        fill = FALSE,
        color = "gray",
        weight = 1,
        group = "boroughs"
      ) %>% 
      addPolygons(
        data = lots_421a,
        fillColor = "blue",
        fillOpacity = 0.6,
        color = "blue",
        weight = 1,
        group = "421a_buildings",
        layerId = ~BBL
      ) %>% 
      fitBounds(
        lng1 = nyc_bounds[1],
        lat1 = nyc_bounds[2],
        lng2 = nyc_bounds[3],
        lat2 = nyc_bounds[4]
      ) %>%
      
      #zoom back to NYC view
      addResetMapButton()
  })
  
  #lot info
  selected_lot <- reactive({
    click <- input$tax_map_shape_click #this needs to be <map name>_shape_click for input
    if (is.null(click)) return (NULL)

      lots_421a %>%
        filter(BBL == click$id)
    
  })
  
  output$lot_info <- renderUI({

    lot <- selected_lot()
    if (is.null(lot)) {
      HTML(paste0(
        "<div style='font-size:18px; line-height:1.4; padding:15px'>",
        "<p><b>Click a building on the map to see details about its 421-a benefits.</b></p>"))
    } else {
      HTML(paste0(
        "<div style='font-size:16px; line-height:1.4; padding:15px'>",
        
        "<div style='font-size:18px'><b>Address: </b>", lot$Address, "</div>", "<br/>",
        
        "<div style='font-size:18px'><b>BBL: </b>", lot$BBL, "</div>", "<br/>",
        
        "<div style='font-size:18px'><b>Number of Residential Units: </b>", lot$UnitsRs, "</div>",
        
        "<hr>",
        
        "<div style='font-size:18px'><b>421-a Benefit Type: </b>", lot$dscrptn, "</div>",
        
        "<ul style='font-size:16px;'>",
        "<li><b>Benefit Start Year:</b> ", lot$bnftstr, "</li>",
        "<li><b>Benefit End Year:</b> ", lot$exmp_nd, "</li>",
        "<li><b>Years Receiving Benefit:</b> ", lot$crrnt__, "</li>",
        "<li><b>For this type of 421-a, benefits start phasing out by year:</b> ", lot$phs_t_s, "</li>",
        "<li><b>Is this building’s 421-a phasing out?:</b> ", lot$flg_phs, "</li>",
        "<li><b>Is this building receiving a version of 421-a(16)?*:</b> ", lot$f_42116, "</li>",
        "</ul>",
        "<div style='font-size:14px; font-weight:bold;'>",
        "<i>*If the building receives 421-a(16) benefits, it cannot collect rent surcharges.</i>",
        "</div>",
        
        "<hr>",

        "<div style='font-size:18px'><b>Building Construction Details</b></div>",
        "<ul style='font-size:16px;'>",
        "<li><b>Construction Start Date:</b> ", lot$apprvd_, "</li>",
        "<li><b>Year Completed:</b> ", lot$yer_cmp, "</li>",
        "<li><b>35 Years From Completed Construction:</b> ", lot$yr_c_35, "</li>",
        "</ul>",
        
        "</div>"
        
      #  "<hr>",
     
      ))
    }
  })
  
  ####specific construction info?####
  output$rs_info <- renderUI({
    lot <- selected_lot()
    if (is.null(lot)) {
      HTML(paste0(
        "<div style='font-size:18px'>",
        "<b>When will my apartment's rent stabilization status end?</b>",
        "</div>",
        
        "<br/>",
        "<p><b>Click a building on the map to see details about its rent stabilization status.</b></p>"
      ))
   
    } else {
    HTML(paste0(
      "<div style='font-size:18px'>",
      "<b>When will my apartment's rent stabilization status end?</b>",
      "</div>",
      
      "<br/>",

      "<ul style='font-size:16px;'>",
      "<li><b>For income-restricted units*:</b> ", lot$rs_inc, "</li>",
      "<li><b>For market-rate units:</b> ", lot$rs_mr, "</li>",
      "</ul>",
      "</div>",
      
      "<div style='font-size:14px; font-weight:bold;'>",
      "<i>*Income-restricted units are rented via HPD's Housing Connect.</i>",
      "</div>"
    ))
    }
  })
  
  ####generic surcharge info####
  output$surcharge_info <- renderUI({
    
    lot <- selected_lot()
    
    HTML(paste0(
      
      ####HPD's fact sheet explanation####
      "<div style='font-size:18px'>",
      "<b>Is my landlord allowed to charge a 2.2% surcharge during the phase-out of the 421-a benefits?</b>",
      "</div>",
      
      "<br/>",
      
      
      "<div style='font-size:16px'>",
      "<p>A building receiving 421-a benefits may be allowed to add an annual 2.2% surcharge 
        to the rent for <i>some</i> units during each year of the phase-out period of the building’s 
        421-a benefits. <u>If this building is able to collect surcharges from your unit</u>, those surcharges would be limited to: ",
        "<b>",lot$surchrg,"</b>",
        "</p>",

        "<p> The 2.2% surcharge is <b>not</b> collectible from the following categories of 
        units in such buildings:</p>",
      "</div>",
      
      "<br/>",
      
      "<ul style='font-size:16px;'>",
      "<li>421-a affordable units that were built without governmental assistance 
        pursuant to Section 6-08 of HPD Rules, </li>",
      "<li>421-a affordable units that were built with governmental assistance pursuant to 
        Section 6-08 of HPD Rules and that are subject to a regulatory agreement prohibiting the 
        collection of such surcharges, and  </li>",
      "<li>GEA SGA units and GEA 60% AMI units pursuant to Section 6-09 of HPD Rules 
        (these are two different types of 421-a income-restricted units in buildings that 
        commenced construction on or after July 1, 2008 and on or before December 31, 2015, 
        as defined in 28 RCNY 6-09).</li>",
      "<li>All rental units in buildings that receive 421-a(16) benefits.</li>",
      "</ul>",
      "</div>",
      
      "</div>"
    ))
  })
  
  #outline for selected lot
  observeEvent(input$tax_map_shape_click, {
    click <- input$tax_map_shape_click
    req(click$id)
    
    selected_id <- click$id
    
    # remove previous outline if it exists
    leafletProxy("tax_map") %>%
      removeShape(layerId = "selected_outline")
    
    # extract the clicked lot geometry
    lot_geom <- lots_421a[lots_421a$BBL == selected_id, ]
    
    # add a bold yellow outline
    leafletProxy("tax_map") %>%
      addPolylines(
        data = lot_geom,
        color = "yellow",
        weight = 6,
        opacity = 1,
        layerId = "selected_outline"
      )
    
    # zoom to the selected lot
    bb <- as.list(st_bbox(lot_geom))
    
    leafletProxy("tax_map") %>%
      fitBounds( #flytobounds feels a lil jerky 
        lng1 = bb$xmin - 0.0003,
        lat1 = bb$ymin - 0.0003,
        lng2 = bb$xmax + 0.0003,
        lat2 = bb$ymax + 0.0003
      )
    
  })
  
  #geocoder
  observeEvent(input$geocoder, {
    xy <- geocoder_as_xy(input$geocoder)

    leafletProxy("tax_map") %>%
      clearMarkers() %>%
      addMarkers(
        lng = xy[1],
        lat = xy[2]
      ) %>%
      flyTo(lng = xy[1],
            lat = xy[2],
            zoom = 18)
  })

  
}#end of server

#app
shinyApp(ui = ui, server = server)



#phasing out does not capture when benefits have ended
#number of years receiving 421a doesnt account for benefits ending 