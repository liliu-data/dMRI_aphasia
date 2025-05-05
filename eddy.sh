#!/bin/bash

# Set the base directory where all subject data is located
BASE_DIR="/Volumes/adam/DTI_only2" # Modify this to your actual path

# Get a list of all subject directories (accounting for both CP and AP endings)
cd "$BASE_DIR"
SUBJECTS=($(ls -d [0-9]*_[CA]P* 2>/dev/null))

# If no subjects are found, exit
if [ ${#SUBJECTS[@]} -eq 0 ]; then
    echo "No subject directories found in $BASE_DIR"
    exit 1
fi

echo "Found ${#SUBJECTS[@]} subjects to process"

# Process each subject
for subj in "${SUBJECTS[@]}"; do
    echo "===================================="
    echo "Processing subject: $subj"
    echo "===================================="
    
    # Change to the subject's directory
    cd "$BASE_DIR/$subj" || { echo "Cannot access $BASE_DIR/$subj directory"; continue; }
    
    # Check if DTI file exists
    DTI_FILE="DTI_raw_${subj}.nii"
    if [ ! -f "$DTI_FILE" ] && [ ! -f "${DTI_FILE}.gz" ]; then
        echo "WARNING: DTI file not found for subject $subj. Skipping."
        continue
    fi
    
    # Ensure DTI file is in .nii.gz format
    if [ -f "$DTI_FILE" ] && [ ! -f "${DTI_FILE}.gz" ]; then
        echo "Converting $DTI_FILE to .nii.gz format..."
        gzip -k "$DTI_FILE"
    fi
    
    # Compressed filename
    DTI_FILE_GZ="${DTI_FILE}.gz"
    
    # Check for bval and bvec files
    BVAL_FILE="bval_${subj}.bval"
    BVEC_FILE="bval_${subj}.bvec"
    
    if [ ! -f "$BVAL_FILE" ] || [ ! -f "$BVEC_FILE" ]; then
        echo "WARNING: bval or bvec file not found for subject $subj. Skipping."
        continue
    fi
    
    echo "Extracting first volume for brain extraction..."
    # Extract first volume (assumed to be b0 or close to b0) for brain extraction
    fslroi "$DTI_FILE_GZ" b0_image 0 1
    
    echo "Creating brain mask..."
    # Create brain mask
    bet b0_image b0_brain -m -f 0.4
    
    echo "Creating index file for eddy..."
    # Get number of volumes in the DTI file
    NUM_VOLS=$(fslnvols "$DTI_FILE_GZ")
    
    # Create index file for eddy (simple case with no reverse PE data)
    indx=""
    for ((i=1; i<=$NUM_VOLS; i+=1)); do 
        indx="$indx 1"
    done
    echo $indx > index.txt
    
    # Create simple acquisition parameters file
    # Format: [x y z SCfactor]
    # For A>>P phase encoding: 0 1 0 TotalReadoutTime
    echo "0 1 0 0.05" > acqparams.txt
    
    echo "Running eddy correction..."
    # Run eddy current correction without topup
    eddy --imain="$DTI_FILE_GZ" \
         --mask=b0_brain_mask \
         --acqp=acqparams.txt \
         --index=index.txt \
         --bvecs="$BVEC_FILE" \
         --bvals="$BVAL_FILE" \
         --out=eddy_corrected_data \
         --data_is_shelled \
	     --verbose
    
    # Copy bvals and bvecs files to standardized names
    cp "$BVAL_FILE" eddy_corrected_data.bval
    cp eddy_corrected_data.eddy_rotated_bvecs eddy_corrected_data.bvec
    
    echo "Running quality control check..."
    # Run quality control
    eddy_quad eddy_corrected_data -idx index.txt -par acqparams.txt \
              -m b0_brain_mask.nii.gz -b eddy_corrected_data.bval
    
    echo "Finished processing $subj"
    echo "-------------------------------------"

     ############ Clean unnecessasay files #########################

     # Paso 3: Limpiar archivos temporales
    rm "eddy_corrected_data.eddy.json"
    rm "eddy_corrected_data.eddy_values_of_all_input_parameters"
    rm "eddy_corrected_data.eddy_shell_indicies.json"
    rm "eddy_corrected_data.eddy_rotated_bvecs"
    rm "eddy_corrected_data.eddy_restricted_movement_rms"
    rm "eddy_corrected_data.eddy_post_eddy_shell_PE_translation_parameters"
    rm "eddy_corrected_data.eddy_post_eddy_shell_alignment_parameters"
    rm "eddy_corrected_data.eddy_parameters"
    rm "eddy_corrected_data.eddy_outlier_report"
    rm "eddy_corrected_data.eddy_outlier_n_stdev_map"
    rm "eddy_corrected_data.eddy_outlier_n_sqr_stdev_map"
    rm "eddy_corrected_data.eddy_outlier_map"
    rm "eddy_corrected_data.eddy_movement_rms"

    echo "✅ Eddy finished and all the unnecessary files are clened for $subj"
done

echo "🎉 all subjects are preprocessed and cleaned."
