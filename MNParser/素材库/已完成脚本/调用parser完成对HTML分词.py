from html.parser import HTMLParser
import requests
import nltk
from bs4 import BeautifulSoup

class MyHTMLParser(HTMLParser):
    def handle_starttag(self, tag, attrs):
        print("Encountered a start tag:", tag)

    def handle_endtag(self, tag):
        print("Encountered an end tag :", tag)

    def handle_data(self, data):
        print("Encountered some data  :", data)

parser = MyHTMLParser()
html = requests.get('https://www.kanagawa-u.ac.jp/#')
soup = BeautifulSoup(html.content,'html.parser')
ps = open("requestsdata.dat","w+")
ps.write(str(soup))
ps.close
#parser.feed(str(soup))
tokens = nltk.wordpunct_tokenize(soup)
tokens = tokens[20:2424]
text = nltk.Text(tokens)