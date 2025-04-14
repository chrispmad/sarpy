library(bcmaps)

bc = bcmaps::bc_bound() |> dplyr::summarise()
sf::write_sf(bc, "app\\www\\bc_bound.gpkg")
