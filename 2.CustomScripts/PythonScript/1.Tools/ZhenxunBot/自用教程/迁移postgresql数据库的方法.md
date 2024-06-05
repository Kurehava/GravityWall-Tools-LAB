# 基本指令

  1.```\l``` 查看所有数据库
  
  2.```\d``` 查看所有表
  
  3.```\c zhenxun``` 切换到名字为zhenxun的数据库(默认操作数据库为postgres)
  
  4.```\q``` 退出postgresql管理界面
  
  5.数据库操作命令不要忘记分号";"
  
  6.```sudo /etc/init.d/postgresql start```

# 导出数据库

  1.```sudo -u postgres psql```进入postgresql管理界面 
  
  2.如果OWNER为自己，则直接跳到第9步，否则执行第3步
  
  3.```ALTER DATABASE name OWNER TO new_owner;```修改OWNER为自己，name为数据库名，new_owner为自己(例如: root) 建议切换到root进行操作
  
  4.```\c zhenxun```跳转到zhenxun数据库
  
  5.```select 'ALTER TABLE ' || table_name || ' OWNER TO root;' from information_schema.tables where table_schema='public';```拼接所需要的命令
  
  6.将第5步生成的命令一行一行的复制黏贴执行
  
  7.确定数据库OWNER与所有表的OWNER都为自己
  
  8.```\q```退出管理界面
  
  9.```pg_dump -U 刚刚修改的用户名 -f zhenxun_database.sql zhenxun```导出数据库
  
  10.如果出现pg_dump的版本与postgresql的版本不一致的情况，找到你```psql```这个命令的目录，然后到这个目录下找到对应的pg_dump运行即可

# 将数据库复原到其他的服务器

  1.```sudo -u postgres psql``` 进入postgresql管理界面
  
  2.```DROP DATABASE zhenxun;``` 删除已有的zhenxun数据库
  
  3.```CREATE ROLE 自己的用户名(建议root) LOGIN CREATEDB CREATEROLE PASSWORD 'passwd';``` 创建自己用户的ROLE
  
  4.```CREATE DATABASE zhenxun OWNER root;``` 创建自己用户的zhenxun数据库
  
  5.```\q``` 退出管理界面
  
  6.```psql -d zhenxun -f zhenxun_database.sql``` 导入sql文件到刚刚重新建好的zhenxun数据库
  
  7.```sudo -u postgres psql``` 进入postgresql管理界面
  
  8.```ALTER DATABASE name OWNER TO new_owner;```修改OWNER为zhenxun，name为数据库名，new_owner为zhenxun
  
  9.```\c zhenxun```跳转到zhenxun数据库
  
  10.```select 'ALTER TABLE ' || table_name || ' OWNER TO zhenxun;' from information_schema.tables where table_schema='public';```拼接所需要的命令
  
  11.将第10步生成的命令一行一行的复制黏贴执行
  
  12.确定数据库OWNER与所有表的OWNER都为zhenxun
  
  13.```\q```退出管理界面
