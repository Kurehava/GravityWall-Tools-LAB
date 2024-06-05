from MyQR import myqr
import sys
from os.path import exists
from os import system

MAIN_PATH = sys.path[0]
naiyo = input('内容 : ')
fname = input('ファイルネーム : ')
myqr.run(words = naiyo, version = 1, save_name = MAIN_PATH + '/' + fname)