#!/usr/bin/csh

#SBATCH --constraint=cas
#SBATCH --account=g2538
#SBATCH --partition=preops

set echo

# Set MPI environment variables
setenv OMPI_MCA_btl_vader_single_copy_mechanism none
setenv OMPI_MCA_btl ^openib     # Disable InfiniBand if not available

setenv TAG  merra2
set BinDir  = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
set gritas  = ${BinDir}/gritas.x
source $BinDir/g5_modules

#source /gpfsm/dhome/dao_ops/d5124_m2_jan10/run/FVDAS_Run_Config
module load nco
set echo
set DAY_TABLE   = ( 31 28 31 30 31 30 31 31 30 31 30 31 )
set OBS_DIR     = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/raw_obs_wjd
set STORAGE_DIR = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/work_dir_wjd
set RC_DIR      = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/src/Components/gritas/GIO
set RC_TABLE         = `echo $INSTRUMENT_TABLE`

mkdir -p $OBS_DIR
mkdir -p $STORAGE_DIR
echo $OBS_DIR $STORAGE_DIR

echo $YEAR_TABLE

foreach Date ( `echo $YEAR_TABLE` )
	set MM = `echo $Date | cut -c 5-6`
	if ( $MM == "02" ) then
	        set num_check=`/usr/bin/perl /home/dao_ops/bin/tick $Date$DAY_TABLE[$MM]`
	        set check_num=`echo $num_check | cut -c 7-8`
	        echo $check_num
	        if ( $check_num == "29" ) then
	               set DAY_TABLE=(      31    29    31    30    31    30    31    31    30    31    30    31 )
	        endif
		echo "leap year"
	else
	        echo "not leap year"
	endif

        echo " ------ START TIME ------  " $Date
                          date
        echo " ---------------------------"
        # set Date = 201002
        set DateE = $Date
        set YYYY = `echo $Date | cut -c 1-4`
        set   MM = `echo $Date | cut -c 5-6`
        set DD = 1
        set DAY_MAX = $DAY_TABLE[$MM]
        foreach INSTRUMENT ( `echo $INSTRUMENT_TABLE` )
                set INFILE     = diag_${INSTRUMENT}
                set RC_FILE    = "gritas_${INSTRUMENT}_merra2.rc"
                echo $RC_FILE
                set RC_File = $RC_DIR/rc_files2/$RC_FILE
		echo $RC_File
                set RES     = "d"
                if ( $INSTRUMENT == "o3lev_aura" ) then
                        set Gritas_Core_Opt  = "-nlevs 48 -rc $RC_File -res $RES -ncf -ospl -lb -nopassive"
                else
                        set Gritas_Core_Opt  = "-rc $RC_File -res $RES -ospl -lb -nopassive"
                        #      PASSIVE TEST
                        #  set Gritas_Core_Opt  = "-rc $RC_File -res $RES -ospl -lb "
                endif
                cd $OBS_DIR/$INSTRUMENT/$Date

                # all 00 06 12 18
                foreach Hour ( `echo $SYNOP_TABLE` )
                        echo $YYYY
                        echo $MM
                        if ( $Hour == all ) then
                                #set ods_Files = `ls -1 $OBS_DIR/${INSTRUMENT}/${Date}/${ExpID}.aod.obs.${Date}*ods`
                                set ods_Files = `ls -1 $OBS_DIR/${INSTRUMENT}/${Date}/*.diag_${INSTRUMENT}.${Date}*.ods`
                                set syn_tag = ""
                        else
                                set ods_Files = `ls -1 $OBS_DIR/${INSTRUMENT}/${Date}/*.diag_${INSTRUMENT}.${Date}*_${Hour}z.ods`
                                # d5124_m2_jan10.diag_airs_aqua.20180101_00z.ods
                                set syn_tag = "_${Hour}z"
                        endif


                        echo $ods_Files
                        set out_fileo   = gritaso${Hour}
                        /bin/rm -f ${out_fileo}.{bias,stdv,nobs}.nc4
			
			# Print MPI and resource information
			echo "Starting MPI statistical calculations at `date`"
			echo "Number of MPI processes: $SLURM_NTASKS"
			echo "Processes per node: $SLURM_NTASKS_PER_NODE"
			echo "Available memory: `free -h`"
                        #mpirun -np $SLURM_NTASKS 
			$gritas -obs -o $out_fileo $Gritas_Core_Opt ${ods_Files}

                        #    ... for o-f data
                        set out_filef   = gritasf${Hour}
                        /bin/rm -f ${out_filef}.{bias,stdv,nobs}.nc4
                        echo "Starting MPI statistical calculations at `date`"
                        echo "Number of MPI processes: $SLURM_NTASKS"
                        echo "Processes per node: $SLURM_NTASKS_PER_NODE"
                        echo "Available memory: `free -h`"
                        #mpirun -np $SLURM_NTASKS 
			$gritas -omf -o $out_filef $Gritas_Core_Opt ${ods_Files} &

                        #    ... for o-a data
                        set out_filea   = gritasa${Hour}
                        /bin/rm -f ${out_filea}.{bias,stdv,nobs}.nc4
                        echo "Starting MPI statistical calculations at `date`"
                        echo "Number of MPI processes: $SLURM_NTASKS"
                        echo "Processes per node: $SLURM_NTASKS_PER_NODE"
                        echo "Available memory: `free -h`"
                        #mpirun -np $SLURM_NTASKS 
			$gritas -oma -o $out_filea $Gritas_Core_Opt ${ods_Files} &

                        #    ... for bias data
                        set out_fileb   = gritasb${Hour}
                        /bin/rm -f ${out_fileb}.{bias,stdv,nobs}.nc4
                        echo "Starting MPI statistical calculations at `date`"
                        echo "Number of MPI processes: $SLURM_NTASKS"
                        echo "Processes per node: $SLURM_NTASKS_PER_NODE"
                        echo "Available memory: `free -h`"
                        #mpirun -np $SLURM_NTASKS 
			$gritas -obias -o $out_fileb $Gritas_Core_Opt ${ods_Files} &

                        wait
                        #rm -f ${ods_Files}

                        mkdir -p $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM
                        if ($INSTRUMENT == "sbuv2_nim07" || $INSTRUMENT == "sbuv2_n07" || $INSTRUMENT == "sbuv2_n11" || $INSTRUMENT == "sbuv2_n14" || $INSTRUMENT == "sbuv2_n16" || $INSTRUMENT == "sbuv2_n17"  ) then
                                mv -f ${out_fileo}.bias.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_obs_p.${Date}${syn_tag}.nc4
                                mv -f ${out_fileo}.nobs.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_obs_p.${Date}${syn_tag}.nc4
                                mv -f ${out_fileo}.stdv.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_obs_p.${Date}${syn_tag}.nc4

                                mv -f ${out_filef}.bias.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_omf_p.${Date}${syn_tag}.nc4
                                mv -f ${out_filef}.nobs.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_omf_p.${Date}${syn_tag}.nc4
                                mv -f ${out_filef}.stdv.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_omf_p.${Date}${syn_tag}.nc4

                                mv -f ${out_filea}.bias.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_oma_p.${Date}${syn_tag}.nc4
                                mv -f ${out_filea}.nobs.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_oma_p.${Date}${syn_tag}.nc4
                                mv -f ${out_filea}.stdv.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_oma_p.${Date}${syn_tag}.nc4

                                mv -f ${out_fileb}.bias.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.mean3d_bias_p.${Date}${syn_tag}.nc4
                                mv -f ${out_fileb}.nobs.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.nobs3d_bias_p.${Date}${syn_tag}.nc4
                                mv -f ${out_fileb}.stdv.nc4  $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.stdv3d_bias_p.${Date}${syn_tag}.nc4
                        else
                                
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
                        endif
                        foreach Metric ( nobs mean stdv  )
                                foreach Measure ( obs omf oma bias  )
                                        ncdump -h $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 | grep levels: | awk -F: ' { print $NF } ' | awk -F= ' { print $NF } ' | cut -d';' -f 1 > $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt
                                        sed -i 's/"//g' $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt
                                        cat $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt
                                        foreach line ( `awk '{print}' $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt` )
                                                set LINE = `echo $line`
                                                echo $LINE
                                                if ( $LINE =~ "level" ) then
                                                        echo "run_ncrcat succeeded for $line in $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 "
                                                else if ( $LINE =~ "satellite" || $LINE =~ "channel" ) then
                                                        echo "run_ncrcat succeeded for $LINE in $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 "
                                                else if ( $LINE =~ "channels" ) then
                                                        echo "run_ncrcat succeeded for $LINE in $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 "
                                                else if ( $LINE =~ "up" ) then
                                                        echo "run_ncrcat succeeded for $LINE in $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 "
                                                else
                                                        echo "run_ncrcat failed to edit metadata properly for $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4 "
                                                        cat $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt
							exit
                                                endif
                                                unset LINE

                                        end

                                        /bin/rm -f $TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.attrcheck.txt
                                        $RC_DIR/run_n4zip.csh $STORAGE_DIR/$INSTRUMENT/$RES/Y$YYYY/M$MM/$TAG.${INSTRUMENT}.${Metric}3d_${Measure}_p.${Date}${syn_tag}.nc4
                                end
                        end
                end
                cd -
        end
echo " ------ END  TIME ------  "
                    date
echo " ---------------------------"
end
