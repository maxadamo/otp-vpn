#!/bin/bash
#
APP=otp_vpn
VENV_PREFIX=~/venv/${APP}
export VENV_PREFIX

# prepare the spinning cursor
spinner () {
    sp="/-\|"
    i=1
    echo -n ' '
    while [ -d /proc/$PID ]
    do
      printf "\b${sp:i++%${#sp}:1}"
    done
    printf '\b \b'
}

# try to deactivate virtualenv
deactivate 2>/dev/null || true

# check if we have internet connection
printf "checking internet connection...\n"
if ! curl -s -L http://google.com -o /dev/null; then
    printf "\nplease check your internet connection\n\n"
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
    printf "installing pip..."
    pip install -q pip &
    PID=$!
    spinner
    printf "\n"
fi

if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/setuptools ]; then
    printf "installing setuptools..."
    pip install -q setuptools &
    PID=$!
    spinner
    printf "\n"
fi
 
if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/wheel ]; then
    printf "installing wheel..."
    pip install -q wheel &
    PID=$!
    spinner
    printf "\n"
fi

if [ ! -d ~/venv/${APP}/lib/python${PYTHON_VERSION}/site-packages/onetimepass ]; then
    printf "installing onetimepass..."
    pip install -q onetimepass &
    PID=$!
    spinner
    printf "\n"
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
Exec=/home/maxadamo/bin/otp_vpn.py
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

cat <<EOF > ~/jump_on.sh
#!/bin/bash
rxvt -depth 32 -bg rgba:0000/0000/0000/9999 -fg "[99]green" \\
    --geometry 160x15 -title "Jump VPN" -e /bin/bash \\
    -c "sudo openvpn --config .client.ovpn"
EOF

cat <<EOF > ~/jump_stats.sh
echo "printing OpenVPN statistics"
echo "signal SIGUSR2" | telnet 127.0.0.1 7505 >/dev/null
EOF

cat <<EOF > ~/jump_ff.sh
echo "disconnecting OpenVPN"
echo "signal SIGINT" | telnet 127.0.0.1 7505 >/dev/null
EOF

printf "\nthe following script have been created:
  ~/bin/${APP}
  ~/bin/jump-vpn.sh
  ~/bin/jump-vpn-off.sh
  ~/bin/jump-vpn-stats.sh
  ~/.local/share/applications/jump-vpn.desktop
  ~/.local/share/applications/jump-vpn-off.desktop
  ~/.local/share/applications/jump-vpn-stats.desktop

to uninstall ${APP}:
rm -rf ~/venv/${APP} ~/bin/${APP} ~/.local/share/applications/jump-vpn*\n\n"

deactivate
chmod +x ~/bin/${APP} ~/bin/jump*
