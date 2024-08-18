using System.Globalization;
using System.Text.Json;
using Avalonia.Controls;
using Cpu16EmulatorCommon;

namespace IODeviceI2CSlave;

public class IODeviceI2CSlave: IIODevice
{
    private enum Mode
    {
        None,
        Address,
        Data
    }

    public struct I2CDevice
    {
        public string Name { get; set; }
        public int Address { get; set; }
        public string Parameters { get; set; }
    }
    
    private ushort _address;
    private bool _prevSda;
    private bool _prevScl;
    private bool _sentData;
    private bool _ack;
    private Mode _mode;
    private ILogger? _logger;
    private int _bitCounter;
    private int _data;

    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        if (!kv.TryGetValue("address", out var sAddress) ||
            !ushort.TryParse(sAddress, NumberStyles.AllowHexSpecifier, null, out _address))
            throw new IODeviceException("missing or wrong address in parameters string");
        if (!kv.TryGetValue("devices", out var devicesConfigFile))
            throw new IODeviceException("missing devices in parameters string");
        BuildDevices(devicesConfigFile);
        _prevSda = _prevScl = true;
        _mode = Mode.None;
        _logger = logger;
        _sentData = true;
        return null;
    }

    private void BuildDevices(string devicesCinfigFile)
    {
        using var stream = File.OpenRead(devicesCinfigFile);
        var devices = JsonSerializer.Deserialize<I2CDevice[]>(stream);
    }

    public void IoRead(IoEvent ev)
    {
        if (ev.Address == _address)
        {
            var result = _prevSda ? (_sentData ? (ushort)1 : (ushort)0) : (ushort)0;
            if (_prevScl)
                result |= 2;
            ev.Data = result;
        }
    }

    public void IoWrite(IoEvent ev)
    {
        if (ev.Address == _address)
        {
            var sda = (ev.Data & 1) != 0;
            var scl = (ev.Data & 2) != 0;
            if (_prevScl && scl && _prevSda != sda)
            {
                _mode = sda ? Mode.Address : Mode.None;
                _logger?.Info(sda ? "I2C slave start" : "I2C slave stop");
                _bitCounter = 0;
            }

            if (_mode != Mode.None && _prevScl && !scl)
            {
                if (_bitCounter < 8)
                {
                    _data <<= 1;
                    if (sda)
                        _data |= 1;
                }
                else
                {
                    _ack = GetAck();
                    _sentData = !_ack;
                }
            }
            
            _prevScl = scl;
            _prevSda = sda;
        }
    }

    private bool GetAck()
    {
        return false;
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}