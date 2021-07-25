# Install packages wanted and needed
sudo apt install -y git rxvt-unicode snapd volumeicon blueman network-manager-gnome ; 

# Install dependencies for picom
# https://github.com/ibhagwan/picom
sudo apt install -y libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libxcb-glx0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libpcre3-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev ;

# Install dependecies for i3-gaps
# https://github.com/Airblader/i3
sudo apt install -y lightdm meson dh-autoreconf libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev libxcb-shape0 libxcb-shape0-dev ;

# Create installing directory
[ ! -d "$HOME/installing" ] && mkdir "$HOME/installing"; cd ~/installing ;

# Build picom from source
git clone https://github.com/ibhagwan/picom.git && 
cd picom &&
git submodule update --init --recursive &&
meson --buildtype=release . build &&
ninja -C build &&
sudo ninja install ; 

cd ~/installing ;

# Build i3-gaps from source
git clone https://github.com/Airblader/i3.git i3-gaps && 
cd i3-gaps &&
mkdir -p build && 
cd build && 
meson --prefix /usr/local && 
ninja && 
sudo ninja install ;

# Cleanup
cd ~/installing && 
rm -rf picom && 
rm -rf i3-gaps ;

# Setting the theme from command line doesn't work with i3 and I'm too lazy
# to do the editing of the config file directly, so I'll set it manually
# with lxappearance

# Install Dracula theme for GTK
# https://github.com/matheuuus/dracula-theme
[ ! -d "$HOME/.themes" ] && mkdir "$HOME/.themes" ;
curl -L0 https://github.com/matheuuus/dracula-theme/archive/refs/heads/master.zip --output Dracula.zip &&
unzip Dracula.zip &&
mv dracula-theme-master ~/.themes/Dracula && 
rm -rf Dracula.zip ;

# Install Dracula icons
# https://github.com/matheuuus/dracula-icons
[ ! -d "$HOME/.icons" ] && mkdir "$HOME/.icons" ;
curl -L0 https://github.com/matheuuus/dracula-icons/archive/refs/heads/main.zip --output Dracula-icons.zip && 
unzip Dracula-icons.zip &&
mv dracula-icons-main ~/.icons/Dracula && 
rm -rf Dracula-icons.zip ;

# Install fonts
[ ! -d "$HOME/.local/share/fonts" ] && mkdir "$HOME/.local/share/fonts" ;
# IPAExGothic (Japanese)
sudo apt install -y fonts-ipaexfont-gothic
# Font Awesome
# curl -L0 https://github.com/FortAwesome/Font-Awesome/archive/refs/heads/master.zip --output Font-Awesome.zip &&
# unzip Font-Awesome.zip && 
# mv Font-Awesome-master/webfonts/*.ttf ~/.local/share/fonts/ &&
# mv Font-Awesome-master/otfs/*.otf ~/.local/share/fonts/ &&
# rm -rf Font-Awesome.zip &&
# rm -rf Font-Awesome-master ;
# Nerd Font
curl -L0 https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Overpass.zip --output NerdFonts.zip &&
unzip NerdFonts.zip &&
mv *.otf ~/.local/share/fonts/ && 
rm -rf NerdFonts.zip;

# Rofi Power menu
[ ! -d "$HOME/.local/bin" ] && mkdir "$HOME/.local/bin" ;
curl -L0 https://github.com/jluttine/rofi-power-menu/archive/refs/heads/master.zip --output rofi-power-menu.zip &&
unzip rofi-power-menu.zip &&
mv rofi-power-menu-master/rofi-power-menu ~/.local/bin/ &&
rm -rf rofi-power-menu-master &&
rm -rf rofi-power-menu.zip ;

# Personal dotfiles
[ -d "$HOME/.config/dunst" ] && rm -rf "$HOME/.config/dunst" ;
[ -d "$HOME/.config/i3" ] && rm -rf "$HOME/.config/i3" ;
[ -d "$HOME/.config/neofetch" ] && rm -rf "$HOME/.config/neofetch" ;
[ -d "$HOME/.config/polybar" ] && rm -rf "$HOME/.config/polybar" ;
[ -d "$HOME/.config/volumeicon" ] && rm -rf "$HOME/.config/volumeicon" ;
[ -d "$HOME/.local/share/aliases" ] && rm -rf "$HOME/.local/share/aliases" ;
[ -d "$HOME/.local/share/fonts" ] && rm -rf "$HOME/.local/share/fonts" ;
[ -d "$HOME/.local/share/polybar" ] && rm -rf "$HOME/.local/share/polybar" ;
[ -f "$HOME/.bashrc"] && rm -rf "$HOME/.bashrc" ;
git clone https://natperron@github.com/natperron/dotfiles.git &&
mv dotfiles/.config/* ~/.config/ && 
mv dotfiles/.bashrc ~/.bashrc && 
mv dotfiles/.local/share/* ~/.local/share/ ;