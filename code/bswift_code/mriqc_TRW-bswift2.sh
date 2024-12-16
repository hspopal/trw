#!/bin/bash
#SBATCH --partition=main
#SBATCH --nodes=1 # Number of nodes (use 1 unless you need multiple nodes)
#SBATCH --ntasks=1 # Number of tasks (usually 1 for single-process jobs)
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=24:00:00


Sub=sub-REDTRW${subID}

MPLCONFIGDIR='/tmp/work_${Sub}'

echo "------------------------------------------------------------------"
echo "Starting MRIQC at:"
echo working on ${Sub}
date
echo "------------------------------------------------------------------"


/data/software-research/software/apptainer/bin/singularity run --cleanenv \
    -B /data/software-research/hpopal/TRW:/base \
    /data/software-research/hpopal/mriqc-23.1.1.sif \
    /base /base/derivatives/mriqc \
    participant --participant-label ${Sub} \
    -w /tmp/work_${Sub}

rm -rf /tmp/work_${Sub}


echo "------------------------------------------------------------------"
echo "Ended MRIQC"
echo ${Sub}
date
echo "------------------------------------------------------------------"
