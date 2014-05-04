#!/bin/bash 
#author:    ofer shaham
#plugin:    gmail-group
#about:     whatsup clone
#version:   2
#date:      4.5.2014
#depend:    gxmessage libnotify-bin gmail-notify
#help:      utilize shared gmail to act like the mobile application - whatsup 
#url_gist:  https://gist.github.com/brownman/9019632
#check:     ps -ef | grep gmail-notify | grep -v grep
#
#change log:
##gmail-notify is optional
##install xfce4 hotkey:alt+F2

#31 - red
#32 - green
#33 - yellow

trap_err(){
    local str_caller=`caller`
    print_func
    local cmd=$( gxmessage -entrytext "gvim +${str_caller}" -file /tmp/err -title 'trap_err' )
    echo "[cmd] $cmd"
    eval "$cmd"
}
################################### env ################################\
    nickname=${LOGNAME:-''}
user=${GMAIL_USER:-''} #env
password=${GMAIL_PASSWORD:-''} #env
from=$user@gmail.com
to=$user@gmail.com
FAILURE=1
SUCCESS=0
file_msg=/tmp/file_msg.txt
file_compose=/tmp/compose.txt
filename=`basename $0`
dir_self=`pwd`
file_self=$dir_self/$filename
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
    ########################################################################/

    test(){


        ########################## Test Requirements: ##################################\   
        ################################################################################\
            print_func
        result=$SUCCESS
        ########################## install dependencies ######################\   
        list=`pull depend`
        for item in $list;do
            cmd="dpkg -L $item"
            eval "$cmd" >/dev/null 2>&1 || { echo >&2 "sudo apt-get install $item" ;result=$FAILURE; }
        done
        ########################### test if gmail-notify is running ##########\

            cmd=`pull check`
        str=`eval "$cmd"`
        [ -z "$str" ] && { echo >&2 "please run gmail-notify" ;result=$FAILURE; }



        ########################### test if the user update the default configurations ##########\

            [ -z "$user" ] && { echo >&2 "please update your gmail settings which located in this file" ;result=$FAILURE; }

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

    info(){
        print_func

        expose plugin
        expose help

        echo -e "[CONFIGURATION]\nuser:\t$user\npassword:\tSome password\nfrom:\t$from\nto:\t$to" 
    }
    unread(){
        curl -u $user:$password --silent "https://mail.google.com/mail/feed/atom" | tr -d '\n' | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\ \1/p"
        if [ $? -eq 0 ];then
            notify-send "OK" "retrieving"
        else
            notify-send "Error" "retrieving"

        fi

    }
    run(){
        print_func
        print_color 32 "[SEND!]"

        echo
        unread > $file_msg
        msg=$( gxmessage -entry -sticky -ontop -timeout 3000  -file $file_msg -title "Compose:" )
        if [ -n "$msg" ];then
            echo -e "Subject:${nickname}: $msg" > $file_compose
            cmd="curl -u $user:$password --ssl-reqd --mail-from $from --mail-rcpt $to --url smtps://smtp.gmail.com:465 -T $file_compose"
            eval "$cmd" 
            if [ $? -eq 0 ];then
                notify-send "OK" "sending"
            else
                notify-send "Error" "sending"
            fi

            #>/dev/null
        else
            echo 'skip sending'
        fi
    }
    install_hotkey(){
        detect_xfce
        local res=$?
        if [ $res -eq 0 ];then
            print_color 36 "[INSTALL] hotkey F2"
            #reason: setup the hotkeys for the robot
            cmd="xfconf-query -c xfce4-keyboard-shortcuts -p \"/commands/custom/<Alt>F2\" -t string -s \"$file_self\" --create"
            echo "[cmd] $cmd "
            eval "$cmd"
        else
            print_color 31 "[CONSIDER] setting a key combination: for easier running of this script !"
        fi
    }
    install_symlink(){
        print_func
        ln -sf /tmp/err $dir_self/err
        ln -sf /tmp/env $dir_self/env
    }
    steps(){
        clear
        print_func
        info
        install_hotkey
        install_symlink    
        str_res=$( eval test )
        res=$?
        if [ $res -eq 0 ];then
            print_color 32 'run!'
            run
        else
            print_color 31 'follow the Instructions -> then try again!'
        fi
    }



    [ -f /tmp/err ] && { /bin/rm /tmp/err; }
    [ -f /tmp/env ] && { /bin/rm /tmp/env; }
    env>/tmp/env
    exec 2>/tmp/err
    trap trap_err ERR
    set -o nounset
    steps
