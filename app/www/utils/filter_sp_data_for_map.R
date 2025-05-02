dfo_polys = reactive({
  req(!is.null(input$spec_sel))
  req(!is.null(input$pop_sel))
  # req(nrow(rs_p()) > 0)
  # browser()
  all_data = list()
  files_to_access = tidyr::crossing(cosewic_common_name = input$spec_sel,
                                    legal_population = input$pop_sel
  )
  for(i in 1:nrow(files_to_access)){
    row = files_to_access[i,]
    file_path = paste0("dfo/",row$cosewic_common_name,"/",row$legal_population,"/grid_cells.rds")
    if(file.exists(file_path)){
      all_data[[i]] = readRDS(file_path)
    }
  }

  if(length(all_data) > 0){
    all_data = all_data |>
      dplyr::bind_rows()
    print(paste0("DFO has ",nrow(all_data), " rows."))
  }
  all_data
})

dfo_polys_hr = reactive({
  req(!is.null(input$spec_sel))
  req(!is.null(input$pop_sel))

  all_data = list()
  files_to_access = tidyr::crossing(cosewic_common_name = input$spec_sel,
                                    legal_population = input$pop_sel
  )
  for(i in 1:nrow(files_to_access)){
    row = files_to_access[i,]
    file_path = paste0("dfo/",row$cosewic_common_name,"/",row$legal_population,"/highres_polygons.rds")
    if(file.exists(file_path)){
      all_data[[i]] = readRDS(file_path)
    }
  }

  if(length(all_data) > 0){
    all_data = all_data |>
      dplyr::bind_rows()
    print(paste0("DFO has ",nrow(all_data), " rows."))
  }
  all_data
})

dfo_ch_selected = reactive({
  req(!is.null(input$spec_sel))
  dfo_ch |>
    dplyr::filter(Common_Name_EN %in% input$spec_sel)
})

cdc_selected = reactive({
  req(!is.null(input$spec_sel))
  cdc |>
    dplyr::filter(common_name %in% input$spec_sel)
})

# Known fish occurrences
kfo_selected = reactive({
  req(!is.null(input$spec_sel))
  kfo_all_sp |>
    dplyr::filter(common_name %in% input$spec_sel)
})
