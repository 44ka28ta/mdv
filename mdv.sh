#!/bin/sh


TMP_FILENAME=".mdv_data_${BASHPID}"

TMP_FILEPATH='./'${TMP_FILENAME}

SOCK_NAME='VIEWER'

# parse args

usage_exit () {
	echo "Usage: $0 [-h] MD_FILE_PATH" 1>&2
	echo
	echo "Options:" 1>&2
	echo "      h: this usage show." 1>&2
	exit 1
}

OPTIND=1

while getopts "h" OPT
do
	case "${OPT}" in
		h) usage_exit
			;;
		\?) usage_exit
			;;
	esac
done

shift $((OPTIND - 1))

MD_FILE_PATH=$1

MD_FILE_NAME=`basename ${MD_FILE_PATH}`

MD_FILE_DIR=`dirname ${MD_FILE_PATH}`

compile_doc () {
	pandoc -f markdown -t html -o $TMP_FILEPATH $1
}

WATCH_EVENT="attrib"

compile_doc $MD_FILE_PATH

(inotifywait -m --event $WATCH_EVENT ${MD_FILE_DIR} | while read -r result; do echo $result | if [ -n "$(grep -G ${MD_FILE_NAME}'$')" ]; then compile_doc $MD_FILE_PATH; screen -S ${SOCK_NAME} -p 0 -X stuff "R^M"; fi done) &

trap 'echo "End process ["$!"]."; pkill -P $! &> /dev/null; rm ${TMP_FILEPATH}' EXIT

screen -S ${SOCK_NAME} bash -c "exec w3m -T 'text/html' ${TMP_FILEPATH}"
