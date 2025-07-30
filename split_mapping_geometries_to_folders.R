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

bc = bcmaps::bc_bound() |> sf::st_transform(4326)

bc_g = sf::st_as_sf(sf::st_make_grid(x = bc, n = c(200,200)))

bc_g = bc_g |>
  dplyr::mutate(cell_id = row_number())

ggplot() + geom_sf(data = bc) + geom_sf(data = bc_g, fill = 'transparent')

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

# dfo_hull = sf::st_convex_hull(dfo_fixed)

# Check that we only have one column for geometries called 'geom'
dfo = sf::st_transform(dfo, 4326)
dfo_fixed = sf::st_transform(dfo_fixed, 4326)
# dfo_hull = sf::st_transform(dfo_hull, 4326)

# saveRDS(dfo_hull, "app/www/dfo_sara_occurrences_in_BC_convex_hull.rds")
dfo_hull = readRDS("app/www/dfo_sara_occurrences_in_BC_convex_hull.rds")

dfo_sp_count = dfo_hull |>
  sf::st_drop_geometry() |>
  dplyr::select(common_name = Common_Name_EN, population_name = Population_EN) |>
  dplyr::count(common_name, population_name)

saveRDS(dfo_sp_count, "app/www/dfo_species_row_count.rds")

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
    # # confirm correct CRS
    # okay_geometries = sf::st_transform(okay_geometries, 4326)

    # Identify which grid cells overlap with these geometries
    bc_g_overlap = bc_g |>
      sf::st_transform(sf::st_crs(okay_geometries)) |>
      sf::st_filter(okay_geometries) |>
      sf::st_transform(4326) |>
      dplyr::summarise()

    # Use the list of grid cells that overlapped with the geometry in question
    # to population new columns in a 'cells_w_sp' object.
    # cells_w_sp = bc_g[bc_g$cell_id %in% unique(okay_geometries_w_cell_id$cell_id),]
    the_common_name = unique(okay_geometries$Common_Name_EN)
    the_pop_name = unique(okay_geometries$Population_EN)
    bc_g_overlap$Common_Name_EN = the_common_name
    bc_g_overlap$Population_EN = the_pop_name
    the_folder = paste0("app/www/dfo/",the_common_name,"/",the_pop_name)
    # Delete anything in the folder
    if(dir.exists(the_folder)){
      list.files(the_folder,pattern = '.rds', full.names = T) |> lapply(file.remove)
    }
    # If the folder doesn't exist, create it.
    if(!dir.exists(the_folder)){
      dir.create(the_folder,recursive = T)
    }
    saveRDS(bc_g_overlap, paste0(the_folder,"/grid_cells.rds"))
    # Also save a high-res polygon in the same folder
    high_res_polygon = okay_geometries |>
      dplyr::group_by(Common_Name_EN,Population_EN) |>
      dplyr::summarise(.groups = 'drop') |>
      dplyr::ungroup() |>
      sf::st_transform(4326)
    # Simplify the geometries a bit? Use a tryCatch so if it breaks, we just
    # retain the original geometry.

    # high_res_polygon = tryCatch(
    #   expr = sf::st_simplify(high_res_polygon),
    #   error = function(e) return(high_res_polygon)
    # )
    high_res_polygon = tryCatch(
      expr = rmapshaper::ms_simplify(high_res_polygon),
      error = function(e) return(high_res_polygon)
    )
    high_res_polygon = high_res_polygon |> sf::st_transform(4326)
    # high_res_polygon = rmapshaper::ms_simplify(high_res_polygon)
    saveRDS(high_res_polygon, paste0(the_folder,"/highres_polygon.rds"))
  }, .progress = TRUE)

# Search the BC Data Catalogue's "known fish distribution" layer for
# all common names above.
all_common_names = c(unique(dfo$Common_Name_EN),unique(dfo_ch$Common_Name_EN),unique(cdc$common_name))
all_common_names = stringr::str_to_title(all_common_names)
all_common_names = unique(all_common_names)

the_query = bcdata:::CQL(paste0(paste0("SPECIES_NAME like '",all_common_names,"'"), collapse = ' or '))
kfo_all_species = bcdata::bcdc_query_geodata('known-bc-fish-observations-and-bc-fish-distributions') |>
  bcdata::filter(the_query) |>
  bcdata::collect() |>
  sf::st_transform(4326)
kfo_all_species_sel_cols = kfo_all_species |>
  dplyr::select(common_name = SPECIES_NAME, SPECIES_CODE, OBSERVATION_DATE)
saveRDS(kfo_all_species_sel_cols,"app/www/kfo_all_species.rds")




### Split DFO by natural resource regions
regs = bcmaps::nr_regions() |> sf::st_transform(sf::st_crs(dfo))

dfo_w_regs = dfo |>
  sf::st_join(regs |> dplyr::select(REGION_NAME))

for(i in 1:nrow(regs)){
  print(i)
  the_region_name = regs[i,]$REGION_NAME
  dfo_for_file = dfo_w_regs[dfo_w_regs$REGION_NAME == the_region_name,]
  # simplify the geometries!
  bc_g_overlap = bc_g |>
    sf::st_transform(sf::st_crs(dfo_for_file)) |>
    sf::st_join(dfo_for_file |> dplyr::select(Common_Name_EN,Population_EN,Scientific_Name,
                                              Taxon,Eco_Type)) |>
    sf::st_transform(4326) |>
    dplyr::group_by(Common_Name_EN,Population_EN,Scientific_Name,
                    Taxon,Eco_Type) |>
    dplyr::summarise() |>
    dplyr::ungroup()
  saveRDS(bc_g_overlap, file = paste0("app/www/dfo_by_region/dfo_for_",stringr::str_to_lower(the_region_name),".rds"))
}

