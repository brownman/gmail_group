#!/bin/bash 
#version:   5
#author:    ofer shaham
#plugin:    gmail-group
#about:     whatsup clone
#date:      6.5.2014
#time:      08:05 
#depend:    gxmessage libnotify-bin gmail-notify curl vim-gtk pv cowsay toilet figlet
#help:      utilize shared gmail to act like the mobile application - WhatsUp 
#check:     ps -ef | grep gmail-notify | grep -v grep
#
#change log:
##gmail-notify is optional
##install xfce4 hotkey:alt+F2
##add dependencies for: curl gvim
##limit execution for user:not root

#31 - red
#32 - green
#33 - yellow
ensure_user(){
    [ "$(id -u)" = 0 ] && { print_color 31 "[You Are Root!]\tplease run as user";exit 0; } || { print_color 32  "[Running As User]\t$LOGNAME"; }
}
trap_err(){
    local str_caller=`caller`
    print_func
    local cmd=$( gxmessage -entrytext "gvim +${str_caller}" -file /tmp/err -title 'trap_err' )
    echo "[cmd] $cmd"
    eval "$cmd"
}
################################### env ################################\
filename=`basename $0`
dir_self=`pwd`
file_self=$dir_self/$filename
FAILURE=1
SUCCESS=0
################################### gmail ###############################
nickname=${LOGNAME:-''}
user=${GMAIL_USER:-''} #env
password=${GMAIL_PASSWORD:-''} #env
from=$user@gmail.com
to=$user@gmail.com
#===================================tmp files============================
file_unread=/tmp/file_unread.txt
file_compose=/tmp/compose.txt
#===================================key combination======================
HOTKEY="<Alt>F2"
export TERM=xterm
#/usr/bin/xterm


########################################################################/

function detect_xfce()
{
    #ref: https://github.com/alexeevdv/dename/blob/master/dename.sh
    ps -e | grep -E '^.* xfce4-session$' > /dev/null
    if [ $? -ne 0 ];
    then
        return 1
    fi
    VERSION=`xfce4-session --version | grep xfce4-session | awk '{print $2}'`
    DESKTOP="XFCE"
    return 0
}

################################### helpers ############################\
    print_color_n()       { echo -en "\x1B[01;$1m[*]\x1B[0m $2 "; }
    print_color()       { echo -e "\x1B[01;$1m[*]\x1B[0m $2 "; }
    remove_trailing(){
        local res=$(echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g')
        echo "$res"
    }
    test(){
        ########################## Test Requirements: 
        print_func
        local result=$SUCCESS
        ########################## install dependencies 
        list=`pull depend`
        for item in $list;do
            cmd="dpkg -L $item"
            eval "$cmd" &>/dev/null && { echo "[V] package exist: $item"; } || { echo >&2 "[X] sudo apt-get install $item" ;result=$FAILURE; }
        done
        ########################### test if gmail-notify is running: 
        cmd=`pull check`
        str=`eval "$cmd"`
        [ -n "$str" ] && { echo "[V] gmail-notify is running"; } || { echo >&2 "[X] please run gmail-notify" ;result=$FAILURE; } 

        ########################### test if the user update the default configurations 
        [ -n "$user" ] && { echo "[V] user is set: $user"; } || { echo >&2 "[X] please update your gmail settings which located in this file" ;result=$FAILURE; }
        return $result
    }

    pull(){
        subject="$1"
        str=`cat $0 | grep "$subject:" | cut -d':' -f2`
        remove_trailing "$str"
    }
    expose(){
        subject="$1"
        print_color_n 33 "$subject:\t\t"
        pull "$subject"
    }

    print_func(){
        echo -e "--> ${FUNCNAME[1]}():" 
    }

    info_title(){
        expose plugin
        expose help

    }
    info_conf(){
        echo -e "[CONFIGURATION]\n\t\tuser:\t$user\n\t\tpassword:\tSome password\n\t\tfrom:\t$from\n\t\tto:\t$to" 
    }
    unread(){
        curl -u $user:$password --silent "https://mail.google.com/mail/feed/atom" | tr -d '\n' | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\ \1/p"
        if [ $? -eq 0 ];then
            notify-send "OK" "retrieving"
        else
            notify-send "Error" "retrieving"
        fi
    }
    compose(){
        print_color 32 "[SEND!]"
        echo
        unread > $file_unread
        msg=$( gxmessage -entry -sticky -ontop -timeout 3000  -file $file_unread -title "Compose:" )
        if [ -n "$msg" ];then
            echo -e "Subject:${nickname}: $msg" > $file_compose
            cmd="curl -u $user:$password --ssl-reqd --mail-from $from --mail-rcpt $to --url smtps://smtp.gmail.com:465 -T $file_compose"
            eval "$cmd" 
            if [ $? -eq 0 ];then
                notify-send "OK" "sending"
            else
                notify-send "Error" "sending"
            fi
        else
            echo 'skip sending'
        fi
    }
    installing_hotkey(){
        detect_xfce
        local res=$?
        if [ $res -eq 0 ];then
            print_color 36 "[INSTALLING] hotkey ${HOTKEY}"
            #reason: setup the hotkeys for the robot
            cmd="xfconf-query -c xfce4-keyboard-shortcuts -p \"/commands/custom/${HOTKEY}\" -t string -s \"$file_self\" --create"
            echo "[cmd] $cmd "
            eval "$cmd"
        else
            print_color 31 "[CONSIDER] setting a key combination: for easier running of this script !"
        fi
    }
    installing_symlink(){
            print_color 36 "[INSTALLING] symlinks"
        ln -sf /tmp/err $dir_self/err
        ln -sf /tmp/env $dir_self/env
    }
    info_bug_report(){
        echo
        echo
print_color 35 "[FOUND A BUG?]"
echo -e "\t\t\thttps://github.com/brownman/gmail_group/issues/new"
echo
echo
}
    steps(){
        clear
        info_bug_report
        info_title
        ensure_user
        installing_symlink    
        str_res=$( eval test )
        res=$?
        if [ $res -eq 0 ];then
            info_conf
            installing_hotkey
            compose
        else
            echo
            print_color 32 "[INSTRUCTIONS]"
            cat /tmp/err | pv -qL 10
        fi
    }

    [ -f /tmp/err ] && { /bin/rm /tmp/err; }
    [ -f /tmp/env ] && { /bin/rm /tmp/env; }
    env>/tmp/env
    exec 2>/tmp/err
    trap trap_err ERR
    set -o nounset

    steps

