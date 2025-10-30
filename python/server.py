import socket
import asyncio
import pyautogui
import ctypes
import time

UDP_ID = "0.0.0.0"
UDP_PORT = 4307

socket = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
socket.bind((UDP_ID,UDP_PORT))
socket.setblocking(False)
print("listening... ")

cursor_is_shown = False
pyautogui.FAILSAFE = False
ctypes.windll.user32.ShowCursor(False)


sensitivity = 1070
alpha = 0.25
min_deadzone = 0.35
max_deadzone = 0.47
smooth_x = 0.0
smooth_y = 0.0
dominance_ratio = 1.6 

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
                
            elif message == "Lclick":
                print("click")
                pyautogui.click()
                
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
                smooth_x = (1 - alpha) * smooth_x + alpha * ax
                smooth_y = (1 - alpha) * smooth_y + alpha * ay
                
                
                if abs(smooth_x) < min_deadzone:
                    smooth_x = 0
                if abs(smooth_y) < min_deadzone:
                    smooth_y = 0
                    
                '''    
                if abs(smooth_x) > max_deadzone:
                    smooth_x *= max_deadzone / abs(smooth_x)
                if abs(smooth_y) > max_deadzone:
                    smooth_y *= max_deadzone / abs(smooth_y)
                ''' 
                    
                
                if abs(smooth_x) > abs(smooth_y) * dominance_ratio:
                    smooth_y = 0
                elif abs(smooth_y) > abs(smooth_x) * dominance_ratio:
                    smooth_x = 0
                    
        
                smooth_x = max(-max_deadzone, min(max_deadzone, smooth_x))
                smooth_y = max(-max_deadzone, min(max_deadzone, smooth_y))    
                
                
                x_movement = (smooth_x ** 3) * sensitivity
                y_movement = (smooth_y ** 3) * sensitivity
                
                
                if abs(x_movement) > 0.5 or abs(y_movement) > 0.5:
                    x, y = pyautogui.position()
                    pyautogui.moveTo(x + x_movement, y + y_movement)
                    print(f"x: {x_movement:.2f}, y: {y_movement:.2f}")

        except Exception as e:
            print(f"Error: {e}")
            
        del message
        
    time.sleep(0.03)
    
            