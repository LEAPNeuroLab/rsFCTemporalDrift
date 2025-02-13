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

##Above are cluster related scripts##

#Where anatomical scans located
anat_dir="YOURPROJECTDIR/anat" # raw T1High directory
#raw_anat="sub-MSCparticipant_ses-struct01_run-01_T1w.nii.gz" #raw/unprocessed T1high.
# ave_anat="T1High_ave_RPI"
anat="T1_brain" # reoriented T1high


# where scrips are located
script_dir="DefaultConfounddir" #directory that contains default confound.txt 
#where fsl is located
#fsl_dir="/usr/local/fsl"
fsf_dir="Yourfsftemplatedir"
orig_dir="YOURRAWDIR/sub-participant/ses-session/func" # raw/unprocessed rest dir

resting="sub-participant_ses-session_task-rest_bold.nii.gz" # unprocessed rest state file

rest_dir="YOURPROJECTDIR/results/session" # processed rest dir

feat_dir="YOURPROJECTDIR/results/session/RS.feat" # GLM (processed) rest dir

motfile="prefiltered_func_data_mcf.par"  ## motion parameters for this subject (*AFNI* format)
mot_start="0" # motion computed from the first slice
mot_thresh="0.2" # motion threshold 0.2mm

##############################################
# create processed directory if it doesn't exist

if [ ! -e  $rest_dir ]; then
mkdir $rest_dir
fi

cp $anat_dir/$anat.nii.gz $rest_dir/$anat.nii.gz
mv $rest_dir/$anat.nii.gz $rest_dir/T1High_brain.nii.gz


# now we are in FSL for a bit:
# Run FD estimation for outlier detection changing file type
echo "Running fsl_motion_outliers"
fsl_motion_outliers -i $orig_dir/$resting -o $rest_dir/participant_session_confound.txt --dummy=4 --fd --thresh=$mot_thresh -p $rest_dir/fd_plot -v > $rest_dir/participant_session_confound.txt

# in case no confounds, copy file full of zeroes
if  [ ! -f "$rest_dir/participant_session_confound.txt" ]; then
cp $script_dir/defaultConfound.txt $rest_dir/participant_session_confound.txt
fi

echo "create afni compatible 1D"
# make afni compatible 1D (confound) file (from FSL's file)
awk '{ for(i=1; i<=NF; i++) j+=$i; if (j==1) print 0; if(j==0) print 1;  j=0 }' $rest_dir/participant_session_confound.txt > $rest_dir/participant_session_confound.1D

# bet anat: skull stripping and viewing the anatomical
# original frontal pole cut off, try other -f or -g
# bet $rest_dir/$anat.nii.gz $rest_dir/T1High_brain -R -f 0.2 -g -0.25 #single T1high
# bet $rest_dir/$anat.nii.gz $rest_dir/T1High_brain -R -f 0.4 -g -0.38 #averaged T1high

# fsleyes T1High.nii.gz T1High_brain.nii.gz -l "Red" & 

#copy raw resting-state data to rest_dir
cp $orig_dir/$resting $rest_dir
mv $rest_dir/$resting $rest_dir/participant_session.nii.gz

# create .fsf file
sed -e "s/SUBID/participant/g;s/SESSION/session/g" $fsf_dir/RS_preproc_28andHe.fsf > $rest_dir/participant_session_RS_preproc.fsf

# # running RS preproc
echo "Running feat model"
feat $rest_dir/participant_session_RS_preproc.fsf 

#Nuisance regressor: motion preparing for afni format
echo "Making motion files"
1dnorm -demean $feat_dir/mc/$motfile'['0']' $rest_dir/participant_session_fd_motion.1x.1D
1dnorm -demean $feat_dir/mc/$motfile'['1']' $rest_dir/participant_session_fd_motion.2x.1D
1dnorm -demean $feat_dir/mc/$motfile'['2']' $rest_dir/participant_session_fd_motion.3x.1D
1dnorm -demean $feat_dir/mc/$motfile'['3']' $rest_dir/participant_session_fd_motion.4x.1D
1dnorm -demean $feat_dir/mc/$motfile'['4']' $rest_dir/participant_session_fd_motion.5x.1D
1dnorm -demean $feat_dir/mc/$motfile'['5']' $rest_dir/participant_session_fd_motion.6x.1D


## segment

#  apply warp for functional to MNI space: probably not.
# cd $feat_dir
# applywarp --ref=./reg/standard --in=filtered_func_data --warp=./reg/highres2standard_warp --premat=./reg/example_func2highres.mat --out=$rest_dir/participant_mc2standard     

#register filtered func to highres! And keep the filtered_func_data voxel size: 2mm.
cd ${feat_dir}/reg
flirt -ref highres -in ../filtered_func_data -applyxfm -init example_func2highres.mat -out $rest_dir/participant_session_mc2highres -applyisoxfm 2
 

cd ${rest_dir}

