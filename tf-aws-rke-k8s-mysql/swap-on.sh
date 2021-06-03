#!/bin/bash
dd if=/dev/zero of=/swapfile bs=128M count=16
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon -s
