#!/bin/bash

set -e

COLOR='\033[1;33m'
NC='\033[0m'

echo -e "${COLOR}Installing pikaur${NC}"
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -si --noconfirm
cd ..
rm -rf pikaur

spotify_prompt=$(dialog --stdout --inputbox "Install Spotify(Y/N)? " 0 0 Y)
if [[ $spotify_prompt == "Y" ]]
then
	spotify_user=$(dialog --stdout --inputbox "Spotify username: " 0 0 email@domain.com)
	spotify_password=$(dialog --stdout --inputbox "Spotify password: " 0 0 password1337)
fi

pentest_prompt=$(dialog --stdout --inputbox "Install Pentesting tools(Y/N)? " 0 0 N)
virt_prompt=$(dialog --stdout --inputbox "Install Virt-manager(Y/N)? " 0 0 Y)

git_user=$(dialog --stdout --inputbox "Git username: " 0 0 GitUsername)
git_email=$(dialog --stdout --inputbox "Git contact email: " 0 0 email@domain.com)

git config --global user.name "$git_user"
git config --global user.email "$git_email"

if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
echo -e "${COLOR}Improving laptop battery${NC}"
echo -e "${COLOR}Enabling audio power saving${NC}"
sudo touch /etc/modprobe.d/audio_powersave.conf
sudo tee -a /etc/modprobe.d/audio_powersave.conf << EOF
options snd_hda_intel power_save=1
EOF

echo -e "${COLOR}Enabling wifi (iwlwifi) power saving${NC}"
sudo touch /etc/modprobe.d/iwlwifi.conf
sudo tee -a /etc/modprobe.d/iwlwifi.conf << EOF
options iwlwifi power_save=1
EOF

echo -e "${COLOR}Reducing VM writeback time${NC}"
sudo touch /etc/sysctl.d/dirty.conf
sudo tee -a /etc/sysctl.d/dirty.conf << EOF
vm.dirty_writeback_centisecs = 1500
EOF
fi

echo -e "${COLOR} Installing Rust${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo -e "${COLOR} Installing Go${NC}"
sudo pacman -S --noconfirm --needed go

echo -e "${COLOR}Installing packages:${NC}"
sudo pacman -S --noconfirm --needed rsync cronie lsof dmidecode rlwrap cmake clang polkit brightnessctl grc gimp jq yq resolvconf python-pip nodejs npm chromium firefox vlc udisks2 ffmpeg fzf slurp grim transmission-gtk libreoffice openvpn wireguard-tools docker docker-compose figlet signal-desktop rust-analyzer perl-image-exiftool

pikaur -S  --noconfirm --needed pfetch netdiscover xfce-polkit-git

cargo install bottom bat exa ripgrep

sudo usermod -aG docker $USER
sudo chmod u+s /usr/bin/brightnessctl

echo -e "${COLOR}Graphics${NC}"
sudo pacman -S --noconfirm --needed mesa intel-media-driver

echo -e "${COLOR}Sound${NC}"
sudo pacman -S --noconfirm --needed alsa-utils pulseaudio pulseaudio-alsa pavucontrol alsa-lib libogg libpulse

echo -e "${COLOR}Sway${NC}"
sudo pacman -S --noconfirm --needed sway swayidle swaybg wl-clipboard qt5-wayland glfw-wayland xorg-server-xwayland i3status-rust wofi
pikaur -S --noconfirm --needed swayshot wdisplays swaylock-effects-git

