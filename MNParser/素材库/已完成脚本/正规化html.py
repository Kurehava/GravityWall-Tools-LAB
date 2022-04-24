import re,DLSourceCodeHtml
import string
url = "https://www.kanagawa-u.ac.jp/news/details_22377.html"
sc = DLSourceCodeHtml.DL(url)
sc.replace('\n', '')
sc = " ".join(re.split("\s+", sc, flags=re.UNICODE))
#string = "~!@#$%^&*()_+-*/<>,.[]\/"