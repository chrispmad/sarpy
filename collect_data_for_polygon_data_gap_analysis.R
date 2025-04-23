# = = = = = = = = = = = = = = = = = =
library(bcdata)
library(sf)
library(readxl)
library(openxlsx)
library(tidyverse)
library(wdpar)

# = = = = = = = = = = = = = = = = = =

# Function to extract and clean up population names from CDC info.
repair_geoms = function(d){
  if(sum(!sf::st_is_valid(d)) > 0){
    d_bad_geoms = d |>
      dplyr::filter(!sf::st_is_valid(geom))
    d_good_geoms = d |>
      dplyr::filter(sf::st_is_valid(geom))

    d_fixed_geoms = wdpar::st_repair_geometry(d_bad_geoms)

    output = dplyr::bind_rows(d_good_geoms, d_fixed_geoms)
  } else {
    output = d
  }
  return(output)
}

extract_pop_name = function(d,col_name){
  d |>
    dplyr::mutate(population = stringr::str_extract(!!rlang::sym(col_name), "(,| - |\\().*")) |>
    dplyr::mutate(population = stringr::str_remove_all(population,"(\\(|\\)|,| - )")) |>
    dplyr::mutate(population = stringr::str_squish(population)) |>
    dplyr::mutate(population = stringr::str_remove(population, "(?<=opulation)s$")) |>
    dplyr::mutate(population = stringr::str_remove(population, " ([Pp]opulation|[Gg]roup)")) |>
    dplyr::mutate(population = stringr::str_remove(population, "(?<!(Spring|Cultu|subspecie))s$"))
}

extract_com_name = function(d,name_col){
  d |>
    dplyr::mutate(common_name = stringr::str_extract(!!rlang::sym(name_col),"[a-zA-Z ]*")) |>
    dplyr::mutate(common_name = stringr::str_squish(common_name))
}

# = = = = = = = = = = = = = = = = = =
## Data
### 1. DFO polygons - gold standard
dfo = sf::read_sf("data\\dfo_sara_occurrences_in_BC_all_species.gpkg")
dfo_ch = sf::read_sf("data\\dfo_sara_critical_habitat_bc.gpkg")

### 2. CDC polygons (non-sensitive)
cdc = bcdc_query_geodata('species-and-ecosystems-at-risk-publicly-available-occurrences-cdc') |>
  # Establish filters for CDC polygons (ray-finned fishes, anything else?)
  # filter(TAX_CLASS %in% c("ray-finned fishes","bivalves")) |>
  filter(!TAX_CLASS %in% c("dicots","monocots","ferns","conifers","quillworts") & !is.na(TAX_CLASS)) |>
  collect()

### 3. Chrissy's excel file that notes which data is available.
dat = read_excel("data/CDCresultsExport.xlsx")

# = = = = = = = = = = = = = = = = = =
## Data Cleaning

# Transform CDC to WGS 84 / Pseudomercator
cdc = sf::st_transform(cdc, sf::st_crs(dfo))

# Pull out population for CDC rows that describe this.
cdc = cdc |>
  extract_pop_name("ENG_NAME")

# Clean up the population suffix in Chrissy's data table.
dat = dat |>
  extract_pop_name("English Name")

# Clean up geometries of DFO, DFO CH and CDC.
dfo = repair_geoms(dfo)
cdc = repair_geoms(cdc)
dfo_ch = repair_geoms(dfo_ch)

