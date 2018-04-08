#!/bin/awk -f
BEGIN {
	FS=",";
	OFS="\n";
}
{
	for (i = 1; i <= NF; i++) {
		if (NR == 1) {
			header[i]=$i
		} else if ( $i ~ /^[0-9]+$/ ) {
			if (type[i] != "double precision" && type[i] != "character varying") {
				type[i]="integer"
			}
		} else if ( $i ~ /^[0-9]+(\.[0-9]+)?$/) {
			if (type[i] != "character varying") {
				type[i]="double precision"
			}
		} else {
			type[i]="character varying"
		}
	}
}
END {
	for (i = 1; i <= NF; i++) {
		print type[i]
	}
}