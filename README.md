# HydrolysateIce
A series of bash and awk scripts that serve as wrappers to several python tools for generating molecular dynamics input files for hydrolysate-ice-water interface simulations

#Dependencies
•ColabFold (https://github.com/sokrypton/ColabFold) && (https://github.com/YoshitakaMo/localcolabfold)

•PyPept (https://github.com/Boehringer-Ingelheim/pyPept)

•GenIce2 (https://github.com/vitroid/GenIce)

•GROMACS (https://www.gromacs.org) ;version > 4.5

•GROMACS Force-field Files: CHARMM36m and OPLS-AA/M force-fields; these must be obtained from the respective groups (https://mackerell.umaryland.edu/) & (https://zarbi.chem.yale.edu/)

•(Optional, but higly suggested) •PSSPred (https://zhanggroup.org/PSSpred/); note: Be sure to also download the non-reduntant library for PSSPred from the Zhang Lab webpage.


#Setup/Install

1) Download/clone this repo
2) Generate a conda (or python virtual environment) and install Colabfold (AlphaFold2), PyPept, and GenIce2
3) Download and install PSSPred
4) Install GROMACS
5) Download CHARMM36M and OPLS-AA/M (gromacs formatted) force-field directories and place into cloned repo directory
6) Rename downloaded directories to charmm36m.ff and oplsaam.ff and add (as the first line in the file) charmm36m to the charmm36m.ff/forcefield.doc file and oplsaam to the oplsaam/forcefield.doc file
7) Modify the HYDRC.bash file to activate the conda enviroment that contains ColabFold, Genice2, PyPept, and PSSPred. Ensure that GROMACS is in your path;
9) run "source HYDRC.bash" to put everything in your working path and have your conda environment activate
10) Copy the *.mdp files from this repo into your working directory <--This is needed to make the BuildGromacsInput_gmx/gmxmpi.bash work correctly.
11) Copy the WaterModels directory to your working directory <--This also is needed to make BuildGromacsInput_gmx/gmxmpi.bash script work correctly.
 
   *Note: If your directory contains spaces (running in a windows directory from WSL2, for instance), the GMXLIB path in the HYDRC.bash file should be explicitly written with proper escape characters for GROMACS to
   find the forcefield directories. Be sure to check gmx pdb2gmx (or gmx_mpi) will run with an abriatry test PDB file from the RCSB after sourcing. Be sure to check that the conda enviroment is also activated
   correctly. This can be tested by running:
              run_pyPept -h
              colabfold_batch -h
              genice2 -h

   If you don't have any errors, you should be good to go!
   
#Usage

This repo provides three main scripts to facilitate the generation of input files for hydrolystates at (hexagonal, ih) ice-water interfaces. 

Script 1) TrypsinCutter.awk

Script 2) 3DPredict.bash

Script 3) BuildGromacs_gmx.bash (or BuildGromacs_gmxmpi.bash) 

The expected job flow is: 

TrypsinCutter.awk (your sequence to be digested) > Hydrolystates.csv ;
3DPredict.bash -f Hydrolysates.csv;
for i in `find Hydrolysates_out | grep "*.pdb"`;do BuildGromacsInput_gmx.bash -fPDB $i; done

There are additional options for each of the three scripts that do provide some flexiblity in usage (see below).

==============================================================================================================

Options for TrypsinCutter.awk

