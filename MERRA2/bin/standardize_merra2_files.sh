#!/usr/bin/bash

# Function to standardize a single MERRA-2 NetCDF file
standardize_merra2_file() {
    local input_file="$1"
    local temp_file="${input_file}.tmp"
    local temp_file2="${input_file}.tmp2"
    local backup_file="${input_file}.bak"
    
    echo "Processing: $input_file"
    
    # Create backup of original file
    cp "$input_file" "$backup_file"
    
    # Step 1: First, remove all missing_value attributes
    cp "$input_file" "$temp_file"
    
    # Get list of all variables that have missing_value attribute
    variables_with_missing=$(ncdump -h "$temp_file" | grep "missing_value" | sed 's/.*\t\([^:]*\):missing_value.*/\1/' | sort -u)
    
    for var in $variables_with_missing; do
        echo "  Removing missing_value attribute from $var"
        ncatted --hst -O -a missing_value,$var,d,, "$temp_file"

    done
    
    # Step 2: Reorder variables by extracting them in the desired order
    echo "  Reordering variables..."
    
    # Extract coordinate variables first
    ncks --hst -O -v time,levels,longitude,latitude "$temp_file" "$temp_file2"
    
    # Add main data variables
    ncks --hst -A -v mean_bias,mean_obs,mean_oma,mean_omf "$temp_file" "$temp_file2"
    
    # Add remaining data variables
    ncks --hst -A -v nobs_obs,stdv_bias,stdv_obs,stdv_oma,stdv_omf "$temp_file" "$temp_file2"
    
    # Add channel variables last
    ncks --hst -A -v wavelength,frequency "$temp_file" "$temp_file2"

    # Remove reference to NCO if it exists
    ncatted --hst -O -a NCO,global,d,, "$temp_file"

    # Remove history if it exists
    ncatted --hst -O -a history,global,d,, "$temp_file"
    
    # Step 3: Replace original file with standardized version
    mv "$temp_file2" "$input_file"
    
    # Clean up temporary files
    rm -f "$temp_file"
    
    # Remove backup (comment out if you want to keep backups)
    #rm "$backup_file"
    
    echo "  Completed: $input_file"
}

# Main script
echo "MERRA-2 File Standardization Script"
echo "==================================="

# Process files based on command line arguments
if [ $# -eq 0 ]; then
    # No arguments - process all .nc4 files in current directory
    echo "No files specified. Processing all .nc4 files in current directory..."
    for file in *.nc4; do
        if [ -f "$file" ]; then
            standardize_merra2_file "$file"
        fi
    done
else
    # Process specified files
    for file in "$@"; do
        if [ -f "$file" ]; then
            standardize_merra2_file "$file"
        else
            echo "Warning: File not found: $file"
        fi
    done
fi

echo "Standardization complete!"
