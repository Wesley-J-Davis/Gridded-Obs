#!/bin/csh -f

#SBATCH --constraint=mil
#SBATCH --account=g2538
#SBATCH --partition=preops

set echo

umask 022

limit stacksize unlimited

# Set MPI environment variables
#setenv OMPI_MCA_btl_vader_single_copy_mechanism none
#setenv OMPI_MCA_btl ^openib     # Disable InfiniBand if not available

#set BinDir =  /home/dao_ops/operations/M2_GRITAS/GrITAS/Linux/bin
set BinDir = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
#set BinDir = $BIN_DIR
#source $BinDir/g5_modules
#module load nco
echo "BASEDIR = $BASEDIR"
setenv TAG   merra2

set NYMD = $1 
set YEAR_TABLE = `echo $NYMD | cut -c 1-6`
#set INSTRUMENT_TABLE = 'conv'
set SYNOP_TABLE = $2
set ExpID = $3
set INSTRUMENT_TABLE = $4

set BASE_DIR    = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/
set RC_DIR	= ${BASE_DIR}/etc
set EXE_DIR     = ${BASE_DIR}/bin
set RC_File     = ${RC_DIR}/rc_files2/gritas_${INSTRUMENT_TABLE}_merra2.rc

set RES      = 'd'
#set Gritas_Core_Opt  = "-nlevs 106 -rc $RC_File -hdf -res $RES -ncf -ospl -lb -nopassive"
set Gritas_Core_Opt  = "-nlevs 50 -rc $RC_File -res d -ncf -ospl -lb -nopassive"

set WorkRootDir  =  /discover/nobackup/projects/gmao/merra2/data/obs/.WORK
set Storage_Base =  $WorkRootDir/work_dir_wjd/${INSTRUMENT_TABLE}/$RES
set Work_Base	 =  $WorkRootDir/raw_obs_wjd/${INSTRUMENT_TABLE}

set n4zip_file   = ${EXE_DIR}/n4zip.csh

echo " BinDir   $BinDir"
echo " RC_DIR   $RC_DIR"
echo " n4zip_dir $n4zip_file"

set gritas  = ${BinDir}/gritas.x
set grmeans = ${BinDir}/GFIO_mean_r8.x

set YYYY = `echo $YEAR_TABLE | cut -c 1-4`
set MM   = `echo $YEAR_TABLE | cut -c 5-6`

set WorkDir     = ${Work_Base}/${YEAR_TABLE}
mkdir -p $WorkDir
chmod 755 $WorkDir

set STORAGE_DIR = ${Storage_Base}/Y$YYYY/M$MM
chmod 755 $STORAGE_DIR
mkdir -p $STORAGE_DIR

cd $WorkDir

set Day = `echo $NYMD | cut -c 7-8` 
set Date   = ${NYMD}
set DayDir = $STORAGE_DIR/D${Day}
echo "DayDir $DayDir"
mkdir -p ${DayDir}
chmod 755 ${DayDir}

set ods_Files = `ls -1 $OBS_DIR/${INSTRUMENT}/${Date}/*.diag_${INSTRUMENT}.${Date}*_${SYNOP_TABLE}z.ods`
set syn_tag = "_${SYNOP_TABLE}z"
echo $ods_Files

set out_fileo   = gritaso${SYNOP_TABLE}
/bin/rm -f ${out_fileo}.{bias,stdv,nobs}.nc4
$gritas -obs -o $out_fileo $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for o-f data
set out_filef   = gritasf${SYNOP_TABLE}
/bin/rm -f ${out_filef}.{bias,stdv,nobs}.nc4
$gritas -omf -o $out_filef $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for o-a data
set out_filea   = gritasa${SYNOP_TABLE}
/bin/rm -f ${out_filea}.{bias,stdv,nobs}.nc4
$gritas -oma -o $out_filea $Gritas_Core_Opt ${ods_Files} &
wait

#    ... for bias data
set out_fileb   = gritasb${SYNOP_TABLE}
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
