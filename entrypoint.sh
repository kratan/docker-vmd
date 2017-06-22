#!/bin/bash
#set resolution of virtual screen, set default to 4k
if [ -z "$SCREEN_RESOLUTION" ]; then
    SCREEN_RESOLUTION=4096x2160
fi

#PCI BUS Stuff, using nvidia-smi to support BusIDs
rm -Rf /etc/X11/xorg.conf
MAIN_ARRAY=( `nvidia-smi --query-gpu=gpu_bus_id --format=csv,noheader` )
nvidia-xconfig --virtual=${SCREEN_RESOLUTION} --no-busid --mode-list=4096x2160 -o /etc/X11/xorg.conf

#Check Occurences
FILE_OCCURENCES=$(cat /etc/X11/xorg.conf | grep -o "NVIDIA Corporation" | wc -l)

#Cound Array Length
COUNT=${#MAIN_ARRAY[@]}

if [ -z "$COUNT" ]; then
        echo "No NVIDIA CARDS found, maybe you forgot the --device=/dev/nvidiaX in your Docker run command?"
        exit
fi


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
        sed -i ':a;$!{N;ba};s/\("NVIDIA Corporation"\)/\1 \n''  BusID   "'${BUSIDS}'"/'${TEMP_COUNTER}'' /etc/X11/xorg.conf
done


#3D Stereo Fix, disable composite
#echo 'Section "Extensions"' >> /etc/X11/xorg.conf
#echo '    Option "Composite" "Disable"' >> /etc/X11/xorg.conf
#echo 'EndSection' >> /etc/X11/xorg.conf


#Add/CheckPass for User + Port
if [ -z "$XPRA_PASSWORD" ]; then
    XPRA_PASSWORD=testgeheim
fi

if [ -z "$TARGET_UID" ]; then
    exit
fi

if [ -z "$TARGET_USER" ]; then
    exit
fi

if [ -z "$XPRAPORT" ]; then
    XPRAPORT=10050
fi

if [ -z "$VMD_OPTIONS" ]; then
    VMD_OPTIONS="LINUXAMD64 CUDA OPENGL"
fi

#Setup VMD (workdir is /tmp/vmd-version)
cd /vmd-${VMD_VERSION}
./configure ${VMD_OPTIONS}
cd /vmd-${VMD_VERSION}/src
make install

#Add User
adduser --uid ${TARGET_UID} ${TARGET_USER}

#Get TTYs
#AVAILABLE_TTY=($(ls -d /dev/tty*[0-9]*))
#TTY_COUNT=${#AVAILABLE_TTY[@]}
#if [ $TTY_COUNT -ne 1 ]; then
#        echo "No TTY found or multiple TTYs found for Xorg. Please run container with one free TTY, e.g. --device=/dev/tty60"
#        exit
#fi

#Manipulate Strings and export
USEVT=$(echo "${AVAILABLE_TTY[0]:8}")
USEVT=60

#UserStuff + Adduser to xpra group
chown ${TARGET_USER} /dev/tty${USEVT}
usermod -a -G xpra ${TARGET_USER}
mkdir -p /var/run/user/1000/xpra
chown -R ${TARGET_USER}:xpra /var/run/user/1000/xpra
mkdir -p /var/run/xpra
chown -R ${TARGET_USER}:xpra /var/run/xpra
mkdir -p /var/run/user/${TARGET_UID}/xpra
chown -R ${TARGET_USER}:xpra /var/run/user/${TARGET_UID}

#remove suid from xorg
chmod -s /usr/bin/Xorg

#generate SSL Cert
openssl req -new -x509 -days 365 -nodes \
  -out /home/${TARGET_USER}/gpunode.crt \
  -keyout /home/${TARGET_USER}/gpunode.key \
  -subj "/C=DE/ST=BW/L=KA/O=KIT/CN=gpunode"


chmod +r /home/${TARGET_USER}/gpunode.crt
chmod +r /home/${TARGET_USER}/gpunode.key

#dbus fix
dbus-uuidgen > /etc/machine-id

#install virtualgl
#ENV VIRTUALGL_VERSION=2.5.2
#curl -sSL https://downloads.sourceforge.net/project/virtualgl/"${VIRTUALGL_VERSION}"/virtualgl_"${VIRTUALGL_VERSION}".x86_64.rpm -o virtualgl_"${VIRTUALGL_VERSION}".x86_64.rpm && \


#Run Xpra with vmd
su - ${TARGET_USER} -c 'Xorg :0 -keeptty -novtswitch -sharevts vt'${USEVT}' & (XPRA_PASSWORD='${XPRA_PASSWORD}' xpra start :11 --bind-tcp=0.0.0.0:'${XPRAPORT}' --auth=env --ssl=on --ssl-cert=/home/'${TARGET_USER}'/gpunode.crt --ssl-key=/home/'${TARGET_USER}'/gpunode.key --no-clipboard --no-pulseaudio --start-child="vglrun vmd" --exit-with-child --no-printing --no-speaker --no-cursors --start-after-connect --dbus-control=no --dbus-proxy=no --no-daemon)'
#su - ${USERNAME} -c 'Xorg :11 -keeptty -novtswitch -sharevts vt'${USEVT}' & (XPRA_PASSWORD='${XPRA_PASSWORD}' xpra start :11 --bind-tcp=0.0.0.0:'${XPRAPORT}' --auth=env --no-clipboard --no-pulseaudio --start-child="vmd" --exit-with-child --no-printing --no-speaker --no-cursors --dbus-control=no --dbus-proxy=no --use-display --no-daemon)'

