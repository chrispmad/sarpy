library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ggplot2)
library(shinyWidgets)

domain_select = pickerInput('dom_sel','Domain',
                            choices = c("Terrestrial","Aquatic"),
                            selected = 'Aquatic',
                            options = pickerOptions(container = 'body'))
species_select = pickerInput('spec_sel','Species',choices = NULL,multiple = T,
                             options = pickerOptions(container = 'body',liveSearch = T))
population_select = pickerInput('pop_sel','Population',choices = NULL,multiple = T,
                                options = pickerOptions(container = 'body',liveSearch = T))

toolbox = tagList(
  h3("Toolbox"),
  domain_select,
  species_select,
  population_select
)

toolbox_abs_panel = absolutePanel(
  top = '40%', left = '5%', width = '20%', height = '100%',
  draggable = T,
  card(
    toolbox,
    class = 'floating-toolbox'
  )
)

summary_panel = card(
  h3("Summaries", style = 'text-align:center;'),
  bslib::card(
    card_header(
      "Summary 1"
    ),
    h5("I AM TEXT"),
    class = 'bg-success'
  ),
  bslib::card(
    card_header(
      "Summary 2"
    ),
    h5("I AM TEXT"),
    class = 'bg-primary'
  ),
  bslib::card(
    card_header(
      "Summary 3"
    ),
    h5("I AM TEXT"),
    class = 'bg-warning'
  ),
  class = 'summary-panel'
)

ui <- page_fluid(
  shiny::includeCSS("www/my_styles.css"),
  # shiny::includeScript("www/my_js.js"),
  card(
    leafletOutput('myleaf', height = '100%'),
    class = 'leaf-card'
  ),
  toolbox_abs_panel,
  summary_panel
)
