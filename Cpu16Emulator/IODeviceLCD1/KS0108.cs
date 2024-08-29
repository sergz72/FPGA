using Avalonia.Controls;
using Avalonia.Layout;
using Cpu16EmulatorCommon;

namespace IODeviceLCD1;

internal sealed class KS0108: ILcdDriver
{
    private sealed class Controller
    {
        private readonly ushort[] _memory;
        private readonly ILogger _logger;
        private readonly LCD1 _control;

        private int _yAddress;
        private int _xAddress;
        
        internal Controller(ILogger logger)
        {
            _memory = new ushort[256];
            var r = new Random();
            for (var i = 0; i < _memory.Length; i++)
                _memory[i] = (ushort)r.Next(ushort.MaxValue);

            _logger = logger;
            _yAddress = _xAddress = 0;
            _control = new LCD1(_memory, 64, 4);
        }

        internal Control CreateControl()
        {
            return _control;
        }

        internal void Write(bool dc, byte data)
        {
            if (dc) // data
                WriteData(data);
            Command(data);
        }

        private void Command(byte data)
        {
            switch (data)
            {
                case >= 0x3E and <= 0x3F:
                    _control.On = (data & 1) != 0;
                    break;
                case >= 0x40 and <= 0x7F:
                    _yAddress = data & 0x3F;
                    break;
                case >= 0xB8 and <= 0xBF:
                    _xAddress = data & 7;
                    break;
                default:
                    _logger.Error($"Invalid command {data:X2}");
                    break;
            }
        }

        private void WriteData(byte data)
        {
            var datap8 = (_yAddress << 3) | _xAddress;
            var datap16 = datap8 >> 1;
            var hiByte = (datap8 & 0x01) != 0;
            var d = _memory[datap16];
            if (hiByte)
                _memory[datap16] = (ushort)((d & 0xFF) | (data << 8));
            else
                _memory[datap16] = (ushort)((d & 0xFF00) | data);
            _yAddress++;
            _yAddress &= 0x3F;
            
            _control.InvalidateVisual();
        }
    }
    
    private readonly ushort _eBit;
    private readonly ushort _dcBit;
    private readonly ushort _cs1Bit;
    private readonly ushort _cs2Bit;
    private readonly Controller[] _controllers;

    private bool _prevE;
    
    internal KS0108(string driverParameters, ILogger logger)
    {
        var parts = driverParameters.Split(',');
        if (parts.Length != 4)
            throw new IODeviceException("KS0108 driver parameters must contain 4 signal names.");
        
        var bitCount = 0;
        foreach (var part in parts)
        {
            switch (part)
            {
                case "e":
                    _eBit = (ushort)(1 << bitCount);
                    bitCount++;
                    break;
                case "dc":
                    _dcBit = (ushort)(1 << bitCount);
                    bitCount++;
                    break;
                case "cs1":
                    _cs1Bit = (ushort)(1 << bitCount);
                    bitCount++;
                    break;
                case "cs2":
                    _cs2Bit = (ushort)(1 << bitCount);
                    bitCount++;
                    break;
            }
        }
        if (bitCount != 4)
            throw new IODeviceException("Wrong KS0108 driver parameters");
        
        _controllers = new Controller[2];
        _controllers[0] = new Controller(logger);
        _controllers[1] = new Controller(logger);

        _prevE = false;
    }

    public void Write(ushort address, byte data)
    {
        var e = (address & _eBit) != 0;
        if (_prevE && !e)
        {
            var cs1 = (address & _cs1Bit) != 0;
            var cs2 = (address & _cs2Bit) != 0;
            var dc = (address & _dcBit) != 0;
            if (!cs1)
                _controllers[0].Write(dc, data);
            if (!cs2)
                _controllers[1].Write(dc, data);
        }
        _prevE = e;
    }

    public Control CreateControl()
    {
        var control0 = _controllers[0].CreateControl();
        var control1 = _controllers[1].CreateControl();
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal
        };
        panel.Children.Add(control0);
        panel.Children.Add(control1);
        return panel;
    }
}