bc_bound = readRDS("bc_bound.rds")
bc_grid = readRDS("bc_grid.rds")
riskstat = readr::read_csv("risk_status_merged.csv") |>
  purrr::set_names(snakecase::to_snake_case) |>
  dplyr::mutate(legal_population = stringr::str_remove_all(legal_population, " [pP]opulation"))
dfo_hull = readRDS("dfo_sara_occurrences_in_BC_convex_hull.rds")
cdc = readRDS("CDC_polygons_trimmed_by_DFO.rds")
