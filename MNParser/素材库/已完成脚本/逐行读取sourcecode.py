import DLSourceCodeHtml
DLSourceCodeHtml.output("https://www.kanagawa-u.ac.jp/#")
cun2=0 #限制条件
for line in open("DLS.dat"):
    if cun2 < 10:
        print(line)
    else:
        break
    cun2+=1