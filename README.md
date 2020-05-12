# dell-idrac-6-fan-speed-control-service
Simple service to monitor ambient temp of Dell PowerEdge R610 and set fan speed manually and appropiately via IPMI

This service will start on boot, monitor the ambient temp over via lan and the ipmitool.

**[NOTE: if you don't understand the instructions, that's what internet search is for.]**
1. Make sure ipmitool is installed
1. Make sure iDRAC is enabled over lan
1. `sudo cp fan-speed-control.sh /usr/local/bin/`
1. `sudo cp fan-speed-control.service /usr/lib/systemd/system/`
1. `sudo systemctl enable /usr/lib/systemd/system/fan-speed-control.service`
1. `sudo systemctl start fan-speed-control.service`

That's it.  Service will start and run every few seconds depending on the use of your machine, adjusting the fan speed appropiately as the ambient temprature rises.  Once the temp rises past the MAX setting, it will return control to iDRAC until the Ambient temp falls to manageable levels again.  _Please read through the script to understand the default settings, and to adjust the IP address of your iDRAC._

This stopped my machine from sounding like a jet engine, but it still gets warm and sounds like a loud, '90's era desktop with this.  Still much better and much more tolerable. Adjust to your heart's desire, but see warning and disclaimer below.


# DISCLAIMER
#### USE AT YOUR OWN RISK!!  No responsibility taken for any damage caused to your equipment as result of this script.
