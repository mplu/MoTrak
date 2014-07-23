#! /bin/bash
# script inspired by http://www.raspberrypi.org/phpBB3/viewtopic.php?p=453746#p453746
OUTPUT_FILE="image.jpg"
#OPTION="-rot 180 -q 10 -o $OUTPUT_FILE -w 300 -h 225 -s -t "
#OPTION="-rot 180 -q 10 -o $OUTPUT_FILE -w 2400 -h 1800 -s -t "
OPTION="-rot 180 -q 10 -o $OUTPUT_FILE -w 1200 -h 896 -s -t "
LOG_FILE="cap.log"
TIME_FILE="time.left"

test -x /usr/bin/raspistill || exit 0

case "$1" in
  start)
		echo "raspistill shadow process started for $(($2 * 60000)) seconds ($2 minutes)"
        /usr/bin/raspistill $OPTION $(($2 * 60000)) &
		./script_timer_in_min.sh $2 &
        ;;
  stop)
        pkill raspistill
		pkill script_timer_in
		rm -f TIME_FILE
        ;;

  restart)
        pkill raspistill
		pkill script_timer_in
		rm -f TIME_FILE
		echo "raspistill shadow process started for $(($2 * 60000)) seconds ($2 minutes)"
        /usr/bin/raspistill $OPTION $(($2 * 60000)) &
		./script_timer_in_min.sh $2 &
        ;;

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
