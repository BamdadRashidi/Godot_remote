using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;

public class PresentationReceiver
{
    // Configuration
    private const int ListenPort = 8888;
    private const float Deadzone = 0.02f;      // Very low threshold to filter true zero noise
    private const float MouseSensitivity = 15f; // Adjustable max mouse speed
    private const float SmoothingSpeed = 30f;  // Higher = faster response, lower = smoother
    private const float ResponseExponent = 1.5f; // Curve: >1 gives fine micro-control near center

    private static UdpClient _udpListener;
    private static CancellationTokenSource _cts = new CancellationTokenSource();

    // Smoothed movement state
    private static float _targetX = 0f;
    private static float _targetY = 0f;
    private static float _currentX = 0f;
    private static float _currentY = 0f;

    // Sub-pixel movement accumulators for micro-movements
    private static float _accumulatedX = 0f;
    private static float _accumulatedY = 0f;

    // Command Identifiers (must match phone script)
    public enum CommandType : byte
    {
        Joystick = 1,
        PrevSlide = 2,
        NextSlide = 3,
        Click = 4,
        Quit = 5
    }

    public static async Task Main(string[] args)
    {
        Console.WriteLine($"Starting Remote Receiver on port {ListenPort}...");

        // Enable socket address reuse to prevent port-lock errors when restarting the script quickly
        Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
        socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
        socket.Bind(new IPEndPoint(IPAddress.Any, ListenPort));
        _udpListener = new UdpClient { Client = socket };

        // Bind process exit event to guarantee the socket is closed when the script terminates
        AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true;
            OnProcessExit(sender, EventArgs.Empty);
        };

        try
        {
            // Start mouse movement loop in parallel
            Task.Run(() => SmoothMouseLoop(_cts.Token));

            // Start UDP network listener
            await ListenAsync(_cts.Token);
        }
        finally
        {
            Cleanup();
        }
    }

    private static void OnProcessExit(object sender, EventArgs e)
    {
        Cleanup();
    }

    private static void Cleanup()
    {
        if (!_cts.IsCancellationRequested)
        {
            _cts.Cancel();
        }

        if (_udpListener != null)
        {
            _udpListener.Close();
            _udpListener.Dispose();
            _udpListener = null;
        }
    }

    private static async Task ListenAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            try
            {
                UdpReceiveResult result = await _udpListener.ReceiveAsync();
                ProcessPacket(result.Buffer);
            }
            catch (ObjectDisposedException) { break; }
            catch (SocketException ex) when (token.IsCancellationRequested) { break; }
            catch (Exception ex)
            {
                Console.WriteLine($"[UDP Error] {ex.Message}");
            }
        }
    }

    private static void ProcessPacket(byte[] buffer)
    {
        // Require at least 9 bytes for our protocol
        if (buffer.Length < 9) return;

        using (MemoryStream ms = new MemoryStream(buffer))
        using (BinaryReader reader = new BinaryReader(ms))
        {
            CommandType command = (CommandType)reader.ReadByte();
            float x = reader.ReadSingle();
            float y = reader.ReadSingle();

            switch (command)
            {
                case CommandType.Joystick:
                    // Process raw inputs into target direction and magnitude
                    float rawMag = MathF.Sqrt(x * x + y * y);
                    if (rawMag < Deadzone)
                    {
                        _targetX = 0f;
                        _targetY = 0f;
                    }
                    else
                    {
                        // Normalize direction vector
                        float dirX = x / rawMag;
                        float dirY = -y / rawMag; // Invert Y for screen space

                        // Apply non-linear exponential curve for enhanced micro-precision
                        float curvedMag = MathF.Pow(rawMag, ResponseExponent);

                        _targetX = dirX * curvedMag;
                        _targetY = dirY * curvedMag;
                    }
                    break;

                case CommandType.PrevSlide:
                    Console.WriteLine("[Action] Left Arrow (Previous Slide)");
                    VirtualInput.PressKey(VirtualInput.VK_LEFT);
                    break;

                case CommandType.NextSlide:
                    Console.WriteLine("[Action] Right Arrow (Next Slide)");
                    VirtualInput.PressKey(VirtualInput.VK_RIGHT);
                    break;

                case CommandType.Quit:
                    Console.WriteLine("[Action] Escape (Quit Presentation)");
                    VirtualInput.PressKey(VirtualInput.VK_ESCAPE);
                    break;

                case CommandType.Click:
                    Console.WriteLine("[Action] Left Click");
                    VirtualInput.MouseClick();
                    break;
            }
        }
    }

    /// <summary>
    /// Independent update loop (~60Hz) running smoothing interpolation
    /// </summary>
    private static async Task SmoothMouseLoop(CancellationToken token)
    {
        const int frameDelayMs = 16; // ~60 FPS update rate
        float dt = frameDelayMs / 1000f;

        while (!token.IsCancellationRequested)
        {
            // Lerp current speed towards target input for smooth acceleration
            _currentX = Lerp(_currentX, _targetX, SmoothingSpeed * dt);
            _currentY = Lerp(_currentY, _targetY, SmoothingSpeed * dt);

            // Accumulate fractional move values to prevent integer truncation from discarding tiny steps
            _accumulatedX += _currentX * MouseSensitivity;
            _accumulatedY += _currentY * MouseSensitivity;

            int moveX = (int)MathF.Round(_accumulatedX);
            int moveY = (int)MathF.Round(_accumulatedY);

            if (moveX != 0 || moveY != 0)
            {
                VirtualInput.MoveMouseRelative(moveX, moveY);

                // Subtract the executed pixel step from the accumulator, keeping residual fractions
                _accumulatedX -= moveX;
                _accumulatedY -= moveY;
            }

            try
            {
                await Task.Delay(frameDelayMs, token);
            }
            catch (TaskCanceledException)
            {
                break;
            }
        }
    }

    private static float Lerp(float start, float end, float t)
    {
        t = Math.Clamp(t, 0f, 1f);
        return start + (end - start) * t;
    }
}

/// <summary>
/// Windows API Wrapper for System-Wide Input Injection
/// </summary>
public static class VirtualInput
{
    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

    [DllImport("user32.dll")]
    private static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const uint MOUSEEVENTF_MOVE = 0x0001;

    public const byte VK_ESCAPE = 0x1B;
    public const byte VK_LEFT = 0x25;
    public const byte VK_RIGHT = 0x27;

    // Mouse controls
    private const int MOUSE_LEFTDOWN = 0x02;
    private const int MOUSE_LEFTUP = 0x04;

    public static void PressKey(byte keyCode)
    {
        keybd_event(keyCode, 0, 0, 0);                  // Key Down
        keybd_event(keyCode, 0, KEYEVENTF_KEYUP, 0);   // Key Up
    }

    public static void MoveMouseRelative(int deltaX, int deltaY)
    {
        mouse_event(MOUSEEVENTF_MOVE, (uint)deltaX, (uint)deltaY, 0, 0);
    }

    public static void MouseClick()
    {
        mouse_event(MOUSE_LEFTDOWN | MOUSE_LEFTUP, 0, 0, 0, 0);
    }
}


/*
    NOTE: when you want to kill the connection, make sure to enter the following two commands in the terminal:

    STEP 1- netstat -ano | findstr :8888 -> this will find the process that runs on the port 8888 which is this server.
        it will return you the PID for that specific task.
    STEP 2- taskkill /F /PID <PID number here> -> this will kill the task that we found in step 1.

    after that, you can turn on the server and redo your collection again.
*/