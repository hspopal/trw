#!/bin/bash
Sub=$1
indir=$2
proj_dir=$3
lab_server=$4
uname=$USER
scp -r "${indir}"/derivatives/fmriprep/"${Sub}" "${indir}"/derivatives/fmriprep/"${Sub}".html "${uname}"@${lab_server}.umd.edu:${proj_dir}/derivatives/fmriprep/
scp -r "${indir}"/derivatives/freesurfer/"${Sub}" "${uname}"@${lab_server}.umd.edu:${proj_dir}/derivatives/freesurfer/
scp -r "${indir}"/derivatives/log/"$Sub".log "${uname}"@${lab_server}.umd.edu:${proj_dir}/derivatives/log/
