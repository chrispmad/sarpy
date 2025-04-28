library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ggplot2)
library(shinyWidgets)

domain_select = pickerInput('dom_sel','Domain',
                            choices = c("Terrestrial","Aquatic"),
                            selected = 'Aquatic',
                            options = pickerOptions(container = 'body'))
species_select = pickerInput('spec_sel','Species',choices = NULL,multiple = T,
                             options = pickerOptions(container = 'body',liveSearch = T))
population_select = pickerInput('pop_sel','Population',choices = NULL,multiple = T,
                                options = pickerOptions(container = 'body',liveSearch = T))

toolbox = tagList(
  h3("Toolbox"),
  domain_select,
  species_select,
  population_select
)

ui <- page_fluid(
  shiny::includeCSS("www/my_styles.css"),
  # shiny::includeScript("www/my_js.js"),
  card(
    leafletOutput('myleaf', height = '100%'),
    class = 'leaf-card'
  ),
  absolutePanel(
    top = '40%', left = '5%', width = '20%', height = '100%',
    draggable = T,
    card(
      toolbox,
      class = 'floating-toolbox'
    )
  )
)

server <- function(input, output, session) {
  # ============================================
  # Load in data.
  bc_bound = readRDS("www\\bc_bound.rds")
  bc_grid = readRDS("www\\bc_grid.rds")
  riskstat = readr::read_csv("www\\risk_status_merged.csv") |>
    purrr::set_names(snakecase::to_snake_case) |>
    dplyr::mutate(legal_population = stringr::str_remove_all(legal_population, " [pP]opulation"))
  dfo_hull = readRDS("www\\dfo_sara_occurrences_in_BC_convex_hull.rds")

  # ============================================
  # Establish reactives and reactive values
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
  })

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

  observe({
    print(rs_p())
  })

  dfo_polys = reactive({
    req(!is.null(input$spec_sel), nrow(rs_p()) > 0)
    all_data = list()
    files_to_access = tidyr::crossing(cosewic_common_name = rs_p()$cosewic_common_name,
                                      legal_population = rs_p()$legal_population,
                                      cell_id = bc_grid_in_frame()$cell_id
    )
    for(i in 1:nrow(files_to_access)){
      row = files_to_access[i,]
      file_path = paste0("www\\dfo\\",row$cosewic_common_name,"\\",row$legal_population,"\\cell_",row$cell_id,".rds")
      if(file.exists(file_path)){
        all_data[[i]] = readRDS(file_path)
        # all_data[[i]] = sf::read_sf(file_path)
      }
    }

    if(length(all_data) > 0){
      all_data = all_data |>
        dplyr::bind_rows()
    }
    all_data
  })
  # ============================================
  # Render widgets
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
    req(!is.null(input$spec_sel))
    l = leafletProxy('myleaf')
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

    # Clear DFO shapes.
    l = l |>
      clearGroup('dfo_polys')
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
}

shinyApp(ui, server)
