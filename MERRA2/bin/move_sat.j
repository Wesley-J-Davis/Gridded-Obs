#!/usr/bin/csh

#SBATCH --time=0:40:00
#SBATCH --constraint=cas
#SBATCH --account=g2538
#SBATCH --partition=datamove

set echo
set YYYY = `echo $YEAR_TABLE | cut -c 1-4`


set WORK_DIR   = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/raw_obs_wjd
set OBS_DIR     = /home/dao_ops/$ExpID/run/.../archive/obs
#set OBS_DIR     = /discover/nobackup/projects/gmao/merra2/data/obs_dmf/GEOSadas-5_12_4/$ExpID/obs/
set STORAGE_DIR = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/products_wjd

#set INSTRUMENT_TABLE = "airs_aqua"
#set INSTRUMENT_TABLE = `cat  $RC_DIR/instrument.list`
#set YEAR_TABLE = ( 201802 )

foreach Date ( `echo $YEAR_TABLE` )
        echo " ------ START TIME ------  " $Date
                    date
        echo " ---------------------------"
        set DateE = $Date
        set YYYY = `echo $Date | cut -c 1-4`
        set   MM = `echo $Date | cut -c 5-6`
        set kount = 0
        foreach INSTRUMENT ( `echo $INSTRUMENT_TABLE` )
                set INFILE     = diag_${INSTRUMENT}
                set RES     = "d"
                mkdir -p $WORK_DIR/$INSTRUMENT/$Date
                foreach Hour ( `echo $SYNOP_TABLE`  )

#                foreach Hour ( 00 06 12 18  )
                        #echo $YYYY
                        #echo $MM
                        #echo $OBS_DIR/Y$YYYY/M$MM
                        #ls -1 $OBS_DIR/Y$YYYY/M$MM/*ods
                        if ( $Hour == all ) then
                                ls -1 $OBS_DIR/Y$YYYY/M$MM/*ods
                                set ods_Files = `ls -1 $OBS_DIR/Y$YYYY/M$MM/*ods`
                                #${INSTRUMENT}*ods`
                                set syn_tag = ""
                        else
				ls $OBS_DIR
                                ls $OBS_DIR/Y$YYYY
                                ls $OBS_DIR/Y$YYYY/M$MM
                                ls $OBS_DIR/Y${YYYY}/M${MM}/D*
                                ls $OBS_DIR/Y${YYYY}/M${MM}/D*/H${Hour}
                                ls $OBS_DIR/Y${YYYY}/M${MM}/D*/H${Hour}/*${INSTRUMENT}*

                                ls -1 $OBS_DIR/Y${YYYY}/M${MM}/D*/H${Hour}/*${INSTRUMENT}*${Hour}z*ods
                                set ods_Files = `ls -1 $OBS_DIR/Y$YYYY/M$MM/D*/H${Hour}/*${INSTRUMENT}*${Hour}z*ods`
                                # d5124_m2_jan10.diag_airs_aqua.20180101_00z.ods
                                set syn_tag = "_${Hour}z"
                        endif
                        echo $ods_Files
                        foreach FILE ( $ods_Files )
                                echo $FILE
				dmget $FILE 
				wait
                                rsync -av $FILE $WORK_DIR/$INSTRUMENT/$Date
                end
        end
end
