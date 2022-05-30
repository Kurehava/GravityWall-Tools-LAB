import time
import numpy as np
from BDD import BDD

# from ZDD import ZDD

BZCHK_FLAG = 0
averagenode = [[], [], [], [], [], [], []]
averagepath = [[], [], [], [], [], [], []]
averageleaf = [[], [], [], [], [], [], []]

while True:  # while永远等于1 需要break跳出循环 通过flag控制
    TIMECOUNT_START = time.process_time()
    for n in range(1, 255):
        randomintarr = []
        randomint = str(bin(n).replace("0b", ""))  # 转换二进制 去除首2位0b
        if len(randomint) < 8:  # 不够8位补0
            for n in range(len(randomint), 8):
                randomint = "0" + randomint
        for n in range(len(randomint)):  # 把字符串拆分存放数组
            randomintarr.append(randomint[n])
        for n in range(len(randomintarr)):  # 把字符串换成int型
            randomintarr[n] = int(randomintarr[n])
        len_0 = randomintarr.count(0)
        if BZCHK_FLAG == 0:
            (path, node, leaf) = BDD(randomintarr)
        """ else:
            ZDD(randomintarr) """
        if path != 0 and len_0 <= 7 and BZCHK_FLAG == 0:
            averagenode[len_0 - 1].append(node)
            averagepath[len_0 - 1].append(path)
            averageleaf[len_0 - 1].append(leaf)
    TIMECOUNT_END = time.process_time()
    if BZCHK_FLAG == 0:
        print('COUNT CPU TIME OF BDD IS: %lf' % (TIMECOUNT_END - TIMECOUNT_START))
        BZCHK_FLAG += 1
    else:
        print('COUNT CPU TIME OF ZDD IS: %lf' % (TIMECOUNT_END - TIMECOUNT_START))
        break
print("Node : ", end='')
[print("%lf " % np.mean(averagenode[len_ave]), end='') for len_ave in range(len(averagenode))]
# print('\n',averagenode)
print('\nPath : ', end='')
[print("%lf " % np.mean(averagepath[len_ave]), end='') for len_ave in range(len(averagepath))]
# print('\n',averagepath)
print('\nLeaf : ', end='')
[print("%lf " % np.mean(averageleaf[len_ave]), end='') for len_ave in range(len(averageleaf))]
# print('\n',averageleaf)
print('')
