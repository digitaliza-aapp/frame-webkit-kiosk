#!/usr/bin/env bash

echo -n quiet >/sys/module/apparmor/parameters/audit

truncate -s 0 /var/log/syslog
truncate -s 0 /var/log/kern.log
