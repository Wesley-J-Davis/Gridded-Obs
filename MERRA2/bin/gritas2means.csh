#!/bin/csh -f

# Set modules
# -----------
set echo
echo "begin gritas2means.csh"
#setenv OMPI_MCA_btl_vader_single_copy_mechanism=none
#export OMPI_MCA_btl=^openib     # Disable InfiniBand if not available

# Set Dirs and Scripts

set RootDir = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2
#set BinDir  = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
set BinDir = $BIN_DIR
#source $BinDir/g5_modules

set RC_DIR=${RootDir}/etc/rc_files2
echo "gritas2means: $RootDir" 
echo "gritas2means: $BinDir" 
set n4zip = ${RootDir}/bin/n4zip.csh
echo "gritas2means: $n4zip" 
set grmeans = ${BinDir}/GFIO_mean_r8.x

# Set defaults for options
# ------------------------
set TRUE = 1; set FALSE = 0 
set Result  = means
 
# Set options defined by user, if any
# -----------------------------------
set ReqArgv = ()
  while ( $#argv > 0 )
    switch ( $argv[1] )
       case -r:
          set Result =  $argv[2]; shift
	  echo $Result
          breaksw
#       case -o:
#          set OutBaseName = $argv[2]
#          shift
#          breaksw
       
       default:
          set FirstChar = `echo $argv[1] | awk '{ print substr ($1,1,1)}'`
          if ( FirstChar == "-" ) then
                             # Any other option produces an error
             echo "Illegal option "$argv[1]
             goto err

          else               # ... or is a required argument
             set ReqArgv = ($ReqArgv $argv[1])
          endif

    endsw
    shift
  end

# Get required parameters
# -----------------------
#  if ( $#ReqArgv < 2 ) goto err
if ( $#ReqArgv < 1 ) goto err

#  set ExpID  = $ReqArgv[1]; shift ReqArgv
#  set ExpID  = d5124_m2_jan10
  set ExpID  = merra2
  set Date   = $ReqArgv[1]; shift ReqArgv

  set Year   = `echo $Date | awk '{print substr($1,1,4)}'`
  set Month  = `echo $Date | awk '{print substr($1,5,2)}'`

# Check directories
# -----------------
  set Dir     = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/work_dir_wjd/conv/d
  echo "set Dir"
  ls $Dir
  echo "gritas2means.csh: $Dir "

  if ( ! -e $Dir/Y$Year/M$Month ) then
       echo " The directory, $Dir, does not exist."
       goto err
  endif
  if ( ! -r $Dir/Y$Year/M$Month ) then
     echo " The directory, $Dir, is not set with read permission."
     goto err
  endif
  if ( ! -w $Dir/Y$Year/M$Month ) then
     echo " The directory, $Dir, is not set with write permission."
     goto err
  endif

  cd $Dir/Y$Year/M$Month
  pwd
  echo $Result

# Implement result option
# -----------------------
  if      ( $Result == "means" ) then
     set Options       = ""
     set InFile_Result = "mean"
  else if ( $Result == "rms"   ) then
     set Options       = "-rms"
     set InFile_Result = "stdv"
  else if ( $Result == "obrate"  ) then
     set Options       = ""
     set InFile_Result = "nobs"
  else
     echo "Invalid assignment for the variable Result (=$Result)"
     goto err
  endif

  set Quants   = ( obs omf oma )
  set SynTimes = ( 00 06 12 18 )
#  set SynTimes = ( `echo $SYNOP_TABLE` )
  set OutFiles = ""
  foreach Quant ( $Quants )
     set OutFile  = $ExpID.mon_${Result}_${Quant}.${Year}${Month}.nc4; /bin/rm -f $OutFile
     echo $OutFile
     set InFiles  = `ls ./D*/$ExpID.${InFile_Result}3d_${Quant}_p.${Year}${Month}*_*z.nc4`
     echo $InFiles
     set OutFiles = ( $OutFiles $OutFile )
	echo "Starting MPI statistical calculations at `date`"
	#echo "Number of MPI processes: $SLURM_NTASKS"
	#echo "Processes per node: $SLURM_NTASKS_PER_NODE"
	#echo "Available memory: `free -h`"
        # Run MPI Fortran program
        #mpirun -np $SLURM_NTASKS
	$grmeans $Options -inc 060000 $InFiles -o $OutFile; set Status = $status

     if ( $Status ) then
        echo "Error status (= ${Status}) returned from $grmeans"
#      /bin/rm -f $OutFiles
        goto err
     endif

     foreach SynTime ( $SynTimes )
        set OutFile  = $ExpID.mon_${Result}_${Quant}.${Year}${Month}_${SynTime}z.nc4; /bin/rm -f $OutFile
        set InFiles  = `ls ./D*/$ExpID.${InFile_Result}3d_${Quant}_p.${Year}${Month}*_${SynTime}z.nc4`
        set OutFiles = ( $OutFiles $OutFile )
        #echo "Starting MPI statistical calculations at `date`"
        #echo "Number of MPI processes: $SLURM_NTASKS"
        #echo "Processes per node: $SLURM_NTASKS_PER_NODE"
        #echo "Available memory: `free -h`"

        # Run MPI Fortran program
        # mpirun -np $SLURM_NTASKS 
	$grmeans $Options  -inc 060000 $InFiles -o $OutFile; set Status = $status
	#echo "Peak memory usage: $(sacct -j $SLURM_JOB_ID --format=MaxRSS --noheader --units=M)"

        if ( $Status ) then
           echo "Error status (= ${Status}) returned from $grmeans"
#         /bin/rm -f $OutFiles
           goto err
        endif
     end
  end

  $n4zip $OutFiles
  if ( $Status ) then
     echo "Error status (= ${Status}) returned from ${n4zip}"
#   /bin/rm -f $OutFiles
     goto err
  endif

# All is well
# ----------- 
  exit 0

