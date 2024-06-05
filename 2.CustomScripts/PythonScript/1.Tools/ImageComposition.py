import PIL.Image as Image
from os.path import splitext
from os import listdir
from InputClean.InputClean import ci

IMAGES_PATH = ci("input >> ").replace("\\", "/")
IMAGES_PATH = f"{IMAGES_PATH}/"
IMAGES_FORMAT = ['.jpg', '.JPG']  # 画像フォーマット
image_names = [name for name in listdir(IMAGES_PATH) if splitext(name)[1] in IMAGES_FORMAT]
temp = input("set max row or col? > ")
if temp not in ["row", "col"]:
    raise ValueError(f"{temp} is not row or col.")
maxs = input(f"max {temp} is > ")
if not maxs.isdigit():
    raise ValueError(f"{maxs} is not number.")
maxs = int(maxs)
if temp == "row":
    IMAGE_ROW = maxs
    IMAGE_COLUMN = len(image_names)//maxs+1 if divmod(len(image_names),maxs)[-1] > 0 else len(image_names)//maxs
else:
    IMAGE_COLUMN = maxs
    IMAGE_ROW = len(image_names)//maxs+1 if divmod(len(image_names),maxs)[-1] > 0 else len(image_names)//maxs 
w=608            # 画像サイズ 横
h=608            # 画像サイズ 縦

IMAGE_SAVE_PATH = f"{IMAGES_PATH}/MEGERS_YSD.jpg"  # 生成された画像のパース
if len(image_names) > IMAGE_ROW * IMAGE_COLUMN:
    raise ValueError("設定された画像の個数と読み込まれたファイルの個数より小さい")

def image_compose():
    to_image = Image.new('RGB', (IMAGE_COLUMN *w, IMAGE_ROW *h))
    for y in range(1, IMAGE_ROW + 1):
        for x in range(1, IMAGE_COLUMN + 1):
            try:
                from_image = Image.open(IMAGES_PATH + image_names[IMAGE_COLUMN * (y - 1) + x - 1]).resize((w, h))
                to_image.paste(from_image, ((x - 1) * w, (y - 1) * h))
            except:
                pass
    
    return to_image.save(IMAGE_SAVE_PATH)
image_compose()
