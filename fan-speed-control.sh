#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control.
#
# Initial code taken and modified from https://github.com/NoLooseEnds
# ----------------------------------------------------------------------------------


# IPMI SETTINGS:
# Modify to suit your needs.
IPMIHOST=192.168.1.100
IPMIUSER=root
IPMIPW=calvin

# TEMPERATURE
# Change this to the temperature in celcius you are comfortable with.
# If the temperature goes above the set MAX degrees it will send raw IPMI command to enable dynamic fan control
MINTEMP=24
MAXTEMP=33
BOTTOM_ADJUST_TEMP=22

# Will monitor temp every 15 seconds, and then add 15 seconds (STEP) if no change each time
# until hitting 90 seconds.  Will reset to 15 seconds if change in temp is noticed.
TIME_UNIT=15
TIME_STEP=1

while true
do
    # This variable sends a IPMI command to get the temperature, and outputs it as two digits.
    # Do not edit unless you know what you're doing.
    TEMP=$(ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW sdr type temperature | grep degrees | grep -Po '\d{2}' | tail -1)
    
    if [[ $TEMP > $MINTEMP ]]
    then
        if [[ $TEMP > $MAXTEMP ]];
        then
            echo "Warning: Temperature has exceed limits! Activating dynamic fan control! ($TEMP C)" 
            ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x01
        elif [[ $TEMP != $OLD_TEMP ]]
        then
            case "$TEMP" in
                24 | 25 | 26 | 27) ADJUST_TEMP=$((  ($TEMP-BOTTOM_ADJUST_TEMP)*5 )) ;;
		28 | 29 | 30) ADJUST_TEMP=$((  ($TEMP-BOTTOM_ADJUST_TEMP)*7 )) ;;
		*) ADJUST_TEMP=$(( ($TEMP-BOTTOM_ADJUST_TEMP)*9 )) ;;
            esac
            ADJUST_TEMP_HEX=`echo "obase=16 ; $ADJUST_TEMP" | bc`               
            echo "Temperature has initialized or change ($OLD_TEMP vs $TEMP C): adjusting fan speed to $ADJUST_TEMP%"
            ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x00
            ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x02 0xff 0x$ADJUST_TEMP_HEX
	    TIME_STEP=1
	else
            echo "Temp has not changed; waiting ($TEMP C)"
	    TIME_STEP=$(( TIME_STEP += 1))
	    case "$TIME_STEP" in
                1 | 2 | 3 | 4 | 5 | 6) ;;
	        *) TIME_STEP=6 ;;
            esac
        fi
    fi

    if [[ -z $TEMP ]]
    then
        echo "Unable to reach iDRAC: rechecking"
    fi

    echo "Monitoring fan speed every $(( $TIME_STEP*$TIME_UNIT ))s"
    OLD_TEMP=$TEMP
    sleep $(( $TIME_STEP*$TIME_UNIT ))
done

