#!/bin/csh -f

#SBATCH --account=g2538
#SBATCH --partition=preops

set echo
umask 022
limit stacksize unlimited

# Set MPI environment variables
setenv OMPI_MCA_btl_vader_single_copy_mechanism none
setenv OMPI_MCA_btl ^openib     # Disable InfiniBand if not available

#set BinDir =  /home/dao_ops/operations/M2_GRITAS/GrITAS/Linux/bin
set BinDir = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
#set BinDir = $BIN_DIR
#source $BinDir/g5_modules
#module load nco
echo "BASEDIR = $BASEDIR"
setenv TAG   merra2

set YEAR_TABLE = $1 
set INSTRUMENT_TABLE = 'conv'
set Hour = $2
set ExpID = $3
set Day = $4

set YYYY = `echo $YEAR_TABLE | cut -c 1-4`
set MM   = `echo $YEAR_TABLE | cut -c 5-6`

set RC_DIR	= /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/etc
set RC_File  =  ${RC_DIR}/rc_files2/gritas_upconv_merra2.rc
set RES      = 'd'
set Gritas_Core_Opt  = "-nlevs 106 -rc $RC_File -hdf -res $RES -ncf -ospl -lb -nopassive"
#set Gritas_Core_Opt  = "-nlevs 50 -rc $RC_File -res d -ncf -ospl -lb -nopassive"

set WorkRootDir  =  /discover/nobackup/projects/gmao/merra2/data/obs/.WORK
set Storage_Base =  $WorkRootDir/work_dir_wjd/conv/$RES
set Work_Base	 =  $WorkRootDir/raw_obs_wjd/conv

set n4zip_file   = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin/n4zip.csh

echo " BinDir   $BinDir"
echo " RC_DIR   $RC_DIR"
echo " n4zip_dir $n4zip_file"

set gritas  = ${BinDir}/gritas.x
set grmeans = ${BinDir}/GFIO_mean_r8.x

set DAY_TABLE = ( 31 28 31 30 31 30 31 31 30 31 30 31 ) 
set WorkDir     = ${Work_Base}/${YEAR_TABLE}
set STORAGE_DIR = ${Storage_Base}/Y$YYYY/M$MM
mkdir -p $WorkDir
mkdir -p $STORAGE_DIR
if ( $MM == "02" ) then
   set num_check=`/usr/bin/perl /home/dao_ops/bin/tick ${YYYYMM}${DAY_TABLE[$MM]}`
   set check_num=`echo $num_check | cut -c 7-8`
   echo $check_num
   if ( "$check_num" == "29" ) then
      set DAY_TABLE = ( 31 29 31 30 31 30 31 31 30 31 30 31 )
   endif
endif 

set DAY_MAX = $DAY_TABLE[$MM] 
cd $WorkDir

if ( $Day < 10 ) then
   set Day = 0$Day
endif

if ( $Day > $DAY_MAX ) then
    echo "Day $Day exceeds days in month $MM. Exiting."
    exit 0
endif

set Date = ${YYYY}${MM}${Day}
set DayDir        = $STORAGE_DIR/D${Day}
echo "DayDir $DayDir"
mkdir -p ${DayDir}

set DateHr = ${YYYY}${MM}${Day}_${Hour}z.bin
set out_fileo   = gro${Day}${Hour}
/bin/rm -f ${out_fileo}.{bias,stdv,nobs}.nc4
$gritas -obs -o $out_fileo $Gritas_Core_Opt ${ExpID}.diag_conv_anl.$DateHr &

set out_filef   = grf${Day}${Hour}
/bin/rm -f ${out_filef}.{bias,stdv,nobs}.hdf
$gritas -omf -o $out_filef $Gritas_Core_Opt ${ExpID}.diag_conv_ges.$DateHr &
      
set out_filea   = gra${Day}${Hour}
/bin/rm -f ${out_filea}.{bias,stdv,nobs}.hdf
## THIS ONE NEEDS TO BE OMF, DON'T CHANGE TO OMA
$gritas -omf -o $out_filea $Gritas_Core_Opt ${ExpID}.diag_conv_anl.$DateHr &
wait

# clean the work dir for that day of any pre-existing files for that synoptic time
# move recently created gritas output to holding directory
# n4zip compresses and sets permissions

/bin/rm -f ${DayDir}/*${Hour}z*nc4*pid*.tmp
/bin/rm -f ${DayDir}/*${Hour}z*.nc4 

mv ${out_fileo}.bias.hdf ${DayDir}/$TAG.mean3d_obs_p.${Date}_${Hour}z.nc4
mv ${out_fileo}.stdv.hdf ${DayDir}/$TAG.stdv3d_obs_p.${Date}_${Hour}z.nc4
mv ${out_fileo}.nobs.hdf ${DayDir}/$TAG.nobs3d_obs_p.${Date}_${Hour}z.nc4

mv ${out_filef}.bias.hdf ${DayDir}/$TAG.mean3d_omf_p.${Date}_${Hour}z.nc4
mv ${out_filef}.stdv.hdf ${DayDir}/$TAG.stdv3d_omf_p.${Date}_${Hour}z.nc4
mv ${out_filef}.nobs.hdf ${DayDir}/$TAG.nobs3d_omf_p.${Date}_${Hour}z.nc4

mv ${out_filea}.bias.hdf ${DayDir}/$TAG.mean3d_oma_p.${Date}_${Hour}z.nc4
mv ${out_filea}.stdv.hdf ${DayDir}/$TAG.stdv3d_oma_p.${Date}_${Hour}z.nc4
mv ${out_filea}.nobs.hdf ${DayDir}/$TAG.nobs3d_oma_p.${Date}_${Hour}z.nc4

nohup  $n4zip_file ${DayDir}/$TAG*mean3d*${Date}_${Hour}*.nc4
nohup  $n4zip_file ${DayDir}/$TAG*stdv3d*${Date}_${Hour}*.nc4
nohup  $n4zip_file ${DayDir}/$TAG*nobs3d*${Date}_${Hour}*.nc4

echo $STORAGE_DIR
