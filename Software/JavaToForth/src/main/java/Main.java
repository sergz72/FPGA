import classfile.ClassFile;
import classfile.ClassFileException;
import translator.ForthTranslator;
import translator.TranslatorException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Objects;
import java.util.stream.Stream;

public final class Main {
    public static void main(String[] args) throws IOException {
        if (args.length < 3 || !args[0].endsWith(".json"))
            Usage();
        var fileNames = args.length == 3 && args[2].startsWith("@")
                ? buildFileNames(args[2].substring(1))
                : Arrays.stream(args).skip(2);
        var mainClassName = args[1];
        var configurationFileName = args[0];
        var errors = new ArrayList<String>();
        var classes = fileNames
                .map(arg -> {
                    try {
                        return new ClassFile(Files.readAllBytes(Paths.get(arg)), arg);
                    } catch (ClassFileException e) {
                        errors.add(arg + ": ClassFileException: " + e.getMessage());
                        return null;
                    } catch (IOException e) {
                        errors.add(arg + ": file error: " + e.getMessage());
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .toList();
        if (!errors.isEmpty()) {
            for (var error: errors)
                System.out.println(error);
            System.exit(2);
        }
        try {
            new ForthTranslator(mainClassName, classes, configurationFileName).translate();
        } catch (IOException | TranslatorException | ClassFileException e) {
            System.out.println(e.getMessage());
            e.printStackTrace();
        }
    }

    private static Stream<String> buildFileNames(String listFileName) throws IOException {
        return Files.readAllLines(Paths.get(listFileName)).stream();
    }

    private static void Usage() {
        System.out.println("Usage: java -jar JavaToForth.jar config_file_name main_class_name class_file_names");
        System.exit(1);
    }
}