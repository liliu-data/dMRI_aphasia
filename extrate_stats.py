import os
import re
import pandas as pd
import glob

# Find all stats files with your specific naming pattern
file_pattern = "**/1*_stats"  # Pattern matches files like 161020_stats
stats_files = glob.glob(file_pattern, recursive=True)

# Initialize list to store data
results = []

# Process each file
for file_path in stats_files:
    # Extract ID from the filename itself (e.g., "161020" from "161020_stats")
    file_basename = os.path.basename(file_path)
    # Extract the numerical ID at the beginning of the filename
    file_id_match = re.match(r'(\d+)_', file_basename)
    file_id = file_id_match.group(1) if file_id_match else "unknown"
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Use regex to find each TrackGroup section
    track_sections = re.split(r'(?=TrackGroup:)', content)
    
    for section in track_sections:
        if not section.strip():
            continue
            
        data = {}
        # Use ID from filename
        data['ID'] = file_id
        
        # Extract metrics
        track_group_match = re.search(r'TrackGroup:\s+(\S+)', section)
        if track_group_match:
            data['track_group'] = track_group_match.group(1)
            
        track_count_match = re.search(r'Track count:\s+(\d+)', section)
        if track_count_match:
            data['track_count'] = int(track_count_match.group(1))
            
        voxel_count_match = re.search(r'Voxel count:\s+(\d+)', section)
        if voxel_count_match:
            data['voxel_count'] = int(voxel_count_match.group(1))
            
        # Extract both mean and standard deviation with consistent naming
        length_match = re.search(r'Length:\s+([\d\.]+)\s+\+/-\s+([\d\.]+)', section)
        if length_match:
            data['Length_mean'] = float(length_match.group(1))
            data['Length_sd'] = float(length_match.group(2))
            
        hmoa_match = re.search(r'HMOA_1:\s+([\d\.]+)\s+\+/-\s+([\d\.]+)', section)
        if hmoa_match:
            data['HMOA_1_mean'] = float(hmoa_match.group(1))
            data['HMOA_1_sd'] = float(hmoa_match.group(2))
            
        angtrk_match = re.search(r'AngTrk:\s+([\d\.]+)\s+\+/-\s+([\d\.]+)', section)
        if angtrk_match:
            data['AngTrk_mean'] = float(angtrk_match.group(1))
            data['AngTrk_sd'] = float(angtrk_match.group(2))
            
        ap6np1_match = re.search(r'AP6np1:\s+([\d\.]+)\s+\+/-\s+([\d\.]+)', section)
        if ap6np1_match:
            data['AP6np1_mean'] = float(ap6np1_match.group(1))
            data['AP6np1_sd'] = float(ap6np1_match.group(2))
            
        # Try to match the special HARDI data field
        special_match = re.search(r'(\d+_eddy_data\d+_SH\d+_\d+dir_HARDI_AP6np):\s+([\d\.]+)\s+\+/-\s+([\d\.]+)', section)
        if special_match:
            id_name = special_match.group(1)
            data[f'{id_name}_mean'] = float(special_match.group(2))
            data[f'{id_name}_sd'] = float(special_match.group(3))
            
        results.append(data)

# Create DataFrame and export to CSV
df = pd.DataFrame(results)

# Define column order with consistent naming
column_order = ['ID', 'track_group', 'track_count', 'voxel_count', 
                'Length_mean', 'Length_sd', 
                'HMOA_1_mean', 'HMOA_1_sd',
                'AngTrk_mean', 'AngTrk_sd',
                'AP6np1_mean', 'AP6np1_sd']

# Add any special columns that might exist
special_columns = [col for col in df.columns if col not in column_order]
column_order.extend(special_columns)

# Reorder columns to match the desired format (using only columns that exist)
existing_columns = [col for col in column_order if col in df.columns]
df = df[existing_columns]

# Export to CSV
output_file = "track_data_complete.csv"
df.to_csv(output_file, index=False)

print(f"Data exported to {output_file}")