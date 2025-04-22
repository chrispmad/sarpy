import folium.map
from shiny import App, ui, reactive, render, req
import pandas as pd
from shinywidgets import render_widget, output_widget
import folium
from pathlib import Path
from folium.plugins import MarkerCluster
import geopandas as gpd

#%% 
#%% 
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
        ui.ouput_ui("spec_sel"),
        # ui.output_data_frame('rsm_dt'),
        {"class": "floating-toolbox"}
    )
)

def server(input, output, session):
    
    # sar_polys = gpd.read_file(Path(__file__).parent/"www\\dfo_sara_and_crit_hab_bulltrout_and_sockeye_data.gpkg")
    
    @reactive.calc
    def rsm():
        dat = pd.read_csv(Path(__file__).parent/"www\\risk_status_merged.csv")
        return dat
    
    # @render.ui
    # def spec_sel():
    #     rsm()['']
    @render.data_frame
    def rsm_dt():
       return render.DataTable(rsm(), selection_mode='row')
    
    # @render.ui
    # def myleaf():
    #     sar_polys_geojson = folium.GeoJson(data=sar_polys, style_function=lambda x: {
    #         "fillColor": "orange",
    #         "weight": 1,
    #         "color": "black",
    #         "fillOpacity": 0.75
    #         })
    #     my_map = folium.Map(data = [54.93147, -124.12823], zoom_start = 8)
    #     sar_polys_geojson.add_to(my_map)
    #     #boulder_coords = [40.015, -105.2705]
    #     #Create the map
    #     #my_map = folium.Map(location = boulder_coords, zoom_start = 13)

    #     return my_map
    
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
