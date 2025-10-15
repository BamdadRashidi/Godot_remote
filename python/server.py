import socket
import asyncio
import pyautogui
import ctypes

UDP_ID = "YOUR IP"
UDP_PORT = 4307


socket = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
socket.bind((UDP_ID,UDP_PORT))
print("listening... ")


while True:
    data, address = socket.recvfrom(1024)
    message = data.decode().strip
    
    match(message):
        case "quit":
            print("quit")
            pyautogui.press('esc')
        case "next":
            print("right")
            pyautogui.press('right')
        case "previous":
            print("left")
            pyautogui.press('left')
        case "lON":
            print("show")
            ctypes.windll.user32.ShowCursor(True)
        case "lOFF":
            print("hide")
            ctypes.windll.user32.ShowCursor(False)
            
        #TODO: to be added (mouse movement)
            