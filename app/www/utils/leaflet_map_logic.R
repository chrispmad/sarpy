layers_to_map = reactive({
  input$dataset_sel
})

dfo_added = reactiveVal(F)
dfo_hr_added = reactiveVal(F)
dfo_ch_added = reactiveVal(F)
cdc_added = reactiveVal(F)
kfo_added = reactiveVal(F)

output$myleaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    addPolygons(data = bc_bound,
                fillColor = 'transparent',
                color = 'transparent',
                weight = 2) |>
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

# Add/remove DFO CH polygons
observe({

  l = leafletProxy('myleaf')

  if(!'DFO CH' %in% layers_to_map()){
    l |>
      clearGroup('dfo_ch_polys')
    dfo_ch_added(F)
  }

  req(!is.null(input$spec_sel))


  if('DFO CH' %in% input$dataset_sel & dfo_ch_added() == F){
    if(nrow(dfo_ch_selected()) > 0){
      l = l |>
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
})

# Add/remove simplified DFO grid cells
observe({

  l = leafletProxy('myleaf')

  if(!'DFO' %in% layers_to_map()){
    l |>
      clearGroup('dfo_polys')
    dfo_added(F)
  }

  req(!is.null(input$spec_sel))


  if('DFO' %in% input$dataset_sel & dfo_added() == F){
    if(nrow(dfo_polys()) > 0){
      l = l |>
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


  if('DFO HR' %in% input$dataset_sel & dfo_hr_added() == F){
    if(nrow(dfo_polys_hr()) > 0){
      l = l |>
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

# Add/remove CDC polygons
observe({

  l = leafletProxy('myleaf')

  if(!'CDC' %in% layers_to_map()){
    l |>
      clearGroup('cdc_polys')
    cdc_added(F)
  }

  req(!is.null(input$spec_sel))


  if('CDC' %in% input$dataset_sel & cdc_added() == F){
    if(nrow(cdc_selected()) > 0){
      l = l |>
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
