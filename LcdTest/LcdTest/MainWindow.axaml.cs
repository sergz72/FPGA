using Avalonia.Controls;

namespace LcdTest;

public partial class MainWindow : Window
{
    public MainWindow(string fontFileName)
    {
        InitializeComponent();
        Lcd.Init(128, 64, 8, fontFileName);
        Lcd.DrawCharAtPos(0, 0, '1');
        Lcd.DrawCharAtPos(1, 0, '2');
        Lcd.DrawCharAtPos(2, 0, '3');
        Lcd.DrawCharAtPos(3, 0, '.');
        Lcd.DrawCharAtPos(4, 0, '4');
        Lcd.DrawCharAtPos(5, 0, '5');
        Lcd.DrawCharAtPos(6, 0, '6');
        Lcd.DrawCharAtPos(7, 0, '.');
        Lcd.DrawCharAtPos(8, 0, '7');
        Lcd.DrawCharAtPos(9, 0, '8');
        Lcd.DrawCharAtPos(10, 0, '9');
        Lcd.DrawCharAtPos(11, 0, 'H');
        Lcd.DrawCharAtPos(12, 0, 'z');
    }
}