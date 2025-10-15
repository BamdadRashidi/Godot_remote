import socket
import asyncio
import pyautogui
import ctypes

UDP_ID = "0.0.0.0"
UDP_PORT = 4307


socket = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
socket.bind((UDP_ID,UDP_PORT))
print("listening... ")


while True:
    data, address = socket.recvfrom(1024)
    message = data.decode().strip()

    if message == "quit":
        print("quit")
        pyautogui.press('esc')
    elif message == "next":
        print("right")
        pyautogui.press('right')
    elif message == "previous":
        print("left")
        pyautogui.press('left')
    elif message == "lON":
        print("show")
        ctypes.windll.user32.ShowCursor(True)
    elif message == "lOFF":
        print("hide")
        ctypes.windll.user32.ShowCursor(False)
            
    #TODO: to be added (mouse movement)
            