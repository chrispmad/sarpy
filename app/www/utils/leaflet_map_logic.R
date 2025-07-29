
region_for_leaflet = reactiveVal()
dfo_added = reactiveVal(F)
dfo_hr_added = reactiveVal(F)
dfo_ch_added = reactiveVal(F)
cdc_added = reactiveVal(F)
kfo_added = reactiveVal(F)

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
  if(input$reg_sel == "District") {
    obj_for_map = nr_dists |> dplyr::filter(DISTRICT_NAME == input$reg_ent_sel) |>
      dplyr::mutate(name_for_map = DISTRICT_NAME)
  }
  if(input$reg_sel == "Watershed Group") {
    obj_for_map = watershed_groups |> dplyr::filter(WATERSHE_1 == input$reg_ent_sel) |>
      dplyr::mutate(name_for_map = WATERSHE_1)
  }
  region_for_leaflet(obj_for_map)
})

# Run the overlap searches!

# 1. We're using a region.
observeEvent(input$reg_search_button, {
  req(!is.null(region_for_leaflet()))
  print("Search based on selected region/district/watershed!")
  browser()
  dfo_polys(dfo)
})

lat_for_search = reactiveVal()
lng_for_search = reactiveVal()

observeEvent(input$myleaf_click, {
  lat_for_search(input$myleaf_click$lat)
  lng_for_search(input$myleaf_click$lng)
})

# 2. We're using coordinates
observeEvent(input$coord_search_button, {
  req(!is.null(lat_for_search()) & !is.null(lng_for_search()))

  print("Search based on selected coordinates from clicking on the map!")


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

# Add/remove simplified DFO grid cells
observe({

  l = leafletProxy('myleaf')
  print(pop_sel_r())

  if(!is.null(region_for_leaflet())){
    l = l |>
      leaflet::addPolygons(
        data = region_for_leaflet(),
        group = "regions",
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
