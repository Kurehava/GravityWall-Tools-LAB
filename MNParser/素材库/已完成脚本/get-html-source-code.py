import requests
url='https://www.kanagawa-u.ac.jp/#'
r = requests.get(url)
html=r.content
html_doc=str(html,'utf-8') #html_doc=html.decode("utf-8","ignore")
print(html_doc)