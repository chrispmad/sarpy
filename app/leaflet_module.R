leaflet_mod_UI <- function(id) {
  ns <- NS(id)
  tagList(
    leafletOutput(ns('myleaf'), height = '100%')
  )
}

leaflet_mod_Server <- function(id, bc_bound, spec_sel_input, cdc_selected,dfo_polys,map_zoom,dfo_hull) {
  moduleServer(
    id,
    function(input, output, session) {
      # ============================================
      # Render widgets
      output$myleaf = renderLeaflet({
        leaflet() |>
          addProviderTiles(providers$CartoDB) |>
          addPolygons(data = bc_bound, fillColor = 'transparent',
                      color = 'black',
                      weight = 1)
      })

      observe({
        req(!is.null(spec_sel_input))
        l = leafletProxy('myleaf')

        # Clear DFO shapes, always.
        l = l |>
          clearGroup('dfo_polys') |>
          clearGroup('cdc_polys')

        l = l |>
          addPolygons(
            data = cdc_selected(),
            fillColor = 'orange',
            color = 'orange',
            weight = 1
          )
        # Resolve the reactive for DFO polygons outside of the 'isolate' below.
        # This way, dfo_polys is always resolved, but this whole observe
        # block won't be triggered by anything inside the isolate block.

        dat_for_plot = dfo_polys()

        shiny::isolate({

          if(map_zoom() < 10){
            print(paste0("map zoom:", map_zoom()))
            # Use the super simplified convex hull DFO shapes!
            l = l |>
              addPolygons(
                data = dfo_hull[dfo_hull$Common_Name_EN %in% spec_sel_input,],
                group = 'dfo_polys'
              )
          } else {
            if(length(dat_for_plot) > 0){
              print("we have DFO polys to add to the map.")
              l = l |>
                addPolygons(data = dat_for_plot,
                            fillColor = 'blue',
                            fillOpacity = 0.5,
                            color = 'blue',
                            weight = 1,
                            group = 'dfo_polys')
            }
          }
        })
      })
    }
  )
}
