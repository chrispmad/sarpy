# PART 4 - Exercise 1
# ///////////////////

from shiny import App, ui, reactive, render, req
import pandas as pd
from shinywidgets import render_widget, output_widget
import folium
from pathlib import Path
from folium.plugins import MarkerCluster

species_sel = ui.input_selectize('spec_sel',"Species",
                                 choices=['Need Data'])

app_ui = ui.page_fluid(
    ui.include_css(Path(__file__).parent/"www\\my_styles.css"),
    ui.card(
        ui.output_ui('myleaf'),
        {"class": "moop"}
    ),
        ui.card(
        ui.h3("TOOLBOX"),
        ui.output_data_frame('rsm_dt'),
        {"class": "floating-toolbox"}
    )
)

def server(input, output, session):
    
    @render.ui
    def myleaf():
        boulder_coords = [40.015, -105.2705]
        #Create the map
        my_map = folium.Map(location = boulder_coords, zoom_start = 13)
        return my_map
    
    @reactive.calc
    def rsm():
        dat = pd.read_csv(Path(__file__).parent/"www\\risk_status_merged.csv")
        return dat
    
    @render.data_frame
    def rsm_dt():
       return render.DataTable(rsm(), selection_mode='row')
    #@reactive.effect
    #ui.update_selectize('spec_sel', choices = spdat()['species_names'])
    
    #  Start with empty data frame
    #todos = reactive.value(pd.DataFrame())
    #selected_row_reactive = reactive.value("BLROP")
#
    #@reactive.calc
    #@render.data_frame
    #def dt():
    #    return render.DataTable(todos(), selection_mode='row')
    #
    ## Add a new todo
    #@reactive.effect
    #@reactive.event(input.add)
    #def _():
    #    req(input.task().strip())
    #    newTask = pd.DataFrame(
    #        {
    #            "created": [datetime.now().strftime("%Y-%m-%d %H:%M:%S")],
    #            "task": [input.task()],
    #            "completed": [None],
    #        }
    #    )
    #    todos.set(pd.concat([todos(), newTask], ignore_index=True))
    #    ui.update_text("task", value="")


app = App(app_ui, server, static_assets=Path(__file__).parent/"www")
