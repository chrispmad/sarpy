#%% 

import os
import re
import shutil
import glob
import pandas as pd
import getpass


# Set up folder paths and filepaths.
# home_wd = os.getcwd()
# cm_w_drive = "W:/CMadsen/shared_data_sets/"
# user_wd = re.sub("Downloads.*","",home_wd)
# onedrive = user_wd + "OneDrive - Government of BC\\"

#%% 

class AppData:
    def __init__(self):
        home_wd = os.getcwd()
        user_name = getpass.getuser()
        user_wd = "C:\\Users\\"+getpass.getuser()
        onedrive = user_wd + "\\OneDrive - Government of BC\\"
        dfo_polys_name = "dfo_sara_occurrences_in_BC_all_species.gpkg"
        dfo_ch_polys_name = "dfo_sara_critical_habitat_bc.gpkg"
        
        self.paths = {
            'dfo_polys': onedrive + "data\\DFO_SARA\\" + dfo_polys_name,
            'dfo_polys_l': "app\\www\\" + dfo_polys_name,
            'dfo_ch_polys': onedrive + "data\\DFO_SARA\\" + dfo_ch_polys_name,
            'dfo_ch_polys_l': "app\\www\\" + dfo_ch_polys_name,
            'status_tbl': onedrive + "\\SAR_scraper\\output\\risk_status_merged.csv",
            'status_tbl_l': "app\\www\\risk_status_merged.csv"     
        }
        if user_name == "JPHELAN":
            self.paths['status_tbl'] = onedrive + "\\R_projects\\SAR_scraper\\output\\risk_status_merged.csv"

    def update(self):
 
        # 1. Polygon files from DFO of various aquatic SAR in British Columbia.
        if(glob.glob(self.paths['dfo_polys_l']) == []):
            print("Copying DFO SARA shapefile to local data folder...")
            shutil.copy(src = self.paths['dfo_polys'], dst = self.paths['dfo_polys_l'])

        if(glob.glob(self.paths['dfo_ch_polys_l']) == []):
            print("Copying DFO Critical Habitat shapefile to local data folder...")
            shutil.copy(src = self.paths['dfo_ch_polys'], dst = self.paths['dfo_ch_polys_l'])

        # 2. Chrissy and John's table listing COSEWIC statuses for species-at-risk
        if(glob.glob(self.paths['status_tbl_l']) == []):
            print("copying status table to local data folder...")
            shutil.copy(src = self.paths['status_tbl'], dst = self.paths['status_tbl_l'])

#%% 
my_app = AppData()
my_app.update()

#%%