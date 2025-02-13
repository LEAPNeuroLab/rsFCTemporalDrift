#!/bin/bash -l
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --mem=20G
cd $SLURM_SUBMIT_DIR

date
hostname
###########################################################################################################################################

#Set up the environmental variables
FSLDIR=/sw/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

export PATH=$PATH:/sw/afni/bin

sub="01"

basedir="YOURSUBDIR/results/01" #subject directory, always use session 01. 
maskDir="YOURMNIMASKS" # where the MNI space amygdala masks are


funcDir="${basedir}/RS.feat" # FSL directory
# standard=/usr/local/fsl-5.0.10/data/standard/MNI152_T1_2mm_brain

regDir="${funcDir}/reg" #inside FSL directory
# statsDir=${funcDir}/stats


outDir="YOURSUBDIR/finalmasks" # where I saved all my masks (final output in functional RES/ T1High space)_
if [ ! -e  $outDir ]; then
mkdir $outDir
fi

echo "invert highres2standard"
# invert a non-linear registration (comp. intensive)
invwarp --ref=${regDir}/highres  --warp=${regDir}/highres2standard_warp.nii.gz --out=${regDir}/standard2highres_warp.nii.gz
 

echo "register masks to designed space and resolution"
masks="Yeo_DA_A Yeo_DA_B Yeo_DMN_C Yeo_SMotor_A Yeo_SMotor_B Yeo_visual_A Yeo_visual_B Yeo_DMN_A Yeo_DMN_B Yeo_DMN_D Amy_50_bin Left_AMY_AAA_2mm Left_AMY_ATA_2mm Left_AMY_ATA_ASTA_2mm Left_AMY_BL_BLV_2mm Left_AMY_BLN_BL_BLD+BLI_2mm Left_AMY_BLN_BM_2mm Left_AMY_BLN_La_2mm Left_AMY_CEN_2mm Left_AMY_CMN_2mm Right_AMY_AAA_2mm Right_AMY_ATA_2mm Right_AMY_ATA_ASTA_2mm Right_AMY_BL_BLV_2mm Right_AMY_BLN_BL_BLD+BLI_2mm Right_AMY_BLN_BM_2mm Right_AMY_BLN_La_2mm Right_AMY_CEN_2mm Right_AMY_CMN_2mm Maass_alEC_PRCpref_left_MNI_2mm Maass_alEC_PRCpref_right_MNI_2mm Maass_pmEC_PHCpref_left_MNI_2mm Maass_pmEC_PHCpref_right_MNI_2mm Amy_50_bin Navarro_alEC_lr_MNI_2mm Navarro_pmEC_lr_MNI_2mm Maass_alEC_PRCpref_left_MNI_2mm Maass_alEC_PRCpref_right_MNI_2mm Maass_pmEC_PHCpref_left_MNI_2mm Maass_pmEC_PHCpref_right_MNI_2mm"

for mask in ${masks}
do

echo "applying a nonlinear registration to your MNI masks"
#applying a nonlinear registration to your MNI masks --> T1 space
applywarp --ref=${regDir}/highres --in=${maskDir}/${mask} --warp=${regDir}/standard2highres_warp.nii.gz  --out=${outDir}/${mask}_anat --interp=nn  #if subnuclei, use NN; if not, trilinear could be Ok!


echo "put it in functional resolution (still anatomical space!!)" 
flirt -in ${outDir}/${mask}_anat -applyxfm -init YOURSCRIPTDIR/ident.mat -out ${outDir}/${mask}_anat_resampled -paddingsize 0.0 -interp nearestneighbour -ref  ${basedir}/${sub}_01_mask_total_fsl.nii.gz #ident.mat is default from fsl program
# ref is an image that is in the *desired output space*, i.e. T1 space BUT with the functional resolution 


done

date