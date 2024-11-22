#!/bin/bash
#SBATCH --partition=main
#SBATCH --nodes=1 # Number of nodes (use 1 unless you need multiple nodes)
#SBATCH --ntasks=1 # Number of tasks (usually 1 for single-process jobs)
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=24:00:00

#
#module ()
#{
#    eval `/usr/local/Modules/3.2.10/bin/modulecmd bash $*`
#}
Sub=sub-REDTRW${subID}
#
module load freesurfer
#

#
indir=/data/software-research/${uname}/TRW/
[ ! -d $indir ] && mkdir $indir
[ ! -d $indir/derivatives ] && mkdir $indir/derivatives
[ ! -d $indir/derivatives/freesurfer ] && mkdir $indir/derivatives/freesurfer
#[ ! $indir/BIDS/dataset_description.json ] && cp /data/bswift-1/oliver/TRW/fmriprep/BIDS/dataset_description.json $indir/BIDS/dataset_description.json

if [ ! -e $indir/derivatives/freesurfer/${Sub} ]; then
    echo "------------------------------------------------------------------"
    echo "started freesurfer"
    echo ${Sub}
    date
    echo "------------------------------------------------------------------"

    recon-all -i $indir/Nifti/${Sub}/anat/${Sub}_run-1_T1w.nii.gz -openmp 8 -s ${Sub} -sd $indir/derivatives/freesurfer -all -parallel
    #
    #
    echo "------------------------------------------------------------------"
    echo "Ended freesurfer"
    echo ${Sub}
    date
    echo "------------------------------------------------------------------"
    #
    #
    #
    # You can change the 4 lines below, I just like having it time stamp it
    echo "------------------------------------------------------------------"
    echo "Starting fMRIprep at:"
    echo working on ${Sub}
    date
    echo "------------------------------------------------------------------"
fi
#
# 
#
export SINGULARITYENV_TEMPLATEFLOW_HOME=/data/archive/templateflow
#
/data/software-research/software/apptainer/bin/singularity run --cleanenv \
    -B ${indir}:/data \
    /data/software-research/hpopal/fmriprep-20.2.6.simg \
    /data/Nifti /data/derivatives participant \
    --participant-label ${Sub} \
    -w /tmp/work_${uname}_${Sub}_1 \
    --skull-strip-template MNI152NLin2009cAsym \
    --output-spaces MNIPediatricAsym:cohort-5:res-2 MNI152NLin6Asym:res-2 anat \
    --use-aroma \
    --nthreads 8 --n_cpus 6 --omp-nthreads 6 \
    --mem-mb 24000 \
    --skip_bids_validation \
    --no-submm-recon \
    --fs-license-file /data/archive/license.txt

rm -rf /tmp/work_${uname}_${Sub}_1


#
echo "------------------------------------------------------------------"
echo "Ended fMRIprep"
echo ${Sub}
date
echo "------------------------------------------------------------------"

# echo start transfering ${Sub} preprocessed data and log file to neuron
# sh /data/bswift-1/oliver/SCN/code/data_transfer.sh $Sub $indir
#scp -r "${indir}"/derivatives/fmriprep/"${Sub}" "${indir}"/derivatives/fmriprep/"${Sub}".html "${uname}"@neuron.umd.edu:/data/neuron/TRW/derivatives/fmriprep/
#scp -r "${indir}"/derivatives/freesurfer/"${Sub}" "${uname}"@neuron.umd.edu:/data/neuron/TRW/reprocessed/derivatives/freesurfer/
#scp -r "${indir}"/derivatives/log/sub-REDTRW"$idx".log "${uname}"@neuron.umd.edu:/data/neuron/TRW/reprocessed/derivatives/log/
