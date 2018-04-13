#!/bin/bash

TOTAL_LINES=`wc -l < $1`
i=2

source=$1
echo $TOTAL_LINES

HEADER=`head -n1 ${source}`

split_files() {
	while [[ $i -le $TOTAL_LINES ]]; do
		j=$(expr $i + 500)
		jadd=$(expr $j + 1)

		file="postal_geom_${i}.csv"

		echo "creating ${file}..."
		echo "${HEADER}" >> $file
		command="sed -n '${i},${j}p;${jadd}q' ${source} >> ${file}"
		eval $command

		i=$jadd
		break
	done
}

# main
if [[ $TOTAL_LINES -gt 1000 ]]; then
	split_files
fi
