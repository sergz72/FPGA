using Avalonia.Controls;

namespace Cpu16EmulatorCommon;

public sealed class KS0108: StackPanel
{
    private class KS0108Device(int scale): LCD1(new ushort[256], 64, scale)
    {
        private int _address = 0;
        private int _page = 0;
        private int _startLine = 0;
        
        internal void SendCommand(byte command)
        {
            
        }
    
        public void SendData(byte data)
        {
        }
    }
    
    private readonly KS0108Device[] _devices;

    public KS0108(int scale)
    {
        _devices = new KS0108Device[2] { new KS0108Device(scale), new KS0108Device(scale)};
        Orientation = Avalonia.Layout.Orientation.Horizontal;
        Children.AddRange(_devices);
    }
    
    public void SendCommand(bool cs1, byte command)
    {
        var idx = cs1 ? 0 : 1;
        _devices[idx].SendCommand(command);
    }
    
    public void SendData(bool cs1, byte data)
    {
        var idx = cs1 ? 0 : 1;
        _devices[idx].SendData(data);
    }
}