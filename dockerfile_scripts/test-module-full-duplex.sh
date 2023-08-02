#!/bin/sh
set -e

insmod /modules/fdi-test-driver.ko
sleep 1
rmmod fdi-test-driver

dmesg