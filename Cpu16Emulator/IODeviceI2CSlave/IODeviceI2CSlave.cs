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
        Write,
        Read
    }

    public interface I2CDevice
    {
        byte Read(ILogger logger, string name, int byteNo);
        void Write(ILogger logger, string name, int byteNo, byte value);
    }

    public record I2CDeviceData(string Name, I2CDevice Device);
    
    public record I2CDeviceConfiguration(string DeviceName, string DeviceType, int Address, string Parameters)
    {
        internal I2CDeviceData BuildDevice()
        {
            return new I2CDeviceData(DeviceName, BuildI2CDevice());
        }

        private I2CDevice BuildI2CDevice()
        {
            return DeviceType switch
            {
                "MCP3425" => new MCP3425(Parameters),
                "MCP4725" => new MCP4725(Parameters),
                _ => throw new IODeviceException("Unknown I2C device type: " + DeviceType)
            };
        }
    }
    
    private ushort _address;
    private bool _prevSda;
    private bool _prevScl;
    private bool _sentData;
    private bool _ack;
    private Mode _mode;
    private ILogger? _logger;
    private int _bitCounter, _byteCounter;
    private int _data;
    private Dictionary<int, I2CDeviceData> _devices = [];
    private I2CDeviceData? _currentDevice;
    private byte _readData;

    public Control? Init(string parameters, ILogger logger)
    {
        var kv = IODeviceParametersParser.ParseParameters(parameters);
        _address = IODeviceParametersParser.ParseUShort(kv, "address") ?? 
                   throw new IODeviceException("i2cSlave: missing or wrong address parameter");
        if (!kv.TryGetValue("devices", out var devicesConfigFile))
            throw new IODeviceException("i2cSlave: missing devices parameter");
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
        var devices = JsonSerializer.Deserialize<I2CDeviceConfiguration[]>(stream);
        if (devices == null)
            throw new IODeviceException("could not read devices configuration");
        _devices = devices.ToDictionary(d => d.Address, d => d.BuildDevice());
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
                    if (_mode is Mode.Address or Mode.Write)
                    {
                        _data <<= 1;
                        if (sda)
                            _data |= 1;
                    }
                    else
                    {
                        _sentData = (_readData & 0x80) != 0;
                        _readData <<= 1;
                    }
                }
                else
                {
                    if (_mode == Mode.Address)
                    {
                        _mode = (_data & 1) != 0 ? Mode.Read : Mode.Write;
                        _ack = GetAck();
                    }
                    else
                    {
                        if (_currentDevice == null)
                            throw new IODeviceException("null currentDevice");
                        if (_mode == Mode.Read)
                        {
                            _readData = _currentDevice.Device.Read(_logger!, _currentDevice.Name, _byteCounter + 1);
                            _ack = false;
                        }
                        else
                            _currentDevice.Device.Write(_logger!, _currentDevice.Name, _byteCounter, (byte)_data);
                        _byteCounter++;
                    }
                    _sentData = !_ack;
                    _bitCounter = 0;
                }
            }
            
            _prevScl = scl;
            _prevSda = sda;
        }
    }

    private bool GetAck()
    {
        if (!_devices.TryGetValue(_data & 0xFE, out _currentDevice))
        {
            _currentDevice = null;
            _logger?.Error($"unknown I2C Device address: {_data}");
            return false;
        }

        if (_mode == Mode.Read)
            _readData = _currentDevice.Device.Read(_logger!, _currentDevice.Name, 0);
        
        return true;
    }

    public bool? TicksUpdate(int cpuSped, int ticks)
    {
        return null;
    }
}