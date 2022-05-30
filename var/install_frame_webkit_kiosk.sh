############################################################################################
#                                                                                          #
# install_frame_webkit_kiosk.sh: Script para instalar frame-webkit-kiosk                   #
#                                                                                          #
#------------------------------------------------------------------------------------------#
#                                                                                          #
# Script para instalar quioscos Webkit mediante ubuntu-frame en Ubuntu Server              # 
#                                                                                          #
#  - WebKit port optimized for embedded devices (https://wpewebkit.org/)                   #
#  - wpe-webkit-mir-kiosk snap (https://gitlab.com/glancr/wpe-webkit-snap)                 #
#  - Ubuntu Server: https://ubuntu.com/download/server                                     #
#                                                                                          #
#                                                                                          #
#------------------------------------------------------------------------------------------#
#                                                                                          #
# Autor         : Felipe Muñoz Brieva - digitaliza.aapp@gmail.com                          #
#                                                                                          #
#------------------------------------------------------------------------------------------#
#                                                                                          #
# Modificaciones:                                                                          #
#                                                                                          #
# 20/05/2022      Versión inicial                                                          #
#   Felipe                                                                                 #
#                                                                                          #
############################################################################################

KIOSK_VERSION="00.14"
BOOT_SCRIPT=/var/kiosk/service/kiosk_boot.sh
BOOT_SERVICENAME=kiosk_boot
SHUTDOWN_SCRIPT=/var/kiosk/service/kiosk_shutdown.sh
SHUTDOWN_SERVICENAME=kiosk_shutdown
RC_LOCAL="/etc/rc.local"
LSB_KIOSK="/etc/lsb-release-frame-webkit-kiosk"
SYSTEMBACK_VERSION="systemback-install_pack-1.9.4"
GITHUB_SYSTEMBACK="https://github.com/digitaliza-aapp/$SYSTEMBACK_VERSION.git"
CERTIFICADOS="/Certificados"

# Actualizar sistema e instalar sistema grafico
apt update
apt upgrade -y

apt install openbox xinit xterm x11-xserver-utils yad mlocate  -y

# Copiar scripts para el quiosco
cp -ax ./var/kiosk /var/.

# Crear carpeta para cargar certificados *.crt
mkdir $CERTIFICADOS 
chmod 777 $CERTIFICADOS 

# Version frame-webkit-kiosk 
cat > $LSB_KIOSK <<EOF
KIOSK_ID=frame-webkit-kiosk
KIOSK_RELEASE=$KIOSK_VERSION
KIOSK_DESCRIPTION="Quiosco generico: ubuntu-frame con wpe-webkit-mir-kiosk"
EOF


# Ajustar inicio del sistema (/etc/rc.local)
cat > $RC_LOCAL <<EOF
#!/bin/bash

. /var/kiosk/kiosk_config

. \$FILE_KIOSK_LIB

if grep -q "\$MODE_MENU" "\$CMDLINE"; then

   kiosk_menu

 elif grep -q "\$MODE_INSTALL" "\$CMDLINE"; then

   kiosk_install

 elif grep -q "\$MODE_CHG_URL" "\$CMDLINE"; then

   kiosk_chg_url

 elif grep -q "\$MODE_ADD_CRT" "\$CMDLINE"; then

   kiosk_add_crt

 elif grep -q "\$MODE_ADMIN" "\$CMDLINE"; then

   kiosk_admin

 else

   kiosk_menu

fi

exit 0
EOF

chmod +x $RC_LOCAL 

# Instalar servicios de arranque (kiosk_boot) y apagado (kiosk_shutdown)

# kiosk_boot: Servicio de arranque

cat > $BOOT_SCRIPT <<EOF
#!/usr/bin/env bash

echo -n quiet >/sys/module/apparmor/parameters/audit

truncate -s 0 /var/log/syslog
truncate -s 0 /var/log/kern.log
EOF

chmod +x $BOOT_SCRIPT

cat > /etc/systemd/system/$BOOT_SERVICENAME.service <<EOF
[Service]
ExecStart=$BOOT_SCRIPT
[Install]
WantedBy=default.target
EOF

systemctl enable $BOOT_SERVICENAME

# kiosk_shutdown: Servicio de apagado 

cat > $SHUTDOWN_SCRIPT <<EOF
#!/usr/bin/env bash

snap set ubuntu-frame daemon=false
EOF

chmod +x $SHUTDOWN_SCRIPT

cat > /etc/systemd/system/$SHUTDOWN_SERVICENAME.service <<EOF
[Unit]
Description=Kiosk shutdown script
DefaultDependencies=no
Conflicts=reboot.target
Before=poweroff.target halt.target shutdown.target reboot.target
Requires=poweroff.target

[Service]
Type=oneshot
ExecStart=$SHUTDOWN_SCRIPT
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=halt.target reboot.target shutdown.target

EOF

systemctl enable $SHUTDOWN_SERVICENAME

# Instalar systemback para generación de imagenes ISO
#
# base:           https://sourceforge.net/projects/systemback/
# modificaciones: https://github.com/digitaliza-aapp/systemback-install_pack-1.9.4
git clone $GITHUB_SYSTEMBACK 

cd $SYSTEMBACK_VERSION/

chmod +x install.sh

sudo ./install.sh 2> /dev/null

# Instalar wpe-webkit-mir-kiosk en ubuntu-frame
snap install ubuntu-frame
snap install wpe-webkit-mir-kiosk
snap set ubuntu-frame daemon=true
snap connect wpe-webkit-mir-kiosk:wayland
snap set ubuntu-frame daemon=false

# Reiniciar el sistema despues de la instalacion del quiosco
reboot
