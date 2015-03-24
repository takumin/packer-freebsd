#!/bin/sh

# Log clean
service syslogd stop
rm -fr /var/log/*

# Disk clean
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Shutdown
shutdown -p now
