# = = = = = = = = = = = = = = = = = =
library(bcdata)
library(sf)
library(readxl)
library(openxlsx)
library(tidyverse)

# = = = = = = = = = = = = = = = = = =
## Data
### 1. DFO polygons - gold standard
dfo = sf::read_sf("app\\www\\dfo_sara_occurrences_in_BC_all_species.gpkg")
dfo_ch = sf::read_sf("app\\www\\dfo_sara_critical_habitat_bc.gpkg")

### 2. CDC polygons (non-sensitive)
cdc = bcdc_query_geodata('species-and-ecosystems-at-risk-publicly-available-occurrences-cdc') |>
# Establish filters for CDC polygons (ray-finned fishes, anything else?)
  filter(TAX_CLASS %in% c("ray-finned fishes","bivalves")) |>
  collect()

### 3. Chrissy's excel file that notes which data is available.
dat = read_excel("data/CDCresultsExport.xlsx")

# = = = = = = = = = = = = = = = = = =
## Data Cleaning

# Transform CDC to WGS 84 / Pseudomercator
cdc = sf::st_transform(cdc, sf::st_crs(dfo))

# Split by common name and scientific name, filter DFO and DFO crit hab for the
# names, then delete any overlapping rows or geometries in CDC
cdc_trimmed = cdc |>
  dplyr::group_by(ENG_NAME, SCI_NAME) |>
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
      dat_trimmed = suppressWarnings(
        .x |>
          dplyr::mutate(row_id = row_number()) |>
          sf::st_difference(relev_dfo) |>
          dplyr::group_by(ENG_NAME,SCI_NAME,TAX_CLASS,GLOB_RANK,
                          PROV_RANK,COSEWIC,BC_LIST,SARA_SCHED,
                          row_id) |>
          dplyr::summarise(.groups = 'drop')
        )
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
    }, .progress = T)

cdc_trimmed = cdc_trimmed |>
  dplyr::bind_rows()

###
# Come Tuesday, let's look at:
# 1. Stepping through this process with John
# 2. Create hundreds of branches
# 3. simplify and clean up dat and dfo scientific / common / population names
# 4. Maybe search to see if there are multiple rows in Chrissy's table for a given
# common or scientific name - if there are, flag that as a row for which DFO should
# have its population names appended to common name (e.g. think of Bull trout, Bull trout - South Pacific, etc.)

# Fill in columns M for CDC polygons, and R, S with DFO occurrence polygons + critical habitat polygons
for(i in 1:nrow(dat)){
    print(i)
    dfo_for_row = dfo |>
      dplyr::mutate(cn_pop = paste0(Common_Name_EN, " - ", Population_EN))
      dplyr::filter(Common_Name_EN == dat[i,]$`English Name` | Scientific_Name == dat[i,]$`Scientific Name`)
    dfo_ch_for_row = dfo_ch |> dplyr::filter(Common_Name_EN == dat[i,]$`English Name` | Scientific_Name == dat[i,]$`Scientific Name`)
    cdc_for_row = cdc_trimmed |> dplyr::filter(ENG_NAME == dat[i,]$`English Name` | SCI_NAME == dat[i,]$`Scientific Name`)

    dat[i,]$`CDC Mapped Locations - Public` = ifelse(nrow(cdc_for_row) > 0, "Y", "N")
    dat[i,]$`DFO Dist` = ifelse(nrow(dfo_for_row) > 0, "Y", "N")
    dat[i,]$`DFO CH` = ifelse(nrow(dfo_ch_for_row) > 0, "Y", "N")

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

openxlsx::saveWorkbook(wb, "output/CDCREsultsExport_w_DFO_CDC_spatial_match.xlsx", overwrite = T)
openxlsx::write.xlsx(dat, "output/CDCResultsExport_w_spatial_match.xlsx")