The TrypsinCutter.awk script essentially recreates the "simple" trypsin cutting model from the Expasy Peptide Cutter webserver (see: https://web.expasy.org/peptide_cutter/peptidecutter_enzymes.html) as a stand-alone script. One additional option that is added here; however, is that multiple proteins can be processed at a time. Thus there are two usage modes.

Usage 1:
TrypsinCutter.awk (your raw, not FASTA, sequence file here)

Usage 2: 
TrypsinCutter.awk -v multi=1 (your raw, not FASTA sequence file here) 

In usage 1; the output (to StdOut) is the series of hydrolysates for the input sequence (or sequences) without no notation as to what the original sequence was. In usage 2, a special line break (starting with "+++Input" is printed between lists of hydrolysates from different input sequences. 

=====================================================================================================

Options for 3DPredict.bash

The 3DPredict.bash script provides a wrapper to format output from the Trypsin cutter (or a FASTA file or a file where each row is a different raw seqeuence) into the necessary input for ColabFold and/or PyPept. At the moment it is hardcoded that any hydrolysate with a sequence < 35AA in length will have its secondary structure predicted and then an accompanying 3D structure conformer generated by pyPept, and anything longer than 35AA in length will have its structure predicted by Colabfold. Since predictions of protein structures can be slow, the colabfold_batch predictions are used and predictions are made on groups of no more than 10 at a time. Additionally, if users wish to avoid generating large hydrolysates, the option to skip models greater than 35 AA in length is also avaialble.

Usage 1 (standared usage): 
3DPredict.bash -f (my raw sequence file).csv

Usage 2 (no "long" structures)
3DPredict.bash -f (my raw sequence file).csv -nolong

Usage 3 (no "short" structures)
3DPredict.bash -f (my raw sequence file).csv -noshort

Additional Option: PSSPred Secondary Structure Restraints for Short Peptides. 
3DPredict.bash -f (my raw sequence file) -sspred

By default all input sequences are processed and split into one of two files: inputLong.csv or inputShort.csv based on the 35AA test. If predictions do not finish before a wall-time limit, it is possible to restart by trimming the appropriate longInput.csv or shortInput.csv and providing this file in place of the original input sequence file. Note, if the script is to be executated multiple times in the same directory, be sure to remove the inputLong.csv and/or inputShort.csv file or else the script will redo its prior predictions. 

Short sequences are converted to 3D Structures using the PyPept tool; however, this can occasionally give 'knotted' or unrealistic structures. An extra option to inform PyPept's 3D structure generation is to provide a predicted secondary structure for the peptide. This can be done automatically by adding the -sspred option. As a warning, the inclusion of the -sspred command will increase the time necessary to output 3D structures. 

Output from the 3DPredict.bash script is saved to a directory tree with the name "your raw sequence file"_out tied to where the program was executed. For example, if your sequence file was named "MySeq" 3DPredict would generate a subdirectory tree named: "MySeq_out/" and for any short sequence would generate a separate directory for each sequence with the name "MySeq_out/short_(your sequence here)"

As a note, FASTA files may also be provided to this script, but testing has been less robust, so be careful if using FASTA formatted inputs.


=========================================================================================================================

Options for BuildGromacsInput_gmx.bash or (and/or BuildGromacsInput_gmxmpi.bash)

*Note: The BuildGromacsInput_gmx[gmxmpi].bash scripts are effectively the same script, but with the caveat that if GROMACS was compiled with mpi and the gromacs executable is named gmx_mpi, BuildGromacsInput_gmxmpi.bash should be used intead of BuildGromacsInput_gmx.bash

The BuildGromacsInput_gmx.bash script takes as an input the a PDB file of a protein/peptide system (it may contain multiple chains), passes it through the pdb2gmx parser and generates a solute gro and topology pair and then proceeds to solvate the system with tip5p or tip4p-ice water (depending on user input, the default is tip5p), places the solvated protein/peptide at an ice-water interface, neutralizes the system, and then finally generates a combined system topology file, gromacs formatted (gro) geometry file, and an energy minimization ready tpr file for the system. This script comes with a variety of different input options (see below).

Note: Options must be preceeded with -f and come after input pdb, allowed values are listed in '[ ]', 0 == Off, 1==On; example option usage: -fpdb2gmx 0, * indicates default
Options:
pdb2gmxFF [charmm36m*, oplsaa/m]
WaterModel [tip4p_ice, tip5p*]
UseCustomTopology [0*,1]
CustomSoluteToplogyFile [ any gromacs topology file, default=solute.top* ] ---NOTE** only works if pdb2gmx is set to 0; obeys water model choice
LiquidWaterFraction [ any floating point from 0.1 to 0.8, 0.7* ] --NOTE This is merely a target to estimate the number of layers in the ice and will round to an integer
SoluteBoxEdgeDistance [ any floating point, default=1.2* (corresponding to cutoff for charmm), distance in nm]
SaltConc [ any floating point number < 0.5; units in molar, default 0.05*]; --NOTE** We always neutralize the box with NaCl, this is additional NaCl

An experimental option to allow users to bypass pdb2gmx is provided as well (UseCustomTopology) which merely solvates the system, calculates an appropriately sized water slab, and modifies the provided custom topology file for the water-ice-solute system is also provided; however, this is not well supported at this time and may be prone to failures. 

Additionally, while the current version of the script is tied to charmm36m or oplsaa/m, users can use any force-field compatable with pdb2gmx by merely renaming the input directory to a single word and providing the name to the -fpdb2gmxFF parameter.

*Note: Output names are based on input PDB names. Intermediate files are also provided for those interested in debugging/adjusting input files in the future.
