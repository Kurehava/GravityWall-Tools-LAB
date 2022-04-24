import sys
import ParserVer1,ParserVer2,ParserVer3
import DLSourceCodeHtml,logo
import re,platform,sys,shutil,os
class ProgSet():
    def automatic():
        print("\033[96m")
        if platform.system() == 'Windows':os.system("mode con cols=140 lines=40");os.system("cls")
        elif platform.system() == "Linux" or platform.system() == "Darwin":os.system("printf '\033[8;40;140t'");os.system("clear")
        logo.LOGO()
        print("\033[93m"
            "=================================================\n"
            "Automatic HTMLsource FIle Downloader for MNParser \n"
            "Process Status : Downloading......\n"
            "================================================="
            "\033[96m")
    def manual():
        print("\033[96m")
        if platform.system() == 'Windows':os.system("mode con cols=50 lines=40");os.system("cls")
        elif platform.system() == "Linux" or platform.system() == "Darwin":os.system("printf '\033[8;40;50t'");os.system("clear")
        logo.LOGO()
        print("=================================================")
        """ print("\033[93m"
            "=================================================\n"
            "Manual Task for MNParser \n"
            "================================================="
            "\033[96m") """

def manual():
    ProgSet.manual()
    url = 'https://www.kanagawa-u.ac.jp/'
    #url = "https://docs.python.org/zh-cn/3/library/../_static/jquery.js"
    #url = sys.argv[1]
    #ParserVer2.analyze(url)
    #ParserVer2.analyzehumanread(url)
    #ParserVer2.analyzeoutput(url,"tester")
    #ParserVer2.script(url,"")
    #ParserVer2.scriptout(url,url.split("/")[-1])
    #DLSourceCodeHtml.urlclean(url)
    #print(DLSourceCodeHtml.DL(url))
    #ParserVer3.ScriptOutput(url,"tester")
    #ParserVer3.HTMLParserAnalyze(url)
    #ParserVer3.HTMLParserAnalyzeHumanRead(url)
    #ParserVer3.HTMLParserAnalyzeOutput(url,"p3")
    #ParserVer3.Script(url)
    ParserVer3.ScriptOutput(url,"p5")
    #ParserVer3.Script("https://qiita.com/nannoki/items/15004992b6bb5637a9cd")
    #DLSourceCodeHtml.DLJS(url,".","tester.info")

def automatic():
    ProgSet.automatic()
    if os.path.exists("/home/oriki/Desktop/parser/Data"):
        shutil.rmtree("/home/oriki/Desktop/parser/Data")
    filelen=len(open("list.txt").readlines())
    count=0
    with open ("list.txt","r") as list:
        lines=list.readlines()
    for line in lines:
        count+=1
        print("Process %02d%% [%2d/%d] : %s" % (count/filelen*100,count,filelen,line.replace("\n","")))
        if line.replace("\n","").split("/")[-1].count(".html")>=1:
            fn=re.search('.*?.html',line.replace("\n","").split("/")[-1]).group()
        else:
            fn=line.replace("\n","").split("/")[-1][0:7]
        PVSOINFO=ParserVer3.ScriptOutput(line.replace("\n",""),fn)
        #ParserVer2.scriptout(line.replace("\n",""),line.replace("\n","").split("/")[-1])
        if PVSOINFO=="exit":
            sys.exit()

#manual()
automatic()