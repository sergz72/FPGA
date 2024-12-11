namespace UsbDecoder;

public class UsbDecoder
{
    private const int IdleCounterMax = 2048;
    
    private enum UsbState
    {
        WaitIdle,
        WaitIdle2,
        Idle,
        ReceiveByte,
        Sync,
        DecodePacketId,
        PacketEnd,
        ReceiveNext
    }

    private UsbState _state = UsbState.WaitIdle;
    private UsbState _stateAfter = UsbState.WaitIdle;
    private int _idleCounter = 0;
    private int _bit = 1;
    private int _tickCounter = 0;
    private int _bitTickCounter = 0;
    private int _data = 0;
    private bool _prevK = true;
    private int _packetId = 0;
    private byte[] _packetData = new byte[64];
    private int _packetLength = 0;

    private void StartReceiving(UsbState stateAfter)
    {
        _data = 0;
        _bit = 1;
        _state = UsbState.ReceiveByte;
        _stateAfter = stateAfter;
    }
    
    public void Process(byte data)
    {
        var k = data == 2;
        var j = data == 1;
        var se0 = data == 0;
        var se1 = data == 3;
        
        _tickCounter++;
        if (_state == UsbState.Idle)
            _bitTickCounter = 0;
        else
            _bitTickCounter++;
        
        switch (_state)
        {
            case UsbState.WaitIdle:
                if (k)
                {
                    if (_idleCounter == IdleCounterMax)
                        _state = UsbState.Idle;
                    else
                        _idleCounter++;
                }
                else
                    _idleCounter = 0;
                break;
            case UsbState.WaitIdle2:
                if (k)
                    _state = UsbState.Idle;
                break;
            case UsbState.Idle:
                if (j)
                {
                    StartReceiving(UsbState.Sync);
                    _prevK = true;
                }
                break;
            case UsbState.ReceiveByte:
                if ((_bitTickCounter & 3) == 1)
                {
                    if (se1)
                        _state = UsbState.WaitIdle;
                    else if (se0)
                        _state = _stateAfter == UsbState.Sync ? UsbState.WaitIdle : UsbState.PacketEnd;
                    else if ((j & !_prevK) | (k & _prevK))
                        _data |= _bit;
                    if (_bit == 0x80)
                        _state = _stateAfter;
                    else
                        _bit <<= 1;
                    _prevK = k;
                }
                break;
            case UsbState.Sync:
                if (_data != 0x80)
                {
                    Console.WriteLine("Invalid sync byte at " + _tickCounter);
                    _state = UsbState.WaitIdle;
                }
                else
                {
                    StartReceiving(UsbState.DecodePacketId);
                    _packetId = 0;
                }
                break;
            case UsbState.DecodePacketId:
                _packetId = _data & 0x0F;
                if (_packetId == ((_data >> 4) ^ 0x0F))
                {
                    Console.WriteLine($"Packet id {_data:X} at {_tickCounter}");
                    _packetLength = 0;
                    StartReceiving(UsbState.ReceiveNext);
                }
                else
                {
                    Console.WriteLine($"Invalid packet id {_data:X} at {_tickCounter}");
                    _state = UsbState.WaitIdle;
                }
                break;
            case UsbState.ReceiveNext:
                _packetData[_packetLength++] = (byte)_data;
                StartReceiving(UsbState.ReceiveNext);
                break;
            case UsbState.PacketEnd:
                var s = BitConverter.ToString(_packetData[.._packetLength]);
                Console.WriteLine($"End packet {_packetId:X} with length {_packetLength} at {_tickCounter} {s}");
                _state = UsbState.WaitIdle2;
                DecodePacket();
                break;
        }
    }

    void DecodePacket()
    {
        switch (_packetId)
        {
            case 1: // OUT
                DecodeTokenPacket("OUT");
                break;
            case 2: // ACK
                Console.WriteLine("-ACK Packet");
                break;
            case 3:
                DecodeDataPacket("DATA0");
                break;
            case 4: // PING
                Console.WriteLine("-PING Packet");
                break;
            case 5: // SOF
                DecodeSOFPacket();
                break;
            case 6: // NYET
                Console.WriteLine("-NYET Packet");
                break;
            case 7:
                DecodeDataPacket("DATA2");
                break;
            case 8: // SPLIT
                Console.WriteLine("-SPLIT Packet");
                break;
            case 9: // IN
                DecodeTokenPacket("IN");
                break;
            case 0x0A: // NAK
                Console.WriteLine("-NAK Packet");
                break;
            case 0x0B:
                DecodeDataPacket("DATA1");
                break;
            case 0x0C: // PRE/ERR
                Console.WriteLine("-PRE/ERR Packet");
                break;
            case 0x0D: // SETUP
                DecodeTokenPacket("SETUP");
                break;
            case 0x0E: // STALL
                Console.WriteLine("-STALL Packet");
                break;
            case 0x0F:
                DecodeDataPacket("MDATA");
                break;
            default:
                Console.WriteLine("-UNKNOWN Packet");
                break;
        }
    }

    private void DecodeDataPacket(string name)
    {
        if (_packetLength < 2 || !CheckCrc16(_packetData, _packetLength))
            Console.WriteLine($"-Invalid {name} packet");
        else
            Console.WriteLine($"-{name} packet " + BitConverter.ToString(_packetData[..(_packetLength - 2)]));
    }
    
    private void DecodeSOFPacket()
    {
        var data = _packetData[0] + (_packetData[1] << 8);
        if (_packetLength != 2 || !CheckCrc5(data))
            Console.WriteLine("-Invalid SOF packet");
        else
            Console.WriteLine("-SOF packet " + (data & 0x7FF));
    }

    private void DecodeTokenPacket(string name)
    {
        var data = _packetData[0] + (_packetData[1] << 8);
        if (_packetLength != 2 || !CheckCrc5(data))
            Console.WriteLine($"-Invalid {name} packet");
        else
        {
            var addr = data & 0x7F;
            var endp = (data >> 7) & 0x0F;
            Console.WriteLine($"-{name} packet ADDR {addr} ENDP {endp}");
        }
    }
    
    public static bool CheckCrc5(int data)
    {
        var res = 0x1f;

        for (var i = 0;  i < 16;  ++i)
        {
            var b = (data & 1) != (res & 1);
            data >>= 1;
            res >>= 1;
            if (b)
                res ^= 0x14;
        }
        
        return res == 0x06;
    }
    
    private static bool CheckCrc16(byte[] data, int length)
    {
        var res = 0xFFFF;

        var idx = 0;
        var cdata = data[0];
        var bit = 0; 
        for (var i = 0;  i < length * 8;  ++i)
        {
            var b = (cdata & 1) != (res & 1);
            cdata >>= 1;
            res >>= 1;
            bit++;
            if (bit == 8)
            {
                idx++;
                bit = 0;
                if (idx < data.Length)
                    cdata = data[idx];
            }
            if (b)
                res ^= 0xA001;
        }
        
        return res == 0xB001;
    }
}