from html.parser import HTMLParser
from html.entities import name2codepoint
import DLSourceCodeHtml
class MyHTMLParser(HTMLParser):

    def handle_starttag(self, tag, attrs):
        print('<%s>' % tag)

    def handle_endtag(self, tag):
        print('</%s>' % tag)

    def handle_startendtag(self, tag, attrs):
        print('<%s/>' % tag)

    def handle_data(self, data):
        print(data)

    def handle_comment(self, data):
        print('<!--', data, '-->')

    def handle_entityref(self, name):
        print('&%s;' % name)

    def handle_charref(self, name):
        print('&#%s;' % name)

parser = MyHTMLParser()
DLSourceCodeHtml.DL("1")
DLSC = open("DLS.dat","r")
html = DLSC.read()
#print(html)
parser.feed(str(html))