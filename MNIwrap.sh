#!/bin/bash
# Set the base directory where all subject data is located
BASE_DIR="/Volumes/adam/DTI_only2" # Modify this to your actual path

# Get a list of all subject directories (accounting for both CP and AP endings)
cd "$BASE_DIR"
SUBJECTS=($(ls -d [0-9]*_[CA]P* 2>/dev/null))

# Process each subject
for subj in "${SUBJECTS[@]}"; do
    echo "===================================="
    echo "Processing subject: $subj"
    echo "===================================="
    
    # Change to the subject's directory
    cd "$BASE_DIR/$subj" || { echo "Cannot access $BASE_DIR/$subj directory"; continue; }

    # ================== FLIRT ==============================
    /Users/litingliu/fsl/bin/flirt \
    -in $BASE_DIR/$subj/eddy_corrected_data.nii.gz \
    -ref /Users/litingliu/fsl/data/standard/MNI152_T1_2mm_brain \
    -out $BASE_DIR/$subj \
    -omat $BASE_DIR/$subj.mat \
    -bins 256 -cost corratio \
    -searchrx -180 180 \
    -searchry -180 180 \
    -searchrz -180 180 \
    -dof 12  \
    -interp trilinear

done
echo "All processing complete."