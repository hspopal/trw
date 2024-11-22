#!/bin/bash

while getopts "s:dnfrath" opt; do
	case $opt in 
        s) # Provide subject ID
            subID=${OPTARG};;
    esac
done


singularity exec \
    --bind /data/neuron/TRW:/base \
    /software/neuron/Containers/heudiconv_latest.sif \
    heudiconv \
    -d /base/original/RED_TRW_{subject}/*/*/*.dcm \
    -o /base/reprocessed/Nifti \
    -f /base/reprocessed/code/heuristic.py \
    -s $subID \
    -c dcm2niix -b \
    --overwrite 