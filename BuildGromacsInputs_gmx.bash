#!/bin/bash
if [ $# -eq 0 ] || [ $1 == "-h" ]; then 
	echo "Program: Ice-Water Solvate"	
	echo "This script uses built-in GROMACS tools and the genice2 python package (https://github.com/vitroid/GenIce) to place a solute peptide, protein, or small molecule in a box of water between ice-interfaces"
	echo "Usage: ./BuildGromacsIceWater.bash (pdbfile here) Options"
	echo "Note: Options must be preceeded with -f and come after input pdb, allowed values are listed in '[ ]', 0 == Off, 1==On; example option usage: -fpdb2gmx 0, * indicates default"
	echo "Options:"
	echo "pdb2gmx [0,1*];" 
	echo "pdb2gmxFF [charmm36m*, oplsaa/m]"
	echo "WaterModel [tip4p_ice, tip5p*]"
	echo "UseCustomTopology [0*,1]"
	echo "CustomSoluteToplogyFile [ any gromacs topology file, default=solute.top* ] ---NOTE** only works if pdb2gmx is set to 0; obeys water model choice";
	echo "LiquidWaterFraction [ any floating point from 0.1 to 0.8, 0.7* ] --NOTE This is merely a target to estimate the number of layers in the ice and will round to an integer"
	echo "SoluteBoxEdgeDistance [ any floating point, default=1.2* (corresponding to cutoff for charmm), distance in nm] "
	echo "SaltConc [ any floating point number < 0.5; units in molar, default 0.05*]; --NOTE** We always neutralize the box with NaCl, this is additional NaCl"
	exit
fi
#Confirm Gromacs is in your $PATH and is executable
if [ ! -x "$(command -v gmx_mpi)" ] && [ ! -x $(command -v gmx) ]; 
	then echo "Missing Gromacs; are you sure you sourced HYDRC.bash?"; exit
fi
if [ -x "$(command -v gmx_mpi)" ]; 
	then echo "MPI version of Gromacs found, use BuildScript_gmxmpi.sh instead";
		exit;
	fi
	
#	else if [ -x "$(command -v gmx)"];then
#	alias gmx1='gmx'
#	fi
#fi
#Set default
#tmp="$1";
#Check that support scripts are in PATH and setup for use
if [ -x $(command -v DefineXYRepeatsForIce.awk)) ]; then 
	  HYD=$(dirname $(which DefineXYRepeatsForIce.awk));
	else 
	  echo "Support Scripts missing? Did you remember to source HYDRC.bash?"
	  exit
fi
	
