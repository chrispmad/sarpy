#%% 

import os
import re
import shutil
import glob
import pandas as pd

# Set up folder paths and filepaths.
# home_wd = os.getcwd()
# cm_w_drive = "W:/CMadsen/shared_data_sets/"
# user_wd = re.sub("Downloads.*","",home_wd)
# onedrive = user_wd + "OneDrive - Government of BC\\"

#%% 

class AppData:
    def __init__(self):
        home_wd = os.getcwd()
        user_wd = re.sub("Downloads.*","",home_wd)
        onedrive = user_wd + "OneDrive - Government of BC\\"
        dfo_polys_name = "dfo_sara_and_crit_hab_bulltrout_and_sockeye_data.gpkg"
        
        self.paths = {
            'dfo_polys': onedrive + "data\\CNF\\" + dfo_polys_name,
            'dfo_polys_l': "app\\www\\" + dfo_polys_name,
            'status_tbl': onedrive + "SAR_scraper\\output\\risk_status_merged.csv",
            'status_tbl_l': "app\\www\\risk_status_merged.csv"
        }
    
    def update(self):
        # 1. Polygon files from DFO of various aquatic SAR in British Columbia.
        if(glob.glob(self.paths['dfo_polys_l']) == []):
            print("Copying DFO SARA shapefile to local data folder...")
            shutil.copy(src = self.paths['dfo_polys'], dst = self.paths['dfo_polys_l'])
            

        # 2. Chrissy and John's table listing COSEWIC statuses for species-at-risk
        if(glob.glob(self.paths['status_tbl_l']) == []):
            print("copying status table to local data folder...")
            shutil.copy(src = self.paths['status_tbl'], dst = self.paths['status_tbl_l'])

#%% 
my_app = AppData()
my_app.update()
