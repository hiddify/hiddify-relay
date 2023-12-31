<base target="_blank">

<div dir="ltr">



[**![Lang_farsi](https://user-images.githubusercontent.com/125398461/234186932-52f1fa82-52c6-417f-8b37-08fe9250a55f.png) &nbsp;فارسی**](README_fa.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</div>
<br>
<div align=center markdown="1">
 

![Hiddify Logo](https://user-images.githubusercontent.com/125398461/227777845-a4d0f86b-faa2-4f2b-a410-4aa5f68bfe19.png)

</div>

# Hiddify Relay builder
This script provides you with the following methods to create a tunnel between a relay server and your main server.

`1. IP Tables`

`2. GOST`

`3. Xray-Dokodemo`

`4. HA-Proxy`

`5. Socat`

## ⚙️ Installation
In order to create tunnels on your relay server, you just need to run the following command.

```
bash -c "$(curl -L https://raw.githubusercontent.com/hiddify/hiddify-relay/main/install.sh)"
```
<div align=center>

 <img src="https://github.com/hiddify/hiddify-relay/assets/125398461/50bc6374-56b4-4eba-866e-c006e123435f" alt="Relay-builder Menu" width=30% />
</div>

### 🛠️IP-Tables Tunnel
According to the picture above, choose number `1` and enter the `IPTables menu`:

<div align=center>

 ![IP-Tables Tunnel Menu](https://github.com/hiddify/hiddify-relay/assets/125398461/ddd9cf12-3d5c-4aab-9b36-278395c3cbfb)
 
</div>

`1. Install iptables rules`

After selecting the number `1` in the `IPTables Menu`, it asks you to enter the IP address of the main server and press `Enter` button to activate the tunnel on ports `443` and `80`.

`2. Check ports in use`
This option shows you the ports used in the IPTables tunnel

`3. Uninstall iptables rules`
This option clears all rules created for the tunnel and all other rules.

> [!NOTE]
> Be careful that if you have created special rules next to the tunnel manually, they will be deleted with this command.

`4. Back to Main Menu`
in order to go back to the main menu press `4`




<div align=center>

<br>

[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=mail.ru)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![Twitter](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=twitter&logoColor=1DA1F2&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

</div>

<p align=center>
 We appreciate all people who are participating in this project. Some people here and many many more outside of Github. It means a lot to us. ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-relay/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-relay" />
</a>
</p>
<p align=center>
 Made with <a rel="" target="_blank" href="https://contrib.rocks">Contrib.Rocks</a> 
</p>
