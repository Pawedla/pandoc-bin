# regex for space in sed commands
S="[[:space:]]*"

sleep_one_second() {
    sleep `printf "0.%04d\n" $(( RANDOM % 10000 ))`
}

# prints empty lines; $1 = file path
print_empty_lines() {
      echo >> $1
      echo >> $1
}

# prints settings with whole yml header if get_settings returns something; $1 = group name, $2 = file path
print_settings(){
    SETTINGS=$(get_settings $1 $2)
    if [[ ! -z $SETTINGS ]] ; then
        echo "---" 
        echo "$SETTINGS"  
        echo "---"
    fi
}

# generates yaml headers (variables cannot be overridden in the same header)
create_frontmatter() {
    print_settings "settingsGeneral" "${BASE_DIR}/settingsGlobal.yml"
    if [[ $1 = "book" ]] ; then
        print_settings "settingsBook" "${BASE_DIR}/settingsGlobal.yml" 
        print_settings "settingsGeneral" "settings.yml" 
        print_settings "settingsBook" "settings.yml"
    else
        print_settings "settingsSingle" "${BASE_DIR}/settingsGlobal.yml" 
        print_settings "settingsGeneral" "settings.yml" 
        print_settings "settingsSingle" "settings.yml" 
    fi
}

# gets all files of directories from MANUAL_BOOK array for given source; $1 = first entry in MANUAL_BOOK
get_manual_books() {
    MANUAL_BOOK=$(echo $1 |  sed 's/[./]/\\&/g')
    while read -r line; do
    find "$line" -type f -maxdepth 1 \( -name "settings.yml" -o -name "${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}" \) | sort -r
    done < <( sed -n "/^${S}MANUAL_BOOK:${S}."${MANUAL_BOOK}"/{s/.*\[//;s/,${S}/\n/g;s/\]//;p;q}" ${BASE_DIR}/settingsGlobal.yml | sed '1s/.*/./' ) 
}

# gets directories of paths defined in AUTOMATIC_BOOKS Array
get_automatic_books(){
    sed -n "/^${S}AUTOMATIC_BOOKS:${S}/{s/.*\[//;s/,${S}/\n/g;s/\]//;p;q}" settingsGlobal.yml
    #| sed '1s/.*/./'
}

# gets gets directories of paths defined in MANUAL_BOOK Arrays (first entry)
get_manual_book_source(){
        sed -n "/^${S}MANUAL_BOOK/{s/.*\[//;s/,.*//;s/\]//;p}" settingsGlobal.yml
}

# gets settings for a given group; $1 = group name, $2 = file path
get_settings() {
        sed -n -e "/^${S}${1}/,$ p" $2 | sed "1d;s/^${S}//;/settings.*:${S}$/{s/.*//;q}" 
}

# parses yml settings to env syntax
yml_to_env() {
    echo "$@"| sed "s/:${S}/=/" 
}

store_env(){
    if [[ -e $1 ]] ; then
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Read ${4}: " $1
    if [[  $1 =~ .env ]] ; then
        cat $1 >> $2
    else
        yml_to_env "$(get_settings "settingsGeneralEnv" $1)" >> $2
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
