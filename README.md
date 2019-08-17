# How to use it

## first time setup

Let's assume you are logged in as user `foo`. You need first a sudo rule for your user as following:

```bash
foo  ALL=NOPASSWD: /usr/sbin/openvpn*
```

Now you can run the script as user `foo` for the first time:

```bash
./otp_vpn.py
```

## Connect/disconnect the VPN

1. you have GNOME:

    search for an icon starting with `Jump VPN`: there is `Jump VPN`, `Jump VPN Stats`, `Jump VPN OFF`

2. you don't have GNOME:

    run either `/home/foo/bin/otp_vpn.py`, `/home/maxadamo/bin/jump_off.sh`

3. long press the icon:

    it will appear an option to print statistics of close the VPN

## hints

- Do not run the script as root (or with sudo)
- Do not delete or move the repository
