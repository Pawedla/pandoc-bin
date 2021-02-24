S="[[:space:]]*"

sleep_one_second() {
    sleep `printf "0.%04d\n" $(( RANDOM % 10000 ))`
}

print_empty_lines() {
      echo >> $1
      echo >> $1
}

print_settings(){
    SETTINGS=$(get_settings $1 $2)
    if [[ ! -z $SETTINGS ]] ; then
        echo "---" 
        echo "$SETTINGS"  
        echo "---"
    fi
}

create_frontmatter() {
    print_settings "settingsGeneral" "${BASE_DIR}/settingsGlobal.yml"
    if [[ $1 = "book" ]] ; then
    ASDF=3
       print_settings "settingsBook" "${BASE_DIR}/settingsGlobal.yml" 
        print_settings "settingsGeneral" "settings.yml" 
        print_settings "settingsBook" "settings.yml"
    else
        print_settings "settingsSingle" "${BASE_DIR}/settingsGlobal.yml" 
        print_settings "settingsGeneral" "settings.yml" 
        print_settings "settingsSingle" "settings.yml" 
    fi
}

get_manual_books() {
    MANUAL_BOOK=$(echo $1 |  sed 's/[./]/\\&/g')
    while read -r line; do
    find "$line" -type f -maxdepth 1 \( -name "*.yml" -o -name "*.md" \)
    done < <( sed -n "/^${S}MANUAL_BOOK:${S}."${MANUAL_BOOK}"/{s/.*\[//;s/,${S}/\n/g;s/\]//;p;q}" ${BASE_DIR}/settingsGlobal.yml | sed '1s/.*/./') 
}

get_automatic_books(){
    sed -n "/^${S}AUTOMATIC_BOOKS:${S}/{s/.*\[//;s/,${S}/\n/g;s/\]//;p;q}" settingsGlobal.yml | sed '1s/.*/./'
}

get_manual_book_source(){
        sed -n "/^${S}MANUAL_BOOK/{s/.*\[//;s/,.*//;s/\]//;p}" settingsGlobal.yml
}

get_settings() {
      #awk "/$1/,/\(?!\)/" $2 | sed "1d;/settings.*:${S}$/{s/.*//;q}" 
        awk "/$1/,/\(?!\)/" $2 | sed "1d;s/^${S}//;/settings.*:${S}$/{s/.*//;q}" 

}

yml_to_env() {
    echo "$@"| sed "s/:${S}/=/" 
}

store_env(){
    if [[ -e $1 ]] ; then
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Read ${4}: " $1
    if [[  $1 =~ .env ]] ; then
        cat $1 >> $2
    else
        yml_to_env "$(get_settings "settingsEnv" $1)" >> $2
        if [[ $3 = true ]] ; then 
                yml_to_env "$(get_settings "settingsBookEnv" $1)" >> $2
        else 
                yml_to_env "$(get_settings "settingsSingleEnv" $1)" >> $2
        fi
    fi
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
else
    [[ ${DEBUG} = true ]] && echo "Cannot find ${4}:" $1
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
fi
}
