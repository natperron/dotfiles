#!/bin/bash

# For some reason the script gets called once with 99, so we skip that
if [[ $1 == 99 ]]; then 
    exit 0;
fi
brightnessctl --class=backlight set $1