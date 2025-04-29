output$myleaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    addPolygons(data = bc_bound, fillColor = 'transparent',
                color = 'black',
                weight = 1) |>
    addLegend(
      position = 'topleft',
      title = "Legend",
      labels = c("DFO","CDC"),
      colors = c("blue","#ed8cd8")
    )
})

observe({
  l = leafletProxy('myleaf')
  # Clear DFO shapes.
  l = l |>
    clearGroup('dfo_polys') |>
    clearGroup('cdc_polys')

  req(!is.null(input$spec_sel))

  # Add CDC polygons to map.
  if(nrow(cdc_selected()) > 0){
    l = l |>
      addPolygons(
        data = cdc_selected(),
        fillColor = '#ed8cd8',
        color = 'black',
        weight = 1,
        fillOpacity = 0.6,
      )
  }

  # Conditional usage of data based on leaflet zoom level!
  if(map_zoom() < 10){
    dfo_hull_d = dfo_hull[dfo_hull$Common_Name_EN %in% input$spec_sel,]
    if(nrow(dfo_hull_d) > 0){
      # Use the super simplified convex hull DFO shapes!
      l = l |>
        addPolygons(
          data = dfo_hull_d,
          fillColor = 'blue',
          fillOpacity = 0.5,
          color = 'black',
          weight = 1,
          group = 'dfo_polys'
        )
    }
  } else {
    if(length(dfo_polys()) > 0){
      l = l |>
        addPolygons(data = dfo_polys(),
                    fillColor = 'blue',
                    fillOpacity = 0.5,
                    color = 'black',
                    weight = 1,
                    group = 'dfo_polys')
    }
  }
})
