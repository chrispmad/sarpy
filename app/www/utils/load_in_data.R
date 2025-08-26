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

# nr<-bcmaps::nr_regions() |> sf::st_transform(4326)
# sf::write_sf(nr, "app/www/natural_regions.gpkg")
# rd<-bcmaps::nr_districts() |> sf::st_transform(4326)
# sf::write_sf(rd, "app/www/districts.gpkg")
# plot(st_geometry(rd))

nr<-sf::read_sf("natural_regions.gpkg")
rd<-sf::read_sf("districts.gpkg")

# plot(st_geometry(nr), col = "blue")
# plot(st_geometry(rd), add = T, col = "black")
