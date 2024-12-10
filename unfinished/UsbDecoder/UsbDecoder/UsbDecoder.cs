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
                if ((_bitTickCounter & 3) == 2)
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
                _packetData[_packetLength++] = data;
                StartReceiving(UsbState.ReceiveNext);
                break;
            case UsbState.PacketEnd:
                Console.WriteLine($"End packet {_packetId:X} with length {_packetLength} at {_tickCounter}");
                _state = UsbState.WaitIdle2;
                DecodePacket();
                break;
        }
    }

    void DecodePacket()
    {
        switch (_packetId)
        {
            case 5: // SOF
                DecodeTokenPacket("SOF");
                break;
        }
    }

    private void DecodeTokenPacket(string name)
    {
        var token = GetToken();
        if (_packetLength != 2 || !CheckCrc5(token))
            Console.WriteLine($"Invalid {name} packet");
        else
            Console.WriteLine("SOF packet " + token);
    }

    private int GetToken()
    {
        return _packetData[0] + ((_packetData[1] & 7) << 8);
    }

    private bool CheckCrc5(int token)
    {
        var expected = _packetData[1] >> 3;
        var res = 0x1f;

        for (var i = 0;  i < 11;  ++i)
        {
            var b = ((token ^ res) & 1) != 0;
            token >>= 1;
            res >>= 1;
            if (b)
                res ^= 0x14;
        }
        var crc = res ^ 0x1f;

        return expected == crc;
    }
}