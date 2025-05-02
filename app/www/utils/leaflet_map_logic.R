output$myleaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    addPolygons(data = bc_bound,
                fillColor = 'transparent',
                color = 'transparent',
                weight = 1) |>
    addLegend(
      position = 'topleft',
      title = "Legend",
      labels = c("DFO","DFO CH","CDC","KFO"),
      colors = c("blue","darkgreen","#ed8cd8","darkorange")
    )
})

observe({
  l = leafletProxy('myleaf')
  # Clear DFO shapes.
  l = l |>
    clearGroup('dfo_polys') |>
    clearGroup('dfo_ch_polys') |>
    clearGroup('cdc_polys') |>
    clearGroup('kfo_polys')

  req(!is.null(input$spec_sel))

  # Add DFO Critical Habitat polygons to map.
  if('DFO CH' %in% input$dataset_sel){
    if(nrow(dfo_ch_selected()) > 0){
      l = l |>
        addPolygons(
          data = dfo_ch_selected(),
          fillColor = ~'darkgreen',
          color = 'black',
          weight = 1,
          fillOpacity = 0.6,
          group = ('dfo_ch_polys')
        )
    }
  }

  # Add CDC polygons to map.
  if('CDC' %in% input$dataset_sel){
    if(nrow(cdc_selected()) > 0){
      l = l |>
        addPolygons(
          data = cdc_selected(),
          fillColor = ~'#ed8cd8',
          color = 'black',
          weight = 1,
          fillOpacity = 0.6,
          group = ('cdc_polys')
        )
    }
  }

  if('KFO' %in% input$dataset_sel){
    if(nrow(kfo_selected()) > 0){
      l = l |>
        addCircleMarkers(
          data = kfo_selected(),
          fillColor = ~'darkorange',
          color = 'black',
          weight = 1,
          fillOpacity = 0.6,
          group = ('kfo_polys')
        )
    }
  }

  if('DFO' %in% input$dataset_sel){
    if(length(dfo_polys()) > 0){
      l = l |>
        addPolygons(data = dfo_polys(),
                    fillOpacity = 0.6,
                    fillColor = 'blue',
                    color = 'black',
                    weight = 1,
                    group = 'dfo_polys')
    }
  }
})
