step1(){

local dir_self=`where_am_i`
local file_list=$dir_self/list.txt
local str=$(cat $file_list | zenity --list --text='Dirs' --column=dir --print-column=1 )
echo "[str] $str"
open_sub_menu "$str"
}
open_sub_menu(){
    local str=$1
  local   dir_next_menu=$dir_self/$str
  
# ls -dl $dir_next_menu 
local file_next_menu=$dir_next_menu/menu.sh
  
str=$( eval    $file_next_menu )
res=$?
}
step1
