from socket import *
from PIL import Image
from os import listdir
from os.path import splitext
from hashlib import sha256
from sys import path
from pickle import dumps

erro = f"[\033[91mERRO\033[0m]"
info = f"[\033[92mINFO\033[0m]"
warn = f"[\033[93mWARN\033[0m]"

print(f"{info} Waiting Client Connect...")
tcp_server = socket(AF_INET,SOCK_STREAM)
address = ('127.0.0.1',61234)
tcp_server.bind(address)
tcp_server.listen(1)
client_socket, clientAddr = tcp_server.accept()

print(f"{info} Connect Success : {clientAddr[0]}:{clientAddr[1]}.")

print(f"{info} Load All Data...")
IMAGES_DIR = f"{path[0]}/IMAGE"
IMAGES_FN = [[splitext(f"{fn}")[0], splitext(f"{fn}")[1]] for fn in listdir(IMAGES_DIR)]
print(f"{info} Load Data Success.")

while True:
    search_data = []
    print(f"\n{info} Waiting Client Data...")
    recv_msg = client_socket.recv(1024 ** 3)
    recv_msg = recv_msg.decode("utf-8")
    print(f"{info} Get Client Data : \n   -- {recv_msg}")
    print(f"{info} Search in the corresponding file...")
    
    for fn_search in IMAGES_FN:
        if recv_msg in sha256(fn_search[0].encode()).hexdigest():
            print(f"{info} The corresponding file was found.")
            search_data = fn_search
            break
    
    if len(search_data) > 0:
        image_data = [1, Image.open(f"{IMAGES_DIR}/{search_data[0]}{search_data[1]}")]
        print(f"{info} Send Image To Client.")
    else:
        image_data = [0 ,"No corresponding information found"]
        print(f"{erro} No corresponding information found")
        print(f"{warn} Send ERROR Message To Client.")
        continue

    send_msg = dumps(image_data)
    client_socket.send(send_msg)

client_socket.close()