import socket
import asyncio
import pyautogui
import ctypes
import time

UDP_ID = "0.0.0.0"
UDP_PORT = 4307
sensitivity = 100
cursor_is_shown = False

socket = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
socket.bind((UDP_ID,UDP_PORT))
socket.setblocking(False)
print("listening... ")

pyautogui.FAILSAFE = False
ctypes.windll.user32.ShowCursor(False)


def hide_cursor():
    while ctypes.windll.user32.ShowCursor(False) >= 0:
        pass

def show_cursor():
    while ctypes.windll.user32.ShowCursor(True) < 0:
        pass

while True:
    try:
        while True:
             data, address = socket.recvfrom(1024)
             message = data.decode().strip()
    except BlockingIOError:
        pass
    
    
    if 'message' in locals():
        print(message)
        try:
            if message == "quit":
                print("quit")
                pyautogui.press('esc')

            elif message == "next":
                print("right")
                pyautogui.press('right')

            elif message == "previous":
                print("left")
                pyautogui.press('left')

            elif message == "lON" and cursor_is_shown == False:
                print("show")
                cursor_is_shown = True
                show_cursor()

            elif message == "lOFF" and cursor_is_shown == True:
                print("hide")
                cursor_is_shown = False
                hide_cursor()

            elif cursor_is_shown:
                ax, ay, az = map(float, message.split(','))
                x_movement = ax * sensitivity
                y_movement = ay * sensitivity
                
                if abs(x_movement) > 0.5 or abs(y_movement) > 0.5:
                    x, y = pyautogui.position()
                    pyautogui.moveTo(x + x_movement, y + y_movement)
                    print(f"x: {x_movement:.2f}, y: {y_movement:.2f}")

        except Exception as e:
            print(f"Error: {e}")
            
        del message
        
    time.sleep(0.05)
    
            