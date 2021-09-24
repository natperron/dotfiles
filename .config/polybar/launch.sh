#!/bin/sh

killall -q polybar

MONITOR=eDP polybar primary &

