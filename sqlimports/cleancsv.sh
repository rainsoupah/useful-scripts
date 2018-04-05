#!/bin/bash


# clean file replace x with 0, remove carriage returns
sed 's/\,x/\,0/g' $1 | tr -d '\r' | output.csv