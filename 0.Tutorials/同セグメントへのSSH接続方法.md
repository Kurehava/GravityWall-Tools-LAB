# 同セグメントへのSSH接続方法
1. VPNに繋いで二番目のIPセグメントを持つようにします
2. ipconfig /all でCATOから振り分けたIPアドレス(VPNIP)を確認します
3. route add <接続先> mask 255.255.255.255 \<VPNIP\>
4. route print で<接続先>と\<VPNIP\>のペアのメトリックが1になっていることを確認します
5. sshで普通に接続してください
6. route delete <接続先> で一時ルート情報を削除します
7. この設定を永続として設定することがおすすめしません
7. 完了
