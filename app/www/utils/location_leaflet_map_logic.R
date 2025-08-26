# Make reactiveVals to hold various things: which region is selected, the
# map click coordinates, whether or not DFO / CDC / KFO data has been added,
# and which slice of DFO (and other datasets!) is either within the selected
# region or overlapping with the buffered click point. We initialize these
# reactiveVals as either NULL (i.e. empty) or as FALSE, although the
# lat and lng for search has Cultus Lake as its default location.
region_for_leaflet = reactiveVal()
buffered_click_for_leaflet = reactiveVal()
lat_for_search = reactiveVal("49.0538")
lng_for_search = reactiveVal("-121.9860")
dfo_data_for_region = reactiveVal()
nr_added = reactiveVal(F)
rd_added = reactiveVal(F)

data_for_plot = reactive({
  # Do complicated filtering stuff

})

output$location_search_leaf = renderLeaflet({
  leaflet() |>
    addProviderTiles(providers$CartoDB) |>
    leaflet::setView(lng = -125, lat = 55, zoom = 5) |>
    addMapPane(name = 'regions', zIndex = 350) |>
    addMapPane(name = 'nr', zIndex = 320) |>
    addMapPane(name = 'rd', zIndex = 340) |>
    addLegend(
      position = 'topleft',
      title = "Legend",
      labels = c("DFO","DFO HR","DFO CH","CDC","KFO"),
      colors = c("blue","purple","darkgreen","#ed8cd8","darkorange")
    )
})

observe({
  leafletProxy("location_search_leaf") |>
    addPolygons(data = data_for_plot())
})
