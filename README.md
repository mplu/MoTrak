MoTrak
======

Motion detection and tracking for a Raspberry Pi using camera board and a stepper motor

Usage :

script_CamServerTracker.sh must be called first as root (using sudo) providing start/stop/restart or pid parameter.
When using start or restart command, a second parameter should be provided : the duration of the motion detection 
process in minutes.

Once, script_MotionTracker.sh must be run (preferably with & option) as root (using sudo). Resulting picture will be copied in 
/media/motiondetect_imgrepo, you can change it where you want.

NB :
If stepper motor will be used, be sure of GPIO configuration. 
If not, calls to movecamera.py can be commented in script_MotionTracker.sh
BMP_Compare used is version 1.0 (https://github.com/mplu/BMP_Compare/tree/1.0)
As the script is making a lot of writing operation, usage of a ramdisk is recommended.

Some bugs or non-functional stuff may be present in code and script.