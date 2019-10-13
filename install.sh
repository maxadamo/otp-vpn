#!/bin/bash
#
APP=otp_vpn
VENV_PREFIX=~/venv/${APP}
if tty -s; then
    PRINT_CMD='printf'
else
    PRINT_CMD='true'
fi
export VENV_PREFIX PRINT_CMD APP

# prepare the spinning cursor
spinner () {
    sp="/-\|"
    i=1
    echo -n ' '
    while [ -d /proc/$PID ]
    do
      $PRINT_CMD "\b${sp:i++%${#sp}:1}"
    done
    $PRINT_CMD '\b \b'
}

# try to deactivate virtualenv
deactivate 2>/dev/null || true

# check if we have internet connection
$PRINT_CMD "checking internet connection...\n"
if ! curl -s -L http://google.com -o /dev/null; then
    $PRINT_CMD "\nplease check your internet connection\n\n"
    exit 1
fi

# creates directories
[ -d ~/bin ] || mkdir ~/bin
[ -d ~/.local/share/applications ] || mkdir ~/.local/share/applications

# create virtualenv if missing
if [ ! -d ${VENV_PREFIX} ]; then
    if ! python3 -m venv ${VENV_PREFIX} &>/dev/null; then
        echo "please install python3-venv"
        exit
    fi
fi

# activate virtualenv
source ${VENV_PREFIX}/bin/activate

# grab python version
PYTHON_VERSION=$(python --version | awk '{print $2}' | awk -F. '{print $1"."$2}')

# install pip and setuptools within the virtualenv
if [ ! -f ~/venv/${APP}/bin/pip ]; then
    $PRINT_CMD "installing pip..."
    pip install -q pip &
    PID=$!
    spinner
    $PRINT_CMD "\n"
fi

if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/setuptools ]; then
    $PRINT_CMD "installing setuptools..."
    pip install -q setuptools &
    PID=$!
    spinner
    $PRINT_CMD "\n"
fi
 
if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/wheel ]; then
    $PRINT_CMD "installing wheel..."
    pip install -q wheel &
    PID=$!
    spinner
    $PRINT_CMD "\n"
fi

if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/onetimepass ]; then
    $PRINT_CMD "installing onetimepass..."
    pip install -q onetimepass &
    PID=$!
    spinner
    $PRINT_CMD "\n"
fi

# switch branch only if necessary
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "master" ]]; then
    git checkout master
fi

# pull only if necessary
REMOTE_STATUS=$(git log HEAD..origin/master --oneline)
if [ ! -z $REMOTE_STATUS ]; then
    git pull
fi

cp -f ${APP}.py ${VENV_PREFIX}/bin/${APP}.py

cat <<EOF >~/bin/${APP}
#!/bin/bash
export PATH=${VENV_PREFIX}/bin:\$PATH
python ${VENV_PREFIX}/bin/${APP}.py "\$@"
EOF

cat <<EOF > ~/.local/share/applications/jump-vpn.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Jump VPN
GenericName=Jump VPN with OTP
Comment=Launch Jump VPN with OTP
Exec=/home/maxadamo/bin/${APP}
Icon=network-vpn-symbolic
Terminal=false
Type=Application
MimeType=text/plain;
Categories=Network;
Actions=off;stats;

[Desktop Action off]
Name=Jump VPN OFF
Exec=/home/maxadamo/bin/jump_off.sh

[Desktop Action stats]
Name=Jump VPN Stats
Exec=/home/maxadamo/bin/jump_stats.sh
EOF

cat <<EOF > ~/.local/share/applications/jump-vpn-off.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Jump VPN OFF
GenericName=Close Jump VPN connection
Comment=Close Jump VPN connection
Exec=/home/maxadamo/bin/jump_off.sh
Icon=network-vpn-acquiring-symbolic
Terminal=false
Type=Application
MimeType=text/plain;
Categories=Network;
EOF

cat <<EOF > ~/.local/share/applications/jump-vpn-stats.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Jump VPN Stats
GenericName=Dump VPN Statistics
Comment=Close Jump VPN Statistics
Exec=/home/maxadamo/bin/jump_stats.sh
Icon=network-vpn-no-route-symbolic
Terminal=false
Type=Application
MimeType=text/plain;
Categories=Network;
EOF

cat <<EOF > ~/bin/jump_on.sh
#!/bin/bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
if pgrep -f guake >/dev/null; then
    python3 /usr/bin/guake --rename-current-tab="Jump VPN" -e "sudo openvpn --config /home/maxadamo/.client.ovpn"
    sleep 1
    guake --show
    sleep 5
    guake --hide
else
    rxvt -depth 32 -bg rgba:0000/0000/0000/9999 -fg "[99]green" --geometry 160x15 -title "Jump VPN" -e /bin/bash \
        -c "sudo openvpn --config /home/maxadamo/.client.ovpn"
fi
EOF

cat <<EOF > ~/bin/jump_stats.sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
echo "printing OpenVPN statistics"
echo "signal SIGUSR2" | telnet 127.0.0.1 7505 >/dev/null
if pgrep -f guake >/dev/null; then
    guake --show
    sleep 4
    guake --hide
fi
EOF

cat <<EOF > ~/bin/jump_off.sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
echo "disconnecting OpenVPN"
echo "signal SIGINT" | telnet 127.0.0.1 7505 >/dev/null
pgrep -f guake >/dev/null && guake --show
sleep 3
guake --hide
EOF

$PRINT_CMD "\nthe following script have been created:
  ~/bin/${APP}
  ~/bin/jump-vpn.sh
  ~/bin/jump-vpn-off.sh
  ~/bin/jump-vpn-stats.sh
  ~/.local/share/applications/jump-vpn.desktop
  ~/.local/share/applications/jump-vpn-off.desktop
  ~/.local/share/applications/jump-vpn-stats.desktop

to uninstall ${APP}:
rm -rf ~/venv/${APP} ~/bin/${APP} ~/bin/jump-vpn* ~/.local/share/applications/jump-vpn*\n\n"

printf "ensure that you have a sudo entry like th following (including the star after the command):\n"
echo '%sudo  ALL=NOPASSWD: /usr/sbin/openvpn*'
echo ''

deactivate
chmod +x ~/bin/${APP} ~/bin/jump*
