#!/bin/gawk -f
function RoundToNextLattice(Var) {
	#This function checks to see if the input value is an integer and if not rounds up to the next closest integer
	test=int(Var)+1;
	if(test-Var<1){
		return test ;
	}
	else { 
		return Var ;
}
}

#Main Program
BEGIN{ 
	FixedXDim_1h=0.7822839; #Derived from a 1 x 1 x 1 repeat 1h ice box
	FixedYDim_1h=0.7353573;
}
#Read input from gromacs *.gro file using tail -n1 
{
	X=$1;
	Y=$2;
	TestX=X/FixedXDim_1h;
	TestY=Y/FixedYDim_1h;
	printf RoundToNextLattice(TestX)" ";
	printf RoundToNextLattice(TestY)"\n";
}

