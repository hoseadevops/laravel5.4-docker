#!/bin/bash
env > /tmp/crontab.env
chmod +x crontab/crontab
crontab crontab/crontab
cron -f &
