map_bounds = reactiveVal()
map_zoom = reactiveVal()

observeEvent(input$myleaf_bounds, {
  bounds = input$myleaf_bounds
  bounds$south = bounds$south - 2 # correction to include all of visible leaflet map
  if(bounds$north > 90) bounds$north = 60.00069
  if(bounds$south < 48) bounds$south = 48
  if(bounds$east > -115) bounds$east = -114.08890
  if(bounds$west < -140) bounds$west = -139.01451
  map_bounds(bounds)
})

observeEvent(input$myleaf_zoom,{
  map_zoom(input$myleaf_zoom)
})

bc_grid_in_frame = reactive({
  req(input$myleaf_bounds)
  map_bounds_tbl = map_bounds() |>
    tidyr::as_tibble()
  map_bounds_sf = dplyr::bind_rows(
    sf::st_as_sf(map_bounds_tbl[,c(1:2)], coords = c("east","north"),crs = 4326),
    sf::st_as_sf(map_bounds_tbl[,c(3:4)], coords = c("west","south"),crs = 4326)
  ) |>
    sf::st_bbox() |>
    sf::st_as_sfc() |>
    sf::st_as_sf()
  output = bc_grid |>
    sf::st_filter(
      map_bounds_sf
    )
  print(paste0(nrow(output), " cells are in frame"))
  output
}) |>
  shiny::debounce(millis = 1000)

# Risk status table filtered by domain
rs_d = reactive(riskstat |> dplyr::filter(domain %in% input$dom_sel))

observe({
  updatePickerInput('spec_sel', choices = unique(rs_d()$cosewic_common_name)[order(unique(rs_d()$cosewic_common_name))], session=session)
  # Reset population selector to NA so that the order of reactive expressions works well
  updatePickerInput('pop_sel',choices = NULL, session=session)
  print("updated spec_sel input")
})
# Risk status table further filtered by species (this filtering WORKS)
rs_sp = reactive({
  req(!is.null(input$spec_sel))
  print("resolved rs_sp reactive")
  rs_d() |>
    dplyr::filter(cosewic_common_name %in% input$spec_sel)
})

observe({
  req(nrow(rs_sp()) > 0)
  if(!is.na(unique(rs_sp()$legal_population)[1])){
    updatePickerInput('pop_sel',
                      choices = unique(rs_sp()$legal_population)[order(unique(rs_sp()$legal_population))],
                      selected = unique(rs_sp()$legal_population)[1],
                      session=session)
  } else {
    updatePickerInput('pop_sel',choices = 'NA',selected = 'NA',session=session)
  }
  print("updated pop_sel input")
})

# Risk status table further filtered by population, if any.
rs_p = reactive({
  req(nrow(rs_sp()) > 0)
  req(!is.null(input$pop_sel))
  # Need the above line to ensure picker input for population is updated
  # before this reactive expression is resolved.
  if(input$pop_sel == "NA"){
    print('no pop selected - returning all rs_sp()')
    output = rs_sp()
  } else {
    output = rs_sp() |> dplyr::filter(legal_population %in% input$pop_sel)
  }
  output
})