# Split by common name, scientific name, and population name,
# then filter DFO and DFO crit hab for those
# names, then delete any overlapping geometries in CDC
cdc_trimmed = cdc |>
  dplyr::group_by(ENG_NAME, SCI_NAME, population) |>
  dplyr::group_split() |>
  map( ~ {
    output = .x
    the_common_name = unique(.x$ENG_NAME)

    relev_dfo = dfo |>
      dplyr::filter(Common_Name_EN == unique(.x$ENG_NAME) | Scientific_Name == unique(.x$SCI_NAME)) |>
      dplyr::group_by(Common_Name_EN, Scientific_Name, Population_EN,Taxon,Eco_Type,
                      SARA_Status) |>
      dplyr::summarise(.groups = 'drop')

    relev_dfo_ch = dfo_ch |>
      dplyr::filter(Common_Name_EN == unique(.x$ENG_NAME) | Scientific_Name == unique(.x$SCI_NAME)) |>
      dplyr::group_by(Common_Name_EN, Scientific_Name, Population_EN,Taxon,Eco_Type,
                      SARA_Status) |>
      dplyr::summarise(.groups = 'drop')

    print(paste0(nrow(relev_dfo)," rows found for ",the_common_name))

    if(nrow(relev_dfo) > 0) {
      init_area = sum(round(as.numeric(sf::st_area(.x)),0))
      print(paste0("initial area (m^2) of this chunk of data: ",init_area))
      dat_trimmed = suppressWarnings({
       .x |>
          dplyr::mutate(row_id = row_number()) |>
          sf::st_difference(relev_dfo) |>
          dplyr::group_by(ENG_NAME,SCI_NAME,TAX_CLASS,GLOB_RANK,
                          PROV_RANK,COSEWIC,BC_LIST,SARA_SCHED,
                          row_id) |>
          dplyr::summarise(.groups = 'drop')
      })
      new_area = sum(round(as.numeric(sf::st_area(dat_trimmed)),0))
      print(paste0("new area (m^2) of this chunk of data: ",new_area," (",100*round(new_area/init_area,2),"%)"))
    }
    if(nrow(relev_dfo_ch) > 0) {
      print(paste0("before trimming DFO critical habitat, area (m^2) of this chunk of data: ",new_area))
      dat_trimmed = suppressWarnings(
        dat_trimmed |>
          dplyr::mutate(row_id = row_number()) |>
          sf::st_difference(relev_dfo_ch) |>
          dplyr::group_by(ENG_NAME,SCI_NAME,TAX_CLASS,GLOB_RANK,
                          PROV_RANK,COSEWIC,BC_LIST,SARA_SCHED,
                          row_id) |>
          dplyr::summarise(.groups = 'drop')
      )
      new_area = sum(round(as.numeric(sf::st_area(dat_trimmed)),0))
      print(paste0("new area (m^2) of this chunk of data: ",new_area," (",100*round(new_area/init_area,2),"%)"))
      output = dat_trimmed
    }
    output
  }, .progress = T) |>
  dplyr::bind_rows()

# Example plot for Chrissy of trimming CDC polygons with DFO's polygons.

eg_cdc = cdc |> dplyr::filter(ENG_NAME == 'Salish Sucker')
eg_dfo = dfo |> dplyr::filter(Common_Name_EN == 'Salish Sucker')
eg_dfo_ch = dfo_ch |> dplyr::filter(Common_Name_EN == 'Salish Sucker')
eg_cdc_t = cdc_trimmed |> dplyr::filter(ENG_NAME == 'Salish Sucker')
library(leaflet)
library(htmlwidgets)
l = leaflet() |>
  addProviderTiles(providers$CartoDB) |>
  addLayersControl(position = 'bottomright',
                   overlayGroups = c("CDC","DFO","DFO CH","CDC trimmed"),
                   options = layersControlOptions(collapsed = F)) |>
  addMapPane('cdc', zIndex = 300) |>
  addMapPane('dfo', zIndex = 500) |>
  addMapPane('dfo_ch', zIndex = 700) |>
  addMapPane('cdc_t', zIndex = 900) |>
  addPolygons(
    data = eg_cdc |> sf::st_transform(4326),
    color = 'darkgreen',
    fillColor = 'darkgreen',
    fillOpacity = 1,
    opacity = 1,
    group = 'CDC',
    options = pathOptions(pane = 'cdc')
  ) |>
  addPolygons(
    data = eg_dfo |> sf::st_transform(4326),
    color = 'darkblue',
    fillColor = 'darkblue',
    fillOpacity = 1,
    opacity = 1,
    group = 'DFO',
    options = pathOptions(pane = 'dfo')
  ) |>
  addPolygons(
    data = eg_dfo_ch |> sf::st_transform(4326),
    color = 'purple',
    fillColor = 'purple',
    fillOpacity = 1,
    opacity = 1,
    group = 'DFO CH',
    options = pathOptions(pane = 'dfo_ch')
  ) |>
  addPolygons(
    data = eg_cdc_t |> sf::st_transform(4326),
    color = 'red',
    fillColor = 'red',
    fillOpacity = 1,
    opacity = 1,
    group = 'CDC trimmed',
    options = pathOptions(pane = 'cdc_t')
  ) |>
  addLegend(position = 'topright',
            labels = c("CDC","DFO","DFO CH","CDC trimmed"),
            colors = c("darkgreen","darkblue","purple","red"))
