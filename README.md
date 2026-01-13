### USB automount for server and microcontrollers linux OS

Install ``make`` for install this service.

Clone this repo and go to the repo directory.

Change UID and GID in "99-usb-automount.rules" file before start service if necessary. 

For read your user id use ``id -u`` command.

After changing use ``make service`` command for automount service creation.