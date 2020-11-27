#!/bin/bash

# open_files - Un script que evalua los ficheros abiertos por cada usuario

##### Constantes

TITLE="Script: open_files" 
PROGNAME=$(basename $0)

##### Estilos

TEXT_BOLD=$(tput bold)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_ULINE=$(tput sgr 0 1)

##### Funciones
files() {           
  for i in $users_list; do
   if [ $(lsof -u $i | wc -l) != 0 ]; then
      user_name=$i                                
      number_of_files=$(lsof -u $i | grep -E "$pattern\$" | wc -l)
      PID_=$(id -u $i)                      
      UID_=$(ps -u $i --no-headers -eo etime,pid | sort -r | head -n 1 | awk '{ print $2 }')
      printf "%s %4s %4s %4s\n" $user_name $number_of_files $PID_ $UID_
    fi
  done              
}

usage() {
  echo "usage: open_files [OPTIONS]..."
}

write_page() {
  cat << _EOF_
$TEXT_BOLD$TITLE$TEXT_RESET
Usuarios    Número_de_Ficheros    UID    PID
_EOF_
}

error_exit() {
  echo "${PROGNAME}: ${1:-"Terminado"}" 1>&2
  exit 1
}

##### Programa principal
### variables
user_name=
number_of_files=
PID_=
UID_=

pattern='*'     # patron de los ficheros
users_list=     # usuarios que analizar

### errores
if ! command -v lsof &> /dev/null
then
  error_exit
fi

### main
write_page
if [ "$1" = "" ]; then
  users_list=$(who | awk '{ print $1 }' | sort | uniq)
  files
else
  while [ "$1" != "" ]; do
    case $1 in
      -f )
        shift # en $1 estará el patrón 
        pattern=$1
        users_list=$(who | awk '{ print $1 }' | sort | uniq)
        ;;
      -o )
        users_list=$(grep -Fvxf <(who | awk '{ print $1 }' | sort | uniq) \
                    <(cat /etc/passwd | cut -d ":" -f 1))
        ;;
      -u )
        shift 
        while [ "$1" != "" ] && [ $(expr substr $1 1 1) != "-" ]; do # si $1 no es "" o "-" 
          cat /etc/passwd | cut -d ":" -f 1 | grep -q -w $1   
          if [ "$?" = "0" ]; then  # ver si el usuario existe
            users_list+="$1 "
            shift
          else
            echo
            echo "El usuario '$1' no existe."
            error_exit
          fi
        done
        ;;
      -h | --help )
        usage
        exit
        ;;
      * )
        usage
        error_exit
    esac
    shift
  done
  files
fi