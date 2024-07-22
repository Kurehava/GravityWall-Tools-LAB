# DNS Server 構築について

## OS
* Ubuntu Server 22.04 LTS

## 環境構築
``` bash
sudo apt update -y 
sudo apt upgrade -y 
sudo apt autoremove -y
sudo apt install bind9 bind9-utils vim
```

## コマンド関連
* サービス関連：  
    `sudo systemctl <option> <service name>`  
    * `stop` : サービスを停止する
    * `start` : サービスを起動する
    * `status` : サービスの状況を見れる
    * `enable` : システムが起動するとき自動的にサービスを起動する
    * `restart` : サービスを再起動する

## ルート構造
* `o` は既存ファイル
* `+` は必要な追加ファイル
```
.
└── /etc/bind/
    ├── o named.conf
    ├── + named.conf.<zone name>
    ├── o named.options
    ├── + <your.domain.com>.lan
    ├── + db.193.3.10 (10.3.193.0)
    └── ....
```

## 設定手順
1. Zone設定ファイルをconfファイルに追加する  
    > `sudo vim named.conf`  
    最後に追加する  
    `include "/etc/bind/named.conf.<zone name>"` 

    Full File:
    ```ini
    include "/etc/bind/named.conf.options";
    include "/etc/bind/named.conf.local";
    include "/etc/bind/named.conf.default-zones";

    // 追加
    // include "/etc/bind/named.conf.<zone name>";
    include "/etc/bind/named.conf.zones";
    ```

2. 必要なオプションをOptionファイルに追加する  
    (ここからの編集はカンマが必要なので、絶対忘れないで！)  
    > `sudo vim named.conf.options`に設定を修正する  
    

    - まず、最初に`acl internal-network`を使って自分のセグメントを指定する　
        ```ini
        acl internal-network {
            192.168.50.0/24;
        };
        ```
        
    - 次に、`allow-query` （受付）を追加する
        ```ini
        allow-query {
            <DNSサーバーIP>;
            <デフォルトゲートウェイ>;
            internal-network;
        }
        ```
        <>で囲んでいる部分は任意で、もしインターネットに繋ぎたいでしたら、  
        `internal-network`を追加して方がいい
    
    - 最後に、`recursion`を追加して再起問い合わせを許可  
        `recursion yes;`
    
    Full File:
    ```ini
    // DNS鯖のIPセグメント（仮）
    // 192.168.3.0/24
    // DNS鯖のIPアドレス　（仮）
    // 192.168.3.254

    acl internal-network {
        192.168.3.0/24;
    };

    options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable 
        // nameservers, you probably want to use them as forwarders.  
        // Uncomment the following block, and insert the addresses replacing 
        // the all-0's placeholder.

        forwarders {
            8.8.8.8;
        };

        allow-query {
            192.168.3.254;
            internal-network;
        };

        recursion yes;

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;

        listen-on-v6 { any; };
    };
    ```

3. ドメインの設定ファイルを新規作成
    > `sudo vim named.conf.<zone name>`    
    ここの`zone name`は、手順１に追加した内容のzone nameと一致する方が理解しやすい

    ex. zone name
    
    `sudo vim named.conf.zones`

    ex. File:
    ```ini
    zone "<domain>" IN {
        type master;
        file "/etc/bind/<domain>.lan";
    };

    // 192.168.3.2/24 の場合：
    // セグメントは 192.168.3.0/24
    // zone ip : 192.168.3
    // reverse: 3.168.192
    zone "<zone ip>.in-addr.arpa" IN {
        type master;
        file "/etc/bind/db.<zone ip reverse>";
    };
    ```

    Full File:
    ```ini
    zone "test.com" IN {
        type master;
        // このファイルは次のステップでつくる
        file "/etc/bind/test.com.lan";
    };

    zone "192.168.3.in-addr.arpa" IN {
        type master;
        // このファイルは次のステップでつくる
        file "/etc/bind/db.3.168.192";
    };
    ```

4. \<domain name\>.lan ファイルの新規作成
    > `sudo vim <domain name>.lan`  
    このファイルは指定した`domain name`が正確に逆引きできるようにの設定ファイルである。

    ex. domain name
    > `sudo vim test.com.lan`

    Full File
    ```ini
    $TTL	86400
    @	IN	SOA	dns.test.com. root.test.com. (
        2			; Serial
        3600		; Refresh
        1800		; Retry
        604800		; Expire
        865400 )	; Negative Cache TTL
    ;
    @	IN	NS	dns.test.com.
    dns	IN	A	192.168.3.15
    ; ネットサービスが動いている鯖のIP
    www IN  A   192.168.3.10
    ;
    ```

5. db.\<zone IP reverse\> ファイルの新規作成
    > `sudo vim db.<zone IP reverse>`  
    このファイルは指定した`zone IP reverse`が正確に逆引きできるようにの設定ファイルである。

    ex. zone IP reverse
    > `sudo vim db.3.168.192`

    Full File
    ```ini
    ;
    ; BIND data file for local loopback interface
    ;
    $TTL	86400
    @	IN	SOA	dns.test.com. root.test.com. (
                2			; Serial
                3600		; Refresh
                1800		; Retry
                604800		; Expire
                865400 )	; Negative Cache TTL
    ;
    @	IN	NS	dns.test.com.
    15	IN	PTR	dns.test.com.
    10  IN  PTR www.test.com.
    ```

6. サービスの再起動  
    `sudo systemctl restart named`

7. サービスの状況  
    `sudo systemctl status named`
