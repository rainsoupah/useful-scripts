#!/bin/bash

TOTAL_LINES=`wc -l < $1`
i=1

echo $TOTAL_LINES

split_files() {
	while [[ $i -le $TOTAL_LINES ]]; do
		j=$(expr $i + 1000000)
		jadd=$(expr $j + 1)

		file="part${i}.csv"
		command="sed -n '${i},${j}p;${jadd}q' $1 > ${file}"
		eval $command

		i=$jadd
	done
}

# main
if [[ $TOTAL_LINES -gt 10000000 ]]; then
	split_files
fi
