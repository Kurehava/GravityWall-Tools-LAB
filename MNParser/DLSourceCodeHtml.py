import requests
import re
import os
import urllib.request

def DL(url):
    if url == "1" or url == "":
        url = "https://www.kanagawa-u.ac.jp/#"
    r = requests.get(url)
    html=r.content
    html_doc=str(html,'utf-8') #html_doc=html.decode("utf-8","ignore")
    #print(html_doc)
    #sff = open("./DLS.dat","w+")
    #sff.write(html_doc)
    #sff.write(str(html))
    #sff.close
    return html_doc

def DLProcessingstring(url,comm):
    if url == "1" or url == "":
        url = "https://www.kanagawa-u.ac.jp/#"
    r = requests.get(url)
    html=r.content
    try:
        html_doc=str(html,'utf-8') #html_doc=html.decode("utf-8","ignore")
    except:
        #return print("ERROR")
        pass
    else:
        if comm=="y":
            html_doc=re.sub('<!.*?>', "", html_doc)
        html_doc.replace('\n', '')
        html_doc = " ".join(re.split("\s+", html_doc, flags=re.UNICODE))
        #print(html_doc)
        #print(html_doc)
        #sff = open("./DLS.dat","w+")
        #sff.write(html_doc)
        #sff.write(str(html))
        #sff.close
        return html_doc

def DLJS(url,floder,name):
    if url == "1" or url == "":
        url = "https://www.kanagawa-u.ac.jp/#"
    r = urllib.request.urlopen(url)
    html=r.read()
    html_doc=str(html,'utf-8')
    if floder != "":
        if not os.path.exists(floder):os.makedirs(floder)
        sff = open(floder+"/"+name,"w+");sff.write(html_doc);sff.close
    else:
        sff = open(name,"w+");sff.write(html_doc);sff.close


def output(url,floder,name):
    if url == "1" or url == "":
        url = "https://www.kanagawa-u.ac.jp/#"
    r = requests.get(url)
    html=r.content
    html_doc=str(html,'utf-8') #html_doc=html.decode("utf-8","ignore")
    #print(html_doc)
    if floder != "":
        if not os.path.exists(floder):os.makedirs(floder)
        sff = open(floder+"/"+name,"w+");sff.write(html_doc);sff.close
    else:
        sff = open(name,"w+");sff.write(html_doc);sff.close

def urlclean(url):
    if url.split("/")[-1].count(".") > 0 and url.split("/")[0].count("http")>0:
        return (url.split("/")[2]+"/"+url.split("/")[-1].split("/")[0]).replace(".","_")+".txt"