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

subjects="03"
masks1="AMY_AAA_2mm AMY_ATA_2mm AMY_ATA_ASTA_2mm AMY_BL_BLV_2mm AMY_BLN_BL_BLD+BLI_2mm AMY_BLN_BM_2mm AMY_BLN_La_2mm AMY_CEN_2mm AMY_CMN_2mm"
masks2="9 11 13 25 45 46 11m 14m 23ab 24ab 32d 44d 44v 47-12m 47-12o 6r 6v 8A 8B 8m 9-46d 9-46v CCZ FOp FPl FPm IFJ IFS M1 32pl PMd preSMA RCZa RCZp SMA"
masks3="entorhinal_exvivo entorhinal_exvivo.thresh perirhinal_exvivo perirhinal_exvivo.thresh V1_exvivo V1_exvivo.thresh BA4a_exvivo BA4a_exvivo.thresh BA4p_exvivo BA4p_exvivo.thresh"
# masks4="CA1 CA2+3 DG ERC PHC PRC SUB HPC aHPC pHPC"
namefix="anat_resampled_thres.nii.gz"

#make the function mask
SUBSESSION="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31"

for ses in $SUBSESSION
do 
funcmask="YOURSUBDIR/results/${ses}/RS.feat/mask.nii.gz"
feat_dir="YOURSUBDIR/results/${ses}/RS.feat"


flirt -ref ${feat_dir}/reg/highres -in ${funcmask} -applyxfm -init ${feat_dir}/reg/example_func2highres.mat -out ${feat_dir}/mask_anat.nii.gz -applyisoxfm 2
fslmaths ${feat_dir}/mask_anat.nii.gz -thr 0.0 -bin ${feat_dir}/mask_anat_thres.nii.gz
done

#Create master func mask_anat
feat_dir="YOURSUBDIR/results"
finalmaskdir="YOURSUBDIR/finalmasks"

fslmaths YOURSUBDIR/results/01/RS.feat/mask_anat_thres.nii.gz -mul YOURSUBDIR/results/02/RS.feat/mask_anat_thres.nii.gz ${finalmaskdir}/tmp_mask_anat_thres.nii.gz

SUBSESSION="03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31"
for ses1 in $SUBSESSION
do
fslmaths ${finalmaskdir}/tmp_mask_anat_thres.nii.gz -mul ${feat_dir}/${ses1}/RS.feat/mask_anat_thres.nii.gz ${finalmaskdir}/tmp_mask_anat_thres.nii.gz
done

fslmaths ${finalmaskdir}/tmp_mask_anat_thres.nii.gz -mul ${feat_dir}/40/RS.feat/mask_anat_thres.nii.gz ${finalmaskdir}/Master_mask_anat_thres.nii.gz
# fslmaths ${finalmaskdir}/tmp_Master_mask_anat_thres.nii.gz -thr 1 -bin ${finalmaskdir}/Master_mask_anat_thres.nii.gz
fslmaths ${finalmaskdir}/Master_mask_anat_thres.nii.gz -mul ${finalmaskdir}/01_01_mask_total_fsl.nii.gz ${finalmaskdir}/Master_mask_anat_thres_final.nii.gz
rm ${finalmaskdir}/tmp*

funcmask="${finalmaskdir}/Master_mask_anat_thres_final.nii.gz"
#Merge Hemispheres and final masks (voxel only appears in the functional mask)
for sub in $subjects
do
final="YOURSUBDIR/finalmasks"

for AMYmask in $masks1
do
fslmaths ${final}/Left_${AMYmask}_anat_resampled.nii.gz -add ${final}/Right_${AMYmask}_anat_resampled.nii.gz ${final}/${AMYmask}_${namefix}
fslmaths ${final}/${AMYmask}_${namefix} -mul ${funcmask} ${final}/${AMYmask}_final.nii.gz
done

for FSmask in $masks2
do
fslmaths ${final}/FS_lh.L_${FSmask}_${namefix} -add ${final}/FS_rh.R_${FSmask}_${namefix} ${final}/tmp_FS_${FSmask}_${namefix}
fslmaths ${final}/tmp_FS_${FSmask}_${namefix} -thr 0.0 -bin ${final}/FS_${FSmask}_${namefix}
fslmaths ${final}/FS_${FSmask}_${namefix} -mul ${funcmask} ${final}/${FSmask}}_final.nii.gz
rm ${final}/tmp_FS_${FSmask}_${namefix}
done

for FSmaskMTL in $masks3
do
fslmaths ${final}/FS_lh.${FSmaskMTL}_${namefix} -add ${final}/FS_rh.${FSmaskMTL}_${namefix} ${final}/tmp_FS_${FSmaskMTL}_${namefix}
fslmaths ${final}/tmp_FS_${FSmaskMTL}_${namefix} -thr 0.0 -bin ${final}/FS_${FSmaskMTL}_${namefix}
fslmaths ${final}/FS_${FSmaskMTL}_${namefix} -mul ${funcmask} ${final}/${FSmaskMTL}}_final.nii.gz
rm ${final}/tmp_FS_${FSmaskMTL}_${namefix}
done

# for ASHSmask in $masks4
# do
# fslmaths ${final}/L_${ASHSmask}_${namefix} -add ${final}/R_${ASHSmask}_${namefix} ${final}/tmp_${ASHSmask}_${namefix}
# fslmaths ${final}/tmp_${ASHSmask}_${namefix} -thr 0.0 -bin ${final}/${ASHSmask}_${namefix}
# rm ${final}/tmp_${ASHSmask}_${namefix}
# done
done

#make the FP and 9-46
fslmaths ${final}/FS_FPl_${namefix} -add ${final}/FS_FPm_${namefix} ${final}/tmp_FS_FP_${namefix}
fslmaths ${final}/tmp_FS_FP_${namefix} -thr 0.0 -bin ${final}/FS_FP_${namefix}
fslmaths ${final}/FS_FP_${namefix} -mul ${funcmask} ${final}/FP_final.nii.gz
rm ${final}/tmp_FS_FP_${namefix}

fslmaths ${final}/FS_9-46d_${namefix} -add ${final}/FS_9-46v_${namefix} ${final}/tmp_FS_9-46_${namefix}
fslmaths ${final}/tmp_FS_9-46_${namefix} -thr 0.0 -bin ${final}/FS_9-46_${namefix}
fslmaths ${final}/FS_9-46_${namefix} -mul ${funcmask} ${final}/9-46_final.nii.gz
rm ${final}/tmp_FS_9-46_${namefix}
done

date
hostname