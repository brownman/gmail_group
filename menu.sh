#!/bin/bash
#depend: zenity
where_am_i () 
{ 
    local file=${1:-"${BASH_SOURCE[1]}"};
    local rpath=$(readlink -m $file);
    local rcommand=${rpath##*/};
    local str_res=${rpath%/*};
    local dir_self="$( cd $str_res  && pwd )";
    echo "$dir_self"
}

dir_self=`where_am_i`
pushd "$dir_self" >/dev/null
step1(){
local dir_self=`dirname $0`
source $dir_self/helper.cfg
local file_list=$dir_self/list.txt
local str=$(cat $file_list | zenity --list --text='Dirs' --column=dir --print-column=1 $ZENITY)
echo "[str] $str"
if [ -n "$str" ];then
run_dir "$dir_self/BANK/$str"
fi
}
cmd=step1
eval "$cmd"
popd >/dev/null
