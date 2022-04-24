import DLSourceCodeHtml
import re
import string
def analyze(url):
    sc=DLSourceCodeHtml.DL(url)
    chk2strsc=0;cutchg=0;flag=0;lencunt=0
    for cunt in range(len(sc)):
        if flag == 1:
            chk2strsc+=1
            flag=0
        cutchg=chk2strsc+cunt
        if sc[cutchg]=="<" and sc[cutchg+1]=="!":
            print("")
            print("Detected Comment Tag:"+sc[cutchg])
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
            print(sc[cutchg],end='')
        if flag==0:
            lencunt+=1
        else:
            lencunt+=2
        if lencunt==len(sc):
            break
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
    print(arr)
    """ print(url)
    print(url.split('/')[2])
    print(url.split('/')[-1]) """
    """ scriptout = open("script"+url,"w+")
    scriptout.write(arr)
    scriptout.close """