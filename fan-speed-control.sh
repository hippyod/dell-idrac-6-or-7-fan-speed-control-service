#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control.
#
# Initial code taken and modified from https://github.com/NoLooseEnds
# ----------------------------------------------------------------------------------

# IPMI SETTINGS:
# Modify to suit your needs.
IPMI_HOST=192.168.1.100
IPMI_USER=root
IPMI_PW=calvin

# TEMPERATURE
# Extract MAX temperature from first core in celsius using sensors command
# outputs it as two digits, and then sets to 90% of value
MIN_TEMP=25
MAX_TEMP=$(sensors | grep Core | awk '/\+[0-9][0-9]\./{ print $6; exit }' | grep -o '[0-9][0-9]')
MAX_TEMP=$(awk "BEGIN { print ${MAX_TEMP} * 0.9 }" )

TEMP_PERCENT_INCR=1
# If you want to calculate use the following
# TEMP_PERCENT_INCR=$(awk "BEGIN { print 100/(${MAX_TEMP} - ${MIN_TEMP}) }" )

printf "MAX monitoring temp set to %0.2f based on reading\n" ${MAX_TEMP}
printf "Temperature adjustments set to %0.2f%% per °C above ${MIN_TEMP}°C\n" ${TEMP_PERCENT_INCR}

# Will monitor temp every 15 seconds, and then add 15 seconds (STEP) if no change each time
# until hitting 90 seconds.  Will reset to 15 seconds if change in temp is noticed.
SLEEP_TIME=30

TEMP_INDEX=0
TEMP_ARRAY=($MAX_TEMP $MIN_TEMP $MAX_TEMP $MIN_TEMP)
while true
do
    # Extract current temp from first core in celsius using sensors
    # command to get the temperature, and outputs it as two digits.
    TEMPS=$(sensors | awk '/\+[0-9][0-9]\./{ print $3 }' | grep -o '[0-9][0-9]' | tr '\n' ' ')
    TEMP=$(echo ${TEMPS} | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
    TEMP=$(echo "(${TEMP}+0.5)/1" | bc)

    TEMP_ARRAY[$TEMP_INDEX]=${TEMP}

    AVG_TEMP=$(echo ${TEMP_ARRAY[@]} | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
    AVG_TEMP=$(echo "(${AVG_TEMP}+0.5)/1" | bc)

    TEMP_INDEX=$(( (${TEMP_INDEX} + 1) % 4 ))

    # set control to CONTROL if within the control temp range
    CONTROL='0x01'
    if [[ ${AVG_TEMP} < ${MAX_TEMP} ]]
    then
        CONTROL='0x00'
    else
        echo "Warning: Temperature has exceeded safe monitoring limits (${AVG_TEMP}°C > ${MAX_TEMP}°C)! Activating dynamic fan control!"
        TIME_STEP=6
    fi

    if [[ ${OLD_CONTROL} != ${CONTROL} ]]
    then
        ipmitool -I lanplus -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PW} raw 0x30 0x30 0x01 ${CONTROL}
        OLD_CONTROL=${CONTROL}
    fi

    # ignored if on auto fan control
    if [[ ${CONTROL} == '0x00' ]]
    then
        if [[ $(( ${OLD_TEMP} + 2 )) < ${AVG_TEMP} || $(( ${OLD_TEMP} - 2 )) > ${AVG_TEMP} ]]
        then
            TEMP_PERCENT=$(awk "BEGIN { print (${AVG_TEMP} - ${MIN_TEMP}) * ${TEMP_PERCENT_INCR} }")
            TEMP_PERCENT=$(echo "(${TEMP_PERCENT}+0.5)/1" | bc)

            if [[ ${TEMP_PERCENT} < 10 ]]
            then
                TEMP_PERCENT=10
            fi

            TEMP_PERCENT_HEX=$(echo "obase=16 ; ${TEMP_PERCENT}" | bc)
            echo "Temperature reading has changed: ${OLD_TEMP}°C / new: ${AVG_TEMP}°C; Adjusting fan speed to ${TEMP_PERCENT}%"

            ipmitool -I lanplus -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PW} raw 0x30 0x30 0x02 0xff 0x${TEMP_PERCENT_HEX}
            OLD_TEMP=${AVG_TEMP}
        fi
    fi

    echo "Monitoring temperature is current ${OLD_TEMP}°C"
    sleep ${SLEEP_TIME}
done
