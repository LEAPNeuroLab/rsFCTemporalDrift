#Author: Jingyi Wang.
#Configurate for cluster usage
#!/bin/bash -l
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --mem=10G
cd $SLURM_SUBMIT_DIR

date
hostname

#Set up the environmental variables
FSLDIR=/sw/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

# export PATH=$PATH:/sw/afni/bin


ID="01"
sessions="01 03 05 07" # this is the sessions that acquired a anatomical scan

anat_dir="Your_anat_dir" #This is folder contains all the processed anatomical files

for SES in $sessions
do

rawanat_dir="RawDatadir/sub-${ID}/ses-${SES}/anat" #This is folder contains all the raw anatomical files

cp $rawanat_dir/sub-01_ses-${SES}_T1w.nii.gz $anat_dir/sub-01_ses-${SES}_T1w.nii.gz
mv $anat_dir/sub-01_ses-${SES}_T1w.nii.gz $anat_dir/T1High_${SES}.nii.gz

cp $rawanat_dir/sub-01_ses-${SES}_T2star.nii.gz $anat_dir/sub-01_ses-${SES}_T2star.nii.gz
mv $anat_dir/sub-01_ses-${SES}_T2star.nii.gz $anat_dir/T2High_${SES}.nii.gz
done

#Process T1 images
#
# Register all the other T1high to the first run of T1high.
cd $anat_dir

flirt -in $anat_dir/T1High_03.nii.gz -ref $anat_dir/T1High_01.nii.gz -dof 6 -out $anat_dir/T1High2_to_T1High1 -omat $anat_dir/T1High2_to_T1High1.mat
flirt -in $anat_dir/T1High_05.nii.gz -ref $anat_dir/T1High_01.nii.gz -dof 6 -out $anat_dir/T1High3_to_T1High1 -omat $anat_dir/T1High3_to_T1High1.mat
flirt -in $anat_dir/T1High_07.nii.gz -ref $anat_dir/T1High_01.nii.gz -dof 6 -out $anat_dir/T1High4_to_T1High1 -omat $anat_dir/T1High2_to_T1High1.mat

#Average the T1Highs. 
fslmaths $anat_dir/T1High_01.nii.gz -add $anat_dir/T1High2_to_T1High1 -add $anat_dir/T1High3_to_T1High1 -add $anat_dir/T1High4_to_T1High1 -div 4 $anat_dir/T1High_ave -odt float

/sw/ANTs/bin/DenoiseImage -d 3 -i $anat_dir/T1High_ave.nii.gz -o $anat_dir/T1High_denoised.nii.gz


#Process T2 images
#
# Register all the other T2high to the first run of T2high.
flirt -in $anat_dir/T2High_03.nii.gz -ref $anat_dir/T2High_01.nii.gz -dof 6 -out $anat_dir/T2High2_to_T2High1 -omat $anat_dir/T2High2_to_T2High1.mat
flirt -in $anat_dir/T2High_05.nii.gz -ref $anat_dir/T2High_01.nii.gz -dof 6 -out $anat_dir/T2High3_to_T2High1 -omat $anat_dir/T2High3_to_T2High1.mat
flirt -in $anat_dir/T2High_07.nii.gz -ref $anat_dir/T2High_01.nii.gz -dof 6 -out $anat_dir/T2High4_to_T2High1 -omat $anat_dir/T2High2_to_T2High1.mat

#Average the T2Highs. 
fslmaths $anat_dir/T2High_01.nii.gz -add $anat_dir/T2High2_to_T2High1 -add $anat_dir/T2High3_to_T2High1 -add $anat_dir/T2High4_to_T2High1 -div 4 $anat_dir/T2High_ave -odt float

#Denoise
/sw/ANTs/bin/DenoiseImage -d 3 -i $anat_dir/T2High_ave.nii.gz -o $anat_dir/T2High_denoised.nii.gz

ID="01"

anat_dir="Your_anat_dir"

anatfiles="T1High_denoised T1High_ave T2High_ave T2High_denoised"

for anatfile in ${anatfiles}
do
echo $anatfile
#Convert anat files into RPI orientation
3dresample -orient RPI -inset $anat_dir/${anatfile}.nii.gz -prefix  $anat_dir/${anatfile}_RPI #anat file reorient
sleep 10 #unknown

# convert to NIFTI
cd $anat_dir
#3dAFNItoNIFTI  $resting+orig.BRIK  -prefix $rest_dir/$resting.nii
3dAFNItoNIFTI $anat_dir/${anatfile}_RPI+orig.BRIK  -prefix $anat_dir/${anatfile}_RPI.nii

 
# remove AFNI format files we don't need (since we will work with nifti for a while)
rm -f ${anatfile}_RPI+*
#rm -f $resting+*
gzip $anat_dir/*.nii # compress from .nii to .nii.gz
done
date
