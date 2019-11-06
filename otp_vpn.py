#!/usr/bin/env python3
'''
Stores OTP challenge to auth file and access OpenVPN

The first time the script creates a configuration file: ~/.vpn-credentials

if we set user nobody and group nogroup, upon disconnection it fails to restore resolv.conf

Author: Massimiliano Adamo <massimiliano.adamo@geant.org>
'''
from distutils.spawn import find_executable
import configparser
import subprocess
import os
import onetimepass as otp


def is_tool(application):
    """Check whether `name` is on PATH."""
    return find_executable(application) is not None


def get_otp(otp_secret):
    """ common commands """
    return otp.get_totp(otp_secret, as_string=True).decode()


def write_file(file_content, file_name):
    """ write ovpn client """
    config_file = open(file_name, 'w')
    config_file.write(file_content)
    config_file.close()


if __name__ == "__main__":

    for my_tool in ['rxvt-unicode', 'openvpn', 'git']:
        if not is_tool(my_tool):
            print('please install {} or add it to PATH'.format(my_tool))
            os.sys.exit()

    SCRIPT_NAME = os.path.basename(__file__)
    MY_USER_DIR = os.path.expanduser('~')
    SCRIPT_LINK = os.path.join(MY_USER_DIR, 'bin', SCRIPT_NAME)

    OTPCONFIG = os.path.join(MY_USER_DIR, '.vpn-credentials')
    OVPNFILE = os.path.join(MY_USER_DIR, '.client.ovpn')
    AUTHFILE = os.path.join(MY_USER_DIR, '.vpn-auth')

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
        write_file(OTPCONFIG_CONTENT, OTPCONFIG)
        print(" Could not open {0}\n A sample file {0} was created\n".format(OTPCONFIG))
        print(" Please edit this file and fill in your secret, username and password")
        os.sys.exit()

    CONFIG = configparser.RawConfigParser()
    _ = CONFIG.read(OTPCONFIG)
    OTP_SECRET = CONFIG.get('otp-vpn', 'otp_secret')
    VPN_USER = CONFIG.get('otp-vpn', 'vpn_user')
    VPN_PASSWORD = CONFIG.get('otp-vpn', 'vpn_password')
    SELF_SETUP_SCRIPT = '/tmp/otp_vpn_auto_setup.sh'
    CLIENT_OVPN = """\
client
verb 2
dev tun
#log {0}/jump.log
remote 2001:798:3::96 1194
remote 2001:798:3::bb 1194
remote 83.97.92.126 1194
remote 83.97.92.163 1194
connect-timeout 3
connect-retry 2
connect-retry-max 2
remote-random
ncp-disable
script-security 2
# pull-filter ignore "dhcp-option DNS" # usually not needed
# push "dhcp-option DNS 123.45.56.89" # usually not needed
# push "dhcp-option DNS 234.56.78.99" # usually not needed
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
down-pre
#user nobody
#group nogroup
proto udp
management localhost 7505
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
reneg-sec 0
tun-mtu 1500
comp-lzo
auth-nocache
auth-user-pass {1}
<ca>
-----BEGIN CERTIFICATE-----
MIIEzTCCA7WgAwIBAgIJALKAow4vc6w7MA0GCSqGSIb3DQEBCwUAMIGfMQswCQYD
VQQGEwJOTDEWMBQGA1UECBMNTm9vcmQgSG9sbGFuZDESMBAGA1UEBxMJQW1zdGVy
ZGFtMQ4wDAYDVQQKEwVHZWFudDEPMA0GA1UECxMGRGV2T3BzMREwDwYDVQQDEwhH
ZWFudCBDQTEPMA0GA1UEKRMGc2VydmVyMR8wHQYJKoZIhvcNAQkBFhBkZXZvcHNA
Z2VhbnQub3JnMB4XDTE4MDIwMTE0MjAwN1oXDTI4MDEzMDE0MjAwN1owgZ8xCzAJ
BgNVBAYTAk5MMRYwFAYDVQQIEw1Ob29yZCBIb2xsYW5kMRIwEAYDVQQHEwlBbXN0
ZXJkYW0xDjAMBgNVBAoTBUdlYW50MQ8wDQYDVQQLEwZEZXZPcHMxETAPBgNVBAMT
CEdlYW50IENBMQ8wDQYDVQQpEwZzZXJ2ZXIxHzAdBgkqhkiG9w0BCQEWEGRldm9w
c0BnZWFudC5vcmcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7Exu2
k2MceIdMiIGTeOrMqyuBlDzSL0X7n9IQuOEPjDh1RmoKWSLO97QZ3pB5GC14/NKs
FeO5Pi8zsLlTcoiaTwCtOTWa0y3MQiCbCCzyMgDs0IARkWamXHSuMb/ql9PthAgL
sPMHqV+Zjn9zwG4mWzX2ZhV4mtjFI5I7o9OCOUBQ28+Zyk9z2zxen5FRhkUJONNK
qLLSHz79P4UbPwSK2KNFxXcO+HOikIsqleGk5aRRE/fPsa9CH94vKdtDuazvuira
eHATizrlRminFVcz4XiAqvazdGkmf8dLkfXMIaTQ+AIrt2+iBU7s51OBW0XhIL52
Tq6GnIMsxdrVrCjBAgMBAAGjggEIMIIBBDAdBgNVHQ4EFgQU4OyJA6PGCnTg2g/j
Y6dEItAMfAkwgdQGA1UdIwSBzDCByYAU4OyJA6PGCnTg2g/jY6dEItAMfAmhgaWk
gaIwgZ8xCzAJBgNVBAYTAk5MMRYwFAYDVQQIEw1Ob29yZCBIb2xsYW5kMRIwEAYD
VQQHEwlBbXN0ZXJkYW0xDjAMBgNVBAoTBUdlYW50MQ8wDQYDVQQLEwZEZXZPcHMx
ETAPBgNVBAMTCEdlYW50IENBMQ8wDQYDVQQpEwZzZXJ2ZXIxHzAdBgkqhkiG9w0B
CQEWEGRldm9wc0BnZWFudC5vcmeCCQCygKMOL3OsOzAMBgNVHRMEBTADAQH/MA0G
CSqGSIb3DQEBCwUAA4IBAQBsULSWHVsgvhMYqH7QQiD3QixYYI3PNyjUXr5qL4ve
T0tylgkif4SqZXaG7HiIO+AeDjqImcrolQkFa0n0S4mNAt30+UDUDefaxTGVxyPS
TkEbo3xwseLL/0p2SCfm2n+IOrUlK/RxT09H4G3gphF6MppHRDf0oBWVDpEsmPO8
miNMuWdZapagP70CALq8UgPmPK0lJW2ERLl2yF2muTOJD3QjDSLkI9sjbQs8Kg01
B1tvBOFFVFlEHHK6+eAoIrbG/kzr1onXzxvVTaifUS4KVBcwjrMw89Y0uDSTsXu/
rqmweNTkxr8iU1vPv8stRYdCTrYcfXffNkhNdz++6Jwz
-----END CERTIFICATE-----
</ca>
""".format(MY_USER_DIR, AUTHFILE)

    SELF_SETUP = """\
#!/bin/bash
cd $(mktemp -d)
git clone https://github.com/maxadamo/otp_vpn.git .
./install.sh
rm -rf $(pwd) {}
""".format(SELF_SETUP_SCRIPT)

    MY_TOKEN = get_otp(OTP_SECRET)
    write_file("{}\n{}{}\n".format(VPN_USER, VPN_PASSWORD, MY_TOKEN), AUTHFILE)
    write_file(CLIENT_OVPN, OVPNFILE)
    write_file(SELF_SETUP, SELF_SETUP_SCRIPT)

    # Fix permissions
    os.chmod(SELF_SETUP_SCRIPT, 0o755)
    os.chmod(AUTHFILE, 0o600)
    os.chmod(OTPCONFIG, 0o640)

    # Here we go:
    _PROC_1 = subprocess.Popen(
        SELF_SETUP_SCRIPT,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )
    _PROC_2 = subprocess.Popen(
        "{}/bin/jump_on.sh".format(MY_USER_DIR),
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )
