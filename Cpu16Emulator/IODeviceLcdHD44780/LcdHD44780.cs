using Avalonia.Controls;
using Avalonia.Layout;
using Avalonia.Media;
using Cpu16EmulatorCommon;

namespace IODeviceLcdHD44780;

public class LcdHD44780: IIODevice
{
    private ushort _address, _columns;
    private Label[] _rows = [];
    private char[][] _memory = [];
    private ILogger? _logger;
    private bool _prevE, _on;
    private int _currentAddress;
    
    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                   throw new IODeviceException("LcdHD44780: missing or wrong address parameter");
        var rows = IODeviceParametersParser.ParseUShort(kv, "rows") ?? 
                   throw new IODeviceException("LcdHD44780: missing or wrong rows parameter");
        if (rows is 0 or > 4)
            throw new IODeviceException("LcdHD44780: rows should be from 1 to 4");
        _columns = IODeviceParametersParser.ParseUShort(kv, "columns") ?? 
                   throw new IODeviceException("LcdHD44780: missing or wrong columns parameter");
        if (_columns != 8 && _columns != 12 && _columns != 16 && _columns != 20)
            throw new IODeviceException("LcdHD44780: columns should be from 8 or 12 or 16 or 20");
        var control = new StackPanel
        {
            Orientation = Orientation.Vertical,
        };
        _rows = new Label[rows];
        _memory = new char[rows][];
        for (var i = 0; i < rows; i++)
        {
            var l = new Label
            {
                Width = 200,
                Height = 20
            };
            _rows[i] = l;
            control.Children.Add(l);
            _memory[i] = new char[_columns];
        }
        _logger = logger;
        return control;
    }

    public void IoRead(IoEvent ev)
    {
        if ((ev.Address & 0xFFFC) == _address)
            _logger?.Error("LcdHD44780 io read");
    }

    public void IoWrite(IoEvent ev)
    {
        if ((ev.Address & 0xFFFC) == _address)
        {
            var e = (ev.Address & 1) != 0;
            if (_prevE)
            {
                var rs = (ev.Address & 2) != 0;
                if (!e)
                {
                    var data = (char)ev.Data;
                    if (rs) // data
                    {
                        _logger?.Debug($"LcdHD44780 io write {_currentAddress} {data}");
                        var row = _currentAddress >> 6;
                        var col = _currentAddress & 0x3F;
                        _currentAddress++;
                        if (row >= _rows.Length || col >= _columns)
                            return;
                        _memory[row][col] = data;
                        if (_on)
                            _rows[row].Content = new string(_memory[row]);
                    }
                    else // command
                    {
                        if (data == 1)
                            ClearDisplay();
                        else if (data == 2 || data == 3)
                        {
                            _currentAddress = 0;
                            _logger?.Debug($"LcdHD44780 return home");
                        }
                        else if ((data & 0xF8) == 8)
                            DisplayOn((data & 4) != 0);
                        else if ((data & 0x80) == 0x80)
                        {
                            _currentAddress = data & 0x7F;
                            _logger?.Debug($"LcdHD44780 set address {_currentAddress}");
                        }
                    }
                }
            }

            _prevE = e;
        }
    }

    private void ClearDisplay()
    {
        _logger?.Debug($"LcdHD44780 clear display");
        for (var i = 0; i < _memory.Length; i++)
        {
            for (var j = 0; j < _columns; j++)
                _memory[i][j] = ' ';
            if (_on)
                _rows[i].Content = string.Empty;
        }
    }

    private void DisplayOn(bool on)
    {
        var state = (on) ? "on" : "off";
        _logger?.Debug($"LcdHD44780 display {state}");
        if (on != _on)
        {
            _on = on;
            for (var i = 0; i < _rows.Length; i++)
                _rows[i].Content = on ? new string(_memory[i]) : string.Empty;
        }
    }

    public uint? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}