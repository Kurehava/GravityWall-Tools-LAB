import os,logo

targetarr=["/home/oriki/Desktop/MNParser/ImportNotMain/DataCarsh/JS-malware-sample/","/home/oriki/Desktop/MNParser/ImportNotMain/DataCarsh/JS-safefil-sample"]
flogpath="/home/oriki/Desktop/MNParser/file_list.log"
count=1
logo.LOGO()
print("=================================================")
if os.path.exists(flogpath):
    if not os.path.exists(flogpath.split(".")[0]+".bak"):
        print("[INFO]:Move old file to backup file. ")
        os.rename(flogpath,flogpath.split(".")[0]+".bak")
    else:
        print("[INFO]:Backup file detected, Delete old backup file. ")
        os.remove(flogpath.split(".")[0]+".bak")
        print("[INFO]:Move old file to backup file. ")
        os.rename(flogpath,flogpath.split(".")[0]+".bak")
for targetfd in targetarr:
    totalfil=len(os.listdir(targetfd))
    tar = open(flogpath,"a+")
    for filename in os.listdir(targetfd):
        print("Writting %d%% : %s" % (count/totalfil*100,filename))
        tar.write("%06d,p,%s,%s\n" % (count,filename,filename))
        count+=1
    tar.close()
    filename=[]