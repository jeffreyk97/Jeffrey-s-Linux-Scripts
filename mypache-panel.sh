#!/bin/bash
# MyPache webserver management script - (C) 2017 JLS
Version=0.9.9
Stage=release-candidate

RELOADAW=true
ENABLEBACKUP=true

#Functions
function modfile {
UNEDITEDFILE=`stat -c %Y "$FILE"`
sudo nano $FILE

if [[ `stat -c %Y "$FILE"` -gt $UNEDITEDFILE ]] ; then
  echo "Configuration file modified successfully."
  echo
  reloadserver
else
  echo "No changes are made."
fi
}

function nonexisting {
    dialog --title "Notice" --keep-tite --msgbox "This feature is not currently available." 7 60
    mainmenu
}

function finishrespond {
	echo "Managing file: $FILE"
	echo
	echo "[SELECT OPTION]"
    echo "Select an option by typing the letter inside the bracket:"
    echo
	echo "[E] Re-edit file, reload & return to this menu."
	echo "[R] Restore old file, reload & return to main menu."
	echo "[T] Restore old file, reload & re-edit."
	echo "[X] Exit MyPache webserver manager."
	echo "Anything else: Return to main menu."
	echo
	read -r -p "Select option: " -n1 response
	case $response in
	    [eE]|[eE])
		clear
	    autobackup
		echo
		modfile
		echo
		finishrespond
		exit $?
	    ;;
	    [rR]|[rR])
		echo
		restorefile
		echo
		read -rsp $'Press any key to return to main menu...' -n1 key
		mainmenu
		exit $?
		;;
	    [tT]|[tT])
		clear
		restorefile
		echo
		autobackup
		echo
		modfile
		echo
		finishrespond
		exit $?
		;;
	    [xX]|[xX])
		clear
		exit $?
		;;
	    *)
	    mainmenu
		exit $?
	    ;;
	esac
}

function viewlogsearch {
    cmd=(dialog --title "Log search: $LOGFILEAP" --keep-tite --inputbox "Enter search (Leave empty to view full log.):" 9 40)
    maincmd=$("${cmd[@]}" 2>&1 >/dev/tty)
    if [ $? -eq "1" ]; then
        finishlogview
        exit $?
    fi
    if [ -z "$maincmd" ]; then
        clear && clear && clear
        sudo cat /var/log/apache2/$LOGFILEAP
    else
        clear && clear && clear
        sudo cat /var/log/apache2/$LOGFILEAP | grep "$maincmd"
    fi
    echo
    read -rsp $'Press any key to if you are finished...' -n1 key
    finishlogview
    exit $?
}

function aboutdialog {
    dialog --title "About" --keep-tite --msgbox "Version: $Version-$Stage\n(C) 2017 JLS (Jeffrey's Linux Scripts)\nGithub project page: https://github.com/jeffreyk97/Jeffrey-s-Linux-Scripts" 8 65
    mainmenu
    exit $?
}

function viewlog {
    clear && clear && clear
    sudo cat /var/log/apache2/$LOGFILEAP
    echo
    read -rsp $'Press any key to if you are finished...' -n1 key
    finishlogview
    exit $?
}

function finishlogview {
    clear
    echo
	echo "[VIEW LOGFILE]"
    echo "Select an option by typing the letter inside the bracket:"
    echo
	echo "[R] View error.log & search."
	echo "[E] View error.log without search"
	echo "[Y] View access.log & search."
    echo "[A] View access.log without search."
	echo "[X] Exit MyPache webserver manager."
	echo "Anything else: Return to main menu."
	echo
	read -r -p "Select option: " -n1 response
	case $response in
	    [rR]|[rR])
        LOGFILEAP=error.log
		viewlogsearch
		exit $?
	    ;;
	    [eE]|[eE])
        LOGFILEAP=error.log
        viewlog
        exit $?
		;;
	    [yY]|[yY])
        LOGFILEAP=access.log
        viewlogsearch
        exit $?
		;;
	    [xX]|[xX])
        clear
        exit $?
		;;
        [aA]|[aA])
        LOGFILEAP=access.log
        viewlog
        exit $?
        ;;
	    *)
        mainmenu
        exit $?
	    ;;
	esac
}

if [ "$RELOADAW" = "true" ]; then
	function reloadserver {
		sudo service apache2 reload
    }
else
    function reloadserver {
	       echo "Server must be reloaded manually to apply changes."
       }
fi

