#!/bin/bash

# Set the base directory where all subject data is located
BASEDIR="/Volumes/adam/DTI_only"

# Get a list of all subject directories (accounting for both CP and AP endings)
cd "$BASEDIR"
SUBJECTS=($(ls -d [0-9]*_[CA]P* 2>/dev/null))

# Process each subject
for subj in "${SUBJECTS[@]}"; do
    echo "===================================="
    echo "Processing subject: $subj"
    echo "===================================="
    
    cd "$BASEDIR/$subj"
    # Remove .nii.gz extension for output prefixes
    prefix=${subj%.nii.gz}
   
    # ================== BET ==============================
    # Extract first volume (assumed to be b0 or close to b0) for brain extraction
    echo "Extracting b0 image..."
    fslroi "eddy_corrected_data.nii.gz" "${prefix}_b0_eddy" 0 1
    
    echo "Creating brain mask..."
    # Create brain mask
    bet "${prefix}_b0_eddy" "${prefix}_b0_eddy_brain" -m -f 0.3

done
echo "All processing complete."