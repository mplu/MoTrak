#! /bin/bash
# script inspired by http://www.raspberrypi.org/phpBB3/viewtopic.php?p=453746#p453746
OUTPUT_FILE="image.jpg"
OPTION="-rot 180 -q 10 -o $OUTPUT_FILE -w 1200 -h 896 -s -t "
TIME_FILE="time.left"
DATE=$(date +%Y%m%d-%H%M%S)
FOLDER="/media/motiondetect_imgrepo"
LOG_FILE="cap.log"
PID=`pgrep raspistill`
TIME_FILE="time.left"
isRunning=1
CameraMoved=0
IMG_IN_JPG="image.jpg"
IMG_IN_BMP="image.bmp"
IMG_1_BMP="img1_comp.bmp"
IMG_2_BMP="img2_comp.bmp"
IMG_SmallJPG="image_small.jpg"
RESOL_COMPARE="150x112"
RESOL_MINI="300x224"

test -x /usr/bin/raspistill || exit 0

function pause(){
	#echo $1
	$1 = 0
	#read touche
}

case "$1" in
  start)
		nom_process=$(basename "$0")
		nom_process=${nom_process:0:15}
		nb_process=$(pgrep $nom_process | wc -l)
		
		if [ "$nb_process" -gt 2 ]; then
			echo "Process Already Running"
		else
			echo "raspistill shadow process started for $(($2 * 60000)) seconds ($2 minutes)"
			/usr/bin/raspistill $OPTION $(($2 * 60000)) &
			./script_timer_in_min.sh $2 &

			pause "démon démarré"
		
			echo "started at $DATE"
			echo "started at $DATE" >> $FOLDER/$LOG_FILE
			#prendre la capture OLD
			kill -USR1 $PID
			sleep 0.3
			#echo "capturing first file"
			#créer le BMP pour detection
			gm mogrify -format bmp -size $RESOL_COMPARE $IMG_IN_JPG
			mv $IMG_IN_BMP $IMG_1_BMP
		
			while [ $isRunning -eq 1 ]; do
				#prendre la capture NEW
				kill -USR1 $PID
				sleep 0.2
				#créer le BMP pour detection
				gm mogrify -format bmp -size $RESOL_COMPARE $IMG_IN_JPG
				mv $IMG_IN_BMP $IMG_2_BMP
				
				#créer le jpg reduit affichage
				cp $IMG_IN_JPG $IMG_SmallJPG
				gm mogrify -size $RESOL_MINI $IMG_SmallJPG
				#copie des jpg pour surveillance
				cp $IMG_SmallJPG $FOLDER/small
				
				DATE=$(date +%Y%m%d-%H%M%S)
				

				pause "fin acquisition"
				
				if [ $CameraMoved -eq 0 ];
					then
					
					pause "debut comparaison"
					
					#comparing files
					resultat=$(./ImgDiff)
					
					#echo "resultat $resultat"

					c=$((movement_dir+0))
			
					if [ "$c" -gt 5 ]; then
						echo "Move detected : $c"
						echo "$DATE" >> $FOLDER/$LOG_FILE
						
						cammove=$(($c/5))
						echo "Cam Move : $cammove to right"
						sudo python movecamera.py $cammove &
						echo "Move right @ $DATE" >> $FOLDER/$LOG_FILE &
						CameraMoved=1
						
						cp $IMG_IN_JPG $FOLDER/IMG_$DATE.jpg &
					fi
					if [ "$c" -lt -5 ]; then
						echo "Move detected : $c"
						echo "$DATE" >> $FOLDER/$LOG_FILE
						
						cammove=$(($c/5))
						echo "Cam Move : $cammove to left"
						sudo python movecamera.py $cammove &
						echo "Move left @ $DATE" >> $FOLDER/$LOG_FILE &
						CameraMoved=1
						
						cp $IMG_IN_JPG $FOLDER/IMG_$DATE.jpg &
					fi
					
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
				else #du if [ $CameraMoved -eq 0 ];
					CameraMoved=0
				fi
				pause "avant renommage"
				rm $IMG_1_BMP
				mv $IMG_2_BMP $IMG_1_BMP
				pause "après renommage"

			done
		fi
		;;
  stop)
        pkill raspistill
		pkill script_timer_in
		rm -f TIME_FILE
        ;;

#  restart)
#        pkill raspistill
#		pkill script_timer_in
#		rm -f TIME_FILE
#		echo "raspistill shadow process started for $(($2 * 60000)) seconds ($2 minutes)"
#        /usr/bin/raspistill $OPTION $(($2 * 60000)) &
#		./script_timer_in_min.sh $2 &
#        ;;

  pid)
        if [[ -n $(pgrep raspistill) ]]; then
                echo "Raspberry Pi Camera Module Fast Capture Daemon is at" `pgrep raspistill`
        else
                echo "Raspberry Pi Camera Module Fast Capture Daemon is Not Running"
        fi
        ;;

  capture)
        kill -USR1 `pgrep raspistill`
        ;;
  *)
        echo "Usage: $0 {start <nb of minuteof running>|stop|restart<nb of minuteof running>|pid|capture}"
        exit 1
        ;;
esac
exit 0