pdbName=$(echo "$tmp" | sed -e 's|.*/||' -e 's/\.pdb//g');
pdb2gmx=1;
pdb2gmxFF="charmm36m";
WaterModel="tip5p";
LiquidWaterFraction=0.7;
SoluteBoxEdgeDistance=1.2;
SaltConc=0.05;
mdrunFlag=0;
UseCustomTopology=0;
internalPDBtest=0;
#Check ARGV for input terms and reset if needed
ARGVSize=${#@};
limit=$(($ARGVSize+1));
for((i=1;i<$limit;i++));do 
	argvalue=${!i};
	if [ $argvalue == "-fPDB" ]; then
		i=$(($i+1));
		tmp=${!i};
		if [ -f "$tmp" ]; then		
		pdbName=$(echo "$tmp" | sed -e 's|.*/||' -e 's/\.pdb//g');
		else
		    echo "Missing Input PDB"
	    	    exit
		fi		
	fi

	if [ $argvalue == "-fpdb2gmx" ];then
		i=$(($i+1));
		pdb2gmx=${!i};
	fi
	
	if [ $argvalue == "-fpdb2gmxFF" ];then
		i=$(($i+1));
		pdb2gmxFF=${!i};
	fi

	if [ $argvalue == "-fWaterModel" ];then
		i=$(($i+1));
		WaterModel=${!i};
	fi
	
	if [ $argvalue == "-fUseCustomTopology" ] && [ $pdb2gmx -eq 0 ]; then
		i=$(($i+1));
		UseCustomTopology=${!i};
	fi

	if [ $argvalue == "-fCustomSoluteTopologyFile" ] && [ $pdb2gmx -eq 0 ]; then
		i=$(($i+1));
		CustomTopology=${!i};
	fi

	if [ $argvalue == "-fSoluteBoxEdgeDistance" ]; then
		i=$(($i+1));
		SoluteBoxEdgeDistance=${!i};
	fi

	if [ $argvalue == "-fLiquidWaterFraction" ]; then
		i=$(($i+1));
		LiquidWaterFraction=${!i};
	fi

	if [ $argvalue == "-fSaltConcentration" ]; then
		i=$(($i+1));
		SaltConc=${!i};
	fi

#	if [ $argvalue == "-fmdrunFlag" ]; then
#		i=$(($i+1));
#		SaltConc=${!i};
#	fi

done
echo "Start Checks"
#Check for Bad/Inconsistent Inputs
LiquidWaterPercentTest=$(awk -v i=$LiquidWaterFraction 'BEGIN{if(i>0.8||i<0.1){print int(1)}else{print int(0)}}')
SaltConcTest=$(awk -v i=$SaltConc 'BEGIN{if(i>0.5){print int(1)}else{print int(0)}}')

	if [ -n "$CustomTopology" ] && [ ! $UseCustomTopology -eq 0 ] ; then
	       echo "Error: Invalid Combination of input Flags: custom topology provided but UseCustomToplogy not set";
	       exit
	fi

	if [ ! -n "$CustomTopology" ] && [ $UseCustomTopology -eq 1 ] ; then
	       echo "Error: Invalid Combination of input Flags: UseCustomToplogy set but no CustomToplogy Given";
	       exit
	fi

	if  [ "$LiquidWaterPercentTest" -eq 1 ]; then
	       echo "Error: Liquid Water Fraction either exceeds 0.8 or is less than 0.1";
	       exit
	fi

	if [ "$SaltConcTest" -eq 1 ] ; then
		echo "Error: Salt Concentration exceeds 0.5M";
		exit
	fi

	if [ "$pdbName" == "" ];then
		echo "No PDB given"
		exit
	fi
#Start the building process
echo "Running with these settings:"
	if [[ $UseCustomTopoloy -eq 0 ]]; then  
		echo "input PDB" $tmp " pdb2gmxFF " $pdb2gmxFF " WaterModel " $WaterModel " SoluteBoxEdgeDistance " $SoluteBoxEdgeDistance " LiquidWaterFraction " $LiquidWaterFraction; 
	else 
		echo "input PDB" $tmp " WaterModel " $WaterModel " SoluteBoxEdgeDistance " $SoluteBoxEdgeDistance " LiquidWaterFraction " $LiquidWaterFraction; 
		cp $CustomTopogy system_"$CustomTopology";
		cp $tmp solute_"$pdbName".gro
	fi

	if [ $pdb2gmx -eq 1 ] || [ ! -n "$CustomTopology" ]; then
		echo $PWD;
		#GROMACS CHARMM36 has a known bug if the first residue is MET; This checks for this and performs a work around 
		Metcheck=$(awk '{if($0~/ATOM/){if($4=="MET"){print "1";exit}else{print 0;exit}}}' $tmp) ;
		if [ $pdb2gmxFF == "charmm36m"  ] && [ "$Metcheck" -eq 1 ]; then
			echo -e "1 \r 0 \r" | gmx pdb2gmx -f "$tmp" -ff "$pdb2gmxFF" -water "$WaterModel" -ignh -o solute_"$pdbName".gro -p system_"$pdbName".top -i posre_"$pdbName".itp -ter;
		else 
			gmx pdb2gmx -f "$tmp" -ff "$pdb2gmxFF" -water "$WaterModel" -ignh -o solute_"$pdbName".gro -p system_"$pdbName".top -i posre_"$pdbName".itp;
		fi
	fi
		gmx editconf -f solute_"$pdbName".gro -d "$SoluteBoxEdgeDistance" -o BoxedTmp_"$pdbName".gro;
#Get BoxDims 
	BoxDims=$(tail -n 1 BoxedTmp_"$pdbName".gro);
	echo "Box " $BoxDims;
#Calculate Amount of Water in a single layer
	Layer=$(echo $BoxDims | DefineXYRepeatsForIce.awk);
	echo "Layer " $Layer;
	WaterInSingleLayer=$(genice2 --rep $Layer 1 1h --format xyz 2>/dev/null | awk '{if($1=="O"){count++}}END{print count}');
	echo "WaterInSingleLayer" $WaterInSingleLayer;
#Generate Liquid Water Region
	gmx solvate -cp BoxedTmp_"$pdbName".gro -cs WaterModels/"$WaterModel".gro -o solvated_"$pdbName".gro -p system_"$pdbName".top 2>solvateLog; #1>/dev/null  
	gmx grompp -f BuildOnly.mdp -p system_"$pdbName".top -c solvated_"$pdbName".gro -o LiquidSystem_"$pdbName".tpr ;
	gmx select -s LiquidSystem_"$pdbName".tpr -f solvated_"$pdbName".gro -select "resname SOL" -on StartLiquidWater_"$pdbName".ndx;
	sed -i 's/resname_SOL/SOL/' StartLiquidWater_"$pdbName".ndx 
#Remove extra files (part 1)
	rm BoxedTmp_"$pdbName".gro solute_"$pdbName".gro;
	LiquidWaterNumber=$(grep "Number of solvent" solvatelog | awk '{print $5}');
	echo "LiquidWater" $LiquidWaterNumber;
#Estimate Number of Ice Layers to generate initial staring ratio of ice to water; NOTE** This will not be exact!!!
	ZLayerCount=$(awk -v SingleLayer=$WaterInSingleLayer -v LiquidWaterCount=$LiquidWaterNumber -v PercentLiquid=$LiquidWaterFraction 'BEGIN{check=int( (LiquidWaterCount*(1-PercentLiquid))/(SingleLayer));if(check!=0){print check}else{print 1}}');
	echo "ZLayer" $ZLayerCount;
#rm solvateLog;
#Use GenIce and generate the Ice Phase of the box
	genice2 --rep $Layer $ZLayerCount 1h --water $WaterModel >BoxedIce_"$pdbName".gro;
#Translate ice to one side of the box, add a small buffer 
	gmx editconf -f BoxedIce_"$pdbName".gro -translate 0 0 $(echo $BoxDims | awk '{print $3*1.025}') -o mergeReady_"$pdbName".gro;
#get number of atoms in both boxes and get ready to merge
	TotalAtoms=$(awk 'FNR==2{a+=$0;nextfile}END{print a}' BoxedIce_"$pdbName".gro solvated_"$pdbName".gro);
#get Correct ZDim For merge
	ZDims=$(awk '{if(NF==3){a+=$3}}END{print a}' mergeReady_"$pdbName.gro" solvated_"$pdbName".gro)
	XYDims=$(tail -n1 mergeReady_"$pdbName".gro | awk '{print $1, $2}');
	sed '$d' solvated_"$pdbName".gro > tmp_"$pdbName" ;
	sed '1,2d' mergeReady_"$pdbName".gro > tmp2_"$pdbName" ;
	sed -i '$d' tmp2_"$pdbName" ;
	awk -v Atoms=$TotalAtoms -v z=$ZDims -v x="$XYDims" 'NR==2{print "Merged";print Atoms}NR>2{print $0}END{print x, z}'  tmp_"$pdbName" tmp2_"$pdbName" > mergedSystem_"$pdbName".gro
	NewSOL=$(grep SOL mergedSystem_"$pdbName".gro | awk '{if($0~/OW/){count++}}END{print count}');
	sed -i "/^SOL/s/.*/SOL $NewSOL/" system_"$pdbName".top 
#Now to neutralize the system by replacing liquid waters only
#NOTE MW1 and LP1 and MW2 and LP2 are equivilent so we are ignoring warnings, but strictly we should be renaming first and then running
	gmx grompp -f BuildOnly.mdp -p system_"$pdbName".top -c mergedSystem_"$pdbName".gro -o addIons_"$pdbName".tpr -maxwarn 2
	if [ $pdb2gmxFF=="charmm36m" ]; then 
	gmx_mpi genion -s addIons_"$pdbName".tpr -p system_"$pdbName".top -n StartLiquidWater_"$pdbName".ndx -neutral --conc $SaltConc -pname SOD -nname CLA -o CompleteNeutralized_"$pdbName".gro;
	else 
	gmx genion -s addIons_"$pdbName".tpr -p system_"$pdbName".top -n StartLiquidWater_"$pdbName".ndx -neutral -conc $SaltConc -pname NA -nname CL -o CompleteNeutralized_"$pdbName".gro;
	fi
#When adding salts, because we add only to liquid water region, we need to sort the GRO file and move the ions to the end to match the topology
	awk 'NR<3{print $0}NR>2{if($0!~/NA/&&$0!~/CLA/&&$0!~/CL/&&$0!~/SOD/&&NF!=3){print $0}else{a[count++]=$0}}END{for(i=0;i<count;i++){print a[i]}}' CompleteNeutralized_"$pdbName".gro > sorted_"$pdbName".gro;
	mv sorted_"$pdbName".gro CompleteNeutralized_"$pdbName".gro;
#Finally generate energy minimization tpr file	
gmx grompp -f EM_min.mdp -p system_"$pdbName".top -c CompleteNeutralized_"$pdbName".gro -o em_"$pdbName".tpr
#Clean Up tmpFiles
