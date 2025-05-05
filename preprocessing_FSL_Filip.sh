for id in 01 ; do
#for id in `seq -w 1 52` ; do
subj="sub-$id"
cd /Volumes/Filip\'s\ SSD/prueba/$subj/dwi


# subject 03 trying on myccu3

fslmerge -t ${subj}.nii.gz ${subj}_dir-PA_b300_dwi.nii.gz ${subj}_dir-PA_b1000_dwi.nii.gz ${subj}_dir-PA_b2000_dwi.nii.gz
paste -d " " ${subj}_dir-PA_b300_dwi.bval ${subj}_dir-PA_b1000_dwi.bval ${subj}_dir-PA_b2000_dwi.bval>>bvals
paste -d " " ${subj}_dir-PA_b300_dwi.bvec ${subj}_dir-PA_b1000_dwi.bvec ${subj}_dir-PA_b2000_dwi.bvec>>bvecs


fslroi ${subj}_dir-AP_b300_dwi AP_b0 0 2
fslroi ${subj}_dir-PA_b300_dwi PA_b0 0 2
fslmerge -t AP_PA_b0 AP_b0 PA_b0
printf "0 1 0 0.07254\n0 1 0 0.07254\n0 -1 0 0.07254\n0 -1 0 0.07254" > acqparams.txt

#fslroi is used to add a slice (81+1 =82 slices now) because FSL cannot handle an odd number of slices

fslroi AP_PA_b0.nii.gz AP_PA_b0.nii.gz 0 118 0 118 0 82 0 4
fslroi ${subj}.nii.gz ${subj}.nii.gz 0 118 0 118 0 82 0 114

topup --imain=AP_PA_b0 --datain=acqparams.txt --config=b02b0.cnf --out=my_topup_results --iout=my_hifi_b0

#bet

fslmaths my_hifi_b0 -Tmean my_hifi_b0
bet my_hifi_b0 my_hifi_b0_brain -m -f 0.4

indx=""
for ((i=1; i<=114; i+=1)); do indx="$indx 3"; done
echo $indx > index.txt

eddy --imain=${subj}.nii.gz --mask=my_hifi_b0_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvecs --bvals=bvals --topup=my_topup_results --data_is_shelled --repol --cnr_maps --out=eddy_corrected_data

cp bvals eddy_corrected_data.bval
cp eddy_corrected_data.eddy_rotated_bvecs eddy_corrected_data.bvec

##Quality Control

eddy_quad eddy_corrected_data -idx index.txt -par acqparams.txt -m my_hifi_b0_brain_mask.nii.gz -b eddy_corrected_data.bval