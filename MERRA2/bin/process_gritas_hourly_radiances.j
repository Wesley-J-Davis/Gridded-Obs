#!/bin/csh -f

#SBATCH --constraint=mil
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
#set INSTRUMENT_TABLE = 'conv'
set SYNOP_TABLE = $2
set ExpID = $3
set INSTRUMENT_TABLE = $4

set RC_DIR	= /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/etc
set RC_File  =  ${RC_DIR}/rc_files2/gritas_${INSTRUMENT_TABLE}_merra2.rc

set RES      = 'd'
#set Gritas_Core_Opt  = "-nlevs 106 -rc $RC_File -hdf -res $RES -ncf -ospl -lb -nopassive"
set Gritas_Core_Opt  = "-nlevs 50 -rc $RC_File -res d -ncf -ospl -lb -nopassive"

set WorkRootDir  =  /discover/nobackup/projects/gmao/merra2/data/obs/.WORK
set Storage_Base =  $WorkRootDir/work_dir_wjd/${INSTRUMENT_TABLE}/$RES
set Work_Base	 =  $WorkRootDir/raw_obs_wjd/${INSTRUMENT_TABLE}

set n4zip_file   = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin/n4zip.csh

echo " BinDir   $BinDir"
echo " RC_DIR   $RC_DIR"
echo " n4zip_dir $n4zip_file"

set gritas  = ${BinDir}/gritas.x
set grmeans = ${BinDir}/GFIO_mean_r8.x

set DAY_TABLE = ( 31 28 31 30 31 30 31 31 30 31 30 31 ) 

foreach YYYYMM ( `echo $YEAR_TABLE` )

   set YYYY = `echo $YYYYMM | cut -c 1-4`
   set MM   = `echo $YYYYMM | cut -c 5-6`

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
   else
	echo "hello"
   endif 

   set Day0 = 1
#   set Day0 = `ls -r $WorkDir | grep .ods | awk -F. ' END {print $3} ' | awk -F_ '{print $1}' | cut -c7-8`
   set DAY_MAX = $DAY_TABLE[$MM] 

   cd $WorkDir

   while ( $Day0 <= $DAY_MAX )
     set Day = $Day0
     if ( $Day0 < 10 ) then
       set Day = 0$Day0
     endif

     set Date   = ${YYYY}${MM}${Day}
     set DayDir = $STORAGE_DIR/D${Day}
     echo "DayDir $DayDir"
     mkdir -p ${DayDir}
     chmod 755 ${DayDir}

     foreach Hour ( `echo $SYNOP_TABLE` )
      set ods_Files = `ls -1 $OBS_DIR/${INSTRUMENT}/${Date}/*.diag_${INSTRUMENT}.${Date}*_${Hour}z.ods`
      set syn_tag = "_${Hour}z"
      echo $ods_Files

      set out_fileo   = gritaso${Hour}
      /bin/rm -f ${out_fileo}.{bias,stdv,nobs}.nc4
      $gritas -obs -o $out_fileo $Gritas_Core_Opt ${ods_Files} &
      wait

      #    ... for o-f data
      set out_filef   = gritasf${Hour}
      /bin/rm -f ${out_filef}.{bias,stdv,nobs}.nc4
      $gritas -omf -o $out_filef $Gritas_Core_Opt ${ods_Files} &
      wait

      #    ... for o-a data
      set out_filea   = gritasa${Hour}
      /bin/rm -f ${out_filea}.{bias,stdv,nobs}.nc4
      $gritas -oma -o $out_filea $Gritas_Core_Opt ${ods_Files} &
      wait

      #    ... for bias data
      set out_fileb   = gritasb${Hour}
      /bin/rm -f ${out_fileb}.{bias,stdv,nobs}.nc4
      $gritas -obias -o $out_fileb $Gritas_Core_Opt ${ods_Files} &
      wait
      #rm -f ${ods_Files}

      # clean the work dir for that day of any pre-existing files for that synoptic time
      /bin/rm -f ${DayDir}/*${Hour}z*nc4*pid*.tmp
      /bin/rm -f ${DayDir}/*${Hour}z*.nc4 

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.bias.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.nobs.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileo}.stdv.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.bias.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.nobs.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.stdv.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc
   
      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.bias.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.nobs.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filef}.stdv.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.bias.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.nobs.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_filea}.stdv.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.bias.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.nobs.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc

      /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents//lats4d.sh -i ${out_fileb}.stdv.nc4 -o $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag} -zrev
      $RC_DIR/run_ncrcat.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc

      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
      else
          mv -f ${out_fileo}.bias.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
      endif
    
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
      else
          mv -f ${out_fileo}.nobs.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${YYYY}${MM}${syn_tag}.nc4
      endif
     
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_fileo}.stdv.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc4
      endif

      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filef}.bias.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc4
      endif
  
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filef}.nobs.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc4
      endif
 
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filef}.stdv.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc4
      endif

      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filea}.bias.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc4
      endif
  
      if ( -e  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filea}.nobs.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc4
      endif
 
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_filea}.stdv.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc4
      endif

      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_fileb}.bias.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc4
      endif
  
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_fileb}.nobs.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc4
      endif
  
      if ( -e $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc ) then
          mv -f $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc4
      else
          mv -f ${out_fileb}.stdv.nc4 $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc4
      endif

     end #foreach HOUR loop
    @ Day0 = $Day0 + 1
   end #while day < end of month loop
end # for each year_table loop
echo $STORAGE_DIR
