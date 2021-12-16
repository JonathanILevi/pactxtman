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

### Example output of pactxtman

![shot](https://user-images.githubusercontent.com/35940342/146307209-6d2f2240-f016-49b3-88f8-967449d771ea.png)

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

# How it works

When pactxt man is executed or when `pacman.txt` changes (if `-w`) it runs its process. 

1. It gets a list of explicitly installed packages by running `pacman -Qe`  (Command can be configure with `--query`|`-q`.)
2. It parses the `pacman.txt` file (Configured with `--file`|`-f`.)
3. It calculates packages which should be installed or removed.
4. It prints a the `pacman.txt` with colored highlighting of packages which need to be installed/removed.
5. It executes `pacman -S` (or `yay`) for packages which need installed allowing pacman to request confirmation (unless running as a daemon or with `--noconfirm`).
7. It executes `pacman -R` for packages which are marked explicitly for removal (`!`, see above).
8. It executes `pacman -R` for packages which are installed but not listed (implicit removal).  If running as a daemon it will skip this step unless `--removeExtras`|`-e` is specified.
9. If `--watch`|`-w` or `--daemon`|`-d` it will watch for changes and repeat.

(Install & remove commands can be specified with `--pacman`|`-m` or `--install`|`i` and `--remove`|`r`.)

# Project

I am developing pactxtman because I wished to use it.  I am already using it now on my computer.  It should be noted that it is still in development and will have bugs, especially in areas I do not use directly myself.  The "More Elaborate Example" above is very close to what I am using myself.

The project source is super small, abiding by the UNIX philosofy (do one thing, and do it well).

If you want to add a feature, have at it!  Feel free to submit a pull request!

I hope to have an AUR package shortly.
