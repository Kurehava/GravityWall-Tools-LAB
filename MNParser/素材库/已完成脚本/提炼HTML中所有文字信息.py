from bs4 import BeautifulSoup
import urllib.request
from html.parser import HTMLParser
url = "https://www.kanagawa-u.ac.jp/#"
response = urllib.request.urlopen(url)
html = response.read()
soup = BeautifulSoup(html,"html.parser")
text = soup.get_text(strip=True)
tokens = [t for t in text.split()]
print (tokens)