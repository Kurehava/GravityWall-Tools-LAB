# WSL 固定IPの設定方法

## １．Hyper-V
1. Hyper-Vをインストールします（追加機能で）
2. 再起動します
3. Hyper-Vマネージャーを起動して、右側のメニューから仮想スイッチマネージャーをクリック
4. 仮想スイッチのゾーンに新しい仮想ネットワークスイッチをクリックして、右で外部をクリックして、仮想スイッチの作成をクリック
5. 作った仮想スイッチの名前を入力し、接続の種類を外部ネットワークにして、インタフェースを仮想スイッチが接続予定のインタフェースを選んで、OK

## ２．.wslconfig
$HOME に .wslconfig を一個新規作成して、以下の内容を追加してください。
```
[wsl2]
networkingmode=bridged
vmSwitch=<１．に追加した仮想スイッチの名前>
dhcp=False
```

## ３．WSL Linux 環境の設定
以下のコマンドの順番でIPアドレスをセッティングしてください。
```
ip addr del <now_ip>/<now_netmask> dev <interface_name>
sudo ip l set <interface_name> up
sudo ip address add <ubuntu_ip>/<netmask> broadcast <default_gateway> dev <interface_name>
```

## 終わり、お疲れ様でした。