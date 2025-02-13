Author: Jingyi Wang

This pipeline calculate the rate of regional-whole brain resting functional connectivity pattern changes across time. To obtain the regional-whole brain resting state connectivity patterns for each session, we first averaged the time series across all voxels within each region of interest. To measure the connectivity pattern in each session, Pearson’s correlation values (indexing resting state functional connectivity with each seed) were then obtained using AFNI for all gray-matter voxels, which were Fisher-z transformed. Next, we calculated Pearson’s correlation coefficients (i.e., indexing similarity) for resting state functional connectivity patterns between every pair of sessions (across all gray matter voxels), which were Fisher-z-transformed. Between-session similarity values were considered outliers and excluded from subsequent analyses if they exceeded 3 standard deviations relative to the mean across all pairs of sessions for each seed region. Finally, to capture whether connectivity patterns reliably tracked elapsed time, a temporal drift score was calculated for each seed ROI. To do so, we correlated the similarity of connectivity patterns (Z-transformed correlation coefficients obtained for every session pair) with the delta time interval between session pairs.

Steps for calculating the temporal drift scores and test time-related temporal drift for each participant each ROI: 
Step 0: Get the raw data ready. You should have structural scans T1; functional scans for each session; and spreadsheet that indicate run-wise parameters (e.g., scan time, emotion state, hormone level, etc.,.).
Step 1: Get the T1 scans ready. This script will average the different T1 scans and then denoise the averaged T1 file: AverageDenoise_AnatScans.slurm
Step 2: SkullStrip: AntSkullstrip.slurm
Step 3: Get the preprocess template fsf file ready so that the place holders used in the following step is matched RS_preproc.fsf
Step 4: Preprocess: NKIpreprocess.sh
Step 5: Create Masks: MNIMasks_registration.slurm; Freesurfer.slurm; CreateFinalMasks.slurm
Step 6: Compute Regional-whole brain FC: amyConnect_NKI_HemiMerge_all.sh
Step 7: Compute regional-whole brain functional connectivity matrix correlation between each session: VoxelCorrel_HemiMerge_z_sep.py
Step 8: Get the session pair calculations: VoxelCorrel_postanat_cluster.py
Step 9: R scripts for temporal drift related analysis: RegionalWholeBrain_Basic.Rmd