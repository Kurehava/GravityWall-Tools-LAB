from bs4 import BeautifulSoup
from bs4.element import Comment
from nltk.tokenize import sent_tokenize, word_tokenize
import urllib.request
 
def visible_tag(element):
    if element.parent.name in ['style', 'p', 'head', 'title', 'meta', '[document]']:
        return False
    if isinstance(element, Comment):
        return False
    return True
 
def html_text(body):
    soup = BeautifulSoup(body, 'html.parser')
    texts = soup.findAll(text=True)
    visible_texts = filter(visible_tag, texts)  
    return u" ".join(t.strip() for t in visible_texts)
html = urllib.request.urlopen('https://www.kanagawa-u.ac.jp/#').read()
html_data = html_text(html)
html_data = (f'"{html_data}"')
 
print("Word Tokenization: ")
print(word_tokenize(html_data))