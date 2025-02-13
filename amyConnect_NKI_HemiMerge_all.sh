#!/bin/bash -l
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --mem=10G
cd $SLURM_SUBMIT_DIR

date
hostname

export PATH=$PATH:/sw/afni/bin

FSLDIR=/sw/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

# feed session and subject here

subjects="YOURSUBID"
sessions="replace"

# Processing for certain ROI functional connectivity with the whole brain. 
for sub in ${subjects}
do
for ses in ${sessions}
do
# input directory
	conn_dir="YOURSUBDIR/results/${ses}"
# output directory
	output_dir="YOURSUBDIR/results/1D_fc/${sub}_${ses}"

# where my ROIs/masks are
	seed_dir="YOURSUBDIR/finalmasks"

# all the seeds
	seeds=(Amy_50_bin Amy_50_bin_control HPC aHPC pHPC ERC PHC PRC CA1 CA2+3 DG SUB M1 entorhinal_exvivo entorhinal_exvivo.thresh perirhinal_exvivo perirhinal_exvivo.thresh 25 9 32pl 9-46d 9-46v 32d PMd FPl FPm SMA V1_exvivo V1_exvivo.thresh BA4a_exvivo BA4a_exvivo.thresh BA4p_exvivo BA4p_exvivo.thresh Yeo_DA Yeo_DMN_A Yeo_DMN_B Yeo_DMN_C Yeo_DMN_D Yeo_SMotor Yeo_Visual Yeo_PM)
# 	seeds=(Amy_50_bin_control)
	cd $conn_dir
	
# 	create output directory (if it doesn't exist)
	if [ ! -e ${output_dir} ]; then
	mkdir ${output_dir}
	fi

# Whole brain mask. 
# Masks are in the same space as functional files.
	masks=(whole) 
# 	masks=(whole)
# 	maskFile="$conn_dir/${sub}_${ses}_mask_total_fsl.nii.gz"

	for seed in "${seeds[@]}"
  	do
  	for mask in "${masks[@]}"
  	do
  	if [ "${seed}" == "${mask}" ];then
  		echo "seed equal mask"
  	else
  		#Get the name of the seed file. 
  		PostFix="final" #Make sure to modify the "_anat_resampled" mask to final masks that the voxels are stable across functional runs and sessions. 
  		seedfile="${seed}_${PostFix}"
  		
        #Get the name of the mask file.	
  		maskfile="01_01_mask_total_fsl"
  		
  		echo "${seed}_${PostFix}"
  		#Func file name for the whole session
		filename="${sub}_${ses}_mean_fsl_smooth" #You need the Spatial smoothed file here.
		file="${sub}_${ses}_mean_fsl_smooth"
  		
  		#for the whole session 			  		
  		echo "Averaging over seed: $seed" # computing the connectivity!
  		if [ ! -e ${output_dir}/ts.${seed}_${file}.1D ]; then
  			3dmaskave -mask ${seed_dir}/${seedfile}.nii.gz -quiet ${conn_dir}/${filename}.nii.gz > ${output_dir}/tmp.ts.${seed}_${file}.1D
  			1dnorm -demean ${output_dir}/tmp.ts.${seed}_${file}.1D ${output_dir}/ts.${seed}_${file}.1D
  			rm -f ${output_dir}/tmp.ts.${seed}_${file}.1D
        fi 
  		njobs=1
		
		echo "3dDeconvolve"
  		3dDeconvolve \
				-jobs ${njobs} \
				-input ${conn_dir}/${filename}.nii.gz \
				-mask ${seed_dir}/${maskfile}.nii.gz \
				-num_stimts 1 \
				-stim_file 1 ${output_dir}/ts.${seed}_${file}.1D -stim_label 1 ${output_dir}/seed.${seed} \
				-fout -tout -rout \
				-bucket ${output_dir}/Fim.${seed}_${mask}

  		FimFile="Fim.${seed}_${mask}" 

  		if [ ! -e ${output_dir}/R.${FimFile}.nii.gz ]; then
  		3dcalc -a ${output_dir}/${FimFile}+orig'[4]' -b ${output_dir}/${FimFile}+orig'[3]' -expr "sqrt(a)*(b/abs(b))" -prefix ${output_dir}/R.${FimFile}.nii.gz 
  		fi

  		if [ ! -e ${output_dir}/Z.${FimFile}.nii.gz ]; then
  		3dcalc -datum float -a ${output_dir}/R.${FimFile}.nii.gz -expr "log((1+a)/(1-a))" -prefix ${output_dir}/Z.${FimFile}.nii.gz
  		fi
  		

rm ${output_dir}/*+orig.HEAD
rm ${output_dir}/*+orig.BRIK
done # sub level
done # session level
done # seed level
done # mask level


date
hostname

