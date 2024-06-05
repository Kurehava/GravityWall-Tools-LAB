from PIL import Image, ImageSequence
import sys
from time import sleep
from os import system

# 定义 ASCII 字符
ASCII_CHARS = [".", "#", "S", "%", "?", "*", "+", ";", ":", ",", "@"]

def resize_image(image, new_width=100):
    width, height = image.size
    ratio = height / width
    new_height = int(new_width * ratio * 0.55)
    resized_image = image.resize((new_width, new_height))
    return resized_image

def image_to_ascii(image):
    grayscale_image = image.convert("L")
    pixels = grayscale_image.getdata()
    ascii_str = ""
    for pixel_value in pixels:
        ascii_str += ASCII_CHARS[pixel_value // 25]
    return ascii_str

def gif_to_ascii(gif_path):
    try:
        gif = Image.open(gif_path)
        while True:
            frames = [frame.copy() for frame in ImageSequence.Iterator(gif)]
            for frame in frames:
                system("cls")
                resized_frame = resize_image(frame)
                ascii_str = image_to_ascii(resized_frame)
                sys.stdout.write(ascii_str)
                sys.stdout.write("\n")
                sleep(0.1)
    except Exception as e:
        print(f"Error: {e}")

# 指定 GIF 文件路径
gif_path = r"F:\_中转文件集\split_project\test.gif"  # 替换为你的 GIF 文件路径
gif_to_ascii(gif_path)