
# Risk status table filtered by domain
rs_d = reactive(riskstat |> dplyr::filter(domain %in% input$dom_sel))

observe({
  # Find species choices for dropdown.
  spec_choices = unique(rs_d()$cosewic_common_name)
  spec_choices = spec_choices[order(unique(spec_choices))]

  # Add in little check marks and x marks telling us whether or not there
  # is DFO data, DFO CH data, CDC data, or KFO data for each species.
  dfo_data_availability = data.frame(common_name = spec_choices) |>
    dplyr::left_join(dfo_r_p_sp) |>
    dplyr::group_by(common_name) |>
    dplyr::reframe(n = sum(n,na.rm=T)) |>
    dplyr::ungroup() |>
    dplyr::mutate(data_present = ifelse(n > 0 & !is.na(n), "✅", "❌"))

  dfo_ch_data_availability = data.frame(common_name = spec_choices) |>
    dplyr::left_join(dfo_ch |>
                       sf::st_drop_geometry() |>
                       dplyr::select(common_name = Common_Name_EN) |>
                       dplyr::mutate(n = 1)) |>
    dplyr::mutate(n = tidyr::replace_na(n, 0)) |>
    dplyr::group_by(common_name) |>
    dplyr::reframe(n = sum(n,na.rm=T)) |>
    dplyr::ungroup() |>
    dplyr::mutate(data_present = ifelse(n > 0 & !is.na(n), "✅", "❌"))

  cdc_r_p_sp = cdc |>
    sf::st_drop_geometry() |>
    dplyr::select(common_name = ENG_NAME) |>
    dplyr::count(common_name)

  cdc_data_availability = data.frame(common_name = spec_choices) |>
    dplyr::left_join(cdc_r_p_sp) |>
    dplyr::mutate(data_present = ifelse(n > 0 & !is.na(n), "✅", "❌"))

  kfo_data_availability = data.frame(common_name = spec_choices) |>
    dplyr::left_join(kfo_all_sp |> dplyr::mutate(n = 1)) |>
    dplyr::mutate(n = tidyr::replace_na(n, 0)) |>
    dplyr::group_by(common_name) |>
    dplyr::reframe(n = sum(n,na.rm=T)) |>
    dplyr::ungroup() |>
    dplyr::mutate(data_present = ifelse(n > 0 & !is.na(n), "✅", "❌"))

  # Find the longest species name; pad all the other species names' ends with
  # blank spaces so that the DFO and other columns are in (roughly) the same place.
  # browser()
  longest_name_chars = max(stringr::str_count(spec_choices))
  whitespace_padding = stringr::str_pad("",width = 10,side='left')
  # Update species selection options based on which domain has been selected.
  updatePickerInput('spec_sel',
                    choices = spec_choices,
                    choicesOpt = list(
                      subtext = paste0(#"data: ",
                                       whitespace_padding,
                                       "DFO:",
                                       dfo_data_availability$data_present,
                                       "; DFO CH:",
                                       dfo_ch_data_availability$data_present,
                                       "; CDC:",
                                       cdc_data_availability$data_present,
                                       "; KFO:",
                                       kfo_data_availability$data_present
                                       )),
                    session=session)
  # Reset population selector to NA so that the order of reactive expressions works well
  updatePickerInput('pop_sel',choices = NULL, session=session)
  print("updated spec_sel input")
})
# Risk status table further filtered by species
rs_sp = reactive({
  req(!is.null(input$spec_sel))
  print("resolved rs_sp reactive")
  # Wipe any previous searches and polygons that have been mapped for either
  # the region search or the coordinate input search.
  region_for_leaflet(NULL)
  buffered_click_for_leaflet(NULL)
  dfo_data_for_region(NULL)
  rs_d() |>
    dplyr::filter(cosewic_common_name %in% input$spec_sel)
})

# Use the species that has been selected (based on the risk registry table)
# and find which population(s) we have spatial data for.
observe({
  req(nrow(rs_sp()) > 0)
  # Find population(s) in DFO polygon for this data.
  this_sp_pops_dfo = dfo_r_p_sp[dfo_r_p_sp$common_name %in% c(input$spec_sel),]$population_name
  # As above, for CDC.
  this_sp_pops_cdc = cdc[cdc$ENG_NAME %in% input$spec_sel,]$population
  # Combine.
  this_sp_pops = c(this_sp_pops_dfo,this_sp_pops_cdc)
  # Replace any populations that have no label (i.e., are NA), with 'Unspecified'.
  this_sp_pops = this_sp_pops |>
    lapply(\(x) tidyr::replace_na(x, "Unspecified")) |>
    unlist()
  this_sp_pops = unique(this_sp_pops)
  updatePickerInput('pop_sel',
                    choices = unique(this_sp_pops)[order(this_sp_pops)],
                    selected = unique(this_sp_pops)[1],
                    session=session)
})

# rs_p = reactive({
#   req(nrow(rs_sp()) > 0)
#   req(!is.null(input$pop_sel))
#   # Need the above line to ensure picker input for population is updated
#   # before this reactive expression is resolved.
#   if(length(input$pop_sel) == 1){
#     if(input$pop_sel == "NA"){
#       print('no pop selected - returning all rs_sp()')
#       output = rs_sp()
#     }
#   } else {
#     output = rs_sp() |> dplyr::filter(legal_population %in% input$pop_sel)
#   }
#   output
# })

layers_to_map = reactive({
  input$dataset_sel
})

spec_sel_r = reactive({
  input$spec_sel
})

pop_sel_r = reactive({
  input$pop_sel |>
    lapply(\(x) ifelse(x == 'Unspecified',NA,x)) |>
    unlist()
})
