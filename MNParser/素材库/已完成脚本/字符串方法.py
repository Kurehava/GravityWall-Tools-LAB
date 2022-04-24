import getpass,os
#判定字符串中最后一个"/"右边的字符串是否包含"."
#split:以指定符号为分界线，把字符串分成n个部分,指定位置从0开始[0~n]or[-n]
#count:计算字符串中所匹配到指定字符串的个数
str1 = "weqw.wewew.ewew.ew/e/w.213"
print("str1:"+str(str1.split(".")))
print("str1[0]:"+str1.split(".")[0])
print("str1[-1]:"+str1.split(".")[-1])
if str1.split("/")[-1].count(".") > 0:
  print("yes")

#替换字符串中指定字符串
#replace:替换指定字符串 arg1:被替换字符串 arg2:替换字符串 arg3:最大替换次数
str2="213321312.3121321321.3213213213213.123"
print(str2.replace(".","_"))
print(str2.replace(".","_",2))

#判定字符串是否内包于其他字符串
#可用来判定字符串是否为指定字符
if "<>/".count(">")>0:
    print("neibao")
else:
    print("buneibao")

#判定是否为全角字符
#需要库 import unicodedata
#具体参考这个网页 https://water2litter.net/rum/post/python_unicodedata_east_asian_width/
import unicodedata
str="｜"
if unicodedata.east_asian_width(str):
  print("yes")
else:
    print("no")

#路径操作
#/home/oriki/Desktop/TexAutoCompile.py
sciuser=getpass.getuser()                               #获取当前用户名
scipath=os.path.dirname(os.path.abspath(__file__))+"/"  #获取不带文件名的绝对路径：/home/oriki/Desktop/
scifina=os.path.splitext(os.path.basename(__file__))[0] #获取不带后缀名的文件名  :TexAutoCompile
scibase=os.path.basename(os.path.abspath(__file__))     #获取带后缀名的文件名:TexAutoCompile.py