library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ggplot2)
library(shinyWidgets)
library(readr)

# current_zoom = span("Current map zoom: ",textOutput('leaf_zoom'),
#                     style = 'display:ruby;') |>
#   bslib::tooltip('1 is minimum zoom, 18 is most zoomed in')

# dfo_data_fidelity = span("DFO geometries displayed: ",textOutput('dfo_geom_type'),
#                          style = 'display:ruby;') |>
#   bslib::tooltip('To enhance app performance, simplified geometries are shown for DFO up to a zoom level of 10.')

# map_pal_select = radioButtons('map_pal_sel', label = "Colour Map By...", choices = c("Dataset","Species","Population"), selected = "Species", inline = T)

database_choices = c('DFO Occurrences, Simple (DFO)' = 'DFO',
                     'DFO Occurrences, High-res (DFO HR)' = "DFO HR",
                     'DFO Critical Habitat (DFO CH)' = "DFO CH",
                     'Conservation Data Centre (CDC)' = "CDC",
                     'Known Fish Occurrences (KFO)' = "KFO")

dataset_select = checkboxGroupInput("dataset_sel","Datasets to Plot",
                                    choices = database_choices,
                                    selected = database_choices[-2])

domain_select = pickerInput('dom_sel','Domain',
                            choices = c("Terrestrial","Aquatic"),
                            selected = 'Aquatic',
                            options = pickerOptions(container = 'body'))
species_select = pickerInput('spec_sel','Species',choices = NULL,multiple = T,
                             options = pickerOptions(container = 'body',liveSearch = T))
population_select = pickerInput('pop_sel','Population',choices = NULL,multiple = T,
                                options = pickerOptions(container = 'body',liveSearch = T))

polygon_icon = div(shiny::icon("draw-polygon"), id = 'poly_icon_d', class = 'menu-icon hidden')
point_icon = div(shiny::icon("map-pin"), id = 'point_icon_d', class = 'menu-icon hidden')

toolbox = tagList(
  h2("Toolbox", style = 'margin-bottom:-1rem;'),
  # current_zoom,
  # dfo_data_fidelity,
  dataset_select,
  domain_select,
  species_select,
  population_select,
  polygon_icon,
  point_icon
)

toolbox_abs_panel = absolutePanel(
  top = '30%', left = '5%', width = '25%', height = '100%',
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
      "Area (km<sup>2</sup>)"
    ),
    textOutput('area_summary_text'),
    class = 'bg-success'
  ),
  bslib::card(
    card_header(
      "Number of Occurrences"
    ),
    textOutput('occ_summary_text'),
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
  shiny::includeScript("www/my_JS.js"),
  card(
    leafletOutput('myleaf', height = '100%'),
    class = 'leaf-card'
  ),
  toolbox_abs_panel,
  summary_panel
)
