package translator;

import com.google.gson.Gson;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

public final class TranslatorConfiguration {
    static class SourceInlineDefinition {
        String[] code;
        String comment;
    }

    static class SourceSection {
        String fileName;
        String address, size;
        String entryPoint;
        String[] isrHandlers;
    }

    static class SourceConfiguration {
        SourceSection code, data, roData;
        String mapFileName;
        Map<String, SourceInlineDefinition> inlines;
    }

    static class InlineDefinition {
        int[] code;
        String comment;

        public InlineDefinition(String[] code, String comment) {
            this.code = new int[code.length];
            this.comment = comment;
            for (int i = 0; i < code.length; i++)
                this.code[i] = Integer.parseInt(code[i], 16);
        }

        public static Map<String, InlineDefinition> build(Map<String, SourceInlineDefinition> inlines) {
            Map<String, InlineDefinition> result = new HashMap<>();
            for (var entry : inlines.entrySet())
                result.put(entry.getKey(), new InlineDefinition(entry.getValue().code, entry.getValue().comment));
            return result;
        }
    }

    static class Section {
        String fileName;
        int address, size;
        String entryPoint;
        String[] isrHandlers;

        public Section(String mainClassName, SourceSection s, String name, boolean parseAddress) throws TranslatorException {
            this.address = parseAddress ? Integer.parseInt(s.address, 16) : 0;
            this.size = ParseSize(s.size, name);
            this.fileName = s.fileName;
            this.entryPoint = buildClassName(mainClassName, s.entryPoint);
            this.isrHandlers = s.isrHandlers == null ? new String[0] : new String[s.isrHandlers.length];
            for (var i = 0; i < this.isrHandlers.length; i++)
                this.isrHandlers[i] = buildClassName(mainClassName, s.isrHandlers[i]);
        }

        private static String buildClassName(String mainClassName, String name) {
            return mainClassName == null ? name : mainClassName + "." + name + "()V";
        }

        private static int ParseSize(String size, String name) throws TranslatorException {
            var multiplier = 1;
            if (size.endsWith("K"))
            {
                size = size.substring(0, size.length() - 1);
                multiplier = 1024;
            }
            var sz = Integer.parseInt(size);
            if (sz <= 0)
                throw new TranslatorException("inavlid " + name + " section size");
            return sz * multiplier;
        }
    }

    Section code, data, roData;
    String mapFileName;
    Map<String, InlineDefinition> inlines;

    private TranslatorConfiguration(String mainClassName, SourceConfiguration config) throws TranslatorException {
        this.code = new Section(mainClassName, config.code, "code", false);
        if (code.entryPoint.isEmpty() || code.fileName.isEmpty())
            throw new TranslatorException("invalid code segment configuration");
        this.data = new Section(null, config.data, "data", true);
        this.roData = new Section(null, config.roData, "rodata", true);
        if (this.roData.fileName.isEmpty())
            throw new TranslatorException("invalid rodata segment configuration");
        this.mapFileName = config.mapFileName;
        this.inlines = InlineDefinition.build(config.inlines);
    }

    public static TranslatorConfiguration load(String mainClassName, String configurationFileName)
            throws IOException, TranslatorException {
        var g = new Gson();
        var text = Files.readString(Paths.get(configurationFileName));
        return new TranslatorConfiguration(mainClassName, g.fromJson(text, SourceConfiguration.class));
    }
}
