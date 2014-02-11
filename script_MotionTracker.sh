#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
FOLDER="/media/motiondetect_imgrepo"
LOG_FILE="cap.log"
PID=`pgrep raspistill`
TIME_FILE="time.left"
isRunning=1
CameraMoved=0
BenchCounter=30
IMG_IN="image.jpg"
IMG_IN_BMP="image.bmp"
IMG_OLD_BMP="imgold.bmp"
IMG_BASE_BMP="imgbase.bmp"
IMG_NEW_BMP="imgnew.bmp"
IMG_SmallJPG="image_small.jpg"
IMG_CMP_1="imgnew_diff_1.bmp"
IMG_CMP_2="imgnew_diff_2.bmp"
IMG_MOVE="img_move_1_2_3.bmp"

function pause(){
   read -p "$*"
}

timestamp1=$(date +%s)

if [[ -n $PID ]]; then
	echo "Raspberry Pi Camera Module Fast Capture Daemon is at" `pgrep raspistill`
	echo "started at $DATE"
	echo "started at $DATE" >> $FOLDER/$LOG_FILE
	#prendre la capture OLD
	kill -USR1 $PID
	sleep 0.9
	#echo "capturing first file"
	#créer le BMP pour detection
	gm mogrify -format bmp -size 300x225 $IMG_IN
	mv $IMG_IN_BMP $IMG_OLD_BMP

	#prendre la capture BASE
	kill -USR1 $PID
	sleep 0.3
	#echo "capturing next file"
	#créer le BMP pour detection
	gm mogrify -format bmp -size 300x225 $IMG_IN
	mv $IMG_IN_BMP $IMG_BASE_BMP
	
	kill -USR1 $PID
	sleep 0.3
	#créer le BMP pour detection
	gm mogrify -format bmp -size 300x225 $IMG_IN
	mv $IMG_IN_BMP $IMG_NEW_BMP

	while [ $isRunning -eq 1 ]; do
	#while [ $BenchCounter -gt 0 ]; do
	#	BenchCounter=$(($BenchCounter - 1))
		
		
		
		#prendre la capture NEW
		kill -USR1 $PID
		
		#créer le BMP pour detection
		gm mogrify -format bmp -size 300x225 $IMG_IN
		mv $IMG_IN_BMP $IMG_NEW_BMP
		
		#créer le jpg reduit affichage
		cp $IMG_IN $IMG_SmallJPG
		gm mogrify -size 300x225 $IMG_SmallJPG
		
		#copie des jpg pour surveillance
		cp $IMG_SmallJPG $FOLDER/small &
		
		DATE=$(date +%Y%m%d-%H%M%S)
		
		#echo "comparing files"
		resultat=$(./BMP_Compare 11 1)
		#resultat="0 0 0"
		while read var1 var2 var3
		do
			isMove=$var1
			movement_dir=$var2
			movement_orig=$var3
		done <<< "$resultat"
		
		if [ $isMove -eq 0 ];then
			#echo "img identical $DATE"
			A=10
		else
			echo "img different $DATE"
			c=$((movement_dir + movement_orig))
			echo "Move detected : from $movement_orig to $movement_dir, relatively $c"
			echo "$DATE" >> $FOLDER/$LOG_FILE
			
			cp $IMG_CMP_1 $FOLDER/IMG_$DATE.dif1.bmp &
			cp $IMG_CMP_2 $FOLDER/IMG_$DATE.dif2.bmp &
			
			cp $IMG_IN $FOLDER/IMG_$DATE.jpg &
			
			if [ "$c" -gt 25 ]; then
				cammove=$(($c/20))
				echo "Cam Move : $cammove to right"
				cp $IMG_MOVE $FOLDER/IMG_$DATE.move.$movement_dir.$movement_orig.bmp &
				sudo python movecamera.py $cammove &
				echo "Move right @ $DATE" >> $FOLDER/$LOG_FILE &
				CameraMoved=1
			fi
			if [ "$c" -lt -25 ]; then
				cammove=$(($c/20))
				echo "Cam Move : $cammove to left"
				cp $IMG_MOVE $FOLDER/IMG_$DATE.move.$movement_dir.$movement_orig.bmp &
				sudo python movecamera.py $cammove &
				echo "Move left @ $DATE" >> $FOLDER/$LOG_FILE &
				CameraMoved=1
			fi
		fi
		
		
		if [ $CameraMoved -eq 1 ];
		then
			rm $IMG_OLD_BMP -f &
			rm $IMG_BASE_BMP -f &
			rm $IMG_NEW_BMP -f &
		else
			rm $IMG_OLD_BMP -f 
			mv $IMG_BASE_BMP $IMG_OLD_BMP
			mv $IMG_NEW_BMP $IMG_BASE_BMP
		fi
		CameraMoved=0
		
		PID=`pgrep raspistill`
		if [[ -n $PID ]]; then
				#echo "Raspberry Pi Camera Module Fast Capture Daemon is at" `pgrep raspistill`
				isRunning=1
		else
				echo "Raspberry Pi Camera Module Fast Capture Daemon is Not Running"
				isRunning=0
		fi
		
		if [ -f $TIME_FILE ]; then
			A=10
			cp $TIME_FILE $FOLDER/$TIME_FILE &
		fi
		
	done
else
		echo "Raspberry Pi Camera Module Fast Capture Daemon is Not Running"
fi
DATE=$(date +%Y%m%d-%H%M%S)
echo "ended at $DATE"
echo "ended at $DATE" >> $FOLDER/$LOG_FILE

timestamp2=$(date +%s)
echo "duration $((timestamp2 - timestamp1))"
