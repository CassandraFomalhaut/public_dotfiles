```
                                   ___          ____
                               ,-""   `.      < HONK >
                             ,'  _   e )`-._ /  ----
                            /  ,' `-._<.===-'
                           /  /
                          /  ;
              _          /   ;
 (`._    _.-"" ""--..__,'    |
 <_  `-""                     \
  <`-                          :
   (__   <__.                  ;
     `-.   '-.__.      _.'    /
        \      `-.__,-'    _,'
         `._    ,    /__,-'
            ""._\__,'< <____
                 | |  `----.`.
                 | |        \ `.
                 ; |___      \-``
                 \   --<
                  `.`.<
                    `-'
```
---
* WM: Sway
* Bar: i3status-rust
* Shell: zsh
* Term: kitty
* Editor: Neovim
* File manager: Ranger
* Font: Fira Code Nerd Font
* PDF reader: Zathura
* RSS reader: Newsboat
* TUI: ttrv (reddit), tg (telegram), cointop (crypto), tickrs (stonks), bottom (top), spotify-tui

---

Includes install and config scripts. Intended for XPS 9380 but likely to work with some modifications on most intel x86 machines, refer to: https://wiki.archlinux.org/title/Category:Laptops

!! Please examine them before running. This is not meant to be a full fledged installer but rather a convenience script for myself.

1. Boot from arch iso  
2. Download and run install script  
```
curl -LO https://raw.githubusercontent.com/CassandraFomalhaut/public_dotfiles/master/arch_install.sh  
chmod +x ./arch_install.sh
./arch_install.sh
```
4. Reboot  
5. Login with user, clone dotfiles, run config script  
```
git clone https://github.com/CassandraFomalhaut/public_dotfiles.git $HOME/homedirs/dotfiles
cd homedirs/dotfiles
./arch_config.sh
```

---
After running both scripts, open vim to automatically install plugins, then run ':CocInstall <modules>':  
e.g. `:CocInstall coc-python coc-rust-analyzer coc-sh coc-json coc-clangd`  

Run `swaymsg -t get_inputs` to get touchpad identifier (and `swaymsg -t get_outputs` for displays) and adjust sway/config.  

Blacklist psmouse device (XPS9380):  
`echo 'blacklist psmouse' > /etc/modprobe.d/psmouse-disable.conf`  
then regenerate grub:  
`sudo grub-mkconfig -o /boot/grub/grub.cfg`

Firefox addons, theme ('Gruvbox Dark' by 'calvinchd'), and bookmarks are managed via Firefox Account.  
Dark mode via 'DarkReader' addon.  

Stop WebRTC leaks:  
Open `about:config` and set `false` to `media.peerconnection.enabled`  

To use custom dns configure `/etc/resolv.conf` and prevent other services from overwriting it:  
`sudo chattr +i /etc/resolv.conf`  

---
##### Screenshots:  

![1](/img/screenshots/vim.png?raw=true)
![2](/img/screenshots/stonks.png?raw=true)
![3](/img/screenshots/zathura_wallpaper.png?raw=true)
![4](/img/screenshots/wofi.png?raw=true)
![5](/img/screenshots/ussr.png?raw=true)
![6](/img/screenshots/newsboat_spotify.png?raw=true)

---
I'm planning to improve both the setup and the scripts at some point, your feedback is very appreciated.  

Whoever is reading this, I hope you have a wonderful day (づ｡◕‿‿◕｡)づ
