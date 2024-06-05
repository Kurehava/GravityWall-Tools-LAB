#!/usr/bin/env python3
####################################################################################
#TexliveAutoCompile LastVersion 0.9.5 new ver for shellscript refactored to python #
#Powered by orikiringi Belonging to KanagawaUniversity MoritaLab                   #
#Github:https://github.com/Kurehava                                                #
#Affiliated with the GravityWallToolsDevelopmentLAB Project                        #
####################################################################################
import os,platform,getpass,time,re,sys,subprocess
err=0;navichk=1;abspath=relpath=osname=relname=namepath=""
osname=platform.system()
if osname == 'Windows':os.system("mode con cols=80 lines=20");clearswich="cls"
elif osname == "Linux" or osname == "Darwin":os.system("printf '\033[8;20;80t'");clearswich="clear";#os.system("while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-40));date;tput rc;done&")
if osname in {"Linux","Darwin"}:
    hispath=str(subprocess.Popen("echo ~",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].split("\\")[0]+"/.tachistory.his"
    hisnpath=str(subprocess.Popen("echo ~",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].split("\\")[0]+"/.tachistory.hisn"
    homepath=str(subprocess.Popen("echo ~",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].split("\\")[0]
elif osname == "Windows":
    hispath="c:/Users/"+str(subprocess.Popen("whoami",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].replace(r"\n","").replace(r"\r","").split(r"\\")[1]+"/.tachistory.his"
    hisnpath="c:/Users/"+str(subprocess.Popen("whoami",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].replace(r"\n","").replace(r"\r","").split(r"\\")[1]+"/.tachistory.hisn"
    homepath="c:/Users/"+str(subprocess.Popen("whoami",stdout=subprocess.PIPE,shell=True).communicate()).split(",")[0].split("'")[1].replace(r"\n","").replace(r"\r","").split(r"\\")[1]
sciuser=getpass.getuser()
scipath=os.path.dirname(os.path.abspath(__file__))+"/"
#relname=os.path.splitext(os.path.basename(__file__))[0]
rope="------------------------------------------"
banner=(
    "\033[41;30mTAC-Python Ver 0.9.3 powered by oriki\033[0;96m\n\033[33m"
    "=============================================================================\n"
    "  _____             _         _         ____                      _ _        \n"
    " |_   _|____  __   / \  _   _| |_ ___  / ___|___  _ __ ___  _ __ (_) | ___   \n"
    "   | |/ _ \ \/ /  / _ \| | | | __/ _ \| |   / _ \| '_ ' _ \| '_ \| | |/ _ |  \n"
    "   | |  __/>  <  / ___ \ |_| | || (_) | |__| (_) | | | | | | |_) | | |  __/  \n"
    "   |_|\___/_/\_\/_/   \_\__,_|\__\___/ \____\___/|_| |_| |_| .__/|_|_|\___|  \n"
    "                                                           |_|               \n"
    "============================================================================="
"\033[96m")
if str(subprocess.getstatusoutput("platex -ver")[0]) != "0":print(banner+"\n"+rope+"\nPlease install TexLive FIRST!!!!!");exit()
#scibanner=("Script User : %s \nScript Path : %s \n%s" % (sciuser,scipath,rope))
scibanner=("　　ユーザ名 : %s \n　ツールパス : %s \n%s" % (sciuser,scipath,rope))
#maintip=("[E]exit\n[D]delete extras file\n[H]history\n%s" % rope)
maintip=("[E]退出\n[D]コンパイルによる拡張ファイルを削除\n[H]歴史リスト\n%s" % rope)
def navigation(num):
    if num==1:autochkfile()
    elif num==2:mainmenu()
    elif num==3:compilechk()
    elif num==4:tachistory()
    elif num==5:compile()
    elif num==6:submenu()
    
def inputcheck(comment,banners,strings,argv='',args=''):
    global err
    while 1:
        os.system(clearswich);print(banners)
        #if err==1:print("{\033[31m%s\033[96m} is Illegal input, Please reinput." % inputchk);err=0
        if err==1:print("{\033[31m%s\033[96m} は不正な入力です。再入力してください。" % inputchk);err=0
        inputchk=input(comment)
        if argv!="":
            if inputchk=="":err=1;continue
            elif str(re.search(argv,inputchk))!="None":print(re.search(argv,inputchk));err=1
            elif int(inputchk)>args:err=1
            else:return inputchk
        else:
            if not inputchk in strings:err=1;continue
            else:return inputchk

def sciexit():
    if osname in {"Windows","Linux"}:os.system(clearswich);sys.exit(0)
    elif osname == "Darwin":os.system("osascript -e 'tell application \"Terminal\" to close first window' & exit")

def fnprocess(argv):
    global relpath;global relname;global abspath;global namepath
    relpath=argv.rstrip()
    abspath=os.path.dirname(argv)+"/"
    namepath=os.path.splitext(relpath)[0]
    relname=str(os.path.splitext(relpath)[0])
    if osname == "Windows":
        relpath=relpath.replace("/","\\")
        relname=relname.replace("/","\\")
        abspath=abspath.replace("&","`&").replace(r" ",r"` ")
        relname=relname.split("\\")[-1]
    if not os.path.exists(hispath):open(hispath,"w").close()

def cleanner(argv):
    global relname,abspath
    ext=["aux","dvi","log","nav","out","snm","toc","fls","fdb_latexmk","synctex.gz","vrb","bcf","blg","bbl","run.xml","idx","lof","lot"]
    if osname=="Windows":baknamer=relname;baknamea=abspath;abspath=abspath.replace("`","");relname=abspath+relname
    if argv == "know":
        for extit in ext:
            if os.path.exists(relname+"."+extit):os.remove(relname+"."+extit)
        os.system(clearswich)
    elif argv == "non":
        for listfn in os.listdir(scipath):
            #if os.path.splitext(listfn)[1]=="."+ext:os.remove(scipath+listfn)
            if any("."+exts in os.path.splitext(listfn)[1] for exts in ext):os.remove(scipath+listfn)
        os.system(clearswich)
    if osname=="Windows":relname=baknamer;abspath=baknamea

def compile():
    global navichk,relpath,abspath,relname
    if not os.path.exists(namepath+".tex"):
        os.system(clearswich)
        #print(banner+"\033[93m\nWarning:\nThe target file was suddenly not detected,\nPlease don't move or delete the target file After confirming the compiled file.\033[96m")
        print(banner+"\033[93m\n警告:\nターゲットファイル移動を検出、\nコンパイル完成する前にファイルを移動しないでください.\033[96m")
        time.sleep(8)
        navichk=2
    else:
        if osname == "Windows":
            os.system('powershell cd "%s" ; platex "%s.tex"' % (abspath,relname))
            os.system("powershell cd \"%s\" ; pbibtex \"%s.tex\"" % (abspath,relname))
            os.system("powershell cd \"%s\" ; platex \"%s.tex\" ; platex \"%s.tex\" ; dvipdfmx \"%s.dvi\"" % (abspath,relname,relname,relname))
        else:
            os.system("cd \"%s\" && platex \"%s.tex\"" % (abspath,relname))
            os.system("cd \"%s\" && pbibtex \"%s.tex\"" % (abspath,relname))
            os.system("cd \"%s\" && platex \"%s.tex\" && platex \"%s.tex\" && dvipdfmx \"%s.dvi\"" % (abspath,relname,relname,relname))
        if osname == "Windows":os.system('powershell "%s.pdf"' % (abspath+relname)) 
        elif osname == "Linux":subprocess.call(["xdg-open","%s.pdf" % relname]) #os.system("evince '%s.pdf' 2>/dev/null &" % relname)
        elif osname == "Darwin":subprocess.call(["open","%s.pdf" % relname]) #os.system("open '%s.pdf'" % relname)
        cleanner("know");navichk=6
        with open (hispath,"r") as sources:
            lines = sources.readlines()
            if not any(linesc.replace("\n","") in relpath for linesc in lines):
                with open(hispath, "a") as sources:sources.write("\n"+relpath)

def tachistory():
    failfilelist=[];alllist=(banner+"\n");count=1;global navichk
    if os.path.exists(hispath.rstrip()):
        with open(hispath,'r') as fr,open(hisnpath,'w') as fd:
            for line in fr.readlines():
                if line=='\n':line=line.strip('\n')
                fd.write(line)
        fr.close();fd.close();fr.flush;fd.flush
        os.remove(hispath);os.rename(hisnpath,hispath)
        with open(hispath, "r") as sources:lines = sources.readlines()
        for pathcheck in lines:
            pathcheck=pathcheck.rstrip()
            if not os.path.exists(pathcheck):failfilelist.append(pathcheck)
        if len(failfilelist)!=0:
            #value=inputcheck("Detected invalid directories in the history, do you want to remove them?(Y/N)",banner,"YyNn")
            value=inputcheck("歴史リストに無効なパスを検出、無効パスをリストから消去しますか？(Y/N)",banner,"YyNn")
            if value in "Yy":
                for name in failfilelist:
                    with open(hispath, "r") as sources:lines = sources.readlines()
                    with open(hispath, "w") as sources:
                        for line in lines:sources.write(re.sub(name, "", line))
                with open(hispath, "r") as sources:lines = sources.readlines()
                with open(homepath+"/.tachistory.histmp","w+") as tmp:
                    for tmpline in lines:
                        if tmpline!="\n":tmp.write(tmpline)
                os.remove(hispath);os.rename(homepath+"/.tachistory.histmp",hispath);failfilelist.clear()
        with open(hispath,"r") as nlist:nlines=nlist.readlines()
        for nline in nlines:
            #if nline in failfilelist:alllist=(alllist+"\033[0;31m"+str(count)+".fail."+nline+"\033[0;96m");count+=1;print("\033[0;31m"+str(count)+".fail."+nline+"\033[0;96m")
            if any(failfilelistx in nline for failfilelistx in failfilelist):alllist=(alllist+"\033[0;31m"+str(count)+"."+nline+"\033[0;96m");count+=1;print("\033[0;31m"+str(count)+"."+nline+"\033[0;96m")
            else:alllist=(alllist+str(count)+"."+nline);count+=1;print(str(count)+"."+nline)
        #value=inputcheck(rope+"\nInput list number to compile, or input 0 to menu.>>",alllist,"",r"\D",count-1)
        value=inputcheck(rope+"\nコンパイルしたいファイル番号を入力してください。又は０を入力してメインメニューに行きます。.>>",alllist,"",r"\D",count-1)
        if value=="0":navichk=2
        #elif nlines[int(value)-1] in failfilelist:
        elif any(failfilelistx in nlines[int(value)-1] for failfilelistx in failfilelist):
            #valuec=inputcheck("The directory you selected does not exist, do you want to remove it?(Y/N)",banner,"YyNn")
            valuec=inputcheck("選んだパスは無効です。リストから消去しますか？(Y/N)",banner,"YyNn")
            if valuec in "Yy":
                with open(hispath, "r") as sources:linesq = sources.readlines()
                with open(hispath, "w") as sources:
                    for line in linesq:sources.write(re.sub(nlines[int(value)-1], "", line))
            else:navichk=4
        else:fnprocess(nlines[int(value)-1]);navichk=3
    #else:os.system(clearswich);print(banner+"\n"+scibanner);print("No history is detected, return to the main menu after 3 seconds.");time.sleep(3);navichk=2
    else:os.system(clearswich);print(banner+"\n"+scibanner);print("歴史リストを見つかりませんでした.３秒後メインメニューに戻ります。");time.sleep(3);navichk=2

def autochkfile():
    nowtime=time.time();fakerelpath=[];os.system(clearswich);print(banner+"\n"+scibanner);global navichk;global relpath;global err
    if osname=="Windows":chkpath=["D:/OneDrive - 学校法人神奈川大学"]
    elif osname in {"Linux","Darwin"}:chkpath=[homepath+"/Desktop",homepath+"/Document"]
    for path2go in chkpath:
        for path,dir_list,file_list in os.walk(path2go):  
            for dir_name in file_list:
                relpath=os.path.join(path, dir_name).rstrip()
                if os.path.splitext(dir_name)[1]==".tex" and os.path.exists(relpath) and nowtime - os.path.getmtime(relpath) < 120:
                    fakerelpath.append(relpath)
    
    if len(fakerelpath)>0:
        inputbaner=(banner+"\n"+scibanner)
        for cunter in range(len(fakerelpath)):inputbaner=(inputbaner+"\n"+str(cunter+1)+"."+fakerelpath[cunter])
        #strin=inputcheck(rope+"\n"+"If you want to compile list file input the file number or input '0' to mainmenu.>>",inputbaner,"",r"\D",len(fakerelpath))
        strin=inputcheck(rope+"\n"+"最近編集したTexファイルを検出しました。\nコンパイルしたいファイルの番号を入力してください。又は０を入力してメインメニューに行きます。.>>",inputbaner,"",r"\D",len(fakerelpath))
        if strin=="0":navichk=2
        elif strin=="":fnprocess(fakerelpath[1]);navichk=3
        else:fnprocess(fakerelpath[int(strin)-1]);navichk=3
    else:
        navichk=2

def mainmenu():
    while 1:
        os.system(clearswich);print(banner+"\n"+scibanner);global navichk;global err
        print(maintip)
        #if err==1:print("{\033[31m%s\033[96m} is not a .Tex file or can't found." % inputpath);err=0
        if err==1:print("{\033[31m%s\033[96m} は.tex形式のファイルではないか、ファイルが存在しません。" % inputpath);err=0
        #inputpath=input("Put your Tex file or Input your Tex file path in this windows.(E/D/H/Path)\n>>").rstrip()#.replace(r" ","*")
        inputpath=input("このウィンドウにTexファイルを引っ張るまたはTexファイルのパスを入力してください。\n(E/D/H/Path)>>").rstrip()#.replace(r" ","*")
        if osname in {"Linux","Darwin"}:
            if inputpath.count("'")>=2:inputpath=inputpath.split("'")[1]
            if inputpath.count("\\")>=1:inputpath=inputpath.replace("\\","")
        elif osname=="Windows":#文件名处理，还差处理各种符号
            if inputpath.count("\"")>=2:inputpath=inputpath.split("\"")[1]
            inputpath=inputpath.replace("\\","/")
        if inputpath in {"E","e","Ｅ","ｅ"}:sciexit()
        elif inputpath in {"D","d","Ｄ","ｄ"}:cleanner("non")
        elif inputpath in {"H","h","ｈ","Ｈ"}:navichk=4;break
        elif not os.path.exists(inputpath):err=1;continue
        elif os.path.splitext(inputpath)[1]==".tex" and os.path.exists(inputpath):fnprocess(inputpath);navichk=3;break

def compilechk():
    while 1:
        os.system(clearswich);print(banner+"\n"+scibanner);global navichk;global err
        #print("Filename : %s\nPathname : %s/\n%s" % (os.path.basename(relpath),os.path.dirname(relpath),rope))
        print("　ファイル名 : %s\nファイルパス : %s/\n%s" % (os.path.basename(relpath),os.path.dirname(relpath),rope))
        #if err==1:print("{\033[31m%s\033[96m} is Illegal input. Please reinput.>> " % inputselect);err=0
        if err==1:print("{\033[31m%s\033[96m} は不正な入力です。再入力してください。>> " % inputselect);err=0
        #print("[Y]yes [N]no [D]delete extras files")
        print("[Y]コンパイル [N]却下 [D]コンパイルによる拡張ファイルを削除")
        #inputselect=input("Do you want compile this file or Delete extras files? [Y/N/D]: ")
        inputselect=input("このファイルをコンパイルしますか、それともコンパイルによる拡張ファイルを削除しますか？ [Y/N/D]: ")
        if inputselect in {"Y","y","Ｙ","ｙ",""}:navichk=5;break
        elif inputselect in {"D","d","Ｄ","ｄ"}:cleanner("know")
        elif inputselect in {"N","n","Ｎ","ｎ"}:navichk=2;break
        else :err=1

def submenu():
    while 1:
        os.system(clearswich);print(banner+"\n"+scibanner);global navichk;global err
        #print("Filename : %s\nPathname : %s/\n%s" % (os.path.basename(relpath),os.path.dirname(relpath),rope))
        print("　ファイル名 : %s\nファイルパス : %s/\n%s" % (os.path.basename(relpath),os.path.dirname(relpath),rope))
        #if err==1:print("{\033[31m%s\033[96m} is Illegal input. Please reinput.>> " % inputselect);err=0
        if err==1:print("{\033[31m%s\033[96m} は不正な入力です。再入力してください。>> " % inputselect);err=0
        #print("[R]recompile [E]exit [D]delete extras files [B]back to mainmenu")
        print("[R]再コンパイル [E]退出 [D]コンパイルによる拡張ファイルを削除\n[B]メインメニューに戻る")
        #inputselect=input("Do you want Recompile or Exit? [R/E/D/B]: ")
        inputselect=input("再コンパイルしますか、それとも終了しますか？ [R/E/D/B]: ")
        if inputselect in {"R","r","Ｒ","ｒ",""}:navichk=5;break
        elif inputselect in {"E","e","Ｅ","ｅ"}:sciexit()
        elif inputselect in {"D","d","Ｄ","ｄ"}:cleanner("know")
        elif inputselect in {"B","b","Ｂ","ｂ"}:navichk=1;break
        else :err=1

if __name__=='__main__':
    
    while 1:
        navigation(navichk)
