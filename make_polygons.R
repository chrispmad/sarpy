library(bcmaps)

bc = bcmaps::bc_bound() |> dplyr::summarise()
sf::write_sf(bc, "data/bc_bound.gpkg")