# Segment
echo "Segment"
# fast -t 1 -g --Prior -o segment $feat_dir/reg/highres2standard # OLD! standard
fast -t 1 -g --Prior -o segment ${feat_dir}/reg/highres #  highres

echo "resample masks"
flirt -in ${rest_dir}/segment_seg_0.nii.gz -applyxfm -init $script_dir/ident.mat -out ${rest_dir}/tmp.participant_session_fsl_Mask.CSF.2mm -paddingsize 0.0 -interp trilinear -ref  $rest_dir/participant_session_mc2highres.nii.gz
flirt -in ${rest_dir}/segment_seg_1.nii.gz -applyxfm -init $script_dir/ident.mat -out ${rest_dir}/tmp.participant_session_fsl_Mask.GM.2mm -paddingsize 0.0 -interp trilinear -ref  $rest_dir/participant_session_mc2highres.nii.gz
flirt -in ${rest_dir}/segment_seg_2.nii.gz -applyxfm -init $script_dir/ident.mat -out ${rest_dir}/tmp.participant_session_fsl_Mask.WM.2mm -paddingsize 0.0 -interp trilinear -ref  $rest_dir/participant_session_mc2highres.nii.gz

fslmaths tmp.participant_session_fsl_Mask.CSF.2mm.nii -thr 0.7 -bin participant_session_fsl_Mask.CSF.2mm.nii.gz
fslmaths tmp.participant_session_fsl_Mask.WM.2mm.nii -thr 0.4 -bin participant_session_fsl_Mask.WM.2mm.nii.gz
fslmaths tmp.participant_session_fsl_Mask.GM.2mm.nii -thr 0.2 -bin participant_session_fsl_Mask.GM.2mm.nii.gz

3dcopy participant_session_fsl_Mask.CSF.2mm.nii.gz participant_session_fsl_Mask.CSF.2mm
3dcopy participant_session_fsl_Mask.WM.2mm.nii.gz participant_session_fsl_Mask.WM.2mm
3dcopy participant_session_fsl_Mask.GM.2mm.nii.gz participant_session_fsl_Mask.GM.2mm

# clean up
echo "cleaning up"
rm -f $rest_dir/segment*


# clean up
echo "cleaning up"
rm -f $rest_dir/tmp*


# Nuisance regressor: eroded WM
echo "Eroding WM"
3dcalc \
	-datum short \
	-a participant_session_fsl_Mask.WM.2mm+orig \
	-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
	-expr "a*(1-amongst(0,b,c,d,e,f,g))" \
	-prefix participant_session_fsl_Mask.WM.erode
3dROIstats -mask participant_session_fsl_Mask.WM.erode+orig -mask_f2short -quiet $rest_dir/participant_session_mc2highres.nii.gz > tmp.ts.WMe.participant_session_mc2highres.1D
rm -f ts.WMe.participant_session_mc2highres.1D
1dnorm -demean tmp.ts.WMe.participant_session_mc2highres.1D ts.WMe.participant_session_mc2highres.1D
rm -f tmp.ts.WMe.participant_session_mcsa.1D

# Nuisance regressor : derivative of WM
echo "Calculating derivative of WM"
$script_dir/@Derivative1D.fast ts.WMe.participant_session_mc2highres.1D > tmp.ts.WMe.d.participant_session_mc2highres.1D
rm -f ts.WMe.d.participant_session_mc2highres.1D
1dnorm -demean tmp.ts.WMe.d.participant_session_mc2highres.1D ts.WMe.d.participant_session_mc2highres.1D
rm -f tmp.ts.WMe.d.participant_session_mc2highres.1D

echo "Eroding CSF"
3dcalc \
	-datum short \
	-a participant_session_fsl_Mask.CSF.2mm+orig \
	-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
	-expr "a*(1-amongst(0,b,c,d,e,f,g))" \
	-prefix participant_session_fsl_Mask.CSF.erode
3dROIstats -mask participant_session_fsl_Mask.CSF.erode+orig -mask_f2short -quiet $rest_dir/participant_session_mc2highres.nii.gz > tmp.ts.CSFe.participant_session_mc2highres.1D
rm -f ts.CSFe.participant_session_mc2highres.1D
1dnorm -demean tmp.ts.CSFe.participant_session_mc2highres.1D ts.CSFe.participant_session_mc2highres.1D
rm -f tmp.ts.CSFe.participant_session_mc2highres.1D

# Nuisance regressor : derivative of csf
echo "Calculating derivative of CSF"
$script_dir/@Derivative1D.fast ts.CSFe.participant_session_mc2highres.1D > tmp.ts.CSFe.d.participant_session_mc2highres.1D
rm -f ts.CSFe.d.participant_session_mc2highres.1D
1dnorm -demean tmp.ts.CSFe.d.participant_session_mc2highres.1D ts.CSFe.d.participant_session_mc2highres.1D
rm -f tmp.ts.CSFe.d.participant_session_mc2highres.1D

