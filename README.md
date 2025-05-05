# MRI Preprocessing Pipeline

This project implements a preprocessing workflow for diffusion MRI data, designed during my internship at the Donders Institute.

## 🔧 Tools Used
- FSL (BET, eddy)
- Unix Shell Scripting
- Python
- TrackVis, StarTrack

## 📈 Key Features
- Automated artifact correction and DTI fitting

## 🧠 Context
Used in a clinical study on post-stroke aphasia to streamline and standardize imaging analysis.

## 📂 Structure
- use mask.sh to create brain masks for all of your subjects
- use eddy.sh to correct eddy current distortion
- use extractdata.py to extract the statistical data derived from TrackVis to an .csv sheet
