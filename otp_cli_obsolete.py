#!/usr/bin/env python3
'''
Stores OTP challenge to auth file and access OpenVPN

The first time the script creates a configuration file: ~/.vpn-credentials

if we set user nobody and group nogroup, upon disconnection it fails to restore resolv.conf

Author: Massimiliano Adamo <massimiliano.adamo@geant.org>
'''
import configparser
import os
try:
    import onetimepass as otp
except ImportError:
    print("Please install onetimepass: pip3 install onetimepass\n")
    os.sys.exit()



SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPT_NAME = os.path.basename(__file__)
SCRIPT_PATH = os.path.join(SCRIPT_DIR, SCRIPT_NAME)
MY_USER_DIR = os.path.expanduser('~')
try:
    os.makedirs(os.path.join(MY_USER_DIR, 'bin'))
except FileExistsError:
    pass
if not os.path.islink(os.path.join(MY_USER_DIR, 'bin', SCRIPT_NAME)):
    os.symlink(SCRIPT_PATH, os.path.join(MY_USER_DIR, 'bin', SCRIPT_NAME))

OTPCONFIG = os.path.join(MY_USER_DIR, '.vpn-credentials')
OTPCONFIG_CONTENT = """\
[otp-vpn]
# OTP Secret
otp_secret = XXXXXXXXXXXXXX
# VPN User
vpn_user = username.vpn
# VPN Password
vpn_password = your_password
"""

if not os.path.isfile(OTPCONFIG):
    CONFIG_FILE = open(OTPCONFIG, 'w')
    CONFIG_FILE.write(OTPCONFIG_CONTENT)
    CONFIG_FILE.close()
    print(" Could not open {0}\n A sample file {0} was created\n".format(OTPCONFIG))
    print(" Please edit this file and fill in your secret, username and password")
    os.sys.exit()

CONFIG = configparser.RawConfigParser()
_ = CONFIG.read(OTPCONFIG)
OTP_SECRET = CONFIG.get('otp-vpn', 'otp_secret')
VPN_PASSWORD = CONFIG.get('otp-vpn', 'vpn_password')
MY_TOKEN = otp.get_totp(OTP_SECRET, as_string=True).decode()

print('{0} + {1} =\n{0}{1}'. format(VPN_PASSWORD, MY_TOKEN))
