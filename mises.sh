#!/bin/bash

echo -e "\031[0;33m"
echo " :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::";
echo "  Jangan lupa berdoa sebelum memulai !...                             ";
echo "  Twitter : https://twitter.com/dwentzart                             ";
echo "  Github  : https://github.com/Whalealert                             ";
echo "    -----------–------------------------------------                  ";
echo "         .........SEMOGA MEMBANTU ...........                         ";
echo " :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::";
echo -e "\e[0m"

sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
MISES_PORT=36
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export MISES_CHAIN_ID=mainnet" >> $HOME/.bash_profile
echo "export MISES_PORT=${MISES_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "moniker : \e[1m\e[32m$NODENAME\e[0m"
echo -e "wallet  : \e[1m\e[32m$WALLET\e[0m"
echo -e "chain-id: \e[1m\e[32m$MISES_CHAIN_ID\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
ver="1.19" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/mises-id/mises-tm/
cd mises-tm/
git checkout main
make build
make install


# config
misestmd config chain-id $MISES_CHAIN_ID
misestmd config keyring-backend test
misestmd config node tcp://localhost:${MISES_PORT}657

# init
misestmd init $NODENAME --chain-id $MISES_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.misestm/config/genesis.json "curl https://e1.mises.site:443/genesis | jq .result.genesis"

# set peers and seeds
PEERS=40a8318fa18fa9d900f4b0d967df7b1020689fa0@e1.mises.site:26656
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.misestm/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${MISES_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${MISES_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${MISES_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${MISES_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${MISES_PORT}660\"%" $HOME/.misestm/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${MISES_PORT}317\"%; s%^address = \":8080\"%address = \":${MISES_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${MISES_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${MISES_PORT}091\"%" $HOME/.misestm/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.misestm/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.misestm/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.misestm/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.misestm/config/app.toml

# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.000025umis\"/" $HOME/.misestm/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.misestm/config/config.toml

# reset
misestmd tendermint unsafe-reset-all --home $HOME/.misestm

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/misestmd.service > /dev/null <<EOF
[Unit]
Description=misestm
After=network-online.target

[Service]
User=$USER
ExecStart=$(which misestmd) start --home $HOME/.misestm
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable misestmd
sudo systemctl restart misestmd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u misestmd -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${MISES_PORT}657/status | jq .result.sync_info\e[0m"
