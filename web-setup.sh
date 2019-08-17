#!/bin/bash
#
cd $(mktemp -d)

git clone https://github.com/maxadamo/otp_vpn.git .
./install.sh
rm -rf $(pwd)
