from socket import *
from PIL import Image
from MyQR import myqr
from InputClean.InputClean import ci
from pyzbar import pyzbar
from hashlib import sha256
from pickle import loads

erro = f"[\033[91mERRO\033[0m]"
info = f"[\033[92mINFO\033[0m]"
warn = f"[\033[93mWARN\033[0m]"

tcp_socket = socket(AF_INET,SOCK_STREAM)
tcp_socket.connect(("127.0.0.1", 61234))

while True:
    send_data = ci(f"\n{info} Waiting to enter the QR code: ")
    try:
        image = Image.open(send_data)
        send_data = pyzbar.decode(image)[0].data.decode("utf-8")
        print(f"{info} Get QR Code Message: {send_data}")
    except Exception as E:
        print(f"{error} {send_data} is not a QR code.")
        input("Enter any key to back.")
        continue
    
    send_data = sha256(send_data.encode()).hexdigest()
    print(f"{info} Send Message To Server : \n   -- {send_data}")
    tcp_socket.send(send_data.encode("utf-8"))

    tcp_remsg = tcp_socket.recv(1024 ** 3)
    tcp_remsg = loads(tcp_remsg)
    if tcp_remsg[0]:
        print(f"{info} Success Get Image.")
        recv_image = tcp_remsg[1]
        print(f"{info} Show Image.")
        recv_image.show()
    else:
        print(f"{erro} {tcp_remsg[1]}")

tcp_socket.close()