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
        ui.input_select(id = "dom_sel", label = "Domain",choices=['Terrestrial','Aquatic'],selected=['Aquatic'],multiple=True),
        ui.input_select(id = "spec_sel", label = "COSEWIC Common Name",choices=[],selected=[],multiple=True),
        ui.input_select(id = "pop_sel", label = "Population",choices=[],selected=[],multiple=True),
        ui.output_data_frame('rsm_dt'),
        {"class": "floating-toolbox"}
    )
)

def server(input, output, session):
    
    bc_bound = gpd.read_file(Path(__file__).parent/"www\\bc_bound.gpkg")
    # sar_polys = gpd.read_file(Path(__file__).parent/"www\\dfo_sara_and_crit_hab_bulltrout_and_sockeye_data.gpkg")
    rsm = pd.read_csv(Path(__file__).parent/"www\\risk_status_merged.csv")
        
    # Update species that can be selected based on 
    # Update species select input based on Chrissy's data table.
    @reactive.effect
    @reactive.event(input.dom_sel)
    def _():
        rsm_of_domain = rsm[rsm['Domain'].isin(input.dom_sel())]
        rsm_of_domain = rsm_of_domain.sort_values(by='COSEWIC common name')
        species_options = list(rsm_of_domain['COSEWIC common name'].unique())
        ui.update_select(id='spec_sel',choices = species_options, selected=species_options[0])

    @reactive.calc
    def rsm_sp_f():
        req(input.spec_sel())
        return rsm[rsm['COSEWIC common name'].isin(input.spec_sel())]
    
    # Update populations that can be selected based on which species has been selected.
    @reactive.effect
    def _():
        population_options = rsm_sp_f()['Legal population'].unique()
        print(str(population_options))
        if str(population_options) != '[nan]':   
            population_options = population_options[~pd.isna(population_options)]
            ui.update_select(id='pop_sel',choices = list(population_options), selected= population_options[0])
            print('Updated population selection')
        else:
            ui.update_select(id='pop_sel',choices = [], selected=[])
    
    
    @render.data_frame
    def rsm_dt():
       return render.DataTable(rsm, selection_mode='row')
    
    @render.ui
    def myleaf():
        # sar_polys_geojson = folium.GeoJson(data=sar_polys, style_function=lambda x: {
        #     "fillColor": "orange",
        #     "weight": 1,
        #     "color": "black",
        #     "fillOpacity": 0.75
        #     })
        bc = folium.GeoJson(data = bc_bound)
        my_map = folium.Map(data = [54.93147, -124.12823], zoom_start = 15)
        bc.add_to(my_map)
        # sar_polys_geojson.add_to(my_map)
        #boulder_coords = [40.015, -105.2705]
        #Create the map
        #my_map = folium.Map(location = boulder_coords, zoom_start = 13)

        return my_map
    
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
