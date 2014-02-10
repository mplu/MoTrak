#! /bin/bash
FILE="time.left"
tempsrestant=$1

while [ $tempsrestant -gt 0 ]; do
	:> $FILE
	echo "$tempsrestant">>$FILE
	sleep 60
	tempsrestant=$(($tempsrestant - 1))
done
rm $FILE