htmlwidgets::saveWidget(l, file = "output/trim CDC polygons Salish sucker example.html")

# Come Tuesday, let's look at:
# 1. Maybe search to see if there are multiple rows in Chrissy's table for a given
# common or scientific name - if there are, flag that as a row for which DFO should
# have its population names appended to common name (e.g. think of Bull trout, Bull trout - South Pacific, etc.)

# Also, clean up the common name and throw that in its own column for
# CDC and also Chrissy's data table.
cdc_trimmed = cdc_trimmed |> extract_com_name("ENG_NAME")
dat = dat |> extract_com_name("English Name")

# Fill in columns M for CDC polygons, and R, S with DFO occurrence polygons + critical habitat polygons
for(i in 1:nrow(dat)){
  print(i)
  print(dat[i,]$`English Name`)
  dfo_for_row = dfo |>
    dplyr::filter(Common_Name_EN == dat[i,]$common_name) |>
    dplyr::filter(Population_EN == dat[i,]$population | is.na(Population_EN))

  dfo_ch_for_row = dfo_ch |>
    dplyr::filter(Common_Name_EN == dat[i,]$common_name) |>
    dplyr::filter(Population_EN == dat[i,]$population | is.na(Population_EN))

  cdc_for_row = cdc_trimmed |>
    dplyr::filter(common_name == dat[i,]$common_name) |>
    dplyr::filter(population == dat[i,]$population | is.na(population))

  dat[i,]$`CDC Mapped Locations - Public` = ifelse(nrow(cdc_for_row) > 0, "Y", "N")
  dat[i,]$`DFO Dist` = ifelse(nrow(dfo_for_row) > 0, "Y", "N")
  dat[i,]$`DFO CH` = ifelse(nrow(dfo_ch_for_row) > 0, "Y", "N")

  if(nrow(dfo_for_row) > 0 & nrow(cdc_for_row) > 0){
    print("LOOK AT THIS COLUMN!")
  }

  # Bring across additional data, if possible.
  if(nrow(dfo_for_row) > 0){
    if(is.na(dat[i,]$SARA)){
      dat[i,]$SARA = unique(dfo_for_row$SARA_Status)[1]
    }
  }
  if(nrow(dfo_ch_for_row) > 0){
    if(is.na(dat[i,]$SARA)){
      dat[i,]$SARA = unique(dfo_ch_for_row$SARA_Status)[1]
    }
  }
  if(nrow(cdc_for_row) > 0){
    if(is.na(dat[i,]$Global)) {
      dat[i,]$Global = unique(cdc_for_row$GLOB_RANK)
    }
    if(is.na(dat[i,]$COSEWIC)){
      dat[i,]$COSEWIC = unique(cdc_for_row$COSEWIC)
    }
    if(is.na(dat[i,]$SARA)){
      dat[i,]$SARA = unique(cdc_for_row$SARA_SCHED)
    }
  }
}

# Save the trimmed CDC polygons.
sf::write_sf(cdc_trimmed, "app/www/CDC_polygons_trimmed_by_DFO.gpkg")

# openxlsx::saveWorkbook(wb, "output/CDCREsultsExport_w_DFO_CDC_spatial_match.xlsx", overwrite = T)
openxlsx::write.xlsx(dat |> dplyr::select(-c(population,common_name)), "output/CDCResultsExport_w_spatial_match.xlsx")
