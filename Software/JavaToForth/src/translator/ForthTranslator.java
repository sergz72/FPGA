package translator;

import classfile.ClassFile;
import classfile.ClassFileException;
import classfile.MethodsItem;

import java.io.IOException;
import java.util.*;

public final class ForthTranslator {
    TranslatorConfiguration configuration;
    Map<String, ClassFile> classes;
    HashSet<String> toTranslate;

    public ForthTranslator(List<ClassFile> classes, TranslatorConfiguration configuration) throws ClassFileException {
        this.configuration = configuration;
        this.classes = buildClasses(classes);
        this.toTranslate = new HashSet<>();
    }

    public ForthTranslator(List<ClassFile> classes, String configurationFileName)
            throws IOException, TranslatorException, ClassFileException {
        this.configuration = TranslatorConfiguration.load(configurationFileName);
        this.classes = buildClasses(classes);
        this.toTranslate = new HashSet<>();
    }

    private static Map<String, ClassFile> buildClasses(List<ClassFile> classFiles) throws ClassFileException {
        var result = new HashMap<String, ClassFile>();
        for (ClassFile classFile : classFiles) {
            result.put(classFile.GetName(), classFile);
        }
        return result;
    }

    public void translate() throws TranslatorException, ClassFileException {
        buildInitialClassNames();
        var saved = new HashSet<>();
        while (saved.size() != toTranslate.size()) {
            var delta = toTranslate.stream().filter(s -> !saved.contains(s)).toList();
            saved.addAll(delta);
            for (var className : delta)
                translate(className);
        }
    }

    private void buildInitialClassNames() throws TranslatorException {
        toTranslate.add(buildClassName(configuration.code.entryPoint));
        for (var handler: configuration.code.isrHandlers)
            toTranslate.add(buildClassName(handler));
    }

    private String buildClassName(String methodName) throws TranslatorException {
        var idx = methodName.indexOf('.');
        if (idx <= 0)
            throw new TranslatorException("invalid method name: " + methodName);
        return methodName.substring(0, idx);
    }

    private void translate(String className) throws TranslatorException, ClassFileException {
        System.out.printf("Translating %s...\n", className);
        if (!classes.containsKey(className))
            throw new TranslatorException("Unknown class name " + className);
        translate(classes.get(className));
    }

    private void translate(ClassFile classFile) throws ClassFileException, TranslatorException {
        for (var method : classFile.getMethods().entrySet())
            translate(method.getKey(), method.getValue());
    }

    private void translate(String methodName, MethodsItem method) throws ClassFileException, TranslatorException {
        System.out.printf("  Translating %s...\n", methodName);
        var generator = new InstructionGenerator();
        for (var instruction: method.getCode())
            translate(instruction & 0xFF, generator);
    }

    private void translate(int instruction, InstructionGenerator generator) throws TranslatorException {
        System.out.printf("  Translating %d\n", instruction);
        switch (instruction)
        {
            case 1: // aconst_null
                generator.addPush(0);
                break;
            case 0xbe: // arraylength
                generator.addGet();
                break;
            case 0x2a: // aload_0
                generator.addGetLocal(0);
                break;
            case 0x2b: // aload_1
                generator.addGetLocal(1);
                break;
            case 0x2c: // aload_2
                generator.addGetLocal(2);
                break;
            case 0x2d: // aload_3
                generator.addGetLocal(3);
                break;
            case 0x32: // aaload
            case 0x3a: // astore
            case 0x4b: // astore 0
            case 0x4c: // astore 1
            case 0x4d: // astore 2
            case 0x4e: // astore 3
            case 0x53: // aastore
            case 0xb0: // areturn
            case 0xbd: // anewarray
            case 0xbf: // athrow
            default: throw new TranslatorException("unknown instruction " + instruction);
        }
    }
}
