#!/bin/bash

[ ! -d "$HOME/.config/autostart/" ] && exit 0;
for file in "$HOME/.config/autostart/*"; do
  
  cmd=$(awk '
    $0 == "[Desktop Entry]" { in_entry = 1; exec = ""; type = "" }
    /^\[/ && $0 != "[Desktop Entry]" { in_entry = 0 }
    in_entry && /^Exec=/ { exec = substr($0, index($0, "=") + 1) }
    in_entry && /^Type=Application/ { type = "Application" }
    in_entry && exec && type == "Application" {
      print exec
      in_entry = 0
    }
  ' $file)

  $cmd &
done
