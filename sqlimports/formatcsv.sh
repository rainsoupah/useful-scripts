#!/bin/bash

# global vars
correct="n"

# get csv header
clean_csv() {
	# remove carriage return
	sed -i.bak $'s/\r//' $file_path
}

get_col_types() {
	COL_TYPES="$(awk -f aggcol.awk ${file_path})"
	IFS=$'\n' read -rd '' -a col_type_array <<< "$COL_TYPES" # put in array

	num_col=${#col_type_array[@]} # number of cols

	fields="ogc_fid integer DEFAULT nextval('${table}_fid_seq'::regclass) NOT NULL,"
	for (( i = 0; i < ${num_col}; i++ )); do
		read -p "Column $((i+1)) ). ${header_array[i]}: ${col_type_array[i]} (y/n): " name_type_correct
		if [ $name_type_correct = "n" ]; then
			read -p "Name for column (no space please): " name_col
			header_array[i]=$name_col
			echo "Type of column: "
			select ifv in "int" "float" "varchar"; do
				case $ifv in
					int ) col_type_array[i]="integer"; break;;
					float ) col_type_array[i]="double precision"; break;;
					varchar ) col_type_array[i]="character varying"; break;;
					*) echo invalid input, please enter 1, 2 or 3
				esac
			done
		fi
		fields+="${header_array[i]} ${col_type_array[i]},"
	done

	fields+="primary key(ogc_fid)"
}

get_header() {
	header="$(sed '1q;d' ${file_path}\
		| sed -E 's/[][()%$-]//g'\
		| sed -e 's/:/ /g'\
		| sed -e 's/"//g'\
		| sed -E 's/[[:space:]]+/_/g'\ 
	)"
	# replace upper with lower case
	boldPrint $header
	# store in array
	IFS=', ' read -r -a header_array <<< $header
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

function parse_response {
	for token in "$@"; do
		if [[ $token = "COPY" ]]; then
			echo "\n $@ records into ${table}"
			break
		else
			if [[ ! $token =~ $re ]]; then
				# token is number
				ERROR_LINE="$(sed '${token}q;d' ${file_path})"
				echo "Copy failed. \n $ERROR_LINE"
				break
			fi
		fi
	done
}

# prompt user for db info:
read -p 'creating new table? (y/n) ' is_new
read -p 'Postgres host: ' host
read -p 'Username: ' user
read -p 'Database: ' database
read -p 'Table: ' table
read -sp 'Password: ' password


while [ $correct != "y" ];
do
	read -p 'Enter csv file path:' file_path
	clean_csv
	get_header
	read -p 'Is this the correct file? (y/n): ' correct
	if [ $correct = "y" ];
	then
		echo "===Column types==="
		get_col_types
		read -p 'Remove header? (y/n): ' remove
		if [ $remove = "y" ];
		then
			remove_header
		fi
		break
	fi
done





# sql queries

create_Table="create table if not exists ${table}(${fields});"

echo "${create_Table}"


if [ $is_new = "y" ]; then
	table_headers=`PGPASSWORD=${password} psql -h $host -U $user -d $database -t -c \
		"create sequence ${table}_fid_seq;\
		create table if not exists ${table}(${fields});\
		select column_name from information_schema.columns \
			where table_name='${table}' and column_name != 'ogc_fid';"`
else
	table_headers=`PGPASSWORD=${password} psql -h $host -U $user -d $database -t -c \
		"delete from ${table}; \
		alter sequence ${table}_ogc_fid_seq restart with 1; \
		select column_name from information_schema.columns \
			where table_name='${table}' and column_name != 'ogc_fid';"`
fi

echo $table_headers

csv_headers="$(join ',' ${table_headers})"

copy="$(PGPASSWORD=${password} psql -h $host -U $user -d $database -c "\copy ${table}(${csv_headers}) from ${file_path} with delimiter ',' csv")"


# to do: print line number
parse_response $copy
