#!/bin/bash

PATH_FOR_FILE_ARCHIVING=""
PATH_FOR_PLACE_FOR_ARCHIVING=""
IP_COMPUTER=""
USER_NAME=""
GOOD_PATH="true"

output_path()
{
  path=$(\
    dialog \
    --separate-widget $'\n' \
    --title "Enter the correct path:" \
    --form "" \
    0 0 0 \
    "PATH_FOR_FILE_ARCHIVING: "         1 1 "$PATH_FOR_FILE_ARCHIVING"             1 25 100 0  \
    "PATH_FOR_PLACE_FOR_ARCHIVING: "    2 1  "$PATH_FOR_PLACE_FOR_ARCHIVING"       2 30 100 0  \
    3>&1 1>&2 2>&3 3>&- \
    )
  PATH_FOR_FILE_ARCHIVING=$(echo "$path" | sed -n 1p)
  PATH_FOR_PLACE_FOR_ARCHIVING=$(echo "$path" | sed -n 2p)

}

create_information()
{
  dialog --title "$1" \
  --no-collapse \
  --msgbox "\n $2" 10 80
}
 
archiving_for_other_computer()
{
  information_about_computer=$(\
  dialog \
  --separate-widget $'\n' \
  --title "Enter the correct number another computer:" \
  --form "" \
  0 0 0 \
  "USER_NAME: "           1 1 "$USER_NAME"             1 25 100 0  \
  "IP_COMPUTER: "         2 1 "$IP_COMPUTER"             2 25 100 0  \
  3>&1 1>&2 2>&3 3>&- \
  )
  USER_NAME=$(echo "$information_about_computer" | sed -n 1p)
  IP_COMPUTER=$(echo "$information_about_computer" | sed -n 2p)
  a=$(ping -c 10 $IP_COMPUTER)
  status_active=$?
  if [ $status_active == 0 ]; then
    create_information "Information about connect with computer." "This computer is active."
    output_path
    check_path $PATH_FOR_FILE_ARCHIVING
    if [ $GOOD_PATH == "true" ]; then
      rsync --progress --delete -avh -r $PATH_FOR_FILE_ARCHIVING $USER_NAME@$IP_COMPUTER:$PATH_FOR_PLACE_FOR_ARCHIVING
    else
      GOOD_PATH="true"
    fi
  else
    create_information "Information about connect with computer." "This computer is disactive."
  fi
}

archiving_for_external_disk()
{
  text=$(lsblk -o NAME,MOUNTPOINT,LABEL,MODEL --tree | grep sd)
  path=$(\
    dialog \
    --separate-widget $'\n' \
    --title "Select a disk and rewrite mounting point(path) and name katalogy." \
    --form "$text" \
    100 70 0 \
    "PATH_FOR_FILE_ARCHIVING: "         1 1 "$PATH_FOR_FILE_ARCHIVING"             1 25 100 0  \
    "PATH_FOR_PLACE_FOR_ARCHIVING: "    2 1  "$PATH_FOR_PLACE_FOR_ARCHIVING"       2 30 100 0  \
    3>&1 1>&2 2>&3 3>&- \
    )
  PATH_FOR_FILE_ARCHIVING=$(echo "$path" | sed -n 1p)
  PATH_FOR_PLACE_FOR_ARCHIVING=$(echo "$path" | sed -n 2p)
  check_path_and_archiving
}

check_path_and_archiving()
{
  check_path $PATH_FOR_FILE_ARCHIVING
  check_path $PATH_FOR_PLACE_FOR_ARCHIVING
  if [ $GOOD_PATH == "true" ]; then
    rsync --progress --delete -avh -r $PATH_FOR_FILE_ARCHIVING $PATH_FOR_PLACE_FOR_ARCHIVING
  else
    GOOD_PATH="true"
  fi
}

archiving_for_local_computer()
{
  output_path
  check_path_and_archiving
}

check_path()
{
  if [[ -d "$1" ]]; then
    create_information "Information about the correct path." "This path "$1" is correct leads to dictionary."
  elif [[ -f "$1" ]]; then
    create_information "Information about the correct path." "This path "$1" is correct leads to file."
  else
    create_information "Information about the correct path." "This path: "$1" is not correct."
    GOOD_PATH="false"
  fi   
}

main_menu()
{
  exec 3>&1
  selection=$(dialog \
  --backtitle "Archive script" \
  --title "Menu" \
  --clear \
  --cancel-label "Exit" \
  --menu "Please select archiving options:" 0 0 4 \
  "1" "Archiving to a local computer." \
  "2" "Archiving to another computer." \
  "3" "Archiving to an external disk." \
  2>&1 1>&3)
  exit_procedure=$?
  exec 3>&-
  case $exit_procedure in 
    1 )
      exit 1
      ;;
    255 ) 
      clear
      exit
  esac
  case $selection in
    1 ) 
      archiving_for_local_computer
      ;;
    2 )
      archiving_for_other_computer
      ;;
    3) 
      archiving_for_external_disk
      ;; 
  esac
}

while true; do
  main_menu
done
