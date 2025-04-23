from shiny import App, ui, reactive, render, req
import pandas as pd
from shinywidgets import render_widget, output_widget, register_widget
import folium
from pathlib import Path
from ipyleaflet import Map, Marker, Polygon, LayersControl, GeoData, LayerGroup
import geopandas as gpd
from shapely.geometry import box
import glob

#%% 
#%% 
species_sel = ui.input_selectize('spec_sel',"Species",
                                 choices=['Need Data'])

app_ui = ui.page_fluid(
    ui.include_css(Path(__file__).parent/"www\\my_styles.css"),
    ui.card(
        #ui.output_ui('myleaf'), 
        output_widget("myleaf"),
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
    bc_grid = gpd.read_file(Path(__file__).parent/"www\\bc_grid.gpkg")

    bc_bound = gpd.GeoDataFrame(bc_bound)
    bc_grid = gpd.GeoDataFrame(bc_grid)

    bc_bound_gd = GeoData(geo_dataframe = bc_bound,
                   style={'color': 'black', 'fillColor': 'transparent', 'opacity':1, 'weight':1, 'dashArray':'2', 'fillOpacity':0.6},
                #    hover_style={'fillColor': 'red' , 'fillOpacity': 0.75},
                   name = 'BC')
    bc_grid_gd = GeoData(geo_dataframe = bc_grid,
                   style={'color': 'black', 'fillColor': '#3366cc', 'opacity':0.05, 'weight':1.9, 'dashArray':'2', 'fillOpacity':0.6},
                #    hover_style={'fillColor': 'red' , 'fillOpacity': 0.2},
                   name = 'Grid')
    
    bc_bound_lg = LayerGroup(name = 'layer_group')
    bc_bound_lg.add_layer(bc_bound_gd)

    dfo_lg = LayerGroup(name = 'DFO')

    # Register the map widget
    m = Map(center=(55, -130), zoom=4, scroll_wheel_zoom = True)
    register_widget("myleaf",m)
    m.add(bc_bound_lg)
    m.add(dfo_lg)
    
    m.add_control(LayersControl(position="bottomleft",
                                collapsed = False))

    # sar_polys = gpd.read_file(Path(__file__).parent/"www\\dfo_sara_and_crit_hab_bulltrout_and_sockeye_data.gpkg")
    rsm = pd.read_csv(Path(__file__).parent/"www\\risk_status_merged.csv")
        
    # Drop the word 'population' from Legal population column
    rsm['Legal population'] = rsm['Legal population'].str.replace(' population.*','',regex = True)

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
    
    @reactive.calc
    def rsm_sp_pop_f():
        req(input.spec_sel())
        if input.pop_sel() == ():
            return rsm_sp_f()
        else:
            return rsm_sp_f()[rsm_sp_f()['Legal population'].isin(input.pop_sel())]
    
    # Observe the map boundaries; update a reactive value.
    map_bounds = reactive.value()

    def update_bounds(*args):
        bounds = m.bounds  # bounds = ((south, west), (north, east))
        bounds = [round(coord, 2) for pair in bounds for coord in pair]
        map_bounds.set(bounds)

    # Attach observer to map
    m.observe(update_bounds, names=["bounds"])

    # Figure out which bc grid cells are within the map view.
    @reactive.calc
    def cells_in_view():
        # Make polygon from leaflet map boundaries.
        cs = map_bounds()
        cs_p = box(miny=cs[0],minx=cs[1],maxy=cs[2],maxx=cs[3])
        
        # Spatial filter for grid cells
        bc_grid_in_frame = bc_grid[bc_grid.intersects(cs_p)]['cell_id']
        print(bc_grid_in_frame)
        # Return grid cell ids
        return bc_grid_in_frame

    @reactive.calc
    def dfo_polys():
        # Cycle through selected species, population, and grid cells
        # and dynamically access the data files, joining together
        # geometries for the same species and population.
        req(input.spec_sel())
        all_data = []
        for name, pop in zip(rsm_sp_pop_f()['COSEWIC common name'], 
                             rsm_sp_pop_f()['Legal population']):
            if str(pop) == 'nan':
                pop_name = "NA"
            else:
                pop_name = pop   
            for cell_id in cells_in_view():
                # file_path = Path(__file__).parent/f"www\\dfo\\{name}\\{pop_name}\\cell_{cell_id}.gpkg"
                file_path = f"\\www\\dfo\\{name}\\{pop_name}\\cell_{cell_id}.gpkg"
                file_path = str(Path(__file__).parent) + file_path
                print("file path is " + str(file_path))
                if glob.glob(file_path):
                    dfo_data_chunk = gpd.read_file(file_path)
                    all_data.append(dfo_data_chunk)
                    print("Added a new spatial file to all_data")
        if all_data != []:
            result = pd.concat(all_data, ignore_index=True)
        else:
            result = all_data  
        return result


    @render.data_frame
    def rsm_dt():
       return render.DataTable(rsm, selection_mode='row')
    
    # Reactive effect to update map layers based on selected species and population
    @reactive.effect
    def _():
        #print(map_bounds())
        #print(cells_in_view())
        # Add / remove layers from dfo layergroup
        print("dfo polys is: " + str(dfo_polys()))
        if(len(dfo_polys()) > 0):
            dfo_gd = GeoData(geo_dataframe = dfo_polys(),
                    style={'color': 'black', 'fillColor': 'purple', 'opacity':1, 
                           'weight':1, 'fillOpacity':0.6},
                    #    hover_style={'fillColor': 'red' , 'fillOpacity': 0.75},
                    name = 'BC')
            for layer in dfo_lg.layers:
                dfo_lg.remove_layer(layer)
            dfo_lg.add_layer(dfo_gd)
        # Clear existing markers
        #m.layers = m.layers[:3]  # Preserve the base layer

        # Add filtered dfo polygons to the map
        # for item in rsm_sp_pop_f():
            
        #     item_as_polygon = Polygon(item)
        #     m.add_layer(item_as_polygon)

    
    
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
