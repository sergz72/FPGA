package translator;

import classfile.ClassFile;
import classfile.ClassFileException;
import classfile.MethodOrField;
import classfile.constantpool.*;
import translator.instructions.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public final class ForthTranslator {
    private static final String staticConstructor = "<clinit>()V";
    private static final Set<String> builtInClasses = Set.of("java/lang/Object", "java/lang/String");
    private static final Set<String> ignoreMethodCalls = Set.of("java/lang/String.toCharArray()[C");

    TranslatorConfiguration configuration;
    Map<String, ClassFile> classes;
    HashSet<String> toTranslate;
    ClassFile currentClassFile;
    InstructionGenerator instructionGenerator;
    Segment data, roData;
    Map<String, Integer> dataSegmentMapping;
    MethodOrField currentMethod;
    String currentMethodName;
    Map<String, List<Instruction>> methodInstructions;

    public ForthTranslator(List<ClassFile> classes, TranslatorConfiguration configuration) throws ClassFileException {
        this.configuration = configuration;
        this.classes = buildClasses(classes);
        this.toTranslate = new HashSet<>();
        this.data = new Segment("data", configuration.data.address, configuration.data.size);
        this.roData = new Segment("rodata", configuration.roData.address, configuration.roData.size);
        this.methodInstructions = new HashMap<>();
        this.dataSegmentMapping = new HashMap<>();
    }

    public ForthTranslator(String mainClassName, List<ClassFile> classes, String configurationFileName)
            throws IOException, TranslatorException, ClassFileException {
        this(classes, TranslatorConfiguration.load(mainClassName, configurationFileName));
    }

    private static Map<String, ClassFile> buildClasses(List<ClassFile> classFiles) throws ClassFileException {
        var result = new HashMap<String, ClassFile>();
        for (ClassFile classFile : classFiles) {
            result.put(classFile.getName(), classFile);
        }
        return result;
    }

    public void translate() throws TranslatorException, ClassFileException, IOException {
        buildInitialClassNames();
        var saved = new HashSet<>();
        while (saved.size() != toTranslate.size()) {
            var delta = toTranslate.stream().filter(s -> !saved.contains(s)).toList();
            saved.addAll(delta);
            for (var className : delta)
                translate(className);
        }
        var labels = new HashMap<Integer, String>();
        var code = link(labels);
        createOutputFiles(code, labels);
    }

    private void buildInitialClassNames() throws TranslatorException {
        toTranslate.add(buildClassName(configuration.code.entryPoint));
        for (var handler: configuration.code.isrHandlers)
            toTranslate.add(buildClassName(handler));
    }

    private static String buildClassName(String methodName) throws TranslatorException {
        var idx = methodName.indexOf('.');
        if (idx <= 0)
            throw new TranslatorException("invalid method name: " + methodName);
        return methodName.substring(0, idx);
    }

    private void translate(String className) throws TranslatorException, ClassFileException {
        System.out.printf("Translating %s...\n", className);
        if (!classes.containsKey(className))
            throw new TranslatorException("Unknown class name " + className);
        currentClassFile = classes.get(className);
        translateCurrentClassFile();
    }

    private void translateCurrentClassFile() throws ClassFileException, TranslatorException {
        for (var method : currentClassFile.getMethods().entrySet()) {
            if (method.getValue().isNative())
                System.out.printf("  Skipping native method %s...\n", method.getKey());
            else {
                currentMethod = method.getValue();
                currentMethodName = method.getKey();
                System.out.printf("  Translating %s...\n", method.getKey());
                translateCurrentMethod();
            }
        }
    }

    private void translateCurrentMethod() throws ClassFileException, TranslatorException {
        instructionGenerator = new InstructionGenerator(0);
        createProlog();
        int pc = 0;
        var code = currentMethod.getCode();
        while (pc < code.length)
            pc = translate(code, pc);
        instructionGenerator.finish();
        methodInstructions.put(currentMethodName, instructionGenerator.getInstructions());
    }

    private void createProlog() throws ClassFileException {
        var localsCount = currentMethod.getNumberOfLocals();
        if (localsCount != 0)
        {
            instructionGenerator.addLocals(localsCount);
            var parametersCount = currentMethod.getNumberOfParameters();
            if (!currentMethod.isStatic())
                parametersCount++;
            while (parametersCount != 0) {
                parametersCount--;
                instructionGenerator.addSetLocal(parametersCount);
            }
        }
    }

    private int translate(byte[] code, int pc) throws TranslatorException, ClassFileException {
        instructionGenerator.setCurrentBytecodePc(pc);
        var instruction = code[pc++] & 0xFF;
        int index;
        switch (instruction)
        {
            case 0: // nop
                instructionGenerator.addNop();
                break;
            case 1: // aconst_null
                instructionGenerator.addBPush(0, "aconst_null");
                break;
            case 3: // iconst_0
                instructionGenerator.addBPush(0, "iconst_0");
                break;
            case 9: // lconst_0
                instructionGenerator.addBPush(0, "lconst_0");
                break;
            case 2: // iconst_m1
                instructionGenerator.addBPush(-1, "iconst_m1");
                break;
            case 4: // iconst_1
                instructionGenerator.addBPush(1, "iconst_1");
                break;
            case 0x0A: // lconst_1
                instructionGenerator.addBPush(1, "lconst_1");
                break;
            case 5: // iconst_2
                instructionGenerator.addBPush(2, "iconst_2");
                break;
            case 6: // iconst_3
                instructionGenerator.addBPush(3, "iconst_3");
                break;
            case 7: // iconst_4
                instructionGenerator.addBPush(4, "iconst_4");
                break;
            case 8: // iconst_5
                instructionGenerator.addBPush(5, "iconst_5");
                break;
            case 0x11: // sipush
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addSPush(index, "sipush");
                break;
            case 0x12: // ldc
                translateLdc(code[pc++] & 0xFF);
                break;
            case 0x13: // ldc_w
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                translateLdc(index);
                break;
            case 0x14: // ldc2_w
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                translateLdc2(index);
                break;
            case 0x15: // iload
            case 0x16: // lload
            case 0x19: // aload
                instructionGenerator.addGetLocal(code[pc++] & 0xFF);
                break;
            case 0x1a: // iload_0
            case 0x1e: // lload_0
            case 0x2a: // aload_0
                instructionGenerator.addGetLocal(0);
                break;
            case 0x1b: // iload_1
            case 0x1f: // lload_1
            case 0x2b: // aload_1
                instructionGenerator.addGetLocal(1);
                break;
            case 0x1c: // iload_2
            case 0x20: // lload_2
            case 0x2c: // aload_2
                instructionGenerator.addGetLocal(2);
                break;
            case 0x1d: // iload_3
            case 0x21: // lload_3
            case 0x2d: // aload_3
                instructionGenerator.addGetLocal(3);
                break;
            case 0x36: // istore
            case 0x37: // lstore
            case 0x3a: // astore
                instructionGenerator.addSetLocal(code[pc++] & 0xFF);
                break;
            case 0x3b: // istore_0
            case 0x3f: // lstore_0
            case 0x4b: // astore_0
                instructionGenerator.addSetLocal(0);
                break;
            case 0x3c: // istore_1
            case 0x40: // lstore_1
            case 0x4c: // astore_1
                instructionGenerator.addSetLocal(1);
                break;
            case 0x3d: // istore_2
            case 0x41: // lstore_2
            case 0x4d: // astore_2
                instructionGenerator.addSetLocal(2);
                break;
            case 0x3e: // istore_3
            case 0x42: // lstore_3
            case 0x4e: // astore_3
                instructionGenerator.addSetLocal(3);
                break;
            case 0x10: // bipush
                index = code[pc++];
                instructionGenerator.addBPush(index, "bipush");
                break;
            case 0x57:
                instructionGenerator.addDrop();
                break;
            case 0x58:
                instructionGenerator.addDrop2();
                break;
            case 0x59:
                instructionGenerator.addDup();
                break;
            case 0x5C: // dup_x2
                instructionGenerator.addDup2();
                break;
            case 0x5F: // swap
                instructionGenerator.addSwap();
                break;
            case 0x60: // iadd
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_ADD, "iadd");
                break;
            case 0x61: // ladd
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_ADD, "ladd");
                break;
            case 0x64: // isub
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_SUB, "isub");
                break;
            case 0x65: // lsub
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_SUB, "lsub");
                break;
            case 0x68: // imul
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_MUL, "imul");
                break;
            case 0x69: // lmul
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_MUL, "lmul");
                break;
            case 0x74: // ineg
            case 0x75: // lneg
                instructionGenerator.addNeg();
                break;
            case 0x78: // ishl
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_SHL, "ishl");
                break;
            case 0x79: // lshl
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_SHL, "lshl");
                break;
            case 0x7a: // ishr
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_ASHR, "ishr");
                break;
            case 0x7b: // ishr
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_ASHR, "lshr");
                break;
            case 0x7c: // iushr
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_ILSHR, "iushr");
                break;
            case 0x7d: // lushr
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_LLSHR, "lushr");
                break;
            case 0x7e: // iand
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_AND, "iand");
                break;
            case 0x7f: // land
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_AND, "land");
                break;
            case 0x80: // ior
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_OR, "ior");
                break;
            case 0x81: // lor
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_OR, "lor");
                break;
            case 0x82: // ixor
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_XOR, "ixor");
                break;
            case 0x83: // lxor
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_XOR, "lxor");
                break;
            case 0x84: // iinc
                index = code[pc++] & 0xFF;
                var value = code[pc++];
                instructionGenerator.addInc(index, value);
                break;
            case 0x99: // ifeq
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_EQ, "ifeq", index, pc - 3);
                break;
            case 0x9b: // iflt
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_LT, "ifeq", index, pc - 3);
                break;
            case 0xc6: // ifnull
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_EQ, "ifnull", index, pc - 3);
                break;
            case 0x9a: // ifne
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_NE, "ifne", index, pc - 3);
                break;
            case 0xc7: // ifnonnull
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_NE, "ifnonnull", index, pc - 3);
                break;
            case 0x94: // lcmp
                instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_CMP, "lcmp");
                break;
            case 0x9c: // ifge
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_GE, "ifge", index, pc - 3);
                break;
            case 0x9d: // ifgt
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_GT, "ifgt", index, pc - 3);
                break;
            case 0x9e: // ifle
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIf(InstructionGenerator.IF_LE, "ifle", index, pc - 3);
                break;
            case 0x9f: // if_icmpeq
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_EQ, "if_icmpeq", index, pc - 3);
                break;
            case 0xa5: // if_acmpeq
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_EQ, "if_acmpeq", index, pc - 3);
                break;
            case 0xa0: // if_icmpne
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_NE, "if_icmpne", index, pc - 3);
                break;
            case 0xa6: // if_acmpne
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_NE, "if_acmpne", index, pc - 3);
                break;
            case 0xa1: // if_icmplt
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_LT, "if_icmplt", index, pc - 3);
                break;
            case 0xa2: // if_icmpge
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_GE, "if_icmpge", index, pc - 3);
                break;
            case 0xa3: // if_icmpgt
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_GT, "if_icmpgt", index, pc - 3);
                break;
            case 0xa4: // if_icmple
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_LE, "if_icmple", index, pc - 3);
                break;
            case 0xa7: // goto
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                instructionGenerator.addJmp(index, pc - 3);
                break;
            case 0xac: // ireturn
            case 0xad: // lreturn
            case 0xb0: // areturn
            case 0xb1: // return
                translateReturn();
                break;
            case 0xb6: // invokevirtual
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                translateInvokeVirtual(index);
                break;
            case 0xb7: // invokespecial
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                translateInvokeSpecial(index);
                break;
            case 0xb8: // invokestatic
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                translateInvokeStatic(index);
                break;
            case 0xbe: // arraylength
                instructionGenerator.addGet("get (arraylength)");
                break;
            case 0x2f: // laload
                translateLALoad();
                break;
            case 0x32: // aaload
            case 0x33: // baload
            case 0x34: // caload
            case 0x35: // saload
                translateALoad();
                break;
            case 0x50: // lastore
                translateLAStore();
                break;
            case 0x53: // aastore
            case 0x54: // bastore
            case 0x55: // castore
            case 0x56: // sastore
                translateAStore();
                break;
            case 0x6c: // idiv
                instructionGenerator.addDiv("idiv");
                break;
            case 0x6d: // ldiv
                instructionGenerator.addDiv("ldiv");
                break;
            case 0x70: // irem
                instructionGenerator.addRem("irem");
                break;
            case 0x71: // lrem
                instructionGenerator.addRem("lrem");
                break;
            case 0xaa: // tableswitch
                throw new TranslatorException("tableswitch is not supported");
            case 0xab: // lookupswitch
                throw new TranslatorException("lookupswitch is not supported");
            case 0xb2: // getstatic
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                translateGetStatic(index);
                break;
            case 0xb3: // putstatic
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                translatePutStatic(index);
                break;
            case 0xb4: // getfield
                throw new TranslatorException("getfield is not supported");
            case 0xb5: // putfield
                throw new TranslatorException("putfield is not supported");
            case 0xbb: // new
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                translateNew(index);
                break;
            case 0xbc: // newarray
                translateNewArray(code[pc++]);
                break;
            case 0xbd: // anewarray
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                translateANewArray(index);
                break;
            case 0xbf: // athrow
                throw new TranslatorException("athrow is not supported");
            case 0xc5: // multianewarray
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                var dimensions = code[pc++];
                translateMultiANewArray(index, dimensions);
                break;
            case 0x85: //i2l
            case 0x88: //l2i
            case 0x91: //i2b
            case 0x92: //i2c
            case 0x93: //i2s
                break;
            case 0x5A: // dup_x1
            case 0x5B: // dup_x2
            case 0x5D: // dup2_x1
            case 0x5E: // dup2_x2
            default: throw new TranslatorException(String.format("unknown instruction %x", instruction));
        }
        return pc;
    }

    private int buildFieldAddress(String name, boolean isLong) {
        if (dataSegmentMapping.containsKey(name))
            return dataSegmentMapping.get(name);
        var address = data.allocate(isLong ? 2 : 1);
        dataSegmentMapping.put(name, address);
        return address;
    }

    private void translatePutStatic(int index) throws ClassFileException {
        var name = currentClassFile.getFieldName(index);
        var isLong = currentClassFile.isLongField(index);
        var address = buildFieldAddress(name, isLong);
        instructionGenerator.addPush(address, "push " + name);
        if (isLong)
            instructionGenerator.addSetLong();
        else
            instructionGenerator.addSet();
    }

    private void translateGetStatic(int index) throws TranslatorException, ClassFileException {
        var name = currentClassFile.getFieldName(index);
        var isLong = currentClassFile.isLongField(index);
        var address = buildFieldAddress(name, isLong);
        instructionGenerator.addPush(address, "push " + name);
        if (isLong)
            instructionGenerator.addGetLong();
        else
            instructionGenerator.addGet("getstatic");
    }

    private void translateNew(int index) throws ClassFileException {
        var name = currentClassFile.getName(index);
        var cls = classes.get(name);
        var size = cls.calculateFieldsSize(classes);
        var methods = cls.buildMethodsList(classes);
        var address = buildMethodsTable(methods);
        instructionGenerator.addPush(address, String.format("push %d (new %s methods table address)", address, name));
        instructionGenerator.addPush(size, String.format("push %d (new %s fields size)", size, name));
        instructionGenerator.addCall("System.newObject(II)I");
        instructionGenerator.addDup();
        instructionGenerator.addCall(name + ".<init>()");
    }

    private int buildMethodsTable(List<String> methods) {
        throw new UnsupportedOperationException();
    }

    private void translateANewArray(int index) throws ClassFileException {
        instructionGenerator.addCall("System.newArray(I)I");
    }

    private void translateMultiANewArray(int index, int dimensions) throws TranslatorException {
        throw new TranslatorException("multianewarray is not supported");
    }

    private void translateNewArray(int type) throws TranslatorException {
        if (type == 7 || type == 11) // double or long
            instructionGenerator.addCall("System.newLongArray(I)I");
        else
            instructionGenerator.addCall("System.newArray(I)I");
    }

    private void translateALoad() {
        instructionGenerator.addArrayp();
        instructionGenerator.addGet("get (aload)");
    }

    private void translateLALoad() {
        instructionGenerator.addArrayp2();
        instructionGenerator.addGetLong();
    }

    private void translateAStore() {
        instructionGenerator.addRot();
        instructionGenerator.addRot();
        instructionGenerator.addArrayp();
        instructionGenerator.addSet();
    }

    private void translateLAStore() {
        instructionGenerator.addRot();
        instructionGenerator.addRot();
        instructionGenerator.addArrayp2();
        instructionGenerator.addSetLong();
    }

    private void translateReturn() throws ClassFileException {
        var locals = currentMethod.getNumberOfLocals();
        if (isIsr(currentMethodName))
            instructionGenerator.addReti(locals);
        else
            instructionGenerator.addReturn(locals);
    }

    private void addToTranslate(String name) {
        if (!builtInClasses.contains(name))
            toTranslate.add(name);
    }

    private void translateInvokeVirtual(int index) throws ClassFileException {
        var name = currentClassFile.getMethodClassName(index);
        addToTranslate(name);
        name = currentClassFile.getMethodName(index);
        if (shouldBeIgnored(name))
            return;
        var idx = currentClassFile.getMethodIndex(index);
        instructionGenerator.addIndirectCall(idx, name);
    }

    private boolean shouldBeIgnored(String name) {
        var ignore = ignoreMethodCalls.contains(name);
        if (ignore)
            System.out.println("Ignoring call to " + name);
        return ignore;
    }

    private boolean translateUsingInlines(String name) {
        var canBeTranslated = configuration.inlines.containsKey(name);
        if (canBeTranslated) {
            var inline = configuration.inlines.get(name);
            instructionGenerator.addOpcodes(inline.code, inline.comment + " (" + name + ")");
        }
        return canBeTranslated;
    }

    private void translateInvokeSpecial(int index) throws ClassFileException {
        translateInvokeStatic(index);
    }

    private void translateInvokeStatic(int index) throws ClassFileException {
        var name = currentClassFile.getMethodClassName(index);
        addToTranslate(name);
        name = currentClassFile.getMethodName(index);
        if (shouldBeIgnored(name) | translateUsingInlines(name))
            return;
        instructionGenerator.addCall(name);
    }

    private void generatePush(long value, String comment) {
        if (value <= Byte.MAX_VALUE && value >= Byte.MIN_VALUE)
            instructionGenerator.addBPush((int)value, comment);
        else if (value <= Short.MAX_VALUE && value >= Short.MIN_VALUE)
            instructionGenerator.addSPush((int)value, comment);
        else if (value <= Integer.MAX_VALUE && value >= Integer.MIN_VALUE)
            instructionGenerator.addPush((int)value, comment);
        else
            instructionGenerator.addPushLong(value);
    }

    private void translateLdc(int index) throws ClassFileException {
        var item = currentClassFile.getFromConstantPool(index);
        switch(item) {
            case IntConstantPoolItem i:
                generatePush(i.getValue(), "ldc int");
                break;
            case StringConstantPoolItem s:
                generatePush(buildStringConstant(s.getStringIndex()), "ldc " + currentClassFile.getUtf8Constant(s.getStringIndex()));
                break;
            default:
                throw new ClassFileException("unsupported constant pool item type for ldc/lcd_w");
        };
    }

    private void translateLdc2(int index) throws ClassFileException {
        var item = currentClassFile.getFromConstantPool(index);
        switch(item) {
            case LongConstantPoolItem l:
                generatePush(l.getValue(), "ldc long");
                break;
            default:
                throw new ClassFileException("unsupported constant pool item type for ldc2_w");
        };
    }

    private int buildStringConstant(int stringIndex) throws ClassFileException {
        var name = currentClassFile.getFieldName(stringIndex);
        if (dataSegmentMapping.containsKey(name))
            return dataSegmentMapping.get(name);
        var s = currentClassFile.getUtf8Constant(stringIndex);
        var data = new int[s.length()+1];
        data[0] = s.length();
        int idx = 1;
        for (char c : s.toCharArray()) {
            data[idx++] = c;
        }
        var address = roData.addInstruction(new InlineInstruction(null, data, "string " + s));
        dataSegmentMapping.put(name, address);
        return address;
    }

    private List<Instruction> link(HashMap<Integer, String> labelMap) throws TranslatorException {
        var labels = new HashMap<String, Integer>();
        var instructions = new ArrayList<Instruction>();
        var generator = new InstructionGenerator(null);
        if (configuration.code.isrHandlers != null && configuration.code.isrHandlers.length > 0) {
            generator.addCall(configuration.code.entryPoint);
            generator.addHlt();
            for (var i = 0; i < configuration.code.isrHandlers.length - 1; i++) {
                generator.addJmpToLabel(configuration.code.isrHandlers[i]);
                generator.addHlt();
                generator.addHlt();
            }
        }
        var ins = generator.getInstructions();
        var pc = ins.stream().mapToInt(Instruction::getSize).sum();
        instructions.addAll(ins);
        if (configuration.code.isrHandlers.length > 0) {
            labels.put(configuration.code.isrHandlers[configuration.code.isrHandlers.length - 1], pc);
            ins = methodInstructions.get(configuration.code.isrHandlers[configuration.code.isrHandlers.length - 1]);
            pc += ins.stream().mapToInt(Instruction::getSize).sum();
            instructions.addAll(ins);
            for (var i = 0; i < configuration.code.isrHandlers.length - 1; i++) {
                labels.put(configuration.code.isrHandlers[i], pc);
                ins = methodInstructions.get(configuration.code.isrHandlers[i]);
                pc += ins.stream().mapToInt(Instruction::getSize).sum();
                instructions.addAll(ins);
            }
            labels.put(configuration.code.entryPoint, pc);
            pc += addClassInitCalls(instructions);
            ins = methodInstructions.get(configuration.code.entryPoint);
            pc += ins.stream().mapToInt(Instruction::getSize).sum();
            instructions.addAll(ins);
            for (var entry: methodInstructions.entrySet()) {
                if (entry.getKey().equals(configuration.code.entryPoint) || isIsr(entry.getKey()))
                    continue;
                labels.put(entry.getKey(), pc);
                ins = entry.getValue();
                pc += ins.stream().mapToInt(Instruction::getSize).sum();
                instructions.addAll(ins);
            }
        }
        link(instructions, labels);
        for (var entry : labels.entrySet())
            labelMap.put(entry.getValue(), entry.getKey());
        return instructions;
    }

    private int addClassInitCalls(ArrayList<Instruction> instructions) {
        var generator = new InstructionGenerator(null);
        for (var entry : classes.entrySet()) {
            if (entry.getValue().hasMethod(staticConstructor))
                generator.addCall(entry.getKey() + "." + staticConstructor);
        }
        var ins = generator.getInstructions();
        instructions.addAll(ins);
        return ins.stream().mapToInt(Instruction::getSize).sum();
    }

    private boolean isIsr(String key) {
        if (configuration.code.isrHandlers != null) {
            for (var handler : configuration.code.isrHandlers)
                if (key.equals(handler))
                    return true;
        }
        return false;
    }

    private void link(List<Instruction> instructions, Map<String, Integer> labels) throws TranslatorException {
        var pc = 0;
        for (var instruction : instructions) {
            var label = instruction.getRequiredLabel();
            if (label != null) {
                if (!labels.containsKey(label))
                    throw new TranslatorException("unknown label " + label);
                instruction.buildCode(labels.get(label), pc);
            }
            else
                instruction.buildCode(0, pc);
            pc += instruction.getSize();
        }
    }

    private void createOutputFiles(List<Instruction> code, Map<Integer, String> labels) throws IOException {
        createFile(configuration.code.fileName, code, labels);
        createFile(configuration.data.fileName, data.getInstructions(), labels);
        createFile(configuration.roData.fileName, roData.getInstructions(), labels);
    }

    private static void createFile(String fileName, List<Instruction> instructions, Map<Integer, String> labels)
            throws IOException {
        var lines = new ArrayList<String>();
        var pc = 0;
        for (var instruction : instructions) {
            var label = labels.getOrDefault(pc,"");
            var text = instruction.toText(label, pc);
            pc += instruction.getSize();
            lines.addAll(Arrays.asList(text));
        }
        Files.write(Paths.get(fileName), lines);
    }
}
