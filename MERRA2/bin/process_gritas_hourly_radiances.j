#!/bin/csh -f

#SBATCH --constraint=mil
#SBATCH --account=g2538
#SBATCH --partition=preops

# for a specific yyyymmddhh sequence in a cylc array across month's time
# identify ods files in an obs dir
# feed those into gritas 4 differnt ways
# save the output files for each day in workdir/instrument/d/yyyy/mm/dd/file.syn.nc4

# logging feedback and default permissions for files created from this script
set echo
umask 022
echo "BASEDIR = $BASEDIR"

# read in inputs
set NYMD = $1 
set YEAR_TABLE = `echo $NYMD | cut -c 1-6`
set SYNOP_TABLE = $2
set ExpID = $3
set INSTRUMENT = $4

# establish paths for scripting
set BASE_DIR    = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/
set RC_DIR	= ${BASE_DIR}/etc
set EXE_DIR     = ${BASE_DIR}/bin
set RC_File     = ${RC_DIR}/rc_files2/gritas_${INSTRUMENT}_merra2.rc
set n4zip_file   = ${EXE_DIR}/n4zip.csh

# build link to gritas
#set BinDir =  /home/dao_ops/operations/M2_GRITAS/GrITAS/Linux/bin
set BinDir = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
#set BinDir = $BIN_DIR
setenv TAG   merra2
set RES      = 'd'
#set Gritas_Core_Opt  = "-nlevs 106 -rc $RC_File -hdf -res $RES -ncf -ospl -lb -nopassive"
set Gritas_Core_Opt  = "-nlevs 50 -rc $RC_File -res d -ncf -ospl -lb -nopassive"
set gritas  = ${BinDir}/gritas.x
set grmeans = ${BinDir}/GFIO_mean_r8.x

# establish paths for each stage of data
set HOME_MOUNT  =  /discover/nobackup/projects/gmao/merra2/data/obs/.WORK
set WORKING_DIR =  $HOME_MOUNT/work_dir_wjd/${INSTRUMENT/$RES
set OBS_DIR	 =  $HOME_MOUNT/raw_obs_wjd/${INSTRUMENT}

set YYYY = `echo $YEAR_TABLE | cut -c 1-4`
set MM   = `echo $YEAR_TABLE | cut -c 5-6`

# input ods files and output gritas netcdf
set DataDir     = ${OBS_DIR}/${YEAR_TABLE}
set STORAGE_DIR = ${WORKING_DIR}/Y$YYYY/M$MM
chmod 755 $STORAGE_DIR
mkdir -p $STORAGE_DIR
set Day = `echo $NYMD | cut -c 7-8`
set Date   = ${NYMD}
set DayDir = $STORAGE_DIR/D${Day}
echo "DayDir $DayDir"
mkdir -p ${DayDir}
chmod 755 ${DayDir}


# cd $DataDir
#/discover/nobackup/projects/gmao/merra2/data/obs/.WORK/raw_obs_wjd/airs_aqua/201212/d5124_m2_jan10.diag_airs_aqua.20121231_18z.ods

set ods_Files = `ls -1 ${DataDir}/*.diag_${INSTRUMENT}.${Date}*_${SYNOP_TABLE}z.ods`
set syn_tag = "_${SYNOP_TABLE}z"
echo $ods_Files

set out_fileo   = gritaso${NYMD}${SYNOP_TABLE}
/bin/rm -f ${out_fileo}.{bias,stdv,nobs}.nc4
$gritas -obs -o $out_fileo $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for o-f data
set out_filef   = $DayDir/gritasf${NYMD}${SYNOP_TABLE}
/bin/rm -f ${out_filef}.{bias,stdv,nobs}.nc4
$gritas -omf -o $out_filef $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for o-a data
set out_filea   = gritasa${NYMD}${SYNOP_TABLE}
/bin/rm -f ${out_filea}.{bias,stdv,nobs}.nc4
$gritas -oma -o $out_filea $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for bias data
set out_fileb   = gritasb${NYMD}${SYNOP_TABLE}
/bin/rm -f ${out_fileb}.{bias,stdv,nobs}.nc4
$gritas -obias -o $out_fileb $Gritas_Core_Opt ${ods_Files} &
wait
#rm -f ${ods_Files}

# clean the work dir for that day of any pre-existing files for that synoptic time
/bin/rm -f ${DayDir}/*${SYNOP_TABLE}z*nc4*pid*.tmp
/bin/rm -f ${DayDir}/*${SYNOP_TABLE}z*.nc4 

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.bias.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.nobs.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.stdv.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.bias.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.nobs.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.stdv.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc
   
/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.bias.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.nobs.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.stdv.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.bias.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.nobs.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.stdv.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.bias.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.nobs.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc

/discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.stdv.nc4 -o ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag} -zrev
$EXE_DIR/run_ncrcat.csh ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc

if ( -e ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
else
    mv -f ${out_fileo}.bias.nc4 ${DayDir}/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
endif
    
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
else
    mv -f ${out_fileo}.nobs.nc4 ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
endif
     
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_fileo}.stdv.nc4 ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc4
endif

if ( -e ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filef}.bias.nc4  ${DayDir}/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc4
endif
  
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filef}.nobs.nc4 ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc4
endif
 
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filef}.stdv.nc4 ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc4
endif

if ( -e ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filea}.bias.nc4 ${DayDir}/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc4
endif
  
if ( -e  ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filea}.nobs.nc4 ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc4
endif
 
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_filea}.stdv.nc4 ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc4
endif

if ( -e ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_fileb}.bias.nc4 ${DayDir}/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc4
endif
  
if ( -e ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_fileb}.nobs.nc4 ${DayDir}/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc4
endif

if ( -e ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc ) then
    mv -f ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc  ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc4
else
    mv -f ${out_fileb}.stdv.nc4 ${DayDir}/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc4
endif

echo $NYMD radiance processing complete
