bc_bound = readRDS("bc_bound.rds")
bc_grid = readRDS("bc_grid.rds")
riskstat = readr::read_csv("risk_status_merged.csv") |>
  purrr::set_names(snakecase::to_snake_case) |>
  dplyr::mutate(legal_population = stringr::str_remove_all(legal_population, " [pP]opulation"))
# dfo_hull = readRDS("dfo_sara_occurrences_in_BC_convex_hull.rds")
kfo_all_sp = readRDS("kfo_all_species.rds")
dfo_r_p_sp = readRDS("dfo_species_row_count.rds")
dfo_ch = read_rds("dfo_critical_habitat.rds")
cdc = readRDS("CDC_polygons_trimmed_by_DFO.rds")

# Round two of data additions!
nr_regs = sf::read_sf("nr_regions.gpkg")
nr_dists = sf::read_sf("nr_districts.gpkg")
watershed_groups = sf::read_sf("watershed_groups.gpkg")
nlar_tbl = readr::read_csv("named_lakes_and_rivers_name_table.csv")