timezone=$(stat -c %N /etc/localtime | cut -d"/" -f7-8 | sed "s/'//")
escaped_timezone=$(printf '%s\n' "$timezone" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/Europe\/Helsinki/$escaped_timezone/g" $HOME/homedirs/dotfiles/sway/i3status.toml

ln -sf $HOME/homedirs/dotfiles/sway $HOME/.config/sway
ln -sf $HOME/homedirs/dotfiles/swayshot.sh $HOME/.config/swayshot
ln -sf $HOME/homedirs/dotfiles/wofi $HOME/.config/wofi

echo -e "${COLOR}Vim${NC}"
mkdir $HOME/.config/nvim
sudo npm install -g neovim
pip install wheel autopep8 pynvim jedi pylint flake8
ln -sf $HOME/homedirs/dotfiles/init.vim $HOME/.config/nvim/init.vim

echo -e "${COLOR}Fonts${NC}"
sudo pacman -S --noconfirm --needed noto-fonts noto-fonts-cjk noto-fonts-extra ttf-liberation ttf-dejavu ttf-roboto ttf-inconsolata ttf-font-awesome ttf-freefont ttf-droid powerline-fonts
pikaur -S --noconfirm --needed nerd-fonts-fira-code

echo -e "${COLOR}Ranger${NC}"
sudo pacman -S --noconfirm --needed ranger python-pillow
ranger --copy-config=all
git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons
ln -sf $HOME/homedirs/dotfiles/rc.conf $HOME/.config/ranger/rc.conf

echo -e "${COLOR}Kitty, zsh, powerlevel10k${NC}"
sudo pacman -S --noconfirm --needed kitty zsh-completions
mkdir $HOME/.config/kitty
ln -sf $HOME/homedirs/dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
ln -sf $HOME/homedirs/dotfiles/.zshrc $HOME/.zshrc

echo -e "${COLOR}Newsboat${NC}"
sudo pacman -S --noconfirm --needed newsboat
mkdir $HOME/.newsboat
ln -sf $HOME/homedirs/dotfiles/newsboat_urls $HOME/.newsboat/urls
ln -sf $HOME/homedirs/dotfiles/newsboat_config $HOME/.newsboat/config

echo -e "${COLOR}Zathura${NC}"
pikaur -S --noconfirm --needed zathura zathura-pdf-poppler
ln -sf $HOME/homedirs/dotfiles/zathura $HOME/.config/zathura

if [[ $spotify_prompt == "Y" ]]
then
	echo -e "${COLOR}Spotify-tui${NC}"
	mkdir $HOME/.config/spotifyd
	mkdir -p $HOME/.config/systemd/user
	sudo pacman -S --noconfirm --needed spotifyd
	cargo install spotify-tui
	sed -i "s/SPOTIFY_USER/$spotify_user/g" $HOME/homedirs/dotfiles/spotifyd.conf
	sed -i "s/SPOTIFY_PASSWORD/$spotify_password/g" $HOME/homedirs/dotfiles/spotifyd.conf
	ln -sf $HOME/homedirs/dotfiles/spotifyd.conf $HOME/.config/spotifyd/spotifyd.conf
	ln -sf $HOME/homedirs/dotfiles/spotifyd.service $HOME/.config/systemd/user/spotifyd.service
	systemctl --user enable --now spotifyd 
fi

if [[ $pentest_prompt == "Y" ]]
then
	echo -e "${COLOR}Pentesting tools${NC}"
	sudo pacman -S --noconfirm --needed wireshark-cli aircrack-ng nmap whois dkms macchanger
	pikaur -S --noconfirm --needed burpsuite rustscan
	go get github.com/gcla/termshark/v2/cmd/termshark
	sudo usermod -aG wireshark $USER
	mkdir $HOME/homedirs/pentest
	sudo systemctl enable --now docker.service
	git clone https://github.com/redcode-labs/Citadel.git $HOME/homedirs/pentest/citadel_scripts
	git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git $HOME/homedirs/pentest/peas
	git clone https://github.com/samratashok/nishang.git $HOME/homedirs/pentest/nishang
	git clone --depth 1 https://github.com/danielmiessler/SecLists.git $HOME/homedirs/pentest/SecLists
	git clone https://github.com/oliverwiegers/pentest_lab $HOME/homedirs/pentest/pentest_lab
	sudo docker pull aaaguirrep/offensive-docker
	sudo docker pull bettercap/bettercap
fi

if [[ $virt_prompt == "Y" ]]
then
	echo -e "${COLOR}Virt-manager${NC}"
	sudo pacman -S --noconfirm --needed virt-manager libvirt qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2
	sudo systemctl enable --now libvirtd
	sudo virsh net-define $HOME/homedirs/dotfiles/net/br10.xml
	sudo virsh net-start br10
	sudo virsh net-autostart br10
fi

echo -e "${COLOR}Crypto and stonks${NC}"
go get github.com/miguelmota/cointop
mkdir $HOME/.config/tickrs
cargo install tickrs
ln -sf $HOME/homedirs/dotfiles/tickrs.yml $HOME/.config/tickrs/config.yml

echo -e "${COLOR}Taskwarrior${NC}"
sudo pacman -S --noconfirm --needed task
sed -i "s/fomalhaut/$USER/g" $HOME/homedirs/dotfiles/taskwarrior/.taskrc
ln -sf $HOME/homedirs/dotfiles/taskwarrior/.taskrc $HOME/.taskrc

echo -e "${COLOR}Reddit and telegram tui${NC}"
sudo pacman -S --needed --noconfirm feh urlscan youtube-dl mpv
pip install ttrv tg
ln -sf $HOME/homedirs/dotfiles/mailcap $HOME/.mailcap
ln -sf $HOME/homedirs/dotfiles/ttrv $HOME/.config/ttrv
ln -sf $HOME/homedirs/dotfiles/feh $HOME/.config/feh
mkdir $HOME/.config/tg
ln -sf $HOME/homedirs/dotfiles/tg_conf.py $HOME/.config/tg/conf.py

echo -e "${COLOR}Installing and configuring UFW${NC}"
sudo pacman -S --noconfirm ufw
sudo systemctl enable ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow docker
sudo ufw allow transmission
sudo ufw enable

echo -e "${COLOR}Rest of the config${NC}"
mkdir $HOME/applications
mkdir $HOME/bin
curl https://cht.sh/:cht.sh > ~/bin/cht.sh
chmod +x ~/bin/cht.sh
ln -sf $HOME/homedirs/dotfiles/bat $HOME/.config/bat
sudo ln -sf $HOME/homedirs/dotfiles/environment /etc/environment

rm -rf $HOME/homedirs/dotfiles/.git

echo -e "${COLOR}Done${NC}"
