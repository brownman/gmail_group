#!/bin/bash
#depend: zenity
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
