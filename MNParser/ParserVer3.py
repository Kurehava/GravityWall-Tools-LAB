import DLSourceCodeHtml
import re,os,string
import unicodedata
import random
import shutil

def HTMLParserAnalyze(url):
    sc=DLSourceCodeHtml.DLProcessingstring(url,"y")
    lencunt=0;record="";chkbox=""
    for cunt in range(len(sc)):
        if string.punctuation.count(sc[cunt])>0 or sc[cunt] == " ":
            chkbox=chkbox+sc[cunt]
            print(sc[cunt])
        elif sc[cunt].isalnum() or unicodedata.east_asian_width(sc[cunt]):
            record="".join([record,sc[cunt]])
            if not sc[cunt+1].isalnum():#上回修改到这里，这个if条件有问题，现在进行修改
                chkbox=chkbox+record
                print(record)
                record=""
        lencunt+=1
        if lencunt==len(sc):
            break

def HTMLParserAnalyzeHumanRead(url):
    sc=DLSourceCodeHtml.DLProcessingstring(url,"")
    chk2strsc=0;cutchg=0;flag=0;lencunt=0;record=""
    for cunt in range(len(sc)):
        if flag == 1:
            chk2strsc+=1
            flag=0
        cutchg=chk2strsc+cunt
        if sc[cutchg]=="<" and sc[cutchg+1]=="!":
            print("")
            print("Detected Comment Tag:"+sc[cutchg]+sc[cutchg+1])
            flag=1
        elif sc[cutchg]=="<" and sc[cutchg+1]!="/":
            print("")
            print("Detected Start Tag:"+sc[cutchg])
        elif sc[cutchg]=="<" and sc[cutchg+1]=="/":
            print("")
            print("Detected End Tag:"+sc[cutchg]+sc[cutchg+1])
            flag=1
        elif sc[cutchg]==">":
            print("")
            print("Detected Back Tag:"+sc[cutchg])
        else:
            #print(sc[cutchg],end='')
            record="".join([record,sc[cutchg]])
            if cutchg + 1 < len(sc):
                if sc[cutchg+1] == ">" or sc[cutchg+1] == "<":
                    print(record)
                    record=""
        if flag==0:
            lencunt+=1
        else:
            lencunt+=2
        if lencunt==len(sc):
            break

def HTMLParserAnalyzeOutput(url,fn):
    sc=DLSourceCodeHtml.DLProcessingstring(url,"")
    chk2strsc=0;cutchg=0;flag=0;lencunt=0;record=""
    fotp = open(fn+".txt","w+")
    for cunt in range(len(sc)):
        if flag == 1:
            chk2strsc+=1
            flag=0
        cutchg=chk2strsc+cunt
        if sc[cutchg]=="<" and sc[cutchg+1]=="!":
            fotp.write(sc[cutchg]+"\n")
        elif sc[cutchg]=="<" and sc[cutchg+1]!="/":
            fotp.write(sc[cutchg]+"\n")
        elif sc[cutchg]=="<" and sc[cutchg+1]=="/":
            fotp.write(sc[cutchg]+sc[cutchg+1]+"\n")
            flag=1
        elif sc[cutchg]==">":
            fotp.write(sc[cutchg]+"\n")
        else:
            #fotp.write(sc[cutchg],end='')
            record="".join([record,sc[cutchg]])
            if cutchg + 1 < len(sc):
                if sc[cutchg+1] == ">" or sc[cutchg+1] == "<":
                    fotp.write(record+"\n")
                    record=""
        if flag==0:
            lencunt+=1
        else:
            lencunt+=2
        if lencunt==len(sc):
            break
    fotp.close

def Script(url):
    for script in re.findall("<script.*?</script>",DLSourceCodeHtml.DLProcessingstring(url,"")):
      print(script+"\n")

def ScriptOutput(url,filename):
    try:
        if url[0:8].lower()=="https://" or url[0:7].lower()=="http://":domain=url.split("//")[0]+"//"+url.split("//")[1].split("/")[0]
        else:domain=url.split("/")[0]
        if url.split("/")[-1]=="":filepath="Data/"+domain.split("//")[1]+"/original/"
        else:filepath="Data/"+domain.split("//")[1]+"/"+url.split("/")[-1]+"/"
        if not os.path.exists(filepath):os.makedirs(filepath)
        else:
            while 1:
                inputchk=input("[\033[032mpick-\033[96m] 目标文件已存在，是否覆写？(Y/N)>>")
                if inputchk in {"y","Y",""}:break
                elif inputchk in {"n","N"}:return "exit"
                else :print("输入有误，请重新输入.");continue
        sourcefile=DLSourceCodeHtml.DLProcessingstring(url,"")
        if type(sourcefile) is str:
            for script in re.findall("<script.*?</script>",sourcefile):
                if filename=="":
                    filename=str.lower(''.join(random.sample(string.ascii_letters + string.digits, 32)))
                    with open (filepath+filename+".HPOscript","a+") as scriptwrite:scriptwrite.write(script+"\n")
                else:
                    with open (filepath+filename+".HPOscript","a+") as scriptwrite:scriptwrite.write(script+"\n")
                if script.count('src=')>=1:
                    if str(re.search('src=".*?"',script))!="None":
                        srcurl=re.search('src=".*?"',script).group().split("\"")[1]
                        if srcurl.split("/")[-1].count(".js")>=1:
                            fn=re.search('.*?.js',srcurl.split("/")[-1]).group()
                        elif len(srcurl.split("/")[-1]) > 15:
                                fn=srcurl.split("/")[-1][0:7]
                        else:fn=srcurl.split("/")[-1]
                        if srcurl[0:8]=="https://" or srcurl[0:7]=="http://":
                            DLSourceCodeHtml.DLJS(srcurl,filepath,fn)
                        elif srcurl[0:2]=="..":
                            DLSourceCodeHtml.DLJS(url.replace(url.split("/")[-1],"")+srcurl,filepath,fn)
                        elif srcurl[0:1]!="/":
                            DLSourceCodeHtml.DLJS(domain+"/"+srcurl,filepath,fn)
                        else:
                            DLSourceCodeHtml.DLJS(domain+srcurl,filepath,fn)
        else:
            try:
                os.removedirs(filepath)
            except:
                pass
            print("          \033[1;40;31m[WarnURL-]\033[96m::\033[93m",url,"\033[0;96m")
            print("          \033[1;40;31m[WarnINFO]\033[96m::\033[93m The return value is not string is .",type(sourcefile),"\033[0;96m")
    except BaseException as e:
        try:
            os.removedirs(filepath)
        except:
            pass
        sourcefile=DLSourceCodeHtml.DLProcessingstring(url,"")
        print("          \033[1;40;31m[WarnURL-]\033[96m::\033[93m",url,"\033[0;96m")
        print("          \033[1;40;31m[WarnTYPE]\033[96m::\033[93m",type(sourcefile),"\033[0;96m")
        if type(sourcefile) is str:
            print("          \033[1;40;31m[WarnSTR-]\033[96m::\033[93m",sourcefile[:100],"\033[0;96m")
        print("          \033[1;40;31m[WarnINFO]\033[96m::\033[93m",e,"\033[0;96m")
