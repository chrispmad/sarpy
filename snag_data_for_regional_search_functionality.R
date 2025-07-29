#

regs = bcmaps::nr_regions() |> sf::st_transform(4326)
dists = bcmaps::nr_districts() |> sf::st_transform(4326)

sf::write_sf(regs, "app/www/nr_regions.gpkg")
sf::write_sf(dists, "app/www/nr_districts.gpkg")

# Subwatersheds (i.e. 'Watershed Groups')
subw = sf::read_sf("W:/CMadsen/shared_data_sets/WatershedGroups_lowres.shp") |>
  sf::st_transform(4326)
sf::write_sf(subw, "app/www/watershed_groups.gpkg")

nlar = readRDS("C:/Users/CMADSEN/OneDrive - Government of BC/data/named_lakes_and_rivers_merged.rds")

# table of wb names
nlar = nlar |>
  dplyr::select(waterbody, watershed) |>
  dplyr::left_join(
    subw |> dplyr::select(watershed = WATERSHED_, watershed_name = WATERSHE_1) |>
      sf::st_drop_geometry()
  )

nlar_tbl = nlar |>
  dplyr::select(waterbody, watershed_name, watershed) |>
  sf::st_drop_geometry() |>
  dplyr::distinct()

readr::write_csv(nlar_tbl, "app/www/named_lakes_and_rivers_name_table.csv")
