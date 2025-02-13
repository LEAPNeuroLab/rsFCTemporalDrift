import numpy as np
import pandas as pd
import itertools
import random
import os
import glob
import itertools
import glob

#import the fc spreadsheet
files = glob.glob("YOURSUBDIR/results/1D_fc/1D_fc_FD.2cut/*.csv") #todo change directory
dfs = [pd.read_csv(f, delimiter =',', header = 0) for f in files]
fc = pd.concat(dfs,ignore_index=True)
#create the dataframe for time interval between sessions for all the subjects.
# ID=[]
# for i in range (10):
#     ID.extend(list(itertools.repeat(i+1, 10)))
#
# li=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# session=li*10

directory="YOURSUBDIR/results"
scantime_dir = os.path.join(directory,"28andHe_scantime" + "." + "csv")
scantime=pd.read_csv(scantime_dir, delimiter =',', header = 0)

time_elapse=scantime['time_elapse(day)'].tolist()
session = scantime['Session'].tolist()
ID=scantime['ID']
AbsoluteMotion = scantime["AbsoluteMotion"]
RelativeMotion = scantime["RelativeMotion"]

refdf=pd.DataFrame(list(zip(ID, session, time_elapse, AbsoluteMotion, RelativeMotion)), columns=['ID','session','time_elapse', 'AbsoluteMotion', 'RelativeMotion'])

TimeInterval=[]
Ses1AbsFD = []
Ses2AbsFD = []
deltaAbsFD = []

Ses1RevFD = []
Ses2RevFD = []
deltaRevFD = []
for ind in fc.index:
    current_sub=fc['Subject'][ind]
    ses1=fc['Session_1'][ind]
    ses2=fc['Session_2'][ind]
    interval1 = refdf.loc[(refdf['ID']==current_sub) & (refdf['session']==ses1), 'time_elapse'].iloc[0]
    interval2 = refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses2), 'time_elapse'].iloc[0]
    TimeInterval.append(interval2-interval1)

    # Get motion
    Ses1AbsFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses1), 'AbsoluteMotion'].iloc[0])
    Ses2AbsFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses2), 'AbsoluteMotion'].iloc[0])
    deltaAbsFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses2), 'AbsoluteMotion'].iloc[0] -
                      refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses1), 'AbsoluteMotion'].iloc[0])

    Ses1RevFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses1), 'RelativeMotion'].iloc[0])
    Ses2RevFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses2), 'RelativeMotion'].iloc[0])
    deltaRevFD.append(refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses2), 'RelativeMotion'].iloc[0] -
                      refdf.loc[(refdf['ID'] == current_sub) & (refdf['session'] == ses1), 'RelativeMotion'].iloc[0])
fc['TimeInterval']=TimeInterval
fc['Ses1AbsFD'] = Ses1AbsFD
fc['Ses2AbsFD'] = Ses2AbsFD
fc['deltaAbsFD'] = deltaAbsFD

fc['Ses1RevFD'] = Ses1RevFD
fc['Ses2RevFD'] = Ses2RevFD
fc['deltaRevFD'] = deltaRevFD

fc.to_csv(os.path.join("YOURSUBDIR/results/1D_fc", "28andHe_voxelcorrel_fc_z_FD.2cut" + "." + "csv"), index=False)