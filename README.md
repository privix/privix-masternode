# privix-masternode
A handy bash script to setup masternode in no time on a VPS with Ubuntu 16.04 x64.

***

## VPS installation for version **1.0.0.0**
```
wget -N https://raw.githubusercontent.com/privix/privix-masternode/master/masternode.sh && bash masternode.sh
```
***

## Desktop wallet setup

After the Masternode is up and running, you need to configure the desktop wallet accordingly. Here are the steps:
1. Open the privix Desktop Wallet.
2. Go to RECEIVE and create a New Address: **MN1**
3. Send **1000** VPX to **MN1**. You need to send all 1000 coins in one single transaction.
4. Wait for 16 confirmations.
5. Go to **Help -> "Debug Window - Console"**
6. Type the following command: **masternode outputs**
7. Go to  **Tools -> "Open Masternode Configuration File"**
8. Add the following entry:
```
Alias Address Privkey TxHash TxIndex
```
* Alias: **MN1**
* Address: **VPS_IP:PORT**
* Privkey: **Masternode Private Key**
* TxHash: **First value from Step 6**
* TxIndex:  **Second value from Step 6**
9. Save and close the file.
10. Go to **Masternode Tab**. If you tab is not shown, please enable it from: **Settings - Options - Wallet - Show Masternodes Tab**
11. Click **Update status** to see your node. If it is not shown, close the wallet and start it again. Make sure the wallet is unlocked.
12. Select your MN and click **Start Alias** to start it.
13. Alternatively, open **Debug Console** and type:
```
startmasternode "alias" "0" "MN1"
```
14. Login to your VPS and check your masternode status by running the following command to confirm your MN is running:
```
privix-cli masternode status
```
***

## Usage:
```
privix-cli masternode status
privix-cli getinfo
privix-cli mnsync status
```
Also, if you want to check/start/stop **privix**, run one of the following commands as **root**:

```
systemctl status privix #To check if privix service is running
systemctl start privix #To start privix service
systemctl stop privix #To stop privix service
systemctl is-enabled privix #To check if privix service is enabled on boot
```
