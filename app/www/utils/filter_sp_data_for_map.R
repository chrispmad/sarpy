dfo_polys = reactive({
  req(!is.null(input$spec_sel))
  req(nrow(rs_p()) > 0)
  all_data = list()
  files_to_access = tidyr::crossing(cosewic_common_name = rs_p()$cosewic_common_name,
                                    legal_population = rs_p()$legal_population,
                                    cell_id = bc_grid_in_frame()$cell_id
  )
  for(i in 1:nrow(files_to_access)){
    row = files_to_access[i,]
    file_path = paste0("dfo\\",row$cosewic_common_name,"\\",row$legal_population,"\\cell_",row$cell_id,".rds")
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

cdc_selected = reactive({
  req(!is.null(input$spec_sel))
  cdc |>
    dplyr::filter(common_name %in% input$spec_sel)
})

# Initial loading of the 'dfo_polys_to_add' queue.
observe({
  if(nrow(dfo_polys()) > 0 & nrow(dfo_detail_polys_to_add()) == 0 & dfo_polys_added() == FALSE){
    dfo_detail_polys_to_add(dfo_polys())
  }
})

