import asyncio
import pyautogui
import ctypes
import time


UDP_ID = "0.0.0.0"
UDP_PORT = 4307

pyautogui.FAILSAFE = False

sensitivity = 100
alpha = 0.12
min_deadzone = 0.12
max_deadzone = 0.6
accel_power = 1.12
rotation_damping = 0.02

MOTION_DELTA_THRESHOLD = 0.010
MOTION_UPDATE_INTERVAL = 1 / 50

cursor_is_shown = False
smooth_x = 0.0
smooth_y = 0.0
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
    global cursor_is_shown, smooth_x, smooth_y
    global last_motion, last_motion_time

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
                smooth_x = 0.0
                smooth_y = 0.0
                last_motion = (0, 0, 0)
                last_motion_time = time.perf_counter()

            elif message == "lOFF" and cursor_is_shown:
                cursor_is_shown = False
                hide_cursor()

            return

        if not cursor_is_shown:
            return

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

        smooth_x = smooth_x * (1 - alpha) + ax * alpha
        smooth_y = smooth_y * (1 - alpha) + ay * alpha

        magnitude = (smooth_x**2 + smooth_y**2)**0.5
        if magnitude < min_deadzone:
            return

        norm_mag = (magnitude - min_deadzone) / (max_deadzone - min_deadzone)
        norm_mag = max(0, min(1, norm_mag))

        nx = smooth_x / magnitude
        ny = smooth_y / magnitude

        accel = norm_mag ** accel_power

        vx = nx * accel * sensitivity
        vy = ny * accel * sensitivity

        vx = vx * (1 - rotation_damping)
        vy = vy * (1 - rotation_damping)

        if abs(vx) < 0.22: vx = 0
        if abs(vy) < 0.22: vy = 0

        if vx != 0 or vy != 0:
            move_cursor_rel(vx, vy)

    except Exception as e:
        print("Error:", e)


class UDPServer(asyncio.DatagramProtocol):
    def datagram_received(self, data, addr):
        message = data.decode().strip()
        asyncio.create_task(handle_message(message))


async def main():
    loop = asyncio.get_running_loop()
    transport, protocol = await loop.create_datagram_endpoint(
        lambda: UDPServer(),
        local_addr=(UDP_ID, UDP_PORT)
    )

    print(f"Listening on UDP {UDP_PORT}")

    try:
        while True:
            await asyncio.sleep(3600)
    finally:
        transport.close()


asyncio.run(main())
