
region_for_leaflet = reactiveVal()
buffered_click_for_leaflet = reactiveVal()
dfo_added = reactiveVal(F)
dfo_hr_added = reactiveVal(F)
dfo_ch_added = reactiveVal(F)
cdc_added = reactiveVal(F)
kfo_added = reactiveVal(F)
lat_for_search = reactiveVal("49.0538")
lng_for_search = reactiveVal("-121.9860")
dfo_data_for_region = reactiveVal()

# - - - - - - - - - - -
# REGION SELECT!

# Enable user the select certain regions
observeEvent(input$reg_sel, {
  if(input$reg_sel == "None"){
    region_for_leaflet = reactiveVal()
  }
})

observeEvent(input$reg_ent_sel, {
  req(!is.null(input$reg_ent_sel))

  obj_for_map = NULL

  if(input$reg_sel == "Region") {
    obj_for_map = nr_regs |> dplyr::filter(REGION_NAME == input$reg_ent_sel) |>
      dplyr::mutate(name_for_map = REGION_NAME)
  }
  region_for_leaflet(obj_for_map)
})

# - - - - - - - - - - -

# - - - - - - - - - - -
# Overlap Search Buttons

# 1. We're using a region.
observeEvent(input$reg_search_button, {
  req(!is.null(region_for_leaflet()))
  buffered_click_for_leaflet(NULL)
  print("Search based on selected region!")
  dfo_data_for_region_data = readRDS(file = paste0("dfo_by_region/dfo_for_",
                                                   region_for_leaflet()$REGION_NAME |> stringr::str_to_lower()
                                                   ,".rds"))

  dfo_data_for_region_data = dfo_data_for_region_data |>
    dplyr::filter(!is.na(Common_Name_EN))

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
  clicked_reg_name = str_to_lower(clicked_reg$REGION_NAME)

  dfo_region_data_pre_overlap = readRDS(file = paste0("dfo_by_region/dfo_for_",clicked_reg_name,".rds"))

  dfo_region_data_pre_overlap = dfo_region_data_pre_overlap |> dplyr::filter(!is.na(Common_Name_EN))

  # Buffer clicked point.
  clicked_point_sf_buffered = sf::st_buffer(clicked_point_sf, dist = 10000)
  buffered_click_for_leaflet(clicked_point_sf_buffered)

  # Apply a spatial overlap filter for dfo region data; put that into the
  # dfo_data_for_region reactiveVal.
  dfo_region_data_post_overlap = dfo_region_data_pre_overlap |>
    sf::st_filter(clicked_point_sf_buffered)

  dfo_data_for_region(dfo_region_data_post_overlap)
})

# Add simplified DFO polygons to map either from region select or from clicking
# on the map.
observe({
  if(!is.null(dfo_data_for_region()) | !is.null(buffered_click_for_leaflet())){
    # there is 0 or more rows in this reactive Val.
    l = leafletProxy('myleaf') |>
      clearGroup("dfo_for_region") |>
      clearGroup("dfo") |>
      clearGroup("dfo_ch") |>
      clearGroup("dfo_hr") |>
      clearGroup("cdc") |>
      clearGroup("kfo")

    # If there is at least one row in this reactive Val, plot it.
    if(nrow(dfo_data_for_region()) > 0){
      the_names = unique(dfo_data_for_region()$Common_Name_EN)
      name_pal = leaflet::colorFactor('Spectral',the_names)
      l = l |>
        removeControl('dfo_data_for_region_legend') |>
        addLegend(title = "DFO data in region or clicked area",
                  position = 'bottomleft', pal = name_pal, values = the_names,
                  layerId = 'dfo_data_for_region_legend') |>
        addPolygons(
        data = dfo_data_for_region(),
        label = ~Common_Name_EN,
        color = 'black',
        weight = 2,
        fillColor = ~name_pal(Common_Name_EN),
        fillOpacity = 0.8,
        group = 'dfo_for_region',
        options = pathOptions(pane = "dfo")
      )
    }
  } else {
    leafletProxy('myleaf') |>
      clearGroup('dfo_for_region')
  }
})

output$myleaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    addPolygons(data = bc_bound,
                fillColor = 'transparent',
                color = 'transparent',
                weight = 2) |>
    addMapPane(name = 'regions', zIndex = 350) |>
    addMapPane(name = 'dfo', zIndex = 400) |>
    addMapPane(name = 'dfo_ch', zIndex = 450) |>
    addMapPane(name = 'dfo_hr', zIndex = 500) |>
    addMapPane(name = 'cdc', zIndex = 550) |>
    addMapPane(name = 'kfo', zIndex = 600) |>
    addLegend(
      position = 'topleft',
      title = "Legend",
      labels = c("DFO","DFO HR","DFO CH","CDC","KFO"),
      colors = c("blue","purple","darkgreen","#ed8cd8","darkorange")
    )
})

# Add/remove simplified DFO grid cells based on selected region

