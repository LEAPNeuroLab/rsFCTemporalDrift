import numpy as np
import nibabel as nib
from nilearn import image
from nilearn.masking import apply_mask
import pandas as pd
import random
import collections
import itertools
import os

def CreateDict(sub, seed):
	# sub=input("please enter your subject number as string")
	mask_dir = "YOURSUBDIR/finalmasks"
	mask_dir_Yeo = "YOURSUBDIR/finalmasks/Yeo"
	subject_dict = {}
	#Remove bad session FD>0.2
	# sessions = ["01","02","03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40"] #todo change this to more sessions.
	sessions = ["01", "03", "04", "06", "07", "08", "09", "10", "12", "13", "14", "15", "16", "17", "18",
				"19", "20", "21", "22", "24", "25", "30", "32", "33", "35",
				"36", "37", "38", "39", "40"]  # todo change this to more sessions.
	masks = ["whole", "Amy_50_bin", "HPC", "aHPC", "pHPC","CA1", "CA2+3", "DG", "SUB", "ERC", "PHC", "PRC", "entorhinal_exvivo", "perirhinal_exvivo", "25", "32pl", "9-46d", "9-46v", "32d", "FPl", "FPm", "SMA", "V1_exvivo", "V1_exvivo.thresh", "M1", "PMd", "Yeo_DA_A", "Yeo_DA_B", "Yeo_DMN_C", "Yeo_SMotor_A", "Yeo_SMotor_B", "Yeo_visual_A", "Yeo_visual_B", "Yeo_DMN_A", "Yeo_DMN_B", "Yeo_DMN_D", "Yeo_LIM_A", "Yeo_LIM_B", "Yeo_Control_A", "Yeo_Control_B", "Yeo_Control_C", "Yeo_VAN_A", "Yeo_VAN_B", "Yeo_DA", "Yeo_SMotor", "Yeo_Visual", "Yeo_PM"]
	for mask in masks:
		if seed == mask:
			continue
		else:
			current_pair = seed + "_" + mask
			subject_dict[current_pair] = {}
			for ses in sessions:
				input_dir = "YOURSUBDIR/results/1D_fc/" + sub + "_" + ses + "/"
				mean_fn = input_dir + "Z.Fim." + seed + "_whole.nii.gz"  # just 1D.
		# 				print("Here!!!")
				mean_brain=nib.load(mean_fn)
			# get 3d brain intro 3d matrix
			# change to get_fdata (https://nipy.org/nibabel/devel/biaps/biap_0008.html)
			# 	mean_data = mean_brain.get_data()  # 3D array; get the dimensions; type(mean_control_data)
				#load mask
				if mask in ["Amy_50_bin", "Amy_50_bin_control", "HPC", "aHPC", "pHPC","CA1", "CA2+3", "DG", "SUB", "ERC", "PHC", "PRC", "entorhinal_exvivo", "perirhinal_exvivo", "25", "32pl", "9-46d", "9-46v", "32d", "FPl", "FPm", "SMA", "V1_exvivo", "V1_exvivo.thresh", "M1", "PMd"]:
					mask_fn = os.path.join(mask_dir, str(mask) + '_final.nii.gz')
					mask_load = image.load_img(mask_fn)
				elif mask in ["Yeo_DA_A", "Yeo_DA_B", "Yeo_DMN_C", "Yeo_SMotor_A", "Yeo_SMotor_B", "Yeo_visual_A", "Yeo_visual_B", "Yeo_DMN_A", "Yeo_DMN_B", "Yeo_DMN_D", "Yeo_LIM_A", "Yeo_LIM_B", "Yeo_Control_A", "Yeo_Control_B", "Yeo_Control_C", "Yeo_VAN_A", "Yeo_VAN_B", "Yeo_DA", "Yeo_SMotor", "Yeo_Visual", "Yeo_PM"]:
					mask_fn = os.path.join(mask_dir_Yeo, str(mask) + '_final.nii.gz')
					mask_load_tmp = image.load_img(mask_fn)
					mask_load_np_tmp = mask_load_tmp.get_data()
					# Remove the seed area from the mask
					seed_fn = os.path.join(mask_dir, str(seed) + '_final.nii.gz')
					seed_load = image.load_img(seed_fn)
					seed_load_np = seed_load.get_data()
					seed_load_invert = 1 - seed_load_np
					mask_load_tmp = np.multiply(mask_load_np_tmp, seed_load_invert)
					# create Nifti1Image object
					mask_load = nib.Nifti1Image(mask_load_tmp, seed_load.affine)
					# Save this new mask
					savefn = os.path.join(mask_dir_Yeo, "Yeo_" + str(seed) + "_clean.nii.gz")
					nib.save(mask_load, savefn)

				elif mask == "whole":
					mask_fn = os.path.join(mask_dir, "01_01_mask_total_fsl.nii.gz")
					mask_load_tmp = image.load_img(mask_fn)
					mask_load_np_tmp = mask_load_tmp.get_data()

					# Remove the seed area from the whole brain mask it self
					seed_fn = os.path.join(mask_dir, str(seed) + '_final.nii.gz')
					seed_load = image.load_img(seed_fn)
					seed_load_np = seed_load.get_data()
					seed_load_invert = 1 - seed_load_np
					mask_load_tmp = np.multiply(mask_load_np_tmp, seed_load_invert)
					# Keep only the gray matters
					GM_fn = os.path.join(mask_dir, "01_01_fsl_Mask.GM.2mm.nii.gz")
					GM_load = image.load_img(GM_fn)
					GM_load_np = GM_load.get_data()
					mask_load_tmp = np.multiply(mask_load_tmp, GM_load_np)

					#remove white matter and CSF
					WM_fn = os.path.join(mask_dir, '01_01_fsl_Mask.WM.2mm.nii.gz')
					WM_load = image.load_img(WM_fn)
					WM_load_np = WM_load.get_data()
					WM_load_invert = 1 - WM_load_np
					mask_load_tmp = np.multiply(mask_load_tmp, WM_load_invert)

					CSF_fn = os.path.join(mask_dir, '01_01_fsl_Mask.CSF.2mm.nii.gz')
					CSF_load = image.load_img(CSF_fn)
					CSF_load_np = CSF_load.get_data()
					CSF_load_invert = 1 - CSF_load_np
					mask_load_tmp = np.multiply(mask_load_tmp, CSF_load_invert)

					# create Nifti1Image object
					mask_load = nib.Nifti1Image(mask_load_tmp, seed_load.affine)
					# Save this new mask
					savefn = os.path.join(mask_dir, "01_01_mask_total_fsl_" + str(seed) + "_clean_GMonly.nii.gz")
					nib.save(mask_load, savefn)

				# Get the voxels inside ROI (mask).
				print("apply mask ")
				masked_data = apply_mask(mean_brain, mask_load)
				# flatten 3d matrix into vector (fun part!!!)
				meanDataVector = masked_data.ravel()
				subject_dict[current_pair][ses][run] = meanDataVector
	return subject_dict

