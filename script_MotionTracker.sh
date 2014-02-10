#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
FOLDER="/media/motiondetect_imgrepo"
LOG_FILE="cap.log"
PID=`pgrep raspistill`
TIME_FILE="time.left"
echo $PID

echo "started at $DATE"
echo "started at $DATE" >> $FOLDER/$LOG_FILE

if [[ -n $PID ]]; then
		echo "Raspberry Pi Camera Module Fast Capture Daemon is at" `pgrep raspistill`
		isRunning=1
else
		echo "Raspberry Pi Camera Module Fast Capture Daemon is Not Running"
		isRunning=0
		exit 1
fi

#prendre la capture OLD
kill -USR1 $PID
sleep 0.2
#echo "capturing first file"
#créer le BMP pour detection
gm mogrify -format bmp image.jpg
mv image.bmp imgold.bmp

#prendre la capture BASE
kill -USR1 $PID
sleep 0.1
#echo "capturing next file"
#créer le BMP pour detection
gm mogrify -format bmp image.jpg
mv image.bmp imgbase.bmp

while [ $isRunning -eq 1 ]; do

	#prendre la capture NEW
	kill -USR1 $PID
	sleep 0.1
	#echo "capturing next file"
	#créer le BMP pour detection
	gm mogrify -format bmp image.jpg
	mv image.bmp imgnew.bmp
	
	#créer le jpg reduit affichage
	cp image.jpg image_small.jpg
	
	#copie des jpg pour surveillance
	cp image.jpg $FOLDER
	cp image_small.jpg $FOLDER/small
	
	DATE=$(date +%Y%m%d-%H%M%S)
	
	#echo "comparing files"
	resultat=$(./BMP_Compare 11 1)
	
	echo $resultat | while read isMove movement_dir movement_orig
	do
		if [[ $isMove -eq "0" ]];then
			#echo "img identical $DATE"
			A=10
		else
			
			echo "Move dir : $movement_dir"
			echo "Move orig : $movement_orig"
			c=$((movement_dir + movement_orig))
			echo "Move pos : $c"
			echo "img different $DATE"
			echo "$DATE" >> $FOLDER/$LOG_FILE
			
			cp imgnew_diff_1.bmp $FOLDER/IMG_$DATE.dif1.bmp
			cp imgnew_diff_2.bmp $FOLDER/IMG_$DATE.dif2.bmp
			#cp img_move_1_2_3.bmp $FOLDER/IMG_$DATE.move.$movement_dir.$movement_orig.bmp
			
			if [ "$c" -gt 25 ]; then
				cammove=$(($c/20))
				echo "Cam Move : $cammove"
				cp img_move_1_2_3.bmp $FOLDER/IMG_$DATE.move.$movement_dir.$movement_orig.bmp
				sudo python movecamera.py $cammove
				echo "Move right @ $DATE" >> $FOLDER/$LOG_FILE
				CameraMoved=1
			fi
			if [ "$c" -lt -25 ]; then
				cammove=$(($c/20))
				echo "Cam Move : $cammove"
				cp img_move_1_2_3.bmp $FOLDER/IMG_$DATE.move.$movement_dir.$movement_orig.bmp
				sudo python movecamera.py $cammove
				echo "Move left @ $DATE" >> $FOLDER/$LOG_FILE
				CameraMoved=1
			fi
		fi
	done
	
	if [[ $CameraMoved -eq "1" ]];
	then
		rm imgold.bmp -f
		rm imgbase.bmp -f
		rm imgnew.bmp -f
	else
		rm imgold.bmp -f
		mv imgbase.bmp imgold.bmp
		mv imgnew.bmp imgbase.bmp
	fi
	CameraMoved=0
	
	PID=`pgrep raspistill`
	if [[ -n $PID ]]; then
			#echo "Raspberry Pi Camera Module Fast Capture Daemon is at" `pgrep raspistill`
			isRunning=1
	else
			echo "Raspberry Pi Camera Module Fast Capture Daemon is Not Running"
			isRunning=0
			exit 1
	fi
	
	if [ -f $TIME_FILE ]; then
		cp $TIME_FILE $FOLDER/$TIME_FILE
	fi
	
done
DATE=$(date +%Y%m%d-%H%M%S)
echo "ended at $DATE"
echo "ended at $DATE" >> $FOLDER/$LOG_FILE
