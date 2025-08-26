# - - - - - - - - - - -
# Overlap Search Buttons (either region overlap or mouse click circle overlap)

# 1. We're using a region.
observeEvent(input$reg_search_button, {
  req(!is.null(region_for_leaflet()))
  # Wipe any buffered click circle, if it exists from previous clicks!
  buffered_click_for_leaflet(NULL)

  print("Search based on selected region!")
  # Read in all DFO (simplified) data for the selected region.
  dfo_data_for_region_data = readRDS(file = paste0("dfo_by_region/dfo_for_",
                                                   region_for_leaflet()$REGION_NAME |> stringr::str_to_lower()
                                                   ,".rds"))

  # Ensure no blank rows are included.
  dfo_data_for_region_data = dfo_data_for_region_data |>
    dplyr::filter(!is.na(Common_Name_EN))

  # Temporarily save this data into the 'dfo_data_for_region()' reactiveVal.
  dfo_data_for_region(dfo_data_for_region_data)
})

# 2. We're using coordinates
observeEvent(input$myleaf_click, {
  lat_for_search(input$myleaf_click$lat)
  updateTextInput(session = session, 'lat_for_search', value = lat_for_search())
  lng_for_search(input$myleaf_click$lng)
  updateTextInput(session = session, 'lng_for_search', value = lng_for_search())
})

observeEvent(input$coord_search_button, {
  req(!is.null(lat_for_search()) & !is.null(lng_for_search()))
  # Reset the buffered click shape for leaflet, if it has been loaded with some
  # shape from a previous coord search.
  buffered_click_for_leaflet(NULL)
  print("Search based on selected coordinates from clicking on the map!")

  lat_val = as.numeric(lat_for_search())
  lng_val = as.numeric(lng_for_search())

  clicked_point_sf = sf::st_as_sf(data.frame(lat = lat_val, lng = lng_val),
                                  coords = c("lng","lat"),
                                  crs = 4326)

  # Find which natural resource region has been clicked.
  clicked_reg = nr_regs |>
    sf::st_filter(clicked_point_sf)
  clicked_reg_name = stringr::str_to_lower(clicked_reg$REGION_NAME)

  dfo_region_data_pre_overlap = readRDS(file = paste0("dfo_by_region/dfo_for_",clicked_reg_name,".rds"))

  dfo_region_data_pre_overlap = dfo_region_data_pre_overlap |> dplyr::filter(!is.na(Common_Name_EN))

  # Buffer clicked point.
  clicked_point_sf_buffered = sf::st_buffer(clicked_point_sf, dist = 10000)
  buffered_click_for_leaflet(clicked_point_sf_buffered)

  # Split apart multipolygons so that we only include polygons that are
  # contiguous with anything overlapping the buffered click point.
  dfo_region_data_pre_overlap = sf::st_cast(dfo_region_data_pre_overlap, "POLYGON")

  # Apply a spatial overlap filter for dfo region data; put that into the
  # dfo_data_for_region reactiveVal.
  dfo_region_data_post_overlap = dfo_region_data_pre_overlap |>
    sf::st_filter(clicked_point_sf_buffered)

  dfo_data_for_region(dfo_region_data_post_overlap)
})
