
confirm(){
    local     args=( $@ )
    local     cmd="${args[@]}"
    echo "[confirm] $cmd"
    read answer
    if [ "$answer" = y ];then
        eval "$cmd"
    else
        echo "[skip] $cmd"
    fi
}

steps(){
    clear
    confirm "cp .gvimrc ~/.gvimrc"
    confirm "cp .vimrc ~/.vimrc"
}
steps

