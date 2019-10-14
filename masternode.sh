#!/bin/bash

COIN_NAME='privix'
TMP_FOLDER=$(mktemp -d)
CONFIG_FILE="${COIN_NAME}.conf"
CONFIGFOLDER='/root/.privix'
COIN_DAEMON="${COIN_NAME}d"
COIN_CLI="${COIN_NAME}-cli"
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/privix/privix-core/releases/download/v2.0.0.1/privix-2.0.0.1-ubuntu1604.tar.gz'
COIN_BLOCKS='https://github.com/privix/privix-core/releases/download/v2.0.0.1/bootstrap.zip'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_PORT=7788
RPC_PORT=7789

NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function sync_node() {
  cd $CONFIGFOLDER
  rm -r {peers.dat,chainstate,blocks}
  wget -q $COIN_BLOCKS -O bootstrap.zip
  unzip -q bootstrap.zip
  rm -r bootstrap.zip
  cd - >/dev/null 2>&1
}

function download_node() {
  echo -e "Preparing to download ${GREEN}$COIN_NAME${NC}."
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvzf $COIN_ZIP -C $COIN_PATH >/dev/null 2>&1
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}


function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
debug=0
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
# Privix VPX addnodes (https://explorer.masternodes.online/currencies/VPX/)
addnode=104.238.128.174:7788
addnode=136.244.85.91:7788
addnode=140.82.0.81:49220
addnode=140.82.50.81:39284
addnode=140.82.50.81:39354
addnode=140.82.50.81:39378
addnode=140.82.50.81:42694
addnode=140.82.50.81:57916
addnode=140.82.50.81:58424
addnode=140.82.50.81:58470
addnode=144.202.111.125:44858
addnode=144.202.111.125:45040
addnode=144.202.111.125:45064
addnode=144.202.111.125:49192
addnode=144.202.111.125:49206
addnode=144.202.111.125:49582
addnode=144.202.111.125:51326
addnode=144.202.111.125:51344
addnode=144.202.111.125:51552
addnode=144.202.111.125:56038
addnode=144.202.111.125:56146
addnode=144.202.111.125:56232
addnode=144.202.111.125:56322
addnode=144.202.17.166:37234
addnode=144.202.80.225:7788
addnode=149.28.195.252:35272
addnode=149.28.195.252:40656
addnode=149.28.195.252:42286
addnode=149.28.195.252:51046
addnode=149.28.195.252:51060
addnode=149.28.195.252:51098
addnode=149.28.195.252:7788
addnode=149.28.203.230:56170
addnode=149.28.203.230:58592
addnode=165.22.70.82:7788
addnode=165.227.31.115:33384
addnode=167.71.121.100:7788
addnode=167.86.89.63:7788
addnode=188.166.162.7:7788
addnode=207.154.240.169:7788
addnode=209.250.243.35:7788
addnode=45.32.133.67:37348
addnode=45.32.133.67:40898
addnode=45.32.133.67:40900
addnode=45.32.133.67:43400
addnode=45.32.133.67:47702
addnode=45.32.133.67:47712
addnode=45.32.148.173:53680
addnode=45.63.85.68:39764
addnode=45.63.85.68:39940
addnode=45.63.85.68:58250
addnode=45.63.85.68:58604
addnode=45.63.85.68:7788
addnode=45.76.139.144:7788
addnode=45.77.0.241:33396
addnode=45.77.0.241:33420
addnode=45.77.0.241:33424
addnode=45.77.0.241:34088
addnode=45.77.0.241:35100
addnode=45.77.0.241:35116
addnode=45.77.0.241:43696
addnode=45.77.1.164:39438
addnode=45.77.1.164:52638
addnode=45.77.1.164:7788
addnode=78.141.209.38:7788
addnode=8.9.11.178:7788
addnode=84.17.53.82:59341
addnode=93.174.24.133:25392
addnode=95.179.166.75:7788
addnode=95.179.188.94:45760
EOF
}


function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}


function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 14.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl unzip libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libzmq3-dev libevent-dev >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl unzip libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libzmq3-dev libevent-dev"
 exit 1
fi
clear
}

function important_information() {
  echo -e "================================================================================================================================"
  echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
  echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
  echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
  echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
  echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
  echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
  echo -e "Please check ${RED}$COIN_NAME${NC} daemon is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
  echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
  if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${RED}Sentinel${NC} is installed in ${RED}$CONFIGFOLDER/sentinel${NC}"
  echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
  fi
  echo -e "================================================================================================================================"
}

function setup_node() {
  get_ip
  create_config
  sync_node
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}


##### Main #####
clear

checks
prepare_system
download_node
setup_node
