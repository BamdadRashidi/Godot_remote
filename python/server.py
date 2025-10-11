import socketserver
import asyncio
import pyautogui
import websockets

#TODO: give internet permissions and all while exporting and resize the project to fit into your mobile phone.

async def handler(websocket):
    
    #when we get these messages from godot, we will activate a keyboard input.
    async for message in websocket:
        match(message):
            case 'next':
                pyautogui.press('right')
                print('right')
            case 'previous':
                pyautogui.press('left')
                print('left')
            case 'quit':
                pyautogui.press('esc')
                print('exit')
                
                
                
async def main():
    port = 4307
    async with websockets.serve(handler,"INSERT IP", port):
        print('server running')
        await asyncio.Future()




asyncio.run(main())