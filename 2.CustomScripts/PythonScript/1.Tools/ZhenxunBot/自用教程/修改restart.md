# restart在代码中定义位置

  ```zhenxun_bot/plugins/check_zhenxun_update/__init__.py```
  
  84行
  
# 自动检测重启完毕

  在重启脚本最后加上
  
  ```touch ${WORK_DIR}/zhenxun_bot/is_restart```
