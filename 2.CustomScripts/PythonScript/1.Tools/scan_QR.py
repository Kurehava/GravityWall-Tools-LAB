from MyQR import myqr
import sys
from os.path import exists
from os import system

META_PATH = "xxxxxxxx"

MAIN_PATH = sys.path[0]
naiyo = input('内容 : ')
fname = input('ファイルネーム : ')
myqr.run(words = naiyo, version = 1, save_name = MAIN_PATH + '/' + fname)

if exists(f"{MAIN_PATH}/{fname}"):
    print("\n\n\nQRコードを検出しました")
    print(f"QR: {naiyo}")
else:
    raise FileNotFoundError("QRコードを検出しませんでした")

image_path = "xxxxxxxxxx"
system(f"start {image_path}")