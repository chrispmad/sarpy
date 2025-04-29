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
    if(nrow(dfo_detail_polys_to_add()) > 0 & dfo_polys_added() == F){

      dfo_polys_added(TRUE)
      rows_to_add = nrow(dfo_detail_polys_to_add())
      rows_and_chunks = data.frame(row_num = 1:rows_to_add) |>
        dplyr::mutate(chunk = as.numeric(gl(n = 5, k = ceiling(length(row_num) / 5),
                                 length = length(row_num))))
      # Add chunk identifier to each row of reactiveVal dfo polys to add.
      dfo_detail_polys_to_add(
        cbind(
          dfo_detail_polys_to_add(),
          rows_and_chunks |> dplyr::select(chunk)
        )
      )

      withProgress(message = 'Adding DFO polygons...', value = 0, {
        # browser()
        for(i in 1:max(rows_and_chunks$chunk)){
          # Pull out rows of the chunk we want to add, add as Polygon.
          l = l |>
            addPolygons(data = dfo_detail_polys_to_add()[dfo_detail_polys_to_add()$chunk == i,],
                        fillColor = 'blue',
                        fillOpacity = 0.5,
                        color = 'black',
                        weight = 1,
                        group = 'dfo_polys')
          # As chunks are added to the leaflet map, remove them from the queue
          # dfo_detail_polys_to_add(dfo_detail_polys_to_add()[dfo_detail_polys_to_add()$chunk != i,])
          # if(nrow(dfo_detail_polys_to_add())) dfo_polys_added(TRUE)
          incProgress(1/max(rows_and_chunks$chunk), detail = paste0("Data chunk ", i, " of ",max(rows_and_chunks$chunk)))
        }
      })
    }
  }
})
