#!/bin/gawk -f 
function TrypsinCut(InputPeptide, PepArray) {
#Trypsin Exceptions
Exceptions[0]="CKD"
Exceptions[1]="DKD"
Exceptions[2]="CKH"
Exceptions[3]="CKY"
Exceptions[4]="CRK"
Exceptions[5]="RRH"
Exceptions[6]="RRR"
#Look for reg ex match for trypsin rule; note this is the dummy split
#WorkAround to split
for(i=1;i<length(InputPeptide)+1;i++){
	String[i]=substr(InputPeptide,i,1);
	}
PepArray[1]=1;
count=1;
for(i=2;i<length(InputPeptide);i++){
	FailFlag=0;
	testStr=String[i-1] String[i] String[i+1];
	#print testStr
	for(j in Exceptions){
		if(testStr==Exceptions[j]){
			#print "Exception";
			FailFlag=1;
		}
	}
	if(FailFlag!=1){
		if( ( (String[i]=="K" || String[i]=="R") && String[i+1]!="P") || (testStr=="WKP") || (testStr=="MRP") ) {
			PepArray[++count]=i;
			}
	   	}		
 	}
#special Rule of nothing to print 
 if(count==1){
	 print InputPeptide;
	 return 0;
 }

#Special, Print Start
 #print substr(InputPeptide,PepArray[0]-1,PepArray[1])
 for(j=1;j<count;j++){
	 if(j==1){
		 for(i=PepArray[j];i<PepArray[j+1];i++){
		 printf String[i]
		 }
	 printf String[i]"\n";
 	 } 
	 if(j>1){
	 	for(i=PepArray[j]+1;i<PepArray[j+1]+1;i++){
			printf String[i];
		}
		printf "\n";
	}
 }

#Print Inbetween 
#for(j=1;j<count;j++){
#	print substr(InputPeptide,PepArray[j-1]+1,PepArray[j]-PepArray[j-1])
#	}
#print From Last Cleavage to End
 print substr(InputPeptide,PepArray[count]+1,length(InputPeptide));
}
#Start main program here
NR>0 { 
	if(multi!=1){	
	 InputPeptide=$0;
	 TrypsinCut(InputPeptide,PepArray);
 	} else {
	 InputPeptide=$0
	 print "++Input++" InputPeptide
	 TrypsinCut(InputPeptide,PepArray);
 	}
}


