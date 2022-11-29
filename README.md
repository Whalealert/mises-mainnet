<p align="center">
  <img width="300" height="auto" src="https://user-images.githubusercontent.com/108969749/203468600-bd337c5d-70b2-46bd-8a56-bcc001a447db.jpeg">
</p>


<b>[Mises Explorer](https://explorer.whalealertid.xyz)
 <> [Guide Official](https://https://www.mises.site/validator)
</b>
### Spesifikasi Hardware :
NODE  | CPU     | RAM      | SSD     |
| ------------- | ------------- | ------------- | -------- |
| Mainnet | 4          | 32         | 1TB  |

### Install otomatis
```
wget -O mises.sh https://raw.githubusercontent.com/Whalealert/mises-mainnet/main/mises.sh && chmod +x mises.sh && ./mises.sh
```
### Load variable ke system
```
source $HOME/.bash_profile
```
### Statesync

```
sudo systemctl stop misestmd

cp $HOME/.misestm/data/priv_validator_state.json $HOME/.misestm/priv_validator_state.json.backup
misestmd tendermint unsafe-reset-all --home $HOME/.misestm --keep-addr-book
SNAP_RPC="https://e1.mises.site:443,rpc.gw.mises.site:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.misestm/config/config.toml

mv $HOME/.misestm/priv_validator_state.json.backup $HOME/.misestm/data/priv_validator_state.json
sudo systemctl restart misestmd && sudo journalctl -u misestmd -f --no-hostname -o cat
```
### Informasi node

   * cek sync node
```
misestmd status 2>&1 | jq .SyncInfo
```
   * cek log node
```
journalctl -fu misestmd -o cat
```
   * cek node info
```
misestmd status 2>&1 | jq .NodeInfo
```
   * cek validator info
```
misestmd status 2>&1 | jq .ValidatorInfo
```
  * cek node id
```
misestmd tendermint show-node-id
```

### Membuat wallet
   * wallet baru
```
misestmd keys add $WALLET
```
   * recover wallet
```
misestmd keys add $WALLET --recover
```
   * list wallet
```
misestmd keys list
```
   * hapus wallet
```
misestmd keys delete $WALLET
```
### Simpan informasi wallet
```
MISES_WALLET_ADDRESS=$(misestmd keys show $WALLET -a)
MISES_VALOPER_ADDRESS=$(misestmd keys show $WALLET --bech val -a)
echo 'export MISES_WALLET_ADDRESS='${MISES_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export MISES_VALOPER_ADDRESS='${MISES_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Membuat validator
 * cek balance
```
misestmd query bank balances $MISES_WALLET_ADDRESS
```
 * membuat validator
```
misestmd tx staking create-validator \
  --amount 1000000umis \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.07" \
  --min-self-delegation "1" \
  --pubkey  $(misestmd tendermint show-validator) \
  --moniker $NODENAME \
  --fees 250umis \
  --chain-id $MISES_CHAIN_ID
```
 * edit validator
```
misestmd tx staking edit-validator \
  --moniker="nama-node" \
  --identity="<your_keybase_id>" \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$MISES_CHAIN_ID \
  --fees 250umis \
  --from=$WALLET
```
 ° unjail validator
```
misestmd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$MISES_CHAIN_ID \
  --fees=250umis
```
### Voting
```
misestmd tx gov vote 1 yes --from $WALLET --chain-id=$MISES_CHAIN_ID --fees=250umis
```
### Delegasi dan Rewards
  * delegasi
```
misestmd tx staking delegate $MISES_VALOPER_ADDRESS 1000000umis --from=$WALLET --chain-id=$MISES_CHAIN_ID --fees=250umis
```
  * withdraw reward
```
misestmd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$MISES_CHAIN_ID --fees=250umis
```
  * withdraw reward beserta komisi
```
misestmd tx distribution withdraw-rewards $MISES_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$MISES_CHAIN_ID --fees=250umis
```

### Hapus node
```
sudo systemctl stop misestmd && \
sudo systemctl disable misestmd && \
rm /etc/systemd/system/misestmd.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf mises-tm && \
rm -rf mises.sh && \
rm -rf .misestm && \
rm -rf $(which misestmd)
```
