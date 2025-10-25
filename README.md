# Mosaic N-gram Creation Methods Benchmark

This is a sample program to test speed and memory usage for different approaches for mosaic n-gram creation in Python,
Perl and AWK

# Theory

Mosaic n-gram adds complexity to normal n-grams by introducing fields in place of words which could be used
instead of the actual word (e.g. word form, lemma, POS-tag, etc.).
N-grams consisting of such mixed fields are called a mosaic-ngram.

To get all lower-order n-gram from a higher-order variant it is enough to pad the ending of the sentence
to the required order and count the frequency of the prefixes in the required order
(ignoring n-grams starting with padding words).

There are basically two algorithms presented:

1. Cartesian product-based algorithm
    - Recursively or iteratively takes the permutations of all fields of the current word and
      the rest of the words of the n-gram

2. Odometer (i.e. "analog counter") algorithm implemented with itertools
    - Computes parameters ahead of time or dynamically to find the required number of repeats and cycles of each fields
      in each word in the n-gram and executes them in the required order

# Usage

## Create virtual environment and install requirements

```txt
make venv
```

## Create random artificial test input data

```txt
make input
```

This command creates four files of random length lorem ipsum sentences in one sentence per line (SPL) format.
The first have fixed length of fields per word, the second have variable number of fields.
The last two files are created from the first 1000 sentences of the first two files.

## Running the tests

```txt
make run
```

This command tests word mosaic-3-grams and mosaic-5-grams and prints the test results.
See results in [results.txt](result.txt)

# Acknowledgment

The idea of mosaic n-grams is described in [Indig, Balázs, László János Laki, and Gábor Prószéky. 2016.
“Mozaik Nyelvmodell Az AnaGramma Elemzőhöz.” In XII. Magyar Számítógépes Nyelvészeti Konferencia: MSZNY
2016, 260–270.](http://acta.bibl.u-szeged.hu/58981/1/msznykonf_012_260-270.pdf)

Based on https://github.com/dlazesz/n-gram-benchmark

Dedicated to Bence Nyéki, for the beautiful memories of his job interview and latter joint efforts!

# License

This code is licensed under the MIT license
