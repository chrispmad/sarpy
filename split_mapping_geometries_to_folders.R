library(tidyverse)
library(sf)
library(qs)

ensure_multipolygons <- function(X) {
  tmp1 <- tempfile(fileext = ".gpkg")
  tmp2 <- tempfile(fileext = ".gpkg")
  st_write(X, tmp1)
  gdalUtilities::ogr2ogr(tmp1, tmp2, f = "GPKG", nlt = "MULTIPOLYGON")
  Y <- st_read(tmp2)
  st_sf(st_drop_geometry(X), geom = st_geometry(Y))
}

bc = bcmaps::bc_bound()

bc_g = sf::st_as_sf(sf::st_make_grid(x = bc, n = c(25,25)))

bc_g = bc_g |>
  dplyr::mutate(cell_id = row_number()) |>
  sf::st_transform(4326)

# ggplot()+geom_sf(data = bc_g[1,], aes(fill = cell_id)) + geom_sf(data = bc, fill = 'transparent')

dfo = sf::read_sf("data/dfo_sara_occurrences_in_BC_all_species.gpkg")
dfo_ch = sf::read_sf("data/dfo_sara_critical_habitat_bc.gpkg")
cdc = sf::read_sf("app/www/CDC_polygons_trimmed_by_DFO.gpkg")

dfo_s = sf::st_simplify(dfo)

dfo = sf::st_transform(dfo, 4326)
dfo_s = sf::st_transform(dfo_s, 4326)
dfo_ch = sf::st_transform(dfo_ch, 4326)
cdc = sf::st_transform(cdc, 4326)

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
    okay_geometries |>
      sf::st_join(bc_g) |>
      dplyr::group_by(Common_Name_EN, Population_EN, cell_id) |>
      dplyr::group_split() |>
      purrr::iwalk( ~ {        # Create containing folder for this common name / population name / cell id

        the_common_name = unique(.x$Common_Name_EN)
        the_pop_name = unique(.x$Population_EN)
        the_cell_id = unique(.x$cell_id)

        the_folder = paste0("output/testing/",the_common_name,"/",the_pop_name)
        if(!dir.exists(the_folder)){
          dir.create(the_folder,recursive = T)
        }
        qs::qsave(.x, paste0(the_folder,"/cell_",the_cell_id,".qs"))
      }
      )
  }, .progress = TRUE)