# for sub in ("01"): #todo change this do list of subjects you have. Now it is two subjects.
sub="01"
locals()['MSC' + sub] = CreateDict(sub, "replaceseed")

outdir= "YOURSUBDIR/results/1D_fc/1D_fc_FD.2cut/"

df = pd.DataFrame()

# Get the correlations between sessions for each seed-mask pair for one subject.
#todo change this to multiple subjects.
subjects=["01"]
# sessions=["01", "02","03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40"] # todo eventually will be 10
sessions = ["01", "03", "04", "06", "07", "08", "09", "10", "12", "13", "14", "15", "16", "17", "18",
				"19", "20", "21", "22", "24", "25", "30", "32", "33", "35",
				"36", "37", "38", "39", "40"]  # todo change this to more sessions.
# seeds = ["Amy_50_bin", "HPC", "aHPC", "pHPC","CA1", "CA2+3", "DG", "SUB", "ERC", "PHC", "PRC", "entorhinal_exvivo", "entorhinal_exvivo.thresh", "perirhinal_exvivo", "perirhinal_exvivo.thresh", "25", "32pl", "9-46d", "9-46v", "32d", "FPl", "FPm", "SMA", "V1_exvivo", "V1_exvivo.thresh", "BA4a_exvivo", "BA4a_exvivo.thresh", "BA4p_exvivo", "BA4p_exvivo.thresh"] #todo change this with your own seed.
masks = ["whole", "Amy_50_bin", "HPC", "aHPC", "pHPC","CA1", "CA2+3", "DG", "SUB", "ERC", "PHC", "PRC", "entorhinal_exvivo", "perirhinal_exvivo", "25", "32pl", "9-46d", "9-46v", "32d", "FPl", "FPm", "SMA", "V1_exvivo", "V1_exvivo.thresh", "M1", "PMd", "Yeo_DA_A", "Yeo_DA_B", "Yeo_DMN_C", "Yeo_SMotor_A", "Yeo_SMotor_B", "Yeo_visual_A", "Yeo_visual_B", "Yeo_DMN_A", "Yeo_DMN_B", "Yeo_DMN_D", "Yeo_LIM_A", "Yeo_LIM_B", "Yeo_Control_A", "Yeo_Control_B", "Yeo_Control_C", "Yeo_VAN_A", "Yeo_VAN_B", "Yeo_DA", "Yeo_SMotor", "Yeo_Visual", "Yeo_PM"] #todo change this with your own masks.
subjectList=[]
sessionList_1=[]
sessionList_2=[]
maskList=[]
seedList=[]
correlList=[]
correlzlist = []

