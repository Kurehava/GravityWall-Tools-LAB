# pgadmin4部署

  1.先到docker上下载ubuntu镜像和pgadmin4镜像
  
  2.用pgadmin4镜像创建容器pgadmin41(假设)
  
  3.编辑->高级设置->环境->新增
  
    PATH:PGADMIN DEFAULT_EMAIL     VALUE:mail_add
    
    PATH:PGADMIN DEFAULT PASSWORD  VALUE:passwd
  
  4.把443/80两个端口用本地端口转换
  
  5.去NAS设置里，外部访问->路由器配置->新增pgadmin41的端口外部开放
  
  6.返回docker控制台，进入pgadmin41的终端机
  
  7.因为这个镜像没有bash和zsh，只能在控制台用命令新建sh
  
  8.ifconfig确认ip
  
# 机器人部署
  
  1.用ubuntu镜像创建容器ubuntu1(假设)
  
  2.启动之前，编辑->高级设置->链接，新建刚刚创建的pgadmin41
  
  3.用一键部署脚本在ubuntu1上安装zhenxun_bot
  
  4.ping pgadmin4 的ip, 看是否通畅 ```ping pgadmin4ip```
  
  5.修改pg_hba.conf ```vim /etc/postgresql/12/main/pg_hba.conf```
  
  6.找到下面ip4的位置，把pgadmin41的ip地址添加到下面的信任列表，保存
  
  7.```sudo service postgresql restart``` 重启postgresql服务
  
  8.```netstat -ap``` 确认5432端口是否被postgresql占用
  
  9.```ifconfig``` 确认ubuntu的ip
 
# pgadmin4-web链接

  1.```设备ip:开放端口``` 登录pgadmin4
  
  2.右键左列Servers->Register->服务器
  
  3.General->
  
    名称:任意名称
  
  4.连接->
    
    主机名称/地址：ubuntu的ip
  
    端口：5432
  
    维护数据库：zhenxun
  
    用户名：zhenxun
  
    保存密码
  
    密码：zxpassword
  
  10.保存
