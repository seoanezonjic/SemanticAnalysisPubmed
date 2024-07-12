#!/bin/bash

for file in `cat $1`; do
	echo descargando $file
	wget -c --tries=inf $file &
done
wait

echo "Done!!!"
