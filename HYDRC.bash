#!/bin/bash
#Setup PATH and Environment for Hydrolysate Building
SCRIPT_PATH=$(readlink -f $(dirname $BASH_SOURCE))
#module load anaconda3/2024.06  gromacs/2021.5-gcc  cuda/12.1.1-binary  cudnn/8.9.4-binary
#conda activate $SCRIPT_PATH/PythonDepends
export PATH=$PATH:$SCRIPT_PATH
