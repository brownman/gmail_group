
step1(){

local dir_self=`where_am_i`

source $dir_self/helper.cfg
local file_list=$dir_self/list.txt
local str=$(cat $file_list | zenity --list --text='Dirs' --column=dir --print-column=1 --height=1000)
echo "[str] $str"
if [ -n "$str" ];then
run_dir "$dir_self/BANK/$str"
fi
}
step1
