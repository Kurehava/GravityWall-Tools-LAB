import DLSourceCodeHtml
import string
import unicodedata
import re
import os

def analyze(url):
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
    #print(len(chkbox))
    #print(chkbox)
    #print(len(sc))
    #print(sc)

def analyzehumanread(url):
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

def analyzeoutput(url,fn):
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

def script(url,clean):
    sc=DLSourceCodeHtml.DLProcessingstring(url,"")
    cunt2c=0;flag=0;arr=[]
    for cunt in range(len(sc)):
        if sc[cunt:cunt+7]=="<script":
            if flag == 0:
                save2cunt=cunt;flag=1
        if sc[cunt:cunt+9]=="</script>":
            if clean!="y":
                arr.append(sc[save2cunt:save2cunt+cunt2c+9])
            else:
                arr.append(sc[save2cunt+8:save2cunt+cunt2c-1])
            flag=0;save2cunt=0;cunt2c=0
        if flag == 1:
            cunt2c+=1
    #print(arr)
    for arrlist in arr:
        print(arrlist)
    """ print(url)
    print(url.split('/')[2])
    print(url.split('/')[-1]) """
    """ scriptout = open("script"+url,"w+")
    scriptout.write(arr)
    scriptout.close """

def scriptout(url,fn):
    sc=DLSourceCodeHtml.DLProcessingstring(url,"")
    cunt2c=0;flag=0;arr=[]
    if url[0:8] == "https://" or url[0:7] == "http://":
        if url.split("/")[-1]=="":
            subdomain = "Data/"+url.split("//")[1].split("/")[0]+"/original/"
        else:
            subdomain = "Data/"+url.split("//")[1].split("/")[0]+"/"+url.split("/")[-1]+"/"
        domain = url.split("//")[0]+"//"+url.split("//")[1].split("/")[0]
    elif url.count(r"://") >= 1 and ( url.count(r"http://") <= 0 or url.count(r"https://") <= 0):
        print("error")
    else:
        if url.split("/")[-1]=="":
            subdomain = "Data/"+url.split("/")[0]+"/original/"
        else:
            subdomain = "Data/"+url.split("/")[0]+"/"+url.split("/")[-1]+"/"
        domain = url.split("/")[0]
    if not os.path.exists(subdomain):os.makedirs(subdomain)
    fotp = open(subdomain+"/"+fn+".txt","w+")
    for cunt in range(len(sc)):
        if sc[cunt:cunt+7]=="<script":
            if flag == 0:
                save2cunt=cunt;flag=1
        if sc[cunt:cunt+9]=="</script>":
            arr.append(sc[save2cunt:save2cunt+cunt2c+9])
            flag=0;save2cunt=0;cunt2c=0
        if flag == 1:
            cunt2c += 1
    for arrlist in arr:
        fotp.write(arrlist+"\n")
        if arrlist.count("src=") >= 1:
            suburl=re.search('src=".*"',arrlist).group().split("\"")[1]
            DLSourceCodeHtml.output(domain+suburl,subdomain,suburl.split("/")[-1])
    fotp.close
