Get the session time spreadsheet:
getAcqTime.py can help with the getting each session's scan time. 

Processing the resting state and T1 files: 
Read the Google Doc for more: https://docs.google.com/document/d/1qgDTjvYOCVsXCFpyYzhw2f2AObq2fPurMLPqm-xykvo/edit?usp=sharing
Step 1: Upload the raw data to cluster
Step 2: Get the T1 scans ready (we want RPI oriention and good quality files): AverageDenoise_AnatScans.slurm
Step 3: SkullStrip: AntSkullstrip.slurm
Step 4: Get the preprocess fsf file ready: RS_preproc_28andHe.fsf
Step 5: Preprocess: NKIpreprocess_28andHe_aveanat.sh; 28andHe_preprocess_runall.sh
Step 6: Create Masks: Use the Google Doc (https://docs.google.com/document/d/1qgDTjvYOCVsXCFpyYzhw2f2AObq2fPurMLPqm-xykvo/edit?usp=sharing) to see the descriptions of each scripts (e.g., amygdalaEC_registration_28andHe.slurm; Freesurfer_atlas.slurm; CreateFinalMasks.slurm)
Step 7: Compute Regional-whole brain FC: 28andHe_amyConnect_runall.sh; amyConnect_NKI_HemiMerge_all.sh
Step 8: Compute regional-whole brain functional connectivity matrix correlation between each session: 28andHe_VoxelCorrel_pycreater.sh; 28andHe_voxelCorrel_HemiMerge_z_sep.py; 28andHe_VoxelCorrel_HemiMerge_z_sep_runall.sh; 28andHe_VoxelCorrel_HemiMerge_z_template.slurm
Step 9: Get the session pair calculations: 28andHe_voxelCorrel_postanat_cluster.py
Step 10: R scripts for temporal drift related analysis: 28andMe_1d_fc_Basic.Rmd