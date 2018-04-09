#!/bin/awk -f
BEGIN {
	FS=",";
	OFS="\n";
}
{	
	p=1
	for (i = 1; i <= NF; i++) {
		if (NR == 1) continue
		else if ( $i ~ /^[[:space:]]/ ) continue
		else {
			if ( $i ~ /^[0-9]+$/ ) {
				if (type[p] != "double precision" && type[p] != "character varying") {
					type[p]="integer"
				} 
			} else if ( $i ~ /^[0-9]+(\.[0-9]+)?$/ ) {
				if (type[p] != "character varying") {
					type[p]="double precision"
				}
			} else {
				type[p]="character varying"
			}
			p++
		}
	}
}
END {
	for (i = 1; i < p; i++) {
		print type[i]
	}
}