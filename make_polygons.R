library(bcmaps)

bc = bcmaps::bc_bound() |> dplyr::summarise()
dir.create("app/www")
sf::write_sf(bc, "app\\www\\bc_bound.gpkg")
