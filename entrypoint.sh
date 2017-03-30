#!/bin/bash

#add cuda tools to command path
export PATH=/usr/local/cuda/bin:${PATH}
export MANPATH=/usr/local/cuda/man:${MANPATH}

#add cuda libraries to library path
if [[ "${LD_LIBRARY_PATH}" != "" ]]
   then
   export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
   else
   export LD_LIBRARY_PATH=/usr/local/cuda/lib64
fi

#set resolution of virtual screen, set default to 4k
if [ -z "$SCREEN_RESOLUTION" ]; then
    SCREEN_RESOLUTION=4096x2160
fi


#PCI BUS Stuff, using nvidia-smi to support BusIDs
rm -Rf /etc/X11/xorg.conf
MAIN_ARRAY=( `nvidia-smi --query-gpu=gpu_bus_id --format=csv,noheader` )
nvidia-xconfig --virtual=${SCREEN_RESOLUTION} --use-display-device=none --no-busid  -o /etc/X11/xorg.conf

#Check Occurences
FILE_OCCURENCES=$(cat /etc/X11/xorg.conf | grep -o "NVIDIA Corporation" | wc -l)

#Cound Array Length
COUNT=${#MAIN_ARRAY[@]}

if [ -z "$COUNT" ]; then
        echo "No NVIDIA CARDS found, maybe you forgot the --device=/dev/nvidiaX in your Docker run command?"
        exit
fi

#Add no automatic Device searching of Xorg
echo  'Section "Serverflags"'  >> /etc/X11/xorg.conf
echo  'Option "AutoAddDevices" "false"'  >> /etc/X11/xorg.conf
echo  'Option "AutoEnableDevices" "false"'  >> /etc/X11/xorg.conf
echo  'EndSection'  >> /etc/X11/xorg.conf


#Add more device Sections if needed
if [ $COUNT != $FILE_OCCURENCES ]; then
        echo "Mismatch of Array and File Occurences, Problems with xorg.file and nvidia-smi output. Trying to fix..."
        for ((i=1;i<$COUNT;i++))
        do
                echo 'Section "Device"' >> /etc/X11/xorg.conf
                echo '  Identifier      "Device'$i'"' >> /etc/X11/xorg.conf
                echo '  Driver          "nvidia"' >> /etc/X11/xorg.conf
                echo '  VendorName      "NVIDIA Corporation"' >> /etc/X11/xorg.conf
                echo 'EndSection' >> /etc/X11/xorg.conf
        done
fi


#Begin looping for BUSID
for ((i=0; i<$COUNT; i++))
do
        TEMP=${MAIN_ARRAY[i]}
        IFS=':|.' read -ra array_1 <<< "$TEMP"
        BUSID_0=${array_1[1]}
        BUSID_1=${array_1[2]}
        BUSID_2=${array_1[3]}
        BUSIDS="PCI:$((0x${BUSID_0})):$((0x${BUSID_1})):$((0x${BUSID_2}))"

        #Add Bus IDs to xorg.conf, because nvidia-xconfig does not work in docker-containers
        TEMP_COUNTER=$((i+1))
        sed -i ':a;$!{N;ba};s/\("NVIDIA Corporation"\)/\1 \n''  BusID	"'${BUSIDS}'"/'${TEMP_COUNTER}'' /etc/X11/xorg.conf
done

#Add/CheckPass for User + Port
if [ -z "$XPRA_PASSWORD" ]; then
    XPRA_PASSWORD=testgeheim
fi

if [ -z "$USERNAME" ]; then
    USERNAME=testing
fi

if [ -z "$XPRAPORT" ]; then
    XPRAPORT=10050
fi

#Add User
useradd -ms /bin/bash ${USERNAME}

#Get TTYs
AVAILABLE_TTY=($(ls -d /dev/tty*[0-9]*))
TTY_COUNT=${#AVAILABLE_TTY[@]}
if [ $TTY_COUNT -ne 1 ]; then
        echo "No TTY found or multiple TTYs found for Xorg. Please run container with one free TTY, e.g. --device=/dev/tty60"
        exit
fi

#Manipulate Strings and export
USEVT=$(echo "${AVAILABLE_TTY[0]:8}")

#UserStuff + Adduser to xpra group
chown ${USERNAME} /dev/tty${USEVT}
adduser ${USERNAME} xpra


#generate SSL Cert
openssl req -new -x509 -days 365 -nodes \
  -out /home/${USERNAME}/gpunode.crt \
  -keyout /home/${USERNAME}/gpunode.key \
  -subj "/C=DE/ST=BW/L=KA/O=KIT/CN=gpunode"


chmod +r /home/${USERNAME}/gpunode.crt
chmod +r /home/${USERNAME}/gpunode.key

#Run Xpra with postAtom
su - ${USERNAME} -c 'Xorg :11 -keeptty -novtswitch -sharevts vt'${USEVT}' & (XPRA_PASSWORD='${XPRA_PASSWORD}' xpra start :11 --bind-tcp=0.0.0.0:'${XPRAPORT}' --auth=env --ssl=on --ssl-cert=/home/'${USERNAME}'/gpunode.crt --ssl-key=/home/'${USERNAME}'/gpunode.key --no-clipboard --no-pulseaudio --start-child="meshlab" --exit-with-child --no-printing --no-speaker --no-cursors --dbus-control=no --dbus-proxy=no --use-display --no-daemon)'
