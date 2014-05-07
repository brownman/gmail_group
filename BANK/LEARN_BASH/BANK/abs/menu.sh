
confirm_gui(){
    local str="$1"
local     cmd=$( gxmessage -entrytext "$str" -title confirm 'continue ?' $GXMESSAGE )
str=$( eval "$cmd" )
res=$?
}

step1(){

local dir_self=`where_am_i`
local file_list=$dir_self/list.txt 
    local str=$( cat $file_list | zenity --list --column='example' --text=Advance.Bash.Scripting  --print-column=1 )
    if [ -n "$str" ];then

local res=$?
echo $str
echo $res
local file="$dir_self/BANK/$str"
local cmd="gvim $file"
confirm_gui "$cmd"
else
    echo "[skip]  choosing a row"
    fi
echo zenity --help-list
}
step1
