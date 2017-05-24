#!/bin/bash

function dirpath {
    local cwkdir=`pwd`
	cd `dirname $1`
	local dir=`pwd`
	cd "$cwkdir"
	echo "$dir"
}

self_dir=`dirname $0`
t2t_dir=`dirpath $self_dir/../.`

ld_pl_dir=`find $t2t_dir/lib -type d -name t2tsw`
ld_py_dir="$t2t_dir/lib/python"

pm_path=`find $t2t_dir/lib -name t2tsw.pm`
pm_dir=`dirpath $pm_path`
py_path=`find $t2t_dir/lib -name t2tsw.py`
py_dir=`dirpath $py_path`

var_ld="LD_LIBRARY_PATH"
if [[ "$OSTYPE" == darwin* ]] ; then
	var_ld="DYLD_LIBRARY_PATH"
fi

echo ""
echo "Cut and paste the following lines at the shell command prompt:"
echo ""
echo "export $var_ld=$t2t_dir/lib:$ld_pl_dir:$ld_py_dir:\$$var_ld"
echo "export PYTHONPATH=$py_dir:\$PYTHONPATH"
echo "export PERL5LIB=$pm_dir:$t2t_dir/examples/perl:\$PERL5LIB"
echo "env"
echo ""
