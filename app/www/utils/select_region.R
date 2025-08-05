# - - - - - - - - - - -
# REGION SELECT!

# The user can either choose to display natural resource regions, or not;
# the latter case is the option "None" under the input 'reg_sel'
observeEvent(input$reg_sel, {
  if(input$reg_sel == "None"){
    region_for_leaflet = reactiveVal()
  }
})

# If 'reg_sel' is set to 'Regions', and not 'None', we then listen for which
# of the regions has been selected in the input 'reg_ent_sel'. The selected
# region gets temporarily saved inside the 'region_for_leaflet()' reactiveVal.
observeEvent(input$reg_ent_sel, {
  req(!is.null(input$reg_ent_sel))

  obj_for_map = NULL

  if(input$reg_sel == "Region") {
    obj_for_map = nr_regs |> dplyr::filter(REGION_NAME == input$reg_ent_sel) |>
      dplyr::mutate(name_for_map = REGION_NAME)
  }
  region_for_leaflet(obj_for_map)
})
