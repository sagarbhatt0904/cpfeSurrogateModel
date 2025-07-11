#!/bin/bash=

# Set variables
export DEER=~/packages/deer-gbCav/deer-opt
export ROOTDIR=$(pwd)
export MESH="$ROOTDIR/common/smallAM.e"
export ORI="$ROOTDIR/common/smallAM_Ori.tex"
export INPUT="$ROOTDIR/common/base.i"
export NPROCS=4

i=1
# Generate input files 
python "$ROOTDIR/../inputFileSrc/generateInputFiles.py" 6000

# Define simulation runner function
run_simulation() {
    # rm -r $1
    i=$1
    MODELFILE=$ROOTDIR/$i/$i.xml
    INTPROPS=$ROOTDIR/$i/$i.i
    LOAD=$ROOTDIR/$i/load.i
    OUT=$ROOTDIR/$i/${i}_out
    OUTPUT_LOG="$ROOTDIR/$i/Output.out"

    mpirun -n "$NPROCS" "$DEER" \
        -i "$INPUT" \
        "$INTPROPS" \
        "$LOAD" \
        Mesh/base/file="$MESH" \
        UserObjects/euler_angle_file/prop_file_name="$ORI" \
        Materials/stress/database="$MODELFILE" \
        Outputs/out/file_base="$OUT" > "$OUTPUT_LOG" 2>&1
}

export -f run_simulation

# Find numeric directories, sort them, and run simulations in parallel (max 12 jobs at a time)
find . -maxdepth 1 -type d -regex './[0-9]+' | sed 's|./||' | sort -n | \
    parallel --bar -j 12 run_simulation {} 
