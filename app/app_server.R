source('app_ui.R')

server <- function(input, output, session) {
  if(!stringr::str_detect(getwd(),"www\\/$")) setwd(paste0(getwd(),"/www/"))

  # ============================================
  # Load in data.
  source('utils/load_in_data.R', local = TRUE)

  # ============================================
  # Establish reactives and reactive values
  source('utils/establish_reactives.R', local = TRUE)

  # ============================================
  # Filter spatial data for leaflet map
  source('utils/filter_sp_data_for_map.R', local = TRUE)

  # ============================================
  # Render widgets
  source('utils/leaflet_map_logic.R', local = TRUE)
  source('utils/render_summary_numbers.R', local = TRUE)

  output$region_entity_options_ui = renderUI({

    name_options = NULL
    new_input = NULL

    if(input$reg_sel == "Region") name_options = unique(nr_regs$REGION_NAME)
    if(input$reg_sel == "District") name_options = unique(nr_dists$DISTRICT_NAME)
    if(input$reg_sel == "Watershed Group") name_options = unique(watershed_groups$WATERSHE_1)

    if(!is.null(name_options)){
      new_input = pickerInput("reg_ent_sel","Selection",choices = name_options)
    }
    new_input
  })
}
