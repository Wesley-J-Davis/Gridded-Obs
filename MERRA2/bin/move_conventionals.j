#!/usr/bin/csh

#SBATCH --time=0:30:00
#SBATCH --constraint=cas
#SBATCH --account=g2538
#SBATCH --partition=datamove

set echo
set YEAR_TABLE = $1
set SYNOP = $2
set ExpID = $3

set YYYY = `echo $YEAR_TABLE | cut -c 1-4`

set WORK_DIR   = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/raw_obs_wjd
set OBS_DIR     = /discover/nobackup/projects/gmao/merra2/data/obs_dmf/GEOSadas-5_12_4/$ExpID/obs
#set OBS_DIR     = /home/dao_ops/$ExpID/run/.../archive/obs

mkdir -p $WORK_DIR

foreach Date ( `echo $YEAR_TABLE` )
        echo " ------ START TIME ------  " $Date
                    date
        echo " ---------------------------"
        set YYYY = `echo $Date | cut -c 1-4`
        set   MM = `echo $Date | cut -c 5-6`
        foreach INSTRUMENT ( `echo $INSTRUMENT_TABLE` )
                set RES     = "d"
                mkdir -p $WORK_DIR/$INSTRUMENT/$Date
                #cd $WORK_DIR/$INSTRUMENT
                foreach Hour ( $SYNOP  )
                        set ods_Files = `ls -1 $OBS_DIR/Y$YYYY/M$MM/D*/H${Hour}/*${INSTRUMENT}*`                   # d5124_m2_jan10.diag_conv.20180101_00z.ods
                        echo $ods_Files
                        foreach FILE ( $ods_Files )
                                echo $FILE
				#dmget $FILE
				#wait
                                rsync -av $FILE $WORK_DIR/$INSTRUMENT/$Date
                end
        end
end
