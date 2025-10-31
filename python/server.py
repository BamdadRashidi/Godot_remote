import asyncio
import pyautogui
import ctypes
import time

UDP_ID = "0.0.0.0"
UDP_PORT = 4307

pyautogui.FAILSAFE = False
ctypes.windll.user32.ShowCursor(False)

cursor_is_shown = False
sensitivity = 1080
alpha = 0.25
min_deadzone = 0.35
max_deadzone = 0.35
smooth_x = 0.0
smooth_y = 0.0
dominance_ratio = 1.2

#TODO: make diagonal movement and smoother circular movement (movement right now is just dead vertical or dead horizontal and there is no diagonal)

MOTION_DELTA_THRESHOLD = 0.015  
MOTION_UPDATE_INTERVAL = 1 / 30  
last_motion = (0, 0, 0)
last_motion_time = 0.0

def hide_cursor():
    while ctypes.windll.user32.ShowCursor(False) >= 0:
        pass

def show_cursor():
    while ctypes.windll.user32.ShowCursor(True) < 0:
        pass

def move_cursor_rel(dx, dy):
    x, y = pyautogui.position()
    ctypes.windll.user32.SetCursorPos(int(x + dx), int(y + dy))

async def handle_message(message: str):
    global cursor_is_shown, smooth_x, smooth_y, last_motion, last_motion_time

    try:
        if message in ("quit", "next", "previous", "Lclick", "lON", "lOFF"):
            if message == "quit":
                pyautogui.press('esc')
            elif message == "next":
                pyautogui.press('right')
            elif message == "previous":
                pyautogui.press('left')
            elif message == "Lclick":
                pyautogui.click()
            elif message == "lON" and not cursor_is_shown:
                cursor_is_shown = True
                show_cursor()
            elif message == "lOFF" and cursor_is_shown:
                cursor_is_shown = False
                hide_cursor()
            return

        if cursor_is_shown:
            ax, ay, az = map(float, message.split(','))

            dx = abs(ax - last_motion[0])
            dy = abs(ay - last_motion[1])
            if dx < MOTION_DELTA_THRESHOLD and dy < MOTION_DELTA_THRESHOLD:
                return

            now = time.perf_counter()
            if now - last_motion_time < MOTION_UPDATE_INTERVAL:
                return 

            last_motion_time = now
            last_motion = (ax, ay, az)

            smooth_x = (1 - alpha) * smooth_x + alpha * ax
            smooth_y = (1 - alpha) * smooth_y + alpha * ay

            if abs(smooth_x) < min_deadzone:
                smooth_x = 0
            if abs(smooth_y) < min_deadzone:
                smooth_y = 0

            if abs(smooth_x) > abs(smooth_y) * dominance_ratio:
                smooth_y = 0
            elif abs(smooth_y) > abs(smooth_x) * dominance_ratio:
                smooth_x = 0

            smooth_x = max(-max_deadzone, min(max_deadzone, smooth_x))
            smooth_y = max(-max_deadzone, min(max_deadzone, smooth_y))

            x_move = (smooth_x ** 3) * sensitivity
            y_move = (smooth_y ** 3) * sensitivity

            if abs(x_move) > 0.5 or abs(y_move) > 0.5:
                move_cursor_rel(x_move, y_move)
    except Exception as e:
        print(f"Error: {e}")

class UDPServer(asyncio.DatagramProtocol):
    def datagram_received(self, data, addr):
        message = data.decode().strip()
        asyncio.create_task(handle_message(message))

async def main():
    loop = asyncio.get_running_loop()
    transport, protocol = await loop.create_datagram_endpoint(
        lambda: UDPServer(), local_addr=(UDP_ID, UDP_PORT)
    )
    print("Listening on UDP", UDP_PORT)
    try:
        await asyncio.sleep(3600)
    finally:
        transport.close()

asyncio.run(main())
