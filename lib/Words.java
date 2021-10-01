// Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
package util;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Random;
import java.util.StringJoiner;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.BiFunction;
import java.util.function.Consumer;
import java.util.function.Supplier;
import java.util.stream.Stream;

import static util.Words.Argument.cutoff;
import static util.Words.Argument.count;
import static util.Words.Argument.prefix;
import static util.Words.Argument.suffix;
import static util.Words.Argument.template;
import static java.lang.Math.floorMod;
import static java.nio.charset.StandardCharsets.UTF_8;
import static java.util.Arrays.binarySearch;
import static java.util.Comparator.comparingLong;
import static java.util.function.Function.identity;
import static java.util.function.Predicate.not;
import static java.util.stream.Collectors.counting;
import static java.util.stream.Collectors.groupingBy;

/**
 * @author jonmv
 */
public class Words {

    public static void main(String[] args) {
        try {
            Command.valueOf(args[0]).run(args);
        }
        catch (RuntimeException e) {
            e.printStackTrace();
            usage();
            System.exit(1);
        }
    }

    static void usage() {
        System.err.println("\nUsage: java Words.java <command> [option-name option-value]...\n");

        System.err.println("Examples: echo \"some words.com with#gurba+gurba\" | java Words.java digest cutoff 1 > words.txt\n");
        System.err.println("          cat words.txt | java Words.java feed count 3 template '{ \"id\": \"id:ns:type::$seq()\", \"text\": \"$words(3)\" }'\n");
        System.err.println("          echo \"1 rare 4 common\" | java Words.java query template 'sddocname:type foo:$words()'\n");
        System.err.println("          echo \"\" | java Words.java url template 'my-doc-$seq()' prefix '/document/v1/ns/type/docid/' suffix '?fields=%5Bid%5D'\n");

        System.err.println("List of commands:\n");
        for (Command command : Command.values()) {
            System.err.printf("%12s: %s\n", command.name(), command.description);
            for (Argument argument : command.arguments)
                System.err.printf("%14s%s: %s, %s\n", "", argument.name(), argument.description, argument.fallback != null ? "default '" + argument.fallback + "'": "required");
            System.err.println();
        }

        System.err.println("List of patterns (default count is 1, i.e., $words() and $words(1) are the same):\n");
        for (Pattern pattern : Pattern.values())
            System.err.printf("%12s: %s\n", pattern.name(), pattern.description);
    }

    static void countWords(EnumMap<Argument, String> arguments) {
        Map<String, Long> frequencies = new BufferedReader(new InputStreamReader(System.in, UTF_8))
                .lines().parallel()
                .flatMap(line -> Stream.of(line.split("[\\W&&[^-.']]")) // Split on non-word-chars except -.'
                                       .map(word -> {
                                           int s = 0, e = word.length();
                                           while (s < e && isIntraWordPunctuation(word.codePointAt(s))) s++;
                                           while (s < e && isIntraWordPunctuation(word.codePointAt(e - 1))) e--;
                                           return word.substring(s, e).toLowerCase(Locale.ROOT);
                                       })
                                       .filter(not(String::isBlank)))
                .collect(groupingBy(identity(), counting()));

        int lower = Integer.parseInt(arguments.get(cutoff));
        frequencies.entrySet().stream()
                   .filter(wordCount -> wordCount.getValue() > lower)
                   .sorted(comparingLong(wordCount -> -wordCount.getValue()))
                   .forEach(wordCount -> System.out.println(wordCount.getValue() + " " + wordCount.getKey()));
    }

    static boolean isIntraWordPunctuation(int c) {
        return c == '\'' || c == '-' || c == '.';
    }

    static void generateURLs(EnumMap<Argument, String> arguments, String key, String suffix) {
        PrintStream out = new PrintStream(new BufferedOutputStream(System.out));
        Supplier<String> queries = parseTemplate(arguments.get(template), Generator.readFromSystemIn());
        String base = arguments.get(prefix);
        String url = key.isEmpty() || base.endsWith("?") || base.endsWith("&") ? base : base + (base.contains("?") ? "&" : "?");
        Supplier<String> urls = () -> url + key + URLEncoder.encode(queries.get(), UTF_8) + suffix;
        for (int i = 0; i < Integer.parseInt(arguments.get(count)); i++)
            out.println(urls.get());
        out.flush();
    }

    static void generateFeed(EnumMap<Argument, String> arguments) {
        PrintStream out = new PrintStream(new BufferedOutputStream(System.out));
        Supplier<String> documents = parseTemplate(arguments.get(template), Generator.readFromSystemIn());
        for (int i = 0; i < Integer.parseInt(arguments.get(count)); i++)
            out.println(documents.get());
        out.flush();
    }

    static EnumMap<Argument, String> parseArguments(String[] args) {
        EnumMap<Argument, String> arguments = new EnumMap<>(Argument.class);
        for (int i = 1; i < args.length; )
            if (arguments.put(Argument.valueOf(args[i++]), args[i++]) != null)
                throw new IllegalArgumentException("Duplicate argument " + args[i - 2]);

        return arguments;
    }

    static Supplier<String> parseTemplate(String raw, Generator generator) {
        List<String> context = new ArrayList<>();
        List<Supplier<String>> patterns = new ArrayList<>();
        for (int e = -1; e < raw.length(); ) {
            context.add(raw.substring(++e, e = (e = raw.indexOf('$', e)) == -1 ? raw.length() : e));
            if (e < raw.length())
                patterns.add(Pattern.valueOf(raw.substring(++e, e = raw.indexOf('(', e)))
                                    .sequence(raw.substring(++e, e = raw.indexOf(')', e)), generator));
            else
                patterns.add(() -> "");
        }
        return () -> {
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < context.size(); i++)
                builder.append(context.get(i)).append(patterns.get(i).get());
            return builder.toString();
        };
    }

    enum Command {

        digest("extract the words from stdin and count their occurrences", Words::countWords, cutoff),
        query("generate simple queries from the given template", arguments -> generateURLs(arguments, "query=", ""), count, template, prefix),
        yql("generate yql queries from the given template", arguments -> generateURLs(arguments, "yql=", ""), count, template, prefix),
        url("generate generic URLs from the given template", arguments -> generateURLs(arguments, "", arguments.get(suffix)), count, template, prefix, suffix),
        feed("generate documents from the given template", Words::generateFeed, count, template);

        final String description;
        final Consumer<EnumMap<Argument, String>> program;
        final List<Argument> arguments;

        Command(String description, Consumer<EnumMap<Argument, String>> program, Argument... arguments) {
            this.description = description;
            this.program = program;
            this.arguments = List.of(arguments);
        }

        void run(String[] args) {
            EnumMap<Argument, String> arguments = parseArguments(args);
            for (Argument name : arguments.keySet())
                if ( ! this.arguments.contains(name))
                    throw new IllegalArgumentException("illegal argument " + name + " for command " + this);

            for (Argument argument : this.arguments)
                if ( ! arguments.containsKey(argument))
                    if (argument.fallback == null)
                        throw new IllegalArgumentException("missing required argument " + argument.name() + " for command " + this);
                    else
                        arguments.put(argument, argument.fallback);

            program.accept(arguments);
        }

    }

    enum Argument {

        cutoff("drop all words with frequency no more than this from the tally", "0"),
        count("number of items to generate; these are separated by newlines", "10"),
        template("template to use for queries or feed operations; will be encoded in URLs", null),
        prefix("URL prefix (path and query); will not be URL-encoded", "/search/"),
        suffix("URL suffix (typically query); will not be URL-encoded", "");

        final String description;
        final String fallback;

        Argument(String description, String fallback) {
            this.description = description;
            this.fallback = fallback;
        }

    }

    enum Pattern {

        seq("A sequence which starts at 0, and increments by 1 for each item, e.g., $seq()", (arguments, generator) -> {
            if (arguments.length > 0) throw new IllegalArgumentException("seq accepts no arguments");
            AtomicLong counter = new AtomicLong(0);
            return () -> Long.toString(counter.getAndIncrement());
        }),

        words("N randomly chosen words, e.g., $words(5)", (arguments, generator) -> {
            if (arguments.length > 1) throw new IllegalArgumentException("words accepts 0 or 1 arguments");
            int words = arguments.length == 0 ? 1 : Integer.parseInt(arguments[0]);
            return () -> {
                StringJoiner joiner = new StringJoiner(" ");
                for (int i = 0; i < words; i++)
                    joiner.add(generator.nextWord());
                return joiner.toString();
            };
        }),

        chars("Randomly chosen words truncated after N characters, e.g., $chars(32)", (arguments, generator) -> {
            if (arguments.length > 1) throw new IllegalArgumentException("chars accepts 0 or 1 arguments");
            int chars = arguments.length == 0 ? 1 : Integer.parseInt(arguments[0]);
            return () -> generator.nextChars(chars);
        }),

        ints("N random, comma-separated integers less than an optional bound, e.g., $ints(1, 100)", (arguments, generator) -> {
            if (arguments.length > 2) throw new IllegalArgumentException("ints accepts 0, 1 or 2 arguments");
            int numbers = arguments.length == 0 ? 1 : Integer.parseInt(arguments[0]);
            long bound = arguments.length <= 1 ? 0 : Long.parseLong(arguments[1]);
            return () -> {
                StringJoiner joiner = new StringJoiner(", ");
                for (int i = 0; i < numbers; i++)
                    joiner.add(Long.toString(bound > 0 ? generator.nextLong(bound) : generator.random.nextLong()));
                return joiner.toString();
            };
        }),

        floats("N random, comma-separated (double) floats, in the range [0, 1), e.g., $floats(2)", (arguments, generator) -> {
            if (arguments.length > 1) throw new IllegalArgumentException("floats accepts 0 or 1 arguments");
            int floats = arguments.length == 0 ? 1 : Integer.parseInt(arguments[0]);
            return () -> {
                StringJoiner joiner = new StringJoiner(", ");
                for (int i = 0; i < floats; i++)
                    joiner.add(Double.toString(generator.random.nextDouble()));
                return joiner.toString();
            };
        }),

        filter("Includes each percentage, comma-separated, with probability equal to its value; e.g., $filter(10, 50, 90)", (arguments, generator) -> {
            if (arguments.length == 0) throw new IllegalArgumentException("filter requires at least one term");
            int[] numbers = new int[arguments.length];
            for (int i = 0; i < arguments.length; i++) {
                numbers[i] = Integer.parseInt(arguments[i]);
                if (numbers[i] <= 0 || numbers[i] > 100) throw new IllegalArgumentException("filter term must be in (0, 100], but was " + numbers[i]);
            }

            return () -> {
                StringJoiner joiner = new StringJoiner(", ");
                for (int number : numbers)
                    if (generator.random.nextInt(100) < number)
                        joiner.add(Integer.toString(number));
                return joiner.toString();
            };
        });

        final String description;
        final BiFunction<String[], Generator, Supplier<String>> factory;

        Pattern(String description, BiFunction<String[], Generator, Supplier<String>> factory) {
            this.description = description;
            this.factory = factory;
        }

        Supplier<String> sequence(String arguments, Generator generator) {
            return factory.apply(Stream.of(arguments.split("\\s*,\\s*")).filter(not(String::isBlank)).toArray(String[]::new), generator);
        }

    }

    static class Generator {

        final Random random;
        final long[] counts;
        final String[] words;
        final long count;

        Generator(Random random, long[] counts, String[] words) {
            this.random = random;
            this.words = words;
            long count = 0;
            int i = 0;
            this.counts = new long[counts.length];
            for (long c : counts) this.counts[i++] = count += c;
            this.count = count;
        }

        static Generator readFromSystemIn() {
            List<Long> counts = new ArrayList<>();
            List<String> words = new ArrayList<>();
            new BufferedReader(new InputStreamReader(System.in, UTF_8)).lines().forEach(line -> {
                if (line.isBlank()) return;
                String[] parts = line.split("\\s");
                for (int i = 0; i < parts.length; ) {
                    long count = Long.parseLong(parts[i++]);
                    if (count <= 0) throw new IllegalArgumentException("counts must be positive");
                    counts.add(count);
                    words.add(parts[i++]);
                }
            });
            return new Generator(new Random(-1),
                                 counts.stream().mapToLong(Long::longValue).toArray(),
                                 words.toArray(String[]::new));
        }

        String nextChars(int chars) {
            StringBuilder builder = new StringBuilder();
            while (builder.length() < chars) builder.append(nextWord()).append(" ");
            return builder.substring(0, chars);
        }

        String nextWord() {
            if (words.length == 0) throw new IllegalArgumentException("no word counts given in stdin");
            int i = binarySearch(counts, nextLong(count));
            if (i < 0) i = ~i;
            return words[i];
        }

        long nextLong(long bound) {
            if (bound <= 0) throw new IllegalArgumentException("bound must be positive");
            if (bound <= Integer.MAX_VALUE) return random.nextInt((int) bound);
            long l, c; // Avoid skew due to bound not dividing 2^64, by discarding raw values close to overflow.
            do { l = random.nextLong(); } while ((c = (l - floorMod(l, count))) > c + count);
            return floorMod(l, count);
        }

    }

}
