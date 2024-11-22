#!/bin/bash

export BIDS_DIR="/data/neuron/TRW/reprocessed"
cd ${BIDS_DIR}

subj_list=( 001 002 004 005 006 008 011 013 014 015 
            017 022 023 024 025 026 027 028 029 033 
            034 035 036 037 039 040 041 101 102 103 
            108 112 113 114 115 116 117 118 119 120 
            121 126 127 128 130 132 135 137 139 140 
            141 143 144 146 147 148 149 150 152 153 
            154 155 156 157 159 160 161 168 170 171 
            172 173 174 175 177 178 179 180 181 )

subj_list=( 002 004 005 006 008 011 013 014 015 
            017 022 023 024 025 026 027 028 029 033 
            034 035 036 037 039 040 041 101 102 103 
            108 112 113 114 115 116 117 118 119 120 
            121 126 127 128 130 132 135 137 139 140 
            141 143 144 146 147 148 149 150 152 153 
            154 155 156 157 159 160 161 168 170 171 
            172 173 174 175 177 178 179 180 181 )



##########################################################################
# Set up BIDS
##########################################################################

# Create symbolic links for the dicoms in BIDS format
for subj in "${subj_list[@]}"; do
    mkdir sourcedata/${subj}
    ln -s /data/neuron/TRW/original/${subj}/2* sourcedata/${subj}/
done


# Convert dicoms to niftis, using Heudiconv

# First we will create the heuristic.py file that will be used to pull dicoms of 
# the same type of scans together (e.g. anat, func, fmap)
singularity exec \
    --bind /data/neuron/TRW:/base \
    /software/neuron/Containers/heudiconv_latest.sif \
    heudiconv \
    -d /base/original/RED_TRW_{subject}/*/*/*.dcm \
    -o /base/reprocessed \
    -f reproin \
    -s 001 \
    -c none \
    --overwrite 

# Manually edit the heuristics.py file located in .heudiconv/001/info/

# Use heudiconv to create niftis
for subj in "${subj_list[@]}"; do
    sh code/preprocessing_TRW-bswift2.sh -s ${subj} -n
done


# Run fmriprep on bswift2
for subj in "${subj_list[@]}"; do
    sh code/preprocessing_TRW-bswift2.sh -s ${subj} -f
done


# Transfer preprocessed data back to lab server
for subj in "${subj_list[@]}"; do
    sh code/preprocessing_TRW-bswift2.sh -s ${subj} -t
done

