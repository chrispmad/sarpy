output$myleaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    addPolygons(data = bc_bound, fillColor = 'transparent',
                color = 'black',
                weight = 1) #|>
  # addPolygons(data = bc_grid, fillColor = 'transparent',
  #             color = 'black',
  #             weight = 1)
})

observe({
  l = leafletProxy('myleaf')
  # Clear DFO shapes.
  l = l |>
    clearGroup('dfo_polys')
  req(!is.null(input$spec_sel))
  # Refresh bc grid cells. This can probably be removed,
  # as it is just a test.
  l = l |>
    clearGroup('grid_cells') |>
    addPolygons(data = bc_grid_in_frame(),
                fillColor = 'purple',
                fillOpacity = 0.5,
                color = 'black',
                weight = 1,
                group = 'grid_cells')


  # Conditional usage of data based on leaflet zoom level!
  if(map_zoom() < 10){
    print("I know my map zoom!")
    # Use the super simplified convex hull DFO shapes!
    l = l |>
      addPolygons(
        data = dfo_hull[dfo_hull$Common_Name_EN %in% input$spec_sel,],
        group = 'dfo_polys'
      )
  } else {
    if(length(dfo_polys()) > 0){
      print("we have DFO polys to add to the map.")
      # browser()
      l = l |>
        # clearGroup('dfo_polys') |>
        addPolygons(data = dfo_polys(),
                    fillColor = 'blue',
                    fillOpacity = 0.5,
                    color = 'black',
                    weight = 1,
                    group = 'dfo_polys')
    }
  }
})
