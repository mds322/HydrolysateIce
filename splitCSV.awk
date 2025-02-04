#!/bin/gawk -f
BEGIN{FS=",";if(lengthCheck==""){lengthCheck=35}};
NR==1{
	val="id,sequence";
	print val>> "inputLong.csv";
	print val >> "inputShort.csv"
	}
NR>=1{
	if(NF>1){
		if(length($2)>lengthCheck){
			print "Seq"count++","$0>>"inputLong.csv"
		} else {
		  	print $0>>"inputShort.csv"
		}
       } else {
		if(length($1)>lengthCheck){
			print "Seq"count++","$0>>"inputLong.csv"
		} else {
		  	print $0>>"inputShort.csv"
		}
	}
}
