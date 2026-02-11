#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

YYYY=$(echo ${YEAR_TABLE} | cut -c 1-4)
MM=$(echo ${YEAR_TABLE} | cut -c 5-6)
mm=$(printf $((10#$MM )))
DAY_TABLE=(      31    28    31    30    31    30    31    31    30    31    30    31 )
if [ "$MM" -eq "02" ]; then
        num_check=$( /usr/bin/perl /home/dao_ops/bin/tick ${YEAR_TABLE}${DAY_TABLE[$mm-1]} )
        check_num=$(echo $num_check | cut -c 7-8 )
        echo $check_num 
        if [ "$check_num" -eq "29" ]; then
                DAY_TABLE=(      31    29    31    30    31    30    31    31    30    31    30    31 )
        fi      
fi


# Calculate day and synop from array task ID
DAYS_IN_MONTH=${DAY_TABLE[$mm-1]}
SYNOP_COUNT=4

DAY=$(( (($SLURM_ARRAY_TASK_ID - 1) / $SYNOP_COUNT) + 1 ))
SYNOP_INDEX=$(( ($SLURM_ARRAY_TASK_ID - 1) % $SYNOP_COUNT ))
SYNOP_VALUES=(00 06 12 18)
export SYNOP_TABLE=${SYNOP_VALUES[$SYNOP_INDEX]}

export DD=$(printf "%02d" $DAY)
export NYMD=${YEAR_TABLE}${DD}

export IN_DIR=$HOST_DIR/conv/d/Y$YYYY/M$MM/D$DD
export OUT_DIR=$STORAGE_DIR/conv/d/Y$YYYY/M$MM/D$DD
mkdir -p $OUT_DIR

/usr/bin/csh combine_hourly_conv_output.j $NYMD $SYNOP_TABLE > ${JOB_LOG_DIR}/${NYMD}.hourly.${SYNOP_TABLE}.M2hrlycombine 2>&1
#--array=1-${job_array_size}%20
#        │  │               |
#        │  │               └── Limit: Maximum 20 jobs running simultaneously  
#        │  └── End index: Total number of jobs to create
#        └── Start index: First job array index

#Array Index  →  Day  SYNOP
#     1       →   1     00
#     2       →   1     06  
#     3       →   1     12
#     4       →   1     18
#     5       →   2     00
#     6       →   2     06
#    ...      →  ...   ...
#   124       →  31     18
