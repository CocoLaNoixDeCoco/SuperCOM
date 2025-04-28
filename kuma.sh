#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   __  __      __  _                   __ __                     
  / / / /___  / /_(_)___ ___  ___     / //_/_  ______ ___  ____ _
 / / / / __ \/ __/ / __  __ \/ _ \   / ,< / / / / __  __ \/ __  /
/ /_/ / /_/ / /_/ / / / / / /  __/  / /| / /_/ / / / / / / /_/ / 
\____/ .___/\__/_/_/ /_/ /_/\___/  /_/ |_\__,_/_/ /_/ /_/\__,_/  
    /_/                                                          
 
EOF
}
header_info
echo -e "Loading..."
APP="Uptime Kuma Beta 2.0"
var_disk="4"
var_cpu="1"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /opt/uptime-kuma ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
BETA_VERSION="2.0.0-beta.2"
msg_info "Stopping ${APP}"
sudo systemctl stop uptime-kuma &>/dev/null
msg_ok "Stopped ${APP}"

cd /opt/uptime-kuma

msg_info "Pulling ${APP} ${BETA_VERSION}"
git fetch --all &>/dev/null
git checkout ${BETA_VERSION} --force &>/dev/null
msg_ok "Pulled ${APP} ${BETA_VERSION}"

msg_info "Updating ${APP} to ${BETA_VERSION}"
npm install --production &>/dev/null
npm run download-dist &>/dev/null
msg_ok "Updated ${APP}"

msg_info "Starting ${APP}"
sudo systemctl start uptime-kuma &>/dev/null
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

function install_script() {
  msg_info "Installing Dependencies"
  $STD apt-get update
  $STD apt-get -y install \
    curl \
    sudo \
    unzip \
    git
  msg_ok "Installed Dependencies"

  msg_info "Setting up Node.js Repository"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &>/dev/null
  msg_ok "Set up Node.js Repository"

  msg_info "Installing Node.js"
  $STD apt-get install -y nodejs
  msg_ok "Installed Node.js"

  msg_info "Creating User Account"
  useradd -m -s /bin/bash kuma
  msg_ok "Created User Account"

  msg_info "Installing ${APP}"
  mkdir -p /opt/uptime-kuma
  cd /opt/uptime-kuma
  git clone https://github.com/louislam/uptime-kuma.git . &>/dev/null
  BETA_VERSION="2.0.0-beta.2"
  git checkout ${BETA_VERSION} --force &>/dev/null
  npm install --production &>/dev/null
  npm run download-dist &>/dev/null
  chown -R kuma:kuma /opt/uptime-kuma
  msg_ok "Installed ${APP}"

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/uptime-kuma.service
[Unit]
Description=Uptime Kuma
After=network.target

[Service]
Type=simple
User=kuma
WorkingDirectory=/opt/uptime-kuma
ExecStart=/usr/bin/node /opt/uptime-kuma/server/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now uptime-kuma &>/dev/null
  msg_ok "Created Service"
}

start
build_container
description
install_script

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3001${CL} \n"
