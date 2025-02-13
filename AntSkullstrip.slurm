#!/bin/bash -l
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --mem=10G

date
hostname

export ANTSPATH=/sw/ANTs/bin
export PATH=${ANTSPATH}:$PATH

AntDir="YourAnatdir" #This folder contains the averaged denoised T1 files.  
AntsTemplateDir="YourANTs_templatedir/Ants_templates" #Useful website about parameters: https://dpaniukov.github.io/2016/06/06/brain-extraction-with-ants.html

antsBrainExtraction.sh -d 3 -a $AntDir/T1High_ave_RPI.nii.gz -e $AntsTemplateDir/T_template0.nii.gz -m $AntsTemplateDir/T_template0_BrainCerebellumProbabilityMask.nii.gz -f $AntsTemplateDir/T_template0_BrainCerebellumRegistrationMask.nii.gz -o $AntDir/T1_
mv $AntDir/T1_BrainExtractionBrain.nii.gz $AntDir/T1_brain.nii.gz
mv $AntDir/T1_BrainExtractionMask.nii.gz $AntDir/T1_BrainMask.nii.gz
date