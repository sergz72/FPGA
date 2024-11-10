using Avalonia.Controls;
using Avalonia.Interactivity;

namespace Cpu16Emulator;

public partial class MessageBoxWindow : Window
{
    public MessageBoxWindow(string title, string text)
    {
        InitializeComponent();
        Title = title;
        LbText.Content = text;
    }

    private void BnClose_OnClick(object? sender, RoutedEventArgs e)
    {
        Close();
    }
}