#!/bin/bash
##########################################################################
#                       TRW Preprocessing Script
#
# Preprocessing script for the TRW project which downloads dicoms from
# the MNC servers, converts them to niftis in BIDS format, and runs
# preprocessing via fmriprep on the bswift HPC.

# Each stage of this script can be run independently. See the help 
# function for details on running this script. This script should be 
# placed in the "code" directory on Neuron. It relies on 
# certain helper scripts developed by Oliver Xie, Junaid Merchant, and 
# Haroon Popal.
# 
# Prerequisite scripts:
# 1. BidsConvert_TRW.sh - should be in the code directory
# 2. BidsConvertParameters_TRW.sh - same as above
# 3. fmriprep_TRW.sh - should be in YOUR "code" directory on bswift
# (e.g. /data/bswift-1/hpopal/TRW/code/fmriprep_TRW.sh)
#
##########################################################################

##########################################################################
# Help
Help()
{
    # Display help
    echo "SCONN Preprocessing Script"
    echo
    echo "Syntax: sh preprocesssing_TRW-bswift2.sh -s [999 -d|n|f|r|a|h]"
    echo "options:"
    echo "-d    Only download dicoms from MNC servers"
    echo "-n    Only convert dicoms to Niftis"
    echo "-f    Run fmriprep preprocessing"
    echo "-r    Rerun fmriprep for a particular participant"
    echo "-a    Rerun the entire pipeline for a particular participant, from downloading data from MNC to fmriprep"
    echo "-t    Transfer fmriprep, freesurfer, and log data from bswift to neuron"
    echo "-h    Print this help"
}
##########################################################################

# Get optional inputs
dicom_download=false
convert_niftis=false
run_fmriprep=false
rerun_fmriprep=false
transfer_bswift2server=false

while getopts "s:dnfrath" opt; do
	case $opt in 
        s) # Provide subject ID
            subID=${OPTARG};;
        d) # Download dicoms
            dicom_download=true;;
        n) # Convert dicoms to niftis
            convert_niftis=true;;
        f) # Rerun just fmriprep
            run_fmriprep=true;;
        r) # Rerun just fmriprep
            run_fmriprep=true;
            rerun_fmriprep=true;;
        a) # Rerun entire pipeline, removing all data everywhere, and 
           # redownloading data from MNC
            dicom_download=true;
            convert_niftis=true;
            rerun_fmriprep=true;;
        t) # Transfer data from bswift to server
            transfer_bswift2server=true;;
        h) # Display Help
            Help
            exit;;
	esac
done


# Set variables and directories

# Define project code abbreviation
proj_abr="REDTRW"
mnc_abr="RED_TRW"  # In case the project abbreviation from the MNC is something different
uname=$USER  # Record your directory ID/username
lab_server="neuron"

# Set path for MNC servers
MNC_path='/export/software/fmri/massstorage/Elizabeth\ Redcay/TRW\ Social\ Connection'
proj_dir=/data/${lab_server}/TRW/reprocessed  # This should be the BIDS home directory
dicom_dir="$proj_dir"/sourcedata/  # Location of dicome files
nifti_dir=${proj_dir}/Nifti/sub-${proj_abr}${subID}  # Output directory of niftis
bswift_dir=/data/software-research/"${uname}"/TRW/  # BIDS directory on bswift


# Navigate to the project directory
cd $proj_dir

##########################################################################
# Define Functions
##########################################################################
# Download data from fmri2 to server dicom folder
function download_data () 
{
sub=$1
echo Downloading $1

# Path for data on MNC servers
scp -r ${uname}@fmri2.umd.edu:"${MNC_path}"/${sub}/ $dicom_dir
}

# Send BIDS data from server to bswift
function server2bswift () 
{
from_path=$1
to_path=$2
server_path=${uname}@bswift2-login.umd.edu
scp -r "${from_path}" "${server_path}":"$to_path/Nifti/sub-${proj_abr}${subID}"
}



##########################################################################
# Start Pipeline
##########################################################################

# Set variables to capture subject data at various stages of preprocessing
local_dicom=$(ls -d ${dicom_dir}/${mnc_abr}* | sed 's/[^0-9A-Z]*//g' | cut -c 4-)  # get subject index, sed command reduces to ${proj_abv}###, cut command reduces to just ID# - MK
local_bids=$(ls -d "$proj_dir"/Nifti/sub-${proj_abr}* | sed 's/[^0-9A-Z]*//g' | cut -c 4-) 
local_fmriprep=$(ls -d "$proj_dir"/derivatives/fmriprep/sub-${proj_abr}* | sed 's/[^0-9A-Z]*//g' | cut -c 4-) 



# Download dicoms

if $dicom_download
then
    echo ------------------------
    echo checking MNC server for data for ${subID}
    echo ------------------------

    # Check to see if dicoms exist on server
    if [[ ! $local_dicom == *${subID}* ]]
    then
        echo new data found ${proj_abr}$subID 
        download_data ${proj_abr}"${subID}"  # download data from fmri2 to server (dicom)
        chmod 777 -R "$proj_dir"/sourcedata/${mnc_abr}_${subID}
    else
        echo "Dicoms already exist"
    fi
fi



# Convert dicoms to niftis

cd ${proj_dir}/code

if $convert_niftis
then
    echo ------------------------
    echo converting dicoms to niftis for ${subID}
    echo ------------------------

    # Check to see if BIDS converted NIFTIs exist on server
    if [[ ! $local_bids == *${subID}* ]]
    then
        echo ${mnc_abr}_${subID} starting BIDS conversion
        # Convert raw dicom file to nii and put it into BIDS format
        "$proj_dir"/code/heudiconv_TRW.sh -s "${subID}" 
    else
        echo "Niftis already exist"
    fi
fi


# Preprocessing

cd ${proj_dir}

if $run_fmriprep
then
    # Check to see if fmriprep data exists on server
    if [[ ! $local_fmriprep == *${subID}* ]]
    then
        # Transfering data to BSWIFT 
        echo ${proj_abr}_${subID} transferring data to server
        server2bswift $nifti_dir $bswift_dir  # transfer the data to BSWIFT
            
        echo ------------------------
        echo running fmriprep for ${subID}
        echo ------------------------

        # Submit fmriprep sbatch on bswift
        ssh ${uname}@bswift2-login.umd.edu "sbatch --export=indir="$bswift_dir",uname="$uname",subID="$subID" --job-name=${proj_abv}"$subID" --mail-user="${uname}"@umd.edu --output="$bswift_dir"/derivatives/log/sub-${proj_abr}"$subID".log ${bswift_dir}/code/fmriprep_TRW-bswift2.sh"


    elif $rerun_fmriprep
    then
        # Transfering data to BSWIFT 
        echo TRW_${subID} transferring data to server
        server2bswift $nifti_dir $bswift_dir  # transfer the data to BSWIFT

        echo ------------------------
        echo rerunning fmriprep for ${subID}
        echo ------------------------

        # Submit fmriprep sbatch on bswift
        ssh ${uname}@bswift2-login.umd.edu "sbatch --export=indir="$bswift_dir",uname="$uname",subID="$subID" --job-name=${proj_abv}"$subID" --mail-user="${uname}"@umd.edu --output="$bswift_dir"/derivatives/log/sub-${proj_abr}"$subID".log ${bswift_dir}/code/fmriprep_TRW-bswift2.sh"
    
    else
        echo ------------------------
        echo fmriprep data for ${subID} already exists. If you want to rerun, run script with "-r" flag
        echo ------------------------
    fi
fi



# Transfer data from bswift to server
cd ${proj_dir}

if $transfer_bswift2server
then
    BID_ID=sub-${proj_abr}$subID
    ssh ${uname}@bswift2-login.umd.edu "sh ${bswift_dir}/code/data_transfer.sh "$BID_ID" "$bswift_dir" "$proj_dir" $lab_server" 

    # Change permissions to fmriprep files so everyone can edit
    #chgrp -R psyc-dTRW-data ${proj_dir}/derivatives/fmriprep/$BID_ID
    #chmod -R 775 ${proj_dir}/derivatives/fmriprep/$BID_ID
fi

