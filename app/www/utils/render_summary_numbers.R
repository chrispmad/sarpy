
output$area_summary_text = renderText({
  req(!is.null(input$spec_sel))

  total_sum = 0

  if(dfo_added()) total_sum = total_sum + as.numeric(sf::st_area(sf::st_union(dfo_polys())))
  if(dfo_hr_added()) total_sum = total_sum + as.numeric(sf::st_area(sf::st_union(dfo_polys_hr())))
  if(dfo_ch_added()) total_sum = total_sum + as.numeric(sf::st_area(sf::st_union(dfo_ch_selected())))
  if(cdc_added()) total_sum = total_sum + as.numeric(sf::st_area(sf::st_union(cdc_selected())))

  total_sum = total_sum / 1000000
  total_sum
})

output$occ_summary_text = renderText({
  req(!is.null(input$spec_sel) & kfo_added() == T)
  nrow(kfo_selected())
})
