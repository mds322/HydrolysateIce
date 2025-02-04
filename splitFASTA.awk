#!/bin/gawk -f
BEGIN{val=sprintf(id,sequence);if(lengthCheck==""){lengthCheck=35};
	print val >> "inputLong.csv"
}
NR==1{
     if($0~/>/){
	sub(/>/,"",$0);
	gsub(/ /,"_",$0);
	name=$0;
     }
}
NR>1{
    if($0!~/>/){	
	ProteinLength+=length($0);
	array[Rows++]=$0;
    }
     if($0~/>/){
	if(ProteinLength>lengthCheck){
		printf name "," >> "inputLong.csv";
		for(i=0;i<Rows+1;i++){
			printf array[i] >>"inputLong.csv";
		}
		printf "\n" >>"inputLong.csv";
	} else {
		printf name "," >> "inputShort.csv";
		for(i=0;i<Rows+1;i++){
			printf array[i] >>"inputShort.csv";
		}
		printf "\n" >>"inputShort.csv";
	}
	sub(/>/,"",$0);
	gsub(/ /,"_",$0);
	name=$0;
	split("", array);
	ProteinLength=0;
	Rows=0;
     }
}
END{
    if(ProteinLength>lengthCheck){
                printf name "," >> "inputLong.csv";
                for(i=0;i<Rows+1;i++){
                        printf array[i] >>"inputLong.csv";
                }
                printf "\n";
        } else {
		printf name "," >> "inputShort.csv";
		for(i=0;i<Rows+1;i++){
			printf array[i] >>"inputShort.csv";
		}
		printf "\n" >>"inputShort.csv";
	}
}
