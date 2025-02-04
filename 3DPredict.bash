#!/bin/bash
#Set defaults
nolong=0;
noshort=0;
#Check input values
ARGVSize=${#@};
limit=$(($ARGVSize+1));
for((i=1;i<$limit;i++));do 
	argvalue=${!i};
	if [ $argvalue == "-f" ]; then
		i=$(($i+1));
		full=${!i};
	fi		
#Check if only long predictions are wanted
	if [ $argvalue == "-nolong" ];then
		i=$(($i+1));
		nolong=1;
	fi
#check if only short predictions are wanted	
	if [ $argvalue == "-noshort" ];then
		i=$(($i+1));
		noshort=1;
	fi
done

if [ $full == "" ]; then
	echo "Missing input (did you forget to put -f ?)"
	exit
fi

#Check that support scripts are in PATH and setup for use
if [ -x "$(command -v DefineXYRepeatsForIce.awk)" ]; then 
	  HYD=$(dirname $(which DefineXYRepeatsForIce.awk));
	else 
	  echo "Support Scripts missing? Did you remember to source HYDRC.bash?"
	  exit
fi

name=$(echo $full | sed -e 's/\.csv//g' -e 's/\.fasta//g');
echo $name" "$full;
if [ ! -d "$name"_out ]; then
	mkdir "$name"_out;
fi
echo "Check Input File and Split into Long and Short Sequences"
check=$(awk -v i="$full" 'BEGIN{if(i~/csv/||i~/fasta/){if(i~/csv/){print 1};if(i~/fasta/){print 2};}else{print 0}}');
if [ ! $check -eq 0 ]; then 
	if [ $check -eq 1 ]; then #Split CSV into AlphaFold2 length vs short-peptides lengths; output as inputShort.csv or inputLong.csv
		splitCSV.awk $full
	fi
	if [ $check -eq 2 ]; then #Split FASTA into AlphaFold2 length vs short-peptide lengths; output as inputShort.csv or inputLong.csv
		splitFASTA.awk $full
	fi
	EmptyCheck=$(awk '{if($0=="id,sequence"){count++}}END{if(count/NR==1){print 0}else{print 1}}' inputLong.csv)
	if [ "$EmptyCheck" -eq 0 ];then
		rm inputLong.csv
	fi

	EmptyCheckShort=$(awk '{if($0=="id,sequence"){count++}}END{if(count/NR==1){print 0}else{print 1}}' inputShort.csv)
	if [ "$EmptyCheckShort" -eq 0 ];then
		rm inputShort.csv
	fi

	echo "Start Prediction";
	if [ -f inputLong.csv ] && [ $nolong -eq 0 ];then
		LengthCheck=$(awk 'END{print NR}' inputLong.csv);
		if [ "$LengthCheck" -gt 10 ]; then
			Segments=$(awk 'BEGIN{count=0;seg=0}{if(count==0){print val="id,sequence">"inputLong_"seg".csv";print $0>>"inputLong_"seg".csv";count++};if(count<10){print $0>>"inputLong_"seg".csv";count++};if(count==10){count=0;seg++}}END{print seg}')
			for ((i=0;i<seg;i++)); do
				if [ ! -d "$name"_out_"$i" ]; then
					mkdir "$name"_out_"$i"
				fi
				colabfold_batch inputLong_"$i".csv "$name"_out_"$i"
			done
			mv "$name"_out_*/* "$name"_out;
			rm "$name_"out_*;
		else 
			colabfold_batch inputLong.csv "$name"_out
		fi
  	 fi

	if [ -f inputShort.csv ] && [ $noshort -eq 0 ];then
		echo "Short"
		if [ ! -d "$name"_out ]; then
			mkdir "$name"_out/;
		fi
	for i in `awk 'BEGIN{FS=","}{if($0!~/sequence/){print $0}}' inputShort.csv`; do  
		if [ ! -d $name_out/short_"$i" ]; then
			mkdir "$name"_out/short_"$i";
		fi
		echo run_pyPept --fasta $i --prefix "$name"_out/short_"$i"/"$i";
		#PyPept Gives non-standard namining of atoms for his and GLN
		#We need to fix this with the sed script below
		sed -e 's/CD1 HIS/CD2 HSD/g' -e 's/NE1 HIS/NE2 HSD/g' -e 's/CE2 HIS/CE1 HSD/g' -e 's/ND2 HIS/ND1 HSD/g' -e 's/HIS/HSD/g' -e 's/NE1 GLN/NE2 GLN/g' -e 's/OE2 GLN/OE1 GLN/g' "$name"_out/short_"$i"/"$i".pdb > tmp_"$i";
		mv tmp_"$i" "$name"_out/short_"$i"/"$i".pdb
	done
	fi
else 
	echo "Please provide a CSV (with Raw Sequences)"
	echo "A single FASTA can also be provided"
fi;
#if [ -f inputLong.csv ]; then
#	rm inputLong.csv
#fi
#if [ -f inputShort.csv ]; then
#	rm inputShort.csv
#fi
echo "Structure Prediction Complete"