function sudorightsdialog {
  dialog --title "Root request" \
	    --yesno "Failed to get root access, try again?" 7 60
	    response=$?
	    case $response in
   	     0)
		clear
		echo "Please enter your password to continue."
		sudo echo "Root access acquired."
		if [ $? -ne "0" ]; then
		sudorightsdialog
		else
		mainmenu
		fi
                clear
                exit $?
		;;
   	     1)
		clear
	        exit 1
		;;
   	     255)
		clear
	        exit 1
		;;
	    esac
}

if [ $ENABLEBACKUP = "true" ]; then
function autobackup {
sudo cp $FILE $FILE.bak
if [ $? -ne "0" ]; then
echo "Backup of '$FILE' failed!"
else
echo "Automatic backup: '$FILE' backed up."
fi
}
else
function autobackup {
echo "Backups are disabled, skipping backup procedure."
}
fi

function restorefile {
if [ ! -f $FILE ]; then
echo "There is no file backed up."
else
sudo cp $FILE.bak $FILE
if [ $? -ne "0" ]; then
echo "Restore of '$FILE' failed!"
else
echo "Backup restore: '$FILE' restored."
fi
echo
reloadserver
fi
}




function serverstatus {
clear
cmd=(dialog --title "Webserver manager" --keep-tite --menu "Select option:" 22 56 16)

options=(1 "Reload Apache2"
    	 2 "Restart Apache2"
         3 "Stop Apache2"
         4 "Start Apache2"
         5 "View Apache2 status"
         6 "Start MySQL"
         7 "Stop MySQL"
         8 "Restart MySQL"
         9 "Reload MySQL"
         10 "View MySQL status"
         11 "Return to main menu")
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
    1)
	sudo service apache2 reload
	echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
	serverstatus
	exit $?
	;;
    2)
    sudo service apache2 restart
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    3)
    sudo service apache2 stop
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    4)
    sudo service apache2 start
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    5)
    sudo service apache2 status
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    6)
    sudo service mysql start
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    7)
    sudo service mysql stop
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    8)
    sudo service mysql restart
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    9)
    sudo service mysql reload
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    10)
    sudo service mysql status
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    11)
    mainmenu
    exit $?
    ;;
    esac
done
}




#Main dialog
function mainmenu {
clear
cmd=(dialog --title "MyPache webserver manager" --keep-tite --menu "Version: $Version-$Stage\nSelect option:" 22 56 16)

options=(1 "Manage Apache2 & MySQL servers"
    	 2 "Quickly reload Apache2"
    	 3 "Modify apache2.conf"
    	 4 "Modify 000-default.conf (Sites-Available)"
    	 5 "Restore apache2.conf"
    	 6 "Restore 000-default.conf (Sites-Available)"
    	 7 "View error.log & access.log"
         8 "Feedback - Bug report & feature request"
         9 "About"
    	 10 "Exit")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
    1)
    serverstatus
	;;
	2)
	sudo service apache2 reload
	echo
	read -rsp $'Press any key to return to main menu...' -n1 key
	mainmenu
	exit $?
	;;
	3)
	FILE="/etc/apache2/apache2.conf"
	autobackup
	echo
	modfile
	echo
	finishrespond
	exit $?
	;;
	4)
	FILE="/etc/apache2/sites-available/000-default.conf"
	autobackup
	echo
	modfile
	echo
	finishrespond
	exit $?
	;;
	5)
	FILE="/etc/apache2/apache2.conf"
	restorefile
	echo
	reloadserver
	echo
	read -rsp $'Press any key to return to main menu...' -n1 key
	mainmenu
	exit $?
	;;
	6)
	FILE="/etc/apache2/sites-available/000-default.conf"
	restorefile
	echo
	reloadserver
	echo
	read -rsp $'Press any key to return to main menu...' -n1 key
	mainmenu
	exit $?
	;;
	7)
    finishlogview
	exit $?
	;;
    8)
    dialog --title "Feedback system" --keep-tite --msgbox "Report an issue or request a feature on JLS' Github page (CTRL+click to open or highlight and copy the link): https://github.com/jeffreyk97/Jeffrey-s-Linux-Scripts/issues\nPlease use the scriptname (MyPache) in the issue title." 8 70
    mainmenu
    exit $?
	;;
    9)
    aboutdialog
    exit $?
	;;
	10)
    exit $?
	;;
    esac
done
}
#End of main dialog


#Logic
clear
echo "Please enter your password to continue."
sudo echo "Root access acquired."
if [ $? -ne "0" ]; then
    sudorightsdialog
else
    mainmenu
fi
