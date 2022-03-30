import time
import re
import os
import calendar
from platform import system

osname=system()
if osname == 'Windows':os.system("mode con cols=79 lines=20");clsswitch="cls"
elif osname == "Linux" or osname == "Darwin":os.system("printf '\033[8;20;79t'");clsswitch="clear"
print("Powered by nyarinto")

def Direct_cal():
    times=time.time()
    
    NOW_Physical_strength=input("当前体力：")
    while not re.findall('^[0-9]+$',NOW_Physical_strength):
        NOW_Physical_strength=input("当前体力(请只输入数字)：")
        
    FUL_Physical_strength=input("需预测体力：")
    while not re.findall('^[0-9]+$',FUL_Physical_strength):
        FUL_Physical_strength=input("需预测体力(请只输入数字)：")
        
    while int(FUL_Physical_strength) < int(NOW_Physical_strength):
        print("错误：需预测体力需要大于当前体力！")
        NOW_Physical_strength=input("当前体力：")
        while not re.findall('^[0-9]+$',NOW_Physical_strength):
            NOW_Physical_strength=input("当前体力(请只输入数字)：")
        FUL_Physical_strength=input("需预测体力：")
        while not re.findall('^[0-9]+$',FUL_Physical_strength):
            FUL_Physical_strength=input("需预测体力(请只输入数字)：") 
             
    TIME=(int(FUL_Physical_strength)-int(NOW_Physical_strength))*480
    print("\n预测时间：\033[93m\n",time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(times+TIME)),"\033[0m~\033[93m",time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(times+TIME+480)),"\033[0m")

def Indirect_cal():
    NOW_time=time.time()
    
    Target_date=input("目标日期时间(year-mouth-date-hour-minute-second):\n>> ").replace("-"," ")
    if len(Target_date) > 19:
        Target_date=""
        while not re.findall('^[0-9 ]+$',Target_date):
            Target_date=input("请输入目标日期(请输入正确的日期时间)：\n>> ").replace("-"," ")
    while not re.findall('^[0-9 ]+$',Target_date):
        Target_date=input("请输入目标日期(请只输入数字与横杠)：\n>> ").replace("-"," ")       
    while (int(Target_date.split(" ")[0]) < 2022) or (int(Target_date.split(" ")[1]) > 12) or (int(Target_date.split(" ")[2]) > 31) or (int(Target_date.split(" ")[3]) > 24) or (int(Target_date.split(" ")[4]) > 59) or (int(Target_date.split(" ")[5]) > 59):
         Target_date=input("请输入目标日期(请输入正确的日期和时间)：\n>> ").replace("-"," ")
    
    if Target_date.split(" ")[1] in {"02","2"}:
        if calendar.isleap(int(Target_date.split(" ")[0])) == True:
            #非闰年，29天
            if int(Target_date.split(" ")[2]) > 29:
                Target_date=""
                while not re.findall('^[0-9 ]+$',Target_date):
                    Target_date=input("请输入目标日期(请输入正确的2月份日期)：\n>> ").replace("-"," ")
        else:
            #非闰年，28天
            if int(Target_date.split(" ")[2]) > 28:
                Target_date=""
                while not re.findall('^[0-9 ]+$',Target_date):
                    Target_date=input("请输入目标日期(请输入正确的2月份日期)：\n>> ").replace("-"," ")
                
    while not (time.mktime(time.strptime(Target_date,"%Y %m %d %H %M %S")) > NOW_time):
        Target_date=input("请输入目标日期(请输入正确的日期时间格式)：\n>> ").replace("-"," ")
        
    Now_Physical_strength=input("当前体力(若需要预测时间超过21小时20分，请输入0):\n>> ").replace("-"," ")
    while not re.findall('^[0-9]+$',Now_Physical_strength):
        Now_Physical_strength=input("当前体力(请只输入数字)：\n>> ").replace("-"," ")
    
    TIMES=time.mktime(time.strptime(Target_date,"%Y %m %d %H %M %S"))-NOW_time-(160-int(Now_Physical_strength))*480
    
    print("")
    
    if TIMES > 0 and TIMES < 76800:
        print("按照预计您的体力值在%s满格\n在预定时间将会超过最大体力值 \033[93m%s\033[0m 点，请用掉这些体力\n然后从此时间开始计算到指定日期时间将会是满格体力。\n" % (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(NOW_time+(160-int(Now_Physical_strength))*480)),int(TIMES/480)))
    else:
        TIME=time.mktime(time.strptime(Target_date,"%Y %m %d %H %M %S"))-160*480
        print("体力满格前推计算时间为：\033[93m\n",time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(TIME)),"\033[0m")
        if TIMES < 76800:
            print("至目标时间时保有体力值：\033[93m\n",int((time.mktime(time.strptime(Target_date,"%Y %m %d %H %M %S"))-NOW_time)/480+int(Now_Physical_strength)),"\033[0m 点体力。")

while True:
    sec=input("1.预测体力满格时间\n2.体力满格前推计算时间\n>>")
    while not re.findall('^[0-9]+$',sec):
        sec=input("1.预测体力满格时间\n2.体力满格前推计算时间\n(请只输入数字)：\n>>")
    sec=int(sec)
    if sec==1:
        Direct_cal()
    elif sec==2:
        Indirect_cal()
    else:
        print("输入错误请重新输入。")
    
    secny=input("\n继续(Y),退出(N) >>")
    while not re.findall('^[NYny]+$',secny):
        secny=input("请输入正确的选项\n继续(Y),退出(N) >>")
    if secny in {"N","n"}:
        os._exit(0)
    print("\n")
    os.system(clsswitch)
