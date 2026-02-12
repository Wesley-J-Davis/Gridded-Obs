#!/bin/csh

   if ( $#argv < 1 ) then
    clear
    echo "USAGE: run_ncrcat.csh file_name"
    exit
   endif

   set FILE = $1
#   set NCR_DIR = /usr/local/other/SLES11.1/nco/4.2.3/intel-12.1.0.233/bin
#   set NCR_DIR = /usr/local/other/nco/5.1.7/bin
#   $NCR_DIR/
ncatted -O -h -a units,levels,m,c,"level" $FILE 
#   $NCR_DIR/
ncatted -O -h -a description,levels,m,c,"satellite channel" $FILE
#   $NCR_DIR/
ncatted -O -h -a type,levels,m,c,"channels" $FILE
#   $NCR_DIR/
ncatted -O -h -a long_name,levels,m,c,"satellite channel" $FILE
#   $NCR_DIR/
ncatted -O -h -a positive,levels,m,c,"up" $FILE

#att_dsc = att_nm, var_nm, mode, att_type, att_val
#att_nm
#Attribute name. Example: units
#var_nm
#Variable name. Example: pressure
#mode
#Edit mode abbreviation. Example: a. See below for complete listing of valid values of mode.
#att_type
#Attribute type abbreviation. Example: c. See below for complete listing of valid values of att_type.
#att_val
#Attribute value. Example: pascal. There should be no empty space between these five consecutive arguments. The description of these arguments follows in their order of appearance.
