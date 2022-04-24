import requests
from bs4 import BeautifulSoup
def DL(url):
    if url == "1":
        url = "https://www.kanagawa-u.ac.jp/#"
    html = requests.get(url)
    soup = BeautifulSoup(html.content,'html.parser')
    sff = open("DLS.dat","w+")
    sff.write(str(soup))
    sff.close