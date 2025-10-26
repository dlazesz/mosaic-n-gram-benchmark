// Compile: gcc -O3 -march=native -flto -pipe -o c_recursive c_recursive.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#define MAX_WORDS 4096
#define MAX_SUBWORDS 128
#define MAX_LINE 8192
#define MAX_NGRAM 8192
#define MAX_N 16   // Maximum n-gram length

typedef struct {
    char *subwords[MAX_SUBWORDS];
    int len[MAX_SUBWORDS];
    int count;
} WordSplits;

// Split string by multi-character delimiter in-place
int split_delim(char *str, const char *delim, WordSplits *ws) {
    int count = 0;
    size_t delim_len = strlen(delim);
    char *start = str;
    char *pos;

    while ((pos = strstr(start, delim)) != NULL) {
        *pos = '\0';
        ws->subwords[count] = start;
        ws->len[count] = pos - start;
        count++;
        start = pos + delim_len;
    }

    ws->subwords[count] = start;
    ws->len[count] = strlen(start);
    count++;

    ws->count = count;
    return count;
}

// Split line into words by spaces/tabs in-place, treating consecutive spaces as one
int split_words(char *line, char **out) {
    int count = 0;
    char *ptr = line;

    while (*ptr) {
        // Skip any leading whitespace
        while (*ptr == ' ' || *ptr == '\t') ptr++;

        if (!*ptr) break;

        // Start of a word
        out[count++] = ptr;

        // Move to the end of the word
        while (*ptr && *ptr != ' ' && *ptr != '\t') ptr++;

        // Null-terminate the word
        if (*ptr) {
            *ptr = '\0';
            ptr++;
        }
    }
    return count;
}

// Correct recursive permutation function
void permute(WordSplits *words, int word_index, int end, char *buffer, int buf_len, FILE *fout) {
    WordSplits *w = &words[word_index];

    for (int i = 0; i < w->count; i++) {
        int new_buf_len = buf_len;

        // Copy subword of this word
        memcpy(buffer + new_buf_len, w->subwords[i], w->len[i]);
        new_buf_len += w->len[i];

        // Add space only if this is not the last word
        int add_space = (word_index < end);
        if (add_space) buffer[new_buf_len++] = ' ';

        buffer[new_buf_len] = '\0';

        if (word_index < end) {
            permute(words, word_index + 1, end, buffer, buf_len + w->len[i] + add_space, fout);
        } else {
            fprintf(fout, "%s\n", buffer);
        }
    }
}

// Generate n-grams for a single line
void generate_ngrams(char *line, int maxn, const char *delimiter, const char *padding_token, FILE *fout) {
    char *words_arr[MAX_WORDS];
    int word_count = split_words(line, words_arr);
    int padded_count = word_count + maxn - 1;

    WordSplits word_splits[MAX_WORDS];

    for (int i = 0; i < padded_count; i++) {
        if (i < word_count) {
            split_delim(words_arr[i], delimiter, &word_splits[i]);
        } else {
            word_splits[i].subwords[0] = (char *)padding_token;
            word_splits[i].len[0] = strlen(padding_token);
            word_splits[i].count = 1;
        }
    }

    char buffer[MAX_NGRAM];
    buffer[0] = '\0';

    for (int i = 0; i <= padded_count - maxn; i++) {
        buffer[0] = '\0';
        permute(&word_splits[i], 0, maxn - 1, buffer, 0, fout);
    }
}

void print_help(const char *progname) {
    fprintf(stdout,
        "Usage: %s -n <length> [OPTIONS]\n"
        "\n"
        "Generate n-grams from text input.\n"
        "\n"
        "Options:\n"
        "  -i, --input-file <path>      Input file (default: stdin)\n"
        "  -o, --output-file <path>     Output file (default: stdout)\n"
        "  -n, --ngram-length <int>     Length of n-grams (required)\n"
        "  -d, --delimiter <string>     Token delimiter (default: '#')\n"
        "  -p, --padding-token <str>    Padding token (default: 'DUMMY_WORD')\n"
        "  -h, --help                   Show this help message and exit\n"
        "\n"
        "Examples:\n"
        "  %s -n 3 < input.txt > output.txt\n"
        "  %s --input-file data.txt --ngram-length 5 --delimiter ' ' --output-file ngrams.txt\n"
        "\n",
        progname, progname, progname
    );
}

int main(int argc, char **argv) {
    char *in_file = "-";
    char *out_file = "-";
    char *delimiter = "#";
    char *padding_token = "DUMMY_WORD";
    int ngramlen = 0;

    static struct option long_options[] = {
        {"input-file",     required_argument, 0, 'i'},
        {"output-file",    required_argument, 0, 'o'},
        {"ngram-length",   required_argument, 0, 'n'},
        {"delimiter",      required_argument, 0, 'd'},
        {"padding-token",  required_argument, 0, 'p'},
        {"help",           no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };

    int opt, opt_index = 0;
    while ((opt = getopt_long(argc, argv, "i:o:n:d:p:h", long_options, &opt_index)) != -1) {
        switch (opt) {
            case 'i': in_file = optarg; break;
            case 'o': out_file = optarg; break;
            case 'n': ngramlen = atoi(optarg); break;
            case 'd': delimiter = optarg; break;
            case 'p': padding_token = optarg; break;
            case 'h':
                print_help(argv[0]);
                return 0;
            default:
                fprintf(stderr, "Try '%s --help' for usage information.\n", argv[0]);
                return 1;
        }
    }

    if (ngramlen <= 0) {
        fprintf(stderr, "Error: -n/--ngram-length is mandatory.\n");
        fprintf(stderr, "Try '%s --help' for usage information.\n", argv[0]);
        return 1;
    }

    FILE *fin = strcmp(in_file, "-") == 0 ? stdin : fopen(in_file, "r");
    FILE *fout = strcmp(out_file, "-") == 0 ? stdout : fopen(out_file, "w");

    if (!fin) { perror("Input file"); return 1; }
    if (!fout) { perror("Output file"); return 1; }

    char *line = NULL;
    size_t len = 0;

    while (getline(&line, &len, fin) != -1) {
        line[strcspn(line, "\n")] = 0;  // Remove newline
        generate_ngrams(line, ngramlen, delimiter, padding_token, fout);
    }

    free(line);
    if (fin != stdin) fclose(fin);
    if (fout != stdout) fclose(fout);

    return 0;
}
