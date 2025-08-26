# Make reactiveVals to hold various things: which region is selected, the
# map click coordinates, whether or not DFO / CDC / KFO data has been added,
# and which slice of DFO (and other datasets!) is either within the selected
# region or overlapping with the buffered click point. We initialize these
# reactiveVals as either NULL (i.e. empty) or as FALSE, although the
# lat and lng for search has Cultus Lake as its default location.
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
      clearGroup("cdc_polys") |>
      clearGroup("kfo_points")

    # If there is at least one row in this reactive Val, plot it.
    if(nrow(dfo_data_for_region()) > 0){
      # browser()
      the_names = unique(dfo_data_for_region()$Common_Name_EN)
      the_names_sc = snakecase::to_snake_case(the_names)

      name_pal = leaflet::colorFactor('Spectral',the_names)
      l = l |>
        removeControl('dfo_data_for_region_legend') |>
        addLegend(title = "DFO data in region or clicked area",
                  position = 'topright', pal = name_pal, values = the_names,
                  layerId = 'dfo_data_for_region_legend') |>
        addLayersControl(overlayGroups = paste0("dfo_",the_names_sc),
                         options = layersControlOptions(collapsed = F))

      for(group_to_remove in input$myleaf_groups){
        if(stringr::str_detect(group_to_remove, "dfo_[a-z]+")){
          l = l |>
            clearGroup(group_to_remove)
        }
      }

      # Loop through species to add, each one gets its own layer assignment option.
      for(common_name in the_names){
        l = l |>
          addPolygons(
            data = dfo_data_for_region() |> dplyr::filter(Common_Name_EN == common_name),
            label = ~Common_Name_EN,
            color = 'black',
            weight = 2,
            fillColor = ~name_pal(Common_Name_EN),
            fillOpacity = 0.8,
            group = ~paste0('dfo_',snakecase::to_snake_case(Common_Name_EN)),
            options = pathOptions(pane = "dfo")
          )
      }
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

# Add/remove simplified DFO grid cells based on species search
observe({

  l = leafletProxy('myleaf')
  print(pop_sel_r())

  l = l |>
    # Clear away any polygons that are remaining from region or coordinate searches.
    clearGroup("regions") |>
    clearGroup("dfo_for_region") |>
    removeLayersControl()


  # And clear away any species that were added in previous searches (searches
  # are identified as being 'previous' by virtue of the containing reactiveVal
  # "dfo_data_for_region" being NULL).
  if(is.null(dfo_data_for_region())){
    for(group_to_remove in input$myleaf_groups){
      if(stringr::str_detect(group_to_remove, "dfo_[a-z]+")){
        l = l |>
          clearGroup(group_to_remove)
      }
    }
  }


  if(!is.null(region_for_leaflet())){
    l = l |>
      clearGroup("dfo_for_region") |>
      leaflet::addPolygons(
        data = region_for_leaflet(),
        group = "regions",
        options = pathOptions(pane = "regions")
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

  if('DFO' %in% input$dataset_sel & is.null(dfo_data_for_region())){

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
