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
    private static final Set<String> ignoreMethodCalls = Set.of(
            "java/lang/String.toCharArray()[C",
            "java/lang/Class.getParents()[Ljava/lang/Class;"
    );
    private static final Set<String> callAsSpecial = Set.of("java/lang/String", "java/lang/Object");

    final TranslatorConfiguration configuration;
    final Map<String, ClassFile> classes;
    final HashSet<String> toTranslate;
    final Segment data, roData;
    final Map<String, Integer> dataSegmentMapping;
    final Map<String, List<Instruction>> methodInstructions;
    final boolean dropOptimnization;
    final boolean swapOptimnization;
    final boolean localsOptimnization;

    ClassFile currentClassFile;
    InstructionGenerator instructionGenerator;
    MethodOrField currentMethod;
    String currentMethodName;


    public ForthTranslator(List<ClassFile> classes, TranslatorConfiguration configuration) throws ClassFileException {
        this.configuration = configuration;
        this.classes = buildClasses(classes);
        this.toTranslate = new HashSet<>();
        this.data = new Segment("data", configuration.data.address);
        this.roData = new Segment("rodata", configuration.roData.address);
        this.methodInstructions = new HashMap<>();
        this.dataSegmentMapping = new HashMap<>();
        this.dropOptimnization = configuration.optimizations.contains("PUSH_DROP");
        this.swapOptimnization = configuration.optimizations.contains("SWAP");
        this.localsOptimnization = configuration.optimizations.contains("LOCAL_SET_GET");
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
        createBuiltInMethods();
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

    private void createBuiltInMethods() {
        var generator = new InstructionGenerator(0);
        generator.addReturn(0);
        methodInstructions.put("java/lang/Object.hashCode()I", generator.getInstructions());
        methodInstructions.put("java/lang/String.toString()Ljava/lang/String;", generator.getInstructions());
        generator = new InstructionGenerator(0);
        generator.addGet("getclass");
        generator.addReturn(0);
        methodInstructions.put("java/lang/Object.getClass()Ljava/lang/Class;", generator.getInstructions());
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
        instructionGenerator = new InstructionGenerator(0, dropOptimnization, swapOptimnization, localsOptimnization);
        if (!createProlog())
            return;
        int pc = 0;
        var code = currentMethod.getCode();
        while (pc < code.length)
            pc = translate(code, pc);
        instructionGenerator.finish();
        methodInstructions.put(currentMethodName, instructionGenerator.getInstructions());
    }

    private boolean createProlog() throws ClassFileException {
        var localsCount = currentMethod.getNumberOfLocals();
        if (localsCount < 0)
            return false;
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
        return true;
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
            case 0xb9: // invokeinterface
                index = (code[pc++] & 0xFF) << 8;
                index |= code[pc++] & 0xFF;
                pc += 2;
                translateInvokeVirtual(index);
                break;
            case 0xbe: // arraylength
                instructionGenerator.addGet("get (arraylength)");
                break;
            case 0x2f: // laload
                translateLALoad();
                break;
            case 0x2e: // iaload
            case 0x32: // aaload
            case 0x33: // baload
            case 0x34: // caload
            case 0x35: // saload
                translateALoad();
                break;
            case 0x50: // lastore
                translateLAStore();
                break;
            case 0x4f: // iastore
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
                pc = translateTableSwitch(code, pc);
                break;
            case 0xab: // lookupswitch
                pc = translateLookupSwitch(code, pc);
                break;
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
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                translateGetField(index);
                break;
            case 0xb5: // putfield
                index = code[pc++] << 8;
                index |= code[pc++] & 0xFF;
                translatePutField(index);
                break;
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
            case 0xc0: // checkcast
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                translateCheckCast(index);
                break;
            case 0xc1: // instanceof
                index = code[pc++]<< 8;
                index |= code[pc++] & 0xFF;
                translateInstanceOf(index);
                break;
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

    private static int readInt(byte[] code, int pc) {
        return (code[pc] << 24) | (code[pc+1] << 16) | (code[pc+2] << 8) | code[pc+3];
    }

    private int translateTableSwitch(byte[] code, int pc) {
        var startPc = pc - 1;
        if ((pc & 3) != 0) {
            pc += 4;
            pc &= ~3;
        }
        var defaultPc = readInt(code, pc);
        pc += 4;
        var low = readInt(code, pc);
        pc += 4;
        var high = readInt(code, pc);
        pc += 4;

        instructionGenerator.addDup();
        generatePush(low, "check for >=" + low);
        instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_GE, "ifcmp_ge", 4);
        instructionGenerator.addDrop();
        instructionGenerator.addJmp(defaultPc, startPc);
        instructionGenerator.addDup();
        generatePush(high, "check for <=" + high);
        instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_LE, "ifcmp_le", 4);
        instructionGenerator.addDrop();
        instructionGenerator.addJmp(defaultPc, startPc);
        generatePush(low, "push " + low);
        instructionGenerator.addAluOp(InstructionGenerator.ALU_OP_SUB, "sub");
        instructionGenerator.addIndirectJmp();

        for (var i = low; i <= high; i++) {
            var offset = readInt(code, pc);
            instructionGenerator.addJmp(offset, startPc);
            pc += 4;
        }

        return pc;
    }

    private int translateLookupSwitch(byte[] code, int pc) {
        var startPc = pc - 1;
        if ((pc & 3) != 0) {
            pc += 4;
            pc &= ~3;
        }
        var defaultPc = readInt(code, pc);
        pc += 4;
        var npairs = readInt(code, pc);
        pc += 4;
        var pcs = new HashMap<Integer, Integer>();
        for (var i = 0; i < npairs; i++) {
            var v = readInt(code, pc);
            pc += 4;
            var vpc = readInt(code, pc);
            pc += 4;
            pcs.put(v, vpc);
        }

        for (var pcm : pcs.entrySet()) {
            instructionGenerator.addDup();
            generatePush(pcm.getKey(), "lookup for " + pcm.getKey());
            instructionGenerator.addIfcmp(InstructionGenerator.IFCMP_NE, "ifcmp_ne", 4);
            instructionGenerator.addDrop();
            instructionGenerator.addJmp(pcm.getValue(), startPc);
        }

        instructionGenerator.addDrop();
        instructionGenerator.addJmp(defaultPc, startPc);

        return pc;
    }

    private void translateInstanceOf(int index) throws ClassFileException {
        addToTranslate("java/lang/Class");
        var className = currentClassFile.getName(index);
        var cls = classes.get(className);
        buildClass(className, cls);
        instructionGenerator.addPushLabel("$" + className);
        instructionGenerator.addCall("java/lang/Class.isInstance(Ljava/lang/Object;)Z");
    }

    private void translateCheckCast(int index) {
        //todo
    }

    private int buildFieldAddress(String name, boolean isLong) {
        if (dataSegmentMapping.containsKey(name))
            return dataSegmentMapping.get(name);
        var address = data.allocate(isLong ? 2 : 1);
        dataSegmentMapping.put(name, address);
        return address;
    }

    private void translatePutStatic(int index) throws ClassFileException {
        var name = currentClassFile.getFieldFullName(index);
        var isLong = currentClassFile.isLongField(index);
        var address = buildFieldAddress(name, isLong);
        instructionGenerator.addPush(address, "push " + name);
        if (isLong)
            instructionGenerator.addSetLong();
        else
            instructionGenerator.addSet();
    }

    private void translateGetStatic(int index) throws ClassFileException {
        var name = currentClassFile.getFieldFullName(index);
        var isLong = currentClassFile.isLongField(index);
        var address = buildFieldAddress(name, isLong);
        instructionGenerator.addPush(address, "push " + name);
        if (isLong)
            instructionGenerator.addGetLong();
        else
            instructionGenerator.addGet("getstatic");
    }

    private int getFieldIndex(int index, String fname) throws ClassFileException {
        var name = currentClassFile.getFieldClassName(index);
        var cls = classes.get(name);
        return cls.getFieldIndex(fname, classes);
    }

    private void translatePutField(int index) throws ClassFileException {
        var name = currentClassFile.getFieldName(index);
        var isLong = currentClassFile.isLongField(index);
        var findex = getFieldIndex(index, name);
        //objectref, value
        instructionGenerator.addSwap();
        //value, objectref
        generatePush(findex, "push field index " + name);
        instructionGenerator.addArrayp();
        if (isLong)
            instructionGenerator.addSetLong();
        else
            instructionGenerator.addSet();
    }

    private void translateGetField(int index) throws ClassFileException {
        var name = currentClassFile.getFieldName(index);
        var isLong = currentClassFile.isLongField(index);
        var findex = getFieldIndex(index, name);
        generatePush(findex, "push field index " + name);
        instructionGenerator.addArrayp();
        if (isLong)
            instructionGenerator.addGetLong();
        else
            instructionGenerator.addGet("get field");
    }

    private void translateNew(int index) throws ClassFileException {
        var name = currentClassFile.getName(index);
        var cls = classes.get(name);
        var address = buildClass(name, cls);
        var size = cls.calculateFieldsSize(classes);
        instructionGenerator.addPush(address, String.format("push %d (new %s methods table address)", address, name));
        generatePush(size, String.format("push %d (new %s fields size)", size, name));
        instructionGenerator.addCall("JavaCPU/System.newObject(II)I");
    }

    private int buildClass(String name, ClassFile cls) throws ClassFileException {
        var key = "$" + name;
        if (dataSegmentMapping.containsKey(key))
            return dataSegmentMapping.get(key);
        var methods = cls.buildMethodsList(classes);
        var parentsList = cls.buildParentsList(classes);
        return buildClass(key, name, parentsList, methods);
    }

    private int buildClass(String key, String name, List<String> parents, List<String> methods) throws ClassFileException {
        for (var parent : parents) {
            if (!dataSegmentMapping.containsKey(parent))
                buildClass(parent, classes.get(parent));
        }
        var address = roData.getNextAddress();
        dataSegmentMapping.put("%" + name, address);
        roData.addInstruction(new InlineInstruction(null, new int[]{parents.size()}, "parents length"));
        for (var parent : parents) {
            var pkey = "%" + parent;
            roData.addInstruction(new LabelInstruction(pkey));
        }
        var classAddress = roData.getNextAddress();
        dataSegmentMapping.put(key, classAddress);
        roData.addInstruction(new InlineInstruction(null, new int[]{address}, "parents array reference"));
        for (var method : methods) {
            if (shouldBeIgnored(method))
                roData.addInstruction(new InlineInstruction(null, new int[]{0}, method));
            else
                roData.addInstruction(new LabelInstruction(method));
        }
        return classAddress;
    }

    private void translateANewArray(int index) throws ClassFileException {
        instructionGenerator.addCall("JavaCPU/System.newArray(I)I");
    }

    private void translateMultiANewArray(int index, int dimensions) throws TranslatorException {
        throw new TranslatorException("multianewarray is not supported");
    }

    private void translateNewArray(int type) {
        if (type == 7 || type == 11) // double or long
            instructionGenerator.addCall("JavaCPU/System.newLongArray(I)I");
        else
            instructionGenerator.addCall("JavaCPU/System.newArray(I)I");
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
        //arrayref, index, value
        instructionGenerator.add2Rot();
        //value, arrayref, index
        instructionGenerator.addArrayp();
        instructionGenerator.addSet();
    }

    private void translateLAStore() {
        instructionGenerator.add2Rot();
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
        toTranslate.add(name);
    }

    private void translateInvokeVirtual(int index) throws ClassFileException {
        var name = currentClassFile.getMethodClassName(index);
        if (callAsSpecial.contains(name)) {
            translateInvokeSpecial(index);
            return;
        }
        addToTranslate(name);
        var fname = currentClassFile.getMethodFullName(index);
        var mname = currentClassFile.getMethodName(index);
        if (shouldBeIgnored(fname))
            return;
        var cls = classes.get(name);
        var idx = cls.getMethodIndex(mname, classes);
        var nparameters = cls.getNumberOfParameters(fname);
        instructionGenerator.addGetn(nparameters, "get class info for " + fname);
        instructionGenerator.addIndirectCall(idx+1, fname);
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
        name = currentClassFile.getMethodFullName(index);
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
        }
    }

    private void translateLdc2(int index) throws ClassFileException {
        var item = currentClassFile.getFromConstantPool(index);
        switch(item) {
            case LongConstantPoolItem l:
                generatePush(l.getValue(), "ldc long");
                break;
            default:
                throw new ClassFileException("unsupported constant pool item type for ldc2_w");
        }
    }

    private int buildStringConstant(int stringIndex) throws ClassFileException {
        var s = currentClassFile.getUtf8Constant(stringIndex);
        var name = "@" + s;
        if (dataSegmentMapping.containsKey(name))
            return dataSegmentMapping.get(name);
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
        link(instructions, labels);
        for (var entry : labels.entrySet())
            labelMap.put(entry.getValue(), entry.getKey());
        link(roData.getInstructions(), labels);
        return instructions;
    }

    private int addClassInitCalls(ArrayList<Instruction> instructions) {
        var generator = new InstructionGenerator(null);
        for (var entry : classes.entrySet()) {
            if (entry.getKey().equals("JavaCPU/System") && entry.getValue().hasMethod(staticConstructor))
                generator.addCall(entry.getKey() + "." + staticConstructor);
        }
        for (var entry : classes.entrySet()) {
            if (!entry.getKey().equals("JavaCPU/System") && entry.getValue().hasMethod(staticConstructor))
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
                if (labels.containsKey(label))
                    instruction.buildCode(labels.get(label), pc);
                else if (dataSegmentMapping.containsKey(label))
                    instruction.buildCode(dataSegmentMapping.get(label), pc);
                else
                    throw new TranslatorException("unknown label " + label);
            }
            else
                instruction.buildCode(0, pc);
            pc += instruction.getSize();
        }
    }

    private void createOutputFiles(List<Instruction> code, Map<Integer, String> labels) throws IOException {
        createFile(configuration.code.fileName, code, labels, false);
        createFile(configuration.roData.fileName, roData.getInstructions(), labels, true);
    }

    private static void createFile(String fileName, List<Instruction> instructions, Map<Integer, String> labels,
                                   boolean w32)
            throws IOException {
        var lines = new ArrayList<String>();
        var pc = 0;
        for (var instruction : instructions) {
            var label = labels.getOrDefault(pc,"");
            var text = instruction.toText(label, pc, w32);
            pc += instruction.getSize();
            lines.addAll(Arrays.asList(text));
        }
        Files.write(Paths.get(fileName), lines);
    }
}
