# 检查 sshd_config 文件是否存在
  
  ```/etc/ssh/sshd_config```
  
# 修改端口为自己想要的

  ```sudo sed -i 's:#Port 22:#Port 22\nPort 61731:g' /etc/ssh/sshd_config```
  
  启动或重启ssh服务
  
  >启动
  
  ```sudo /etc/init.d/ssh start```

  >重启

  ```sudo /etc/init.d/ssh restart```
