#!/bin/sh

file=$1
count=1
flag=0
id=""
while read line
do
<<'COMMENT'	
	find=`cat "$line" | grep entry - |  wc -l`
	if [ $find -eq 0 ]
	then
		let count+=1
		continue
	fi
COMMENT

	if [[ $line == *"group"* ]]
	then
#		echo $line
		list=($line)
		for i in ${list[@]}
		do
			if [[ $i == *"id"* ]]
			then
				id=`echo $i | awk -F '"' '{print $2}'`
				#echo $id
				break
			fi
		done

		flag=1
		continue
	fi

	if [ $flag -eq 1 ]
	then
		if [[ $line == *"component"* ]]
		then
			list=($line)
			for i in ${list[@]}
			do
				if [[ $i == *"id"* ]]
				then
					elem=`echo $i | awk -F '"' '{print $2}'`
					echo -e $elem'\t'$id
				fi
			done
		fi

		if [[ $line == *"/entry"* ]]
		then
			flag=0
		fi
	fi



<<'COMMENT'
	if [ $count -ge 10 ]
	then
		break
	fi
COMMENT

	let count+=1

done < $file

<<'COMMENT'
a=0

while [ $a -lt 10 ]
do

if [ $((a%2)) -eq 0 ]
	then
		a=`expr $a + 1`
		continue
	fi

#	Q=`expr $a % 2`
	
#	if [ $Q -eq 0 ]
#	then
#		a=`expr $a + 1`
#		continue
#	fi

	echo $a
	a=`expr $a + 1`

done
COMMENT
