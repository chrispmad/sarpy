library(tidyverse)
library(sf)
library(arrow)
library(geoarrow)

ensure_multipolygons <- function(X) {
  tmp1 <- tempfile(fileext = ".gpkg")
  tmp2 <- tempfile(fileext = ".gpkg")
  st_write(X, tmp1)
  gdalUtilities::ogr2ogr(tmp1, tmp2, f = "GPKG", nlt = "MULTIPOLYGON")
  Y <- st_read(tmp2)
  st_sf(st_drop_geometry(X), geom = st_geometry(Y))
}

repair_geoms = function(d){
  if(sum(!sf::st_is_valid(d)) > 0){
    d_bad_geoms = d |>
      dplyr::filter(!sf::st_is_valid(geom))
    d_good_geoms = d |>
      dplyr::filter(sf::st_is_valid(geom))
    d_fixed_geoms = wdpar::st_repair_geometry(d_bad_geoms)
    d_fixed_geoms = d_fixed_geoms |> dplyr::rename(geom = geometry)
    output = dplyr::bind_rows(d_good_geoms, d_fixed_geoms)
  } else {
    output = d
  }
  return(output)
}

bc = bcmaps::bc_bound()

bc_g = sf::st_as_sf(sf::st_make_grid(x = bc, n = c(25,25)))

bc_g = bc_g |>
  dplyr::mutate(cell_id = row_number()) |>
  sf::st_transform(4326)

bc = bc |> sf::st_transform(4326)

saveRDS(bc, "app/www/bc_bound.rds")
saveRDS(bc_g, "app/www/bc_grid.rds")

dfo = sf::read_sf("data/dfo_sara_occurrences_in_BC_all_species.gpkg")
dfo_ch = sf::read_sf("data/dfo_sara_critical_habitat_bc.gpkg")
cdc = readRDS("app/www/CDC_polygons_trimmed_by_DFO.rds")

if(!file.exists("data/dfo_sara_occurrences_in_BC_all_species_geom_fixed.gpkg")){
  dfo_fixed = repair_geoms(dfo)
  dfo_fixed = sf::write_sf(dfo_fixed, "data/dfo_sara_occurrences_in_BC_all_species_geom_fixed.gpkg")
} else {
  dfo_fixed = sf::read_sf("data/dfo_sara_occurrences_in_BC_all_species_geom_fixed.gpkg")
}

dfo_hull = sf::st_convex_hull(dfo_fixed)

# Check that we only have one column for geometries called 'geom'
dfo = sf::st_transform(dfo, 4326)
dfo_fixed = sf::st_transform(dfo_fixed, 4326)
dfo_hull = sf::st_transform(dfo_hull, 4326)

saveRDS(dfo_hull, "app/www/dfo_sara_occurrences_in_BC_convex_hull.rds")

dfo_ch = sf::st_transform(dfo_ch, 4326)

saveRDS(dfo_ch, "app/www/dfo_critical_habitat.rds")

# Split dfo data by name, population, then by bc grid cell ID.
dfo |>
  dplyr::group_by(Common_Name_EN, Population_EN) |>
  dplyr::group_split() |>
  purrr::iwalk( ~ {
    the_common_name = unique(.x$Common_Name_EN)
    the_pop_name = unique(.x$Population_EN)

    spatial_dat = .x |>
      dplyr::mutate(geometry_is_okay = sf::st_is_valid(geom))

    broken_geometries = spatial_dat |> dplyr::filter(!geometry_is_okay)
    okay_geometries = spatial_dat |> dplyr::filter(geometry_is_okay)

    if(nrow(broken_geometries) > 0){
      broken_geometries = broken_geometries |> wdpar::st_repair_geometry()
      okay_geometries = dplyr::bind_rows(
        okay_geometries,
        broken_geometries
      )
    }
    # okay_geometries_summed = okay_geometries |>
    #   dplyr::group_by(Common_Name_EN,Population_EN) |>
    #   dplyr::summarise()

    okay_geometries_w_cell_id = okay_geometries |>
      dplyr::mutate(row_id = dplyr::row_number()) |>
      sf::st_join(sf::st_as_sf(bc_g)) |>
      dplyr::filter(!duplicated(row_id)) |>
      dplyr::select(-row_id)

    okay_geometries_w_cell_id |>
      dplyr::group_by(Common_Name_EN, Population_EN, cell_id) |>
      dplyr::group_split() |>
      purrr::iwalk( ~ {
        # Create containing folder for this common name / population name / cell id

        the_common_name = unique(.x$Common_Name_EN)
        the_pop_name = unique(.x$Population_EN)
        the_cell_id = unique(.x$cell_id)

        the_folder = paste0("app/www/dfo/",the_common_name,"/",the_pop_name)
        if(!dir.exists(the_folder)){
          dir.create(the_folder,recursive = T)
        }
        saveRDS(.x, paste0(the_folder,"/cell_",the_cell_id,".rds"))
        # sf::write_sf(.x, paste0(the_folder,"/cell_",the_cell_id,".gpkg"))
        # geoarrow::write_geo(.x, paste0(the_folder,"/cell_",the_cell_id,".parquet"))
        # arrow::write_parquet(arrow::as_arrow_table(.x),paste0(the_folder,"/cell_",the_cell_id,".parquet"))
        # qs::qsave(.x, paste0(the_folder,"/cell_",the_cell_id,".qs"))
      }
      )
  }, .progress = TRUE)