### 3DConvolve/ remove csf etc noise


cd $rest_dir

#rm -f awreg_rest_fsl.*
#rm -f 3dDeconvolve.err
#rm -f tmp.002_fsl+orig*
#rm -f 002_mean_fsl+orig*


# Brain Mask
echo "Making mask from epi"
3dAutomask -prefix $rest_dir/Mask.Brain.participant_session_epi_fsl $rest_dir/participant_session_mc2highres.nii.gz

echo "Making mask from anat"
#resample highres to match mc2highres.nii.gz
3dresample -master $rest_dir/participant_session_mc2highres.nii.gz -input $feat_dir/reg/highres.nii.gz -prefix participant_session_re_highres.nii.gz -rmode Linear
3dAutomask -prefix $rest_dir/Mask.Brain.participant_session_anat_fsl $rest_dir/participant_session_re_highres.nii.gz

echo "Combining brain masks"
# 3dcalc -a $rest_dir/Mask.Brain.participant_session_epi_fsl+orig -b $rest_dir/Mask.Brain.participant_session_anat_fsl+orig -expr "step(a+b)" -prefix $rest_dir/participant_session_mask_total_fsl
fslmaths ${rest_dir}/participant_session_fsl_Mask.CSF.2mm -add ${rest_dir}/participant_session_fsl_Mask.WM.2mm -add ${rest_dir}/participant_session_fsl_Mask.GM.2mm $rest_dir/tmp_participant_session_mask_total_fsl
fslmaths $rest_dir/tmp_participant_session_mask_total_fsl -thr 0.0 -bin $rest_dir/participant_session_mask_total_fsl
3dcopy participant_session_mask_total_fsl.nii.gz participant_session_mask_total_fsl
rm $rest_dir/tmp_participant_session_mask_total_fsl*

## Nuisance regression
echo "Nuisance regression"

3dDeconvolve \
  -jobs 1 \
  -short \
  -input participant_session_mc2highres.nii.gz \
  -mask participant_session_mask_total_fsl+orig \
  -censor participant_session_confound.1D \
  -nfirst 0 \
  -num_stimts 10 \
  -stim_file 1 participant_session_fd_motion.1x.1D -stim_label 1 mot1 \
  -stim_file 2 participant_session_fd_motion.2x.1D -stim_label 2 mot2 \
  -stim_file 3 participant_session_fd_motion.3x.1D -stim_label 3 mot3 \
  -stim_file 4 participant_session_fd_motion.4x.1D -stim_label 4 mot4 \
  -stim_file 5 participant_session_fd_motion.5x.1D -stim_label 5 mot5 \
  -stim_file 6 participant_session_fd_motion.6x.1D -stim_label 6 mot6 \
  -stim_file 7 ts.CSFe.participant_session_mc2highres.1D -stim_label 7 csf \
  -stim_file 8 ts.WMe.participant_session_mc2highres.1D -stim_label 8 wm \
  -stim_file 9 ts.CSFe.d.participant_session_mc2highres.1D -stim_label 9 csf.d \
  -stim_file 10 ts.WMe.d.participant_session_mc2highres.1D -stim_label 10 wm.d \
  -errts tmp.participant_session_fsl \
  -fout -tout -rout -bout \
  -bucket msc_rest_fsl.wcdmX.participant_session

#above: residuals are   tmp.participant_session_fsl ie data of interest!
#but need the mean back [intercept/coef [2] ie third brick is that]
   
# add mean back
echo "Adding mean back"
3dcalc -a msc_rest_fsl.wcdmX.participant_session+orig'[2]' -b tmp.participant_session_fsl+orig -expr "a+b" -prefix participant_session_mean_fsl
# this is the file of interest from now on: participant_session_mean_fsl
3dAFNItoNIFTI participant_session_mean_fsl+orig. participant_session_mean_fsl

gunzip participant_session_mask_total_fsl+orig*.gz
gunzip participant_session_mean_fsl*
3dBandpass -mask participant_session_mask_total_fsl+orig \
-prefix participant_session_mean_fsl_smooth \
0.01 0.1 \
participant_session_mean_fsl+orig

# .009 .08

3dAFNItoNIFTI participant_session_mean_fsl_smooth* participant_session_mean_fsl_smooth 
3dAFNItoNIFTI participant_session_mask_total_fsl* participant_session_mask_total_fsl
 

rm -f participant_session_mask_total_fsl+orig*
gzip participant_session_mask_total_fsl*
rm -f participant_session_mean_fsl+orig*
gzip participant_session_mean_fsl*

rm -f participant_session_fsl_Mask.CSF.2mm+orig*
rm -f participant_session_fsl_Mask.WM.2mm+orig*
rm -f participant_session_fsl_Mask.GM.2mm+orig*

# rm -f $rest_dir/participant_session_mc2standard* 
# rm -f $rest_dir/nki_rest_fsl*
# rm -f $rest_dir/tmp.0101463_fsl+orig*

date
hostname
