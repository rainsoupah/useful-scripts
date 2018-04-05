#!/bin/bash


# get csv header
get_header() {
	header="$(head -n 1 ${file_path})"
	boldPrint $header
}

remove_header() {
	sed -i '' 1d $file_path
}

boldPrint() {
	# cols=$( tput cols )
	# rows=$( tput lines )
	# message=$@
	# input_length=${#message}
	# half_input_length=$(( $input_length / 2 ))
	# middle_row=$(( $rows / 2 ))
	# middle_col=$(( ($cols / 2) - $half_input_length ))
	# tput clear
	# tput cup $middle_row $middle_col
	tput bold
	echo $@
	tput sgr0
	# tput sgr0
	# tput cup $( tput lines ) 0
}

function join {
	local IFS="$1";
	shift;
	echo "$*";
}

correct="n"
while [ $correct != "y" ];
do
	read -p 'Enter csv file path:' file_path
	get_header
	read -p 'Is this the correct file? (y/n): ' correct
	if [ $correct = "y" ];
	then
		read -p 'Remove header? (y/n): ' remove
		if [ $remove = 'y' ];
		then
			remove_header
		fi
		break
	fi
done


# prompt user for db info:
read -p 'Postgres host: ' host
read -p 'Username: ' user
read -p 'Database: ' database
read -p 'Table: ' table
read -sp 'Password: ' password


table_headers=`PGPASSWORD=${password} psql -h $host -U $user -d $database -t -c "delete from ${table}; alter sequence ${table}_ogc_fid_seq start 1; select column_name from information_schema.columns where table_name='${table}' and column_name != 'ogc_fid';"`

csv_headers="$(join ',' ${table_headers})"

copy="$(PGPASSWORD=${password} psql -h $host -U $user -d $database -c "\copy ${table}(${csv_headers}) from ${file_path} with delimiter ',' csv")"

echo "${copy} records into ${table}"
