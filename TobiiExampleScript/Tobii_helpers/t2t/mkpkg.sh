#!/bin/bash -e

if [[ ! "$OSTYPE" == darwin*  && ! "$OSTYPE" == linux* ]] ; then
    echo "Not a Mac OS X or Linux platform"
    exit 0
fi

path=""
prog=$0

while [ $# -gt 0 ]; do
	if [ "$1" == "--path" ]; then
		shift; path=$1
		force_destination=1
	elif [ "$1" == "--help" ]; then
		echo "$prog [--help] [--path <search path>]"
	else
		echo "Unknown option: $1"
		exit 1
	fi
	shift
done

echo ""
echo "****************************************************************"
echo "** Warning: this script is a facility to build the t2t pkg.   **"
echo "** It depends on the local installation of Matlab and Octave. **"
echo "** On a Mac, this script assumes mexopts.sh to be modified    **"
echo "** in order to take in account the MATLAB_OVERRIDE_ARCH var   **"
echo "** to override the target architecture.                       **"
echo "****************************************************************"
echo ""

if [ ! "$path" == "" ]; then
	export PATH=$path:$PATH;
else
	echo ""
	echo "WARN: --path option was not specified. Hope the PATH env var"
	echo "is already correctly set to point to the proper directories "
	echo "for Matlab and Octave"
	echo ""
fi

make clean
make 
make t2tmexm
make t2tmexo

if [[ "$OSTYPE" == darwin* ]] ; then
	export MATLAB_OVERRIDE_ARCH=maci
	make t2tmexm
	export MATLAB_OVERRIDE_ARCH=
fi

make targz

if [[ "$OSTYPE" == darwin* ]] ; then 
   /Developer/usr/bin/packagemaker --doc installer/Mac\ OS\ X/t2t.pmdoc -v --id edu.sissa --out installer/Mac\ OS\ X/t2t.mpkg
   cd installer/Mac\ OS\ X/
   /usr/bin/zip -A -r t2t.mpkg.zip t2t.mpkg
   cd ../..
fi

echo "Done."