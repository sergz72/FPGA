using Avalonia.Controls;

namespace LcdTest;

public partial class MainWindow : Window
{
    public MainWindow(string fontFileName)
    {
        InitializeComponent();
        Lcd.Init(128, 64, 8, fontFileName);
        Lcd.Clear();
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
        
        Lcd.DrawCharAtPos(0, 1, '0', true);
        Lcd.DrawCharAtPos(1, 1, '1', true);
        Lcd.DrawCharAtPos(2, 1, '.', true);
        Lcd.DrawCharAtPos(3, 1, '9', true);
        Lcd.DrawCharAtPos(4, 1, '8', true);
        Lcd.DrawCharAtPos(5, 1, '7', true);
        Lcd.DrawCharAtPos(6, 1, 'V', true);

        Lcd.DrawCharAtPos(0, 2, '1');
        Lcd.DrawCharAtPos(1, 2, '0');
        Lcd.DrawCharAtPos(2, 2, '.');
        Lcd.DrawCharAtPos(3, 2, '4');
        Lcd.DrawCharAtPos(4, 2, '5');
        Lcd.DrawCharAtPos(5, 2, '6');
        Lcd.DrawCharAtPos(6, 2, 'V');

        Lcd.DrawCharAtPos(0, 3, '1');
        Lcd.DrawCharAtPos(1, 3, '0');
        Lcd.DrawCharAtPos(2, 3, '.');
        Lcd.DrawCharAtPos(3, 3, '4');
        Lcd.DrawCharAtPos(4, 3, '5');
        Lcd.DrawCharAtPos(5, 3, '6');
        Lcd.DrawCharAtPos(6, 3, 'V');

        Lcd.DrawCharAtPos(0, 4, '1');
        Lcd.DrawCharAtPos(1, 4, '0');
        Lcd.DrawCharAtPos(2, 4, '.');
        Lcd.DrawCharAtPos(3, 4, '4');
        Lcd.DrawCharAtPos(4, 4, '5');
        Lcd.DrawCharAtPos(5, 4, '6');
        Lcd.DrawCharAtPos(6, 4, 'V');

        Lcd.DrawCharAtPos(9, 4, '2');
        Lcd.DrawCharAtPos(10, 4, '.');
        Lcd.DrawCharAtPos(11, 4, '4');
        Lcd.DrawCharAtPos(12, 4, 'V');
    }
}