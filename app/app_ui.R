library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ggplot2)
library(shinyWidgets)

source('leaflet_module.R')

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

ui <- page_fluid(
  shiny::includeCSS("www/my_styles.css"),
  # shiny::includeScript("www/my_js.js"),
  card(
    # leafletOutput('myleaf', height = '100%'),
    leaflet_mod_UI('myleaf'),
    class = 'leaf-card'
  ),
  absolutePanel(
    top = '40%', left = '5%', width = '20%', height = '100%',
    draggable = T,
    card(
      toolbox,
      class = 'floating-toolbox'
    )
  )
)
