# pactxtman
Deterministic; Textfile based Package Manager.  Primarily for Arch pacman or yay.

Install & remove packages using a user-friendly package list file.

## Example `pacman.txt`

### Basic

```
# CORE
base linux linux-firmware
sudo make gcc
# GUI
sway swayidle swaylock dmenu
# APPS
xterm
firefox vlc
```

Packages are simply whitespace separated.  `#` are comments.

### More Elaborate

```
: System
        base linux linux-firmware
        : GUI
                : Sway # Cuz sway is the best!
                        sway swayidle swaylock
                        xorg-xwayland
                        dmenu
                xorg-xrdb qt5ct
        xterm
        : Audio
                # Modern pipewire instead of pulseaudio!
                pipewire pipewire-alsa pipewire-pulse
                alsa-utils pavucontrol
                helvum easyeffects
        : Internet
                wpa_supplicant dhcpcd
        : Tools
                : Core
                        zip unzip wget
                        patch
                        sudo inotify-tools
                nano nano-syntax-highlighting
                : Dev
                        git make gcc
                        dmd dub clang
        : Pkgs
                yay-git
        fakeroot


: Media
        vlc mpv
        : Games
                steam

: Dev
        textadept vscode

: Terminal
        !xterm
        kitty

: Web
        firefox
        !chromium
        vivaldi
```

Lines which begin with `:` are groups.  Groups are merely symbolic help in organizing the packages.  Groups use tab indentation and are nestable.

# How to use it

## As a daemon

When running as a root daemon.  Your install process is: `sudo nano /etc/pacman.txt`, add a package name, and save.  Pactxtman will automagially install the added package.  (todo: implement `pactxtman -S [package(s)]` which will add the packages to the end of `pacman.txt` to be organized later.)

When running as a daemon, saving the file will automagically trigger pactxtman to install missing packages.

Run as root: `pactxtman --daemon --removeExtras`.  (todo: implement as a SystemD service!)

`--daemon`|`-d` tells pactxtman to watch the file for changes and run pacman with `--noconfirm`. `--removeExtras`|`-e` will have pactxtman remove installed packages which are not listed (The alternative is to explicitly mark for removal with `!`, for example `!xterm`|`!chromium`.).

<b>When running as a root daemon `pacman.txt` should only have root write permitions!</b>

## As a user daemon

Not tecnically a daemon... if you run pactxtman in a terminal, then anytime you edit `pacman.txt` you can go the that terminal to enter your password.

Run with `pactxtman --daemon --file ~/.config/pactxtman/pactxtman.txt --pacman "sudo pacman --noconfirm` (todo: When running as a user `--file` should default to `~/.config` and pacman should use sudo by default.)

## Run explicitly.

Whenever you change `pacman.txt` run pactxtman explicitly.

# Project

I am developing pactxtman because I wished to use it.  I am already using it now on my computer.  It should be noted that it is still in development and will have bugs, especially in areas I do not use directly myself.  The "More Elaborate Example" above is very close to what I am using myself.

The project source is super small, abiding by the UNIX philosofy (do one thing, and do it well).  The project is currently only two files, one of which is a library for command line argument parsing.  As such, the project remains very hackable.  The small size of the source does not deminish the worth of the project!

If you want to add a feature, or port it for use with another package manager, have at it!  And feel free to submit a pull request!

I hope to have an AUR package shortly.
