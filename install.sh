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

# creates ~/bin
[ -d ~/bin ] || mkdir ~/bin

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

printf "\nthe following script have been created:\n"
printf "  ~/bin/${APP}\n"
chmod +x ~/bin/${APP}


printf "\nto uninstall ${APP}:
rm -rf ~/venv/${APP} ~/bin/${APP}"
echo ''

deactivate
