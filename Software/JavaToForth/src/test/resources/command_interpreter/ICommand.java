package command_interpreter;

public interface ICommand {
    String getName();
    int minParameters();
    int maxParameters();
    void init();
    boolean validateParameter(int parameterNo, char[] buffer, int pos, int l);
    boolean run();
}
