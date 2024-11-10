package translator;

import com.google.gson.Gson;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public final class TranslatorConfiguration {
    static class SourceSection {
        String fileName;
        String address, size;
        String entryPoint;
        String[] isrHandlers;
    }

    static class SourceConfiguration {
        SourceSection code, data, roData;
        String mapFileName;
        String[] options;
    }

    static class Section {
        String fileName;
        int address, size;
        String entryPoint;
        String[] isrHandlers;

        public Section(SourceSection s, String name, boolean parseAddress) throws TranslatorException {
            this.address = parseAddress ? Integer.parseInt(s.address, 16) : 0;
            this.size = ParseSize(s.size, name);
            this.fileName = s.fileName;
            this.entryPoint = s.entryPoint;
            this.isrHandlers = s.isrHandlers;
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
    String[] options;

    private TranslatorConfiguration(SourceConfiguration config) throws TranslatorException {
        this.code = new Section(config.code, "code", false);
        if (code.entryPoint.isEmpty() || code.fileName.isEmpty())
            throw new TranslatorException("invalid code segment configuration");
        this.data = new Section(config.data, "data", true);
        this.roData = new Section(config.roData, "rodata", true);
        if (this.roData.fileName.isEmpty())
            throw new TranslatorException("invalid rodata segment configuration");
        this.mapFileName = config.mapFileName;
        this.options = config.options;
    }

    public static TranslatorConfiguration load(String configurationFileName) throws IOException, TranslatorException {
        var g = new Gson();
        var text = Files.readString(Paths.get(configurationFileName));
        return new TranslatorConfiguration(g.fromJson(text, SourceConfiguration.class));
    }
}