# Add/remove simplified DFO grid cells based on species search
observe({

  l = leafletProxy('myleaf')
  print(pop_sel_r())

  l = l |>
    clearGroup("regions")
  if(!is.null(region_for_leaflet())){
    l = l |>
      clearGroup("dfo_for_region") |>
      leaflet::addPolygons(
        data = region_for_leaflet(),
        group = "regions",
        options = pathOptions(pane = "dfo")
      )
  }
  if(!is.null(buffered_click_for_leaflet())){
    l = l |>
      clearGroup("regions") |>
      # clearGroup("dfo_for_region") |>
      leaflet::addPolygons(
        data = buffered_click_for_leaflet(),
        group = "regions",
        label = "Click location on map buffered by 10km",
        options = pathOptions(pane = "dfo")
      )
  }


  if(!'DFO' %in% layers_to_map()){
    l = l |>
      clearGroup('dfo_polys')
    dfo_added(F)
  }


  req(!is.null(input$spec_sel))
  # req(length(dfo_polys()) > 0)

  if('DFO' %in% input$dataset_sel){

    # Has the user selected a population outside of DFO's options
    # for this species? If so, wipe DFO.
    if(length(dfo_polys()) == 0){
      l = l |>
        clearGroup('dfo_polys')
    } else {
      # Do the DFO polygons consist of anything? If so, refresh / add them.
      if(nrow(dfo_polys()) == 0){
        l = l |>
          clearGroup('dfo_polys')
      }
      if(nrow(dfo_polys()) > 0){
        l = l |>
          clearGroup('dfo_polys') |>
          addPolygons(data = dfo_polys(),
                      fillOpacity = 0.6,
                      fillColor = 'blue',
                      color = 'black',
                      weight = 2,
                      group = 'dfo_polys',
                      label = ~paste0(Common_Name_EN, " (DFO)"),
                      options = pathOptions(pane = 'dfo'))
        dfo_added(T)
      }
    }
  }
})

# Add/remove high-res DFO polygons
observe({

  l = leafletProxy('myleaf')

  if(!'DFO HR' %in% layers_to_map()){
    l |>
      clearGroup('dfo_polys_hr')
    dfo_hr_added(F)
  }

  req(!is.null(input$spec_sel))
  req(length(dfo_polys_hr()) > 0)

  if('DFO HR' %in% input$dataset_sel){
    if(nrow(dfo_polys_hr()) == 0){
      l = l |>
        clearGroup('dfo_polys_hr')
    }
    if(nrow(dfo_polys_hr()) > 0){
      l = l |>
        clearGroup('dfo_polys_hr') |>
        addPolygons(data = dfo_polys_hr(),
                    fillOpacity = 0.6,
                    fillColor = 'purple',
                    color = 'black',
                    weight = 2,
                    group = 'dfo_polys_hr',
                    label = ~paste0(Common_Name_EN, " (DFO HR)"),
                    options = pathOptions(pane = 'dfo_hr'))
      dfo_hr_added(T)
    }
  }
})

# Add/remove DFO CH polygons
observe({

  l = leafletProxy('myleaf')

  if(!'DFO CH' %in% layers_to_map()){
    l |>
      clearGroup('dfo_ch_polys')
    dfo_ch_added(F)
  }

  req(!is.null(input$spec_sel))

  if('DFO CH' %in% input$dataset_sel){
    if(length(dfo_ch_selected()) == 0){
      l = l |>
        clearGroup('dfo_ch_polys')
    } else {
      # no CDC rows after filtering.
      if(nrow(dfo_ch_selected()) == 0){
        l = l |>
          clearGroup('dfo_ch_polys')
      }
      if(nrow(dfo_ch_selected()) > 0){
        l = l |>
          clearGroup('dfo_ch_polys') |>
          addPolygons(data = dfo_ch_selected(),
                      fillOpacity = 0.6,
                      fillColor = 'darkgreen',
                      color = 'black',
                      weight = 2,
                      group = 'dfo_ch_polys',
                      label = ~paste0(Common_Name_EN, " (DFO CH)"),
                      options = pathOptions(pane = 'dfo_ch'))
        dfo_ch_added(T)
      }
    }
  }
})

# Add/remove CDC polygons
observe({

  l = leafletProxy('myleaf')

  if(!'CDC' %in% layers_to_map()){
    l |>
      clearGroup('cdc_polys')
    cdc_added(F)
  }

  req(!is.null(input$spec_sel))

  if('CDC' %in% input$dataset_sel){
    if(length(cdc_selected()) == 0){
      l = l |>
        clearGroup('cdc_polys')
    } else {
      if(nrow(cdc_selected()) == 0){
        l = l |>
          clearGroup('cdc_polys')
      }
      if(nrow(cdc_selected()) > 0){
        l = l |>
          clearGroup('cdc_polys') |>
          addPolygons(data = cdc_selected(),
                      fillOpacity = 0.6,
                      fillColor = '#ed8cd8',
                      color = 'black',
                      weight = 2,
                      group = 'cdc_polys',
                      label = ~paste0(ENG_NAME, " (CDC)"),
                      options = pathOptions(pane = 'cdc'))
        cdc_added(T)
      }
    }
  }
})

# Add/remove Known Fish Occurrences points
observe({

  l = leafletProxy('myleaf')

  if(!'KFO' %in% layers_to_map()){
    l |>
      clearGroup('kfo_points')
    kfo_added(F)
  }

  req(!is.null(input$spec_sel))

  if('KFO' %in% input$dataset_sel & kfo_added() == F){
    if(nrow(kfo_selected()) > 0){
      l = l |>
        clearGroup('kfo_points') |>
        addCircleMarkers(data = kfo_selected(),
                         fillOpacity = 0.6,
                         fillColor = 'darkorange',
                         color = 'black',
                         weight = 2,
                         group = 'kfo_points',
                         label = ~paste0(common_name," (KFO)"),
                         options = pathOptions(pane = 'kfo'))
      kfo_added(T)
    }
  }
})
