#!/bin/bash
env > /tmp/crontab.env
chmod +x docker/crontab/crontab
crontab docker/crontab/crontab
cron -f &
