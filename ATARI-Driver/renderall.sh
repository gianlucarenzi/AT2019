#!/bin/bash
for code in `seq 0 255`
do
	echo "Caracter $code"
	./render $code
done
