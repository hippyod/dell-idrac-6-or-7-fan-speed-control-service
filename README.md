# dell-idrac-6-fan-speed-control-service
Simple service to monitor ambient temp of Dell PowerEdge R610 and set fan speed manually and appropiately via IPMI.

This service will start on boot, monitor the average core CPU temperature every 30s, and adjust fan speed over LAN via the ipmitool based on a rolling average of the average CPU temperatures every two minutes; i.e. `${AVG_CPU_TEMPS_ARRAY_SUM}/4`

**[NOTE: if you don't understand the instructions, that's what internet search is for.]**
1. Make sure ipmitool is installed
1. Make sure lm_sensors is installed
1. Make sure iDRAC is enabled over lan
1. Get the ip address of iDRAC from the LCD menus at the front of the screen, or during boot
1. Enter the iDRAC ip in fan-speed-control.sh
    1. We suggest making the IP address static
    1. If the fan isn't under control by the time your login screen comes up, check the IP address first
1. `sudo sensors-detect`
    1. Hit enter all the way through until it asks you to write out the results of the probe unless you know what you're doing
1. `sudo cp fan-speed-control.sh /usr/local/bin/`
1. `sudo cp fan-speed-control.service /usr/lib/systemd/system/`
1. `sudo systemctl enable /usr/lib/systemd/system/fan-speed-control.service`
1. `sudo systemctl start fan-speed-control.service`

Service will start and run every 30 seconds (default), adjusting the fan speed appropiately as the average core CPU temprature rises.  Once the temp rises past 90% of the high CPU temperature as reported by the sensors command, it will return control to iDRAC until the core CPU average temperature falls back under 90% of the reported high.  _Please read through the script to understand the default settings, and to adjust the IP address of your iDRAC._

This stopped my machine from sounding like a jet engine, but it still sounds like a loud, '90's era desktop with this.  Still much better and much more tolerable. Expect the fan speed to adjust somewhat regularly depending on usage and sensor sensistivity, and adjust the way the service works to your heart's desire, but see warning and disclaimer below.


# DISCLAIMER
#### USE AT YOUR OWN RISK!!  No responsibility taken for any damage caused to your equipment as result of this script.

Original script before modification can be found and freely obtained from [NoLooseEnds](https://github.com/NoLooseEnds/Scripts)
