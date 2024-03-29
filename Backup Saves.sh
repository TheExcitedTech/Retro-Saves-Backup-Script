#!/bin/bash
#Script to check to see if there are save files. Then backs them up. 
#Created by TheExcitedTech

sudo chmod 666 /dev/tty1
printf "\e[?25l" > /dev/tty1 #hide cursor
dialog --clear

height="15" 
width="55"

printf "\033c" > /dev/tty1
printf "Starting Save Backup Script..." > /dev/tty1

CONTROLS="/opt/wifi/oga_controls"
sudo $CONTROLS Backup\ Saves.sh rg552 & sleep 2 #Joystick controls

#########################
SAVE_TYPES=("eep" "fs" "hi" "mcd" "mpk" "nv" "sav" "srm" "st0" "state*")
BACKUP_DIR=${1:-"backupsavs"} #BACKUP FOLDER
ROM_DIRS=()
CHECKED_ROM_DIRS=()
#Directories that will be skipped regardless if they have files in it.
SKIPPED_DIRS=("$BACKUP_DIR" "backup" "bezels" "BGM" "bgmusic" "bios" "etc" "launchimages" "opt" "screenshots" "themes" "tools" "videos")  
TMP_FILE="/tmp/romdirectories.txt"
ROOT_DIR=${2:-"/roms2"} #ROOT Directory
#########################

FindGameDirs () {
ls -d1 $ROOT_DIR/*/ > "$TMP_FILE" #Only shows parent directories.
while read -r line; do
    line=$(cut -c 8- <<< "$line") #Removes the '/roms2/' from the array items.
    ROM_DIRS+=("$line")
done < $TMP_FILE
rm "$TMP_FILE" 
}

PruneGameDirs () {
printf "Finding ROM directories with save files...\n"
for dir in ${ROM_DIRS[@]}; do #Checks if the directories actually have save files. 
    if [ $dir == "dreamcast/" ] && ls "$ROOT_DIR/$dir" | grep -q ".*\.bin$" ; then
        CHECKED_ROM_DIRS+=("$dir")
        continue
    fi
    for svfile in ${SAVE_TYPES[@]}; do 
        if ls "$ROOT_DIR/$dir" | grep -q ".*\.$svfile$"; then
            CHECKED_ROM_DIRS+=("$dir")
            break
        fi
    done
done

for skipped in ${SKIPPED_DIRS[@]}; do
    for fol in ${CHECKED_ROM_DIRS[@]}; do
        if [ "$fol" == "$skipped/" ]; then
        CHECKED_ROM_DIRS=( "${CHECKED_ROM_DIRS[@]/$fol}" )
        fi
    done
done
unset ROM_DIRS
}

CreateBackupDirs () {
for fol in ${CHECKED_ROM_DIRS[@]}; do
    if [ ! -d "$ROOT_DIR/$BACKUP_DIR/$fol" ]; then
        sudo mkdir -v "$ROOT_DIR/$BACKUP_DIR/$fol"; printf "\n"
    fi
done    
}

BackUpSaves () {
printf "\e[0mBacking up save files...\n"
for dir in ${CHECKED_ROM_DIRS[@]}; do
    printf "Finding save files in $dir and copying them to $BACKUP_DIR/$dir...\n"
    if [ $dir == "dreamcast/" ]; then
        sudo find "$ROOT_DIR/$dir" -name "*.bin" -exec cp {} "$ROOT_DIR/$BACKUP_DIR/$dir" \;
    fi
    for svfile in ${SAVE_TYPES[@]}; do 
        sudo find "$ROOT_DIR/$dir" -name "*.$svfile" -exec cp {} "$ROOT_DIR/$BACKUP_DIR/$dir" \;
    done
done

printf "\n\n\e[32mYour saves have been backed up"
sleep 2
}

KillControls () { 
pgrep -f oga_controls | sudo xargs kill -9 #Needs to be run before the script exits.
printf "\033c" > /dev/tty1
}

StartBackupFunction () {
if [ ! -d "$ROOT_DIR/$BACKUP_DIR" ]; then
    printf "\n"
    sudo mkdir -v "$ROOT_DIR/$BACKUP_DIR"
    FindGameDirs
    PruneGameDirs
    CreateBackupDirs
    BackUpSaves
else
    BackupWarning
fi
}

BackupWarning () {
dialog --title "Warning" --yesno "This will overwrite any saves in the $BACKUP_DIR folder. \n Do you want to continue?\n" $height $width
if [ $? = 0 ]; then
    FindGameDirs
    PruneGameDirs
    CreateBackupDirs
    BackUpSaves
elif [ $? = 1 ]; then
    printf "No action taken. Exiting Script..."
    sleep 1
    KillControls 
    exit 1
fi
}

main () {
StartBackupFunction
KillControls
}

main

exit 0