seed="replaceseed"
for mask in masks:
	if seed == mask:
		continue
	else:
		seed_mask = "replaceseed" + "_" + mask
		for pair in itertools.combinations(sessions, 2):
			correl = round(np.corrcoef(locals()['MSC' + sub][seed_mask][pair[0]]["1"], locals()['MSC' + sub][seed_mask][pair[1]]["1"])[1][0],3)
			correlList.append(correl)
			correl_z = np.log(1+correl)-np.log(1-correl)
			correlzlist.append(correl_z)
			maskList.append(mask)
			seedList.append(seed)
			sessionList_1.append(pair[0])
			sessionList_2.append(pair[1])
			subjectList.append(sub)
			
			correl = round(np.corrcoef(locals()['MSC' + sub][seed_mask][pair[0]]["1"], locals()['MSC' + sub][seed_mask][pair[1]]["2"])[1][0],3)
			correlList.append(correl)
			correl_z = np.log(1+correl)-np.log(1-correl)
			correlzlist.append(correl_z)
			maskList.append(mask)
			seedList.append(seed)
			sessionList_1.append(pair[0])
			sessionList_2.append(pair[1])
			subjectList.append(sub)
			
			correl = round(np.corrcoef(locals()['MSC' + sub][seed_mask][pair[0]]["2"], locals()['MSC' + sub][seed_mask][pair[1]]["2"])[1][0],3)
			correlList.append(correl)
			correl_z = np.log(1+correl)-np.log(1-correl)
			correlzlist.append(correl_z)
			maskList.append(mask)
			seedList.append(seed)
			sessionList_1.append(pair[0])
			sessionList_2.append(pair[1])
			subjectList.append(sub)
			
			correl = round(np.corrcoef(locals()['MSC' + sub][seed_mask][pair[0]]["2"], locals()['MSC' + sub][seed_mask][pair[1]]["1"])[1][0],3)
			correlList.append(correl)
			correl_z = np.log(1+correl)-np.log(1-correl)
			correlzlist.append(correl_z)
			maskList.append(mask)
			seedList.append(seed)
			sessionList_1.append(pair[0])
			sessionList_2.append(pair[1])
			subjectList.append(sub)
			
			correl = round(np.corrcoef(locals()['MSC' + sub][seed_mask][pair[0]["1"]], locals()['MSC' + sub][seed_mask][pair[0]["2"]])[1][0],3)
			correlList.append(correl)
			correl_z = np.log(1+correl)-np.log(1-correl)
			correlzlist.append(correl_z)
			maskList.append(mask)
			seedList.append(seed)
			sessionList_1.append(pair[0])
			sessionList_2.append(pair[1])
			subjectList.append(sub)


df['Subject']= pd.Series(subjectList)
df['Session_1']= pd.Series(sessionList_1)
df['Session_2']= pd.Series(sessionList_2)
df['Seed']= pd.Series(seedList)
df['Mask']= pd.Series(maskList)
df['Correlation'] = pd.Series(correlList)
df['CorrelationZ'] = pd.Series(correlzlist)

print(df)
savedfile="replaceseed" + '_voxelcorrel_fc.csv'
df.to_csv(outdir+savedfile, header=True, index=False)