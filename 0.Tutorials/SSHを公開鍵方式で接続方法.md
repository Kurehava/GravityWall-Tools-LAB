# SSHを公開鍵方式で接続する方法

## １．クライアント機器でキーペアを作成します
`ssh-keygen -t ed25519 -f <キーの保存先(フルパス+名前が必要)>`   
`e.g. ssh-keygen -t ed25519 -f save/path/USER01` 
上記のコマンドを使えば、指定したキーの保存先に、USER01(秘密鍵)とUSER01.pub(公開鍵)の両ファイルが生成されます。

## ２．公開鍵を目標サーバに追加する
1. scpコマンドなどの手段でクライアントが持っている公開鍵を目標サーバへ送信
2. 目標サーバで受信した公開鍵を ~/.ssh/authorized_keys に追加します

### - scpコマンド
`scp <公開鍵のフルパス> <サーバのユーザー名>@<サーバIPアドレス>:<サーバユーザーのホームディレクトリ>/.ssh/<指定した名前>.pub`  
`e.g. scp save/path/USER01.pub USER01@xxx.xxx.xxx.xxx:/home/USER01/.ssh/USER01.pub`  
`e.g. scp save/path/USER01.pub root@xxx.xxx.xxx.xxx:/root/.ssh/USER01.pub`

## ３．目標サーバの /etc/ssh/sshd_config ファイルを修正します
1. `#PubkeyAuthentication yes`のコメントアウトを解除します
2. `#AuthorizedKeysFile`のコメントアウトを解除します
3. `UsePAM yes`になっているかどうかを確認します

## ４．クライアントから接続
接続方法としては、二つあります。
* SSHコマンドで公開鍵ファイルを指定して接続していきます
* SSHのConfigファイルに予め設定を入れて、SSHホストネームで接続していきます

### - SSHコマンドで公開鍵ファイルを指定して接続
`ssh -i <秘密鍵のフルパス> <サーバのIP> -l <ユーザー名> -p <ポート番号>`  
`e.g. ssh -i save/path/USER01 xxx.xxx.xxx.xxx -l USER01 -p 22`

### - SSHのConfigファイルに予め設定を入れて、SSHホストネームで接続
Windows : C:\\Users\\<ユーザー名>\\.ssh\\config に以下の内容を修正してから追加してください。  
Linux : $HOME/.ssh/config に以下の内容を修正してから追加してください。　　
注意：ここでは、PUBファイルではないです。
```
Host <ホスト名(任意)>
  HostName <サーバのIPアドレス>
  User <接続するときのユーザー名>
  IdentityFile <秘密鍵のフルパス>
```
```
e.g.
Host USER01_SSH
  HostName xxx.xxx.xxx.xxx
  User USER01
  IdentityFile save/path/USER01 (not .pub file)
```
追加出来ましたら、以下のコマンドで接続できます。  
`ssh <ホスト名(任意)>`    
`e.g. ssh USER01_SSH`

## 終わり、お疲れ様です。


## (その他)自動でUSER01.pubを目標サーバに追加する方法
* \<USER01\>を<目標サーバへログインするユーザーのユーザー名>とします。  
* \<DIR\>を<目標サーバへログインするユーザーのホームディレクトリ>とします。 
* \<Server_IP\> を<目標サーバのIP>とします。
* \<xxx.pub\>を<１．に生成した.pubキーのルート(フルパス)>とします。  

```
> scp <xxx.pub> <USER01>@<Server_IP>:/<DIR>/.ssh/xxx.pub
> ssh <Server_IP> -l <USER01> -p 22 "cat <DIR>/.ssh/xxx.pub >> <DIR>/.ssh/authorized_keys && rm -rf <DIR>/.ssh/xxx.pub"
```

## (その他)自動で目標サーバの /etc/ssh/sshd_config ファイルを修正
```
> ssh <Server_IP> -l <USER01> -p 22 "sudo sed -i 's/#PubkeyAuthentication yes/#PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
> ssh <Server_IP> -l <USER01> -p 22 "sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config"
```
