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
}
