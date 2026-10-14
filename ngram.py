#!/usr/bin/env python3
# -*- coding: utf-8, vim: expandtab:ts=4 -*-

import sys
from math import prod
from os import devnull
from timeit import repeat
from functools import partial
from argparse import ArgumentParser
from statistics import mean, median, stdev
from itertools import product, islice, tee, chain, cycle, repeat as itertools_repeat

from memory_profiler import memory_usage, profile as memory_profile

chain_from_iterable = chain.from_iterable


def cartesian_product(*args):
    """Iterative implementation of Cartesian product (like itertools.product)"""
    result = [[]]
    for pool in args:
        result = [x + [y] for x in result for y in pool]
    return result


def cartesian_product2(*args):
    """Lazy iterative Cartesian product generator (no recursion, no itertools)"""
    if not args:
        return
    # Convert all inputs to lists for multiple iteration
    pools = [list(pool) for pool in args]
    # An empty pool means there are no combinations
    if any(not pool for pool in pools):
        return
    # Initialize indices
    indices = [0] * len(pools)
    while True:
        yield [pools[i][indices[i]] for i in range(len(pools))]
        # Advance indices like an odometer
        for i in reversed(range(len(pools))):
            indices[i] += 1
            if indices[i] < len(pools[i]):
                break
            indices[i] = 0
        else:
            return  # All combinations exhausted


def ng_product(it, n, _):
    """An n-gram feature permutation generator using the built-in product() function"""
    for ngram in n_grams_of_words(it, n):
        for combo in product(*ngram):
            yield ' '.join(combo)


def ng_cproduct(it, n, _):
    """An n-gram feature permutation generator using iterative implementation of Cartesian product"""
    for ngram in n_grams_of_words(it, n):
        for combo in cartesian_product(*ngram):
            yield ' '.join(combo)


def ng_cproduct2(it, n, _):
    """An n-gram feature permutation generator using lazy iterative Cartesian product generator"""
    for ngram in n_grams_of_words(it, n):
        for combo in cartesian_product2(*ngram):
            yield ' '.join(combo)


def ng_recursive(it, n, _):
    """The recursive algorithm (originally in MAWK) by Laszlo Laki"""
    for ngram in n_grams_of_words(it, n):
        yield from _permute(ngram, 0, n - 1)


def _permute(elems, actind, maxind, temp=''):
    if actind < maxind:
        for subelem in elems[actind]:
            yield from _permute(elems, actind + 1, maxind,  # Step an elem right in the n-gram
                                '{0}{1} '.format(temp, subelem))  # Partial mosaic n-gram ending with space!
    else:  # Last elem, the deepest level in the recursion
        for subelem in elems[actind]:
            yield '{0}{1}'.format(temp, subelem)  # Yield the full mosaic n-gram with the last elem


def ng_iter_list_out(it, n, _):
    """Arbitrary number of features with length counting"""
    for ngram in n_grams_of_words(it, n):
        n_gram_lens = [len(e) for e in ngram]
        max_len = prod(n_gram_lens)
        # To get mosaic n-grams in tuples, zip together the iterators come from the above:
        # 1. Get max_len elements (islice)
        # 2. by cycling through the iterator repeatedly (cycle)
        # 3. chaining together previous iterators as they come (chain_from_iterable())
        # 4. repeating each subelement prod(n_gram_lens[i+1:]) times for all subelements (itertools_repeat)
        # 5. for all elements of the n-gram (enumerate)
        # the list() cannot be omitted, because the value of i is interpreted
        #  only at zip()-ing, when i is already changed by the outer loop
        yield from zip(*(list(islice(cycle(chain_from_iterable(
                                     (itertools_repeat(subelem, prod(n_gram_lens[i + 1:]))
                                      for subelem in elem))),
                                     max_len))
                         for i, elem in enumerate(ngram)))


def ng_iter_list_in(it, n, _):
    """Arbitrary number of features with length counting"""
    for ngram in n_grams_of_words(it, n):
        n_gram_lens = [len(e) for e in ngram]
        max_len = prod(n_gram_lens)
        # To get mosaic n-grams in tuples, zip together the iterators come from the above:
        # 1. Get max_len elements (islice)
        # 2. by cycling through the iterator repeatedly (cycle)
        # 3. chaining together previous iterators as they come (chain_from_iterable())
        # 4. repeating each subelement prod(n_gram_lens[i+1:]) times for all subelements (itertools_repeat)
        # 5. for all elements of the n-gram (enumerate)
        # The list() cannot be omitted, because the value of i is interpreted
        #  only at zip()-ing, when i is already changed by the outer loop
        yield from zip(*(islice(cycle(chain_from_iterable(
                                 list(itertools_repeat(subelem, prod(n_gram_lens[i + 1:]))
                                      for subelem in elem))),
                                max_len)
                         for i, elem in enumerate(ngram)))


def ng_iter_fix_len(it, max_n, fixed_len):  # No padding only!
    max_len = fixed_len ** max_n
    for ngram in n_grams_of_words(it, max_n):
        # Zip together the iterators come from the above:
        # 1. Get max_len element (islice)
        # 2. by cycling through the iterator repeatedly (cycle)
        # 3. repeating each element fixed_len ** (max_n - (i+1)) times (itertools_repeat)
        # 4. for all elements of the n-gram (enumerate)
        # The list() cannot be omitted, because the value of i is interpreted
        #  only at zip()-ing, when i is already changed by the outer loop
        yield from zip(*(islice(cycle(chain_from_iterable(
                                      list(itertools_repeat(subelem, fixed_len ** (max_n - (i + 1)))
                                           for subelem in elem))),
                                max_len)
                         for i, elem in enumerate(ngram)))


def ng_iter_fix_len2(it, max_n, fixed_len):  # No padding only!
    n_gram_lens = [fixed_len ** (max_n - (i + 1)) for i in range(max_n)]
    max_len = fixed_len ** max_n
    for ngram in n_grams_of_words(it, max_n):
        # Zip together the iterators come from the above:
        # 1. Get max_len element (islice)
        # 2. by cycling through the iterator repeatedly (cycle)
        # 3. repeating each element fixed_len ** (max_n - (i+1)) times (itertools_repeat)
        # 4. for all elements of the n-gram (enumerate)
        # The list() cannot be omitted, because the value of i is interpreted
        #  only at zip()-ing, when i is already changed by the outer loop
        yield from zip(*(islice(cycle(chain_from_iterable(
                                      list(itertools_repeat(subelem, n_gram_lens[i])
                                           for subelem in elem))),
                                max_len)
                         for i, elem in enumerate(ngram)))


def n_grams_of_words(it, n):
    return zip(*(islice(it, i, None) for i, it in enumerate(tee(it, n))))


def readbywords_wo_padding(fileobj, _):
    for line in fileobj:  # This simulates reading line by line, which is slower than reading the entire file at once
        for word in line.strip().split(' '):
            yield word.split('#')
        # Merges lines for simplicity. It is inevitable for the fixed length methods to generate
        # a lot of unnecessary n-gram
        # for _ in range(n-1):  # To handle each line separately simulating sentence per line (SPL) format
        #     yield ['DUMMY_WORD', 'DUMMY_WORD', ...]  # Fixed len for fields


def readbywords_w_padding(fileobj, n):
    for line in fileobj:  # This simulates reading line by line, which is slower than reading the entire file at once
        for word in line.strip().split(' '):
            yield word.split('#')
        for _ in range(n - 1):  # To handle each line separately simulating sentence per line (SPL) format
            yield ['DUMMY_WORD']


def init_once(in_file, read_fun, ngramlen):
    with open(in_file, encoding='UTF-8') as inp_fh:
        with open(devnull, 'w', encoding='UTF-8'):
            # Constructing the generator does not consume the input.
            read_fun(inp_fh, ngramlen)


def run_once(read_function, inp_file, n, no_of_elems, fun, tim_fun, out_file=devnull):
    """Run one complete workload, including opening and closing its files."""
    with open(inp_file, encoding='UTF-8') as inp_fh:
        if out_file == '-':
            tim_fun(read_function(inp_fh, n), sys.stdout, n, no_of_elems, fun)
        else:
            with open(out_file, 'w', encoding='UTF-8') as out_fh:
                tim_fun(read_function(inp_fh, n), out_fh, n, no_of_elems, fun)


@memory_profile
def run_profiled_once(read_function, inp_file, n, no_of_elems, fun, tim_fun, out_file=devnull):
    """Run one workload with line-by-line memory profiling enabled."""
    run_once(read_function, inp_file, n, no_of_elems, fun, tim_fun, out_file)


def tim(inp, out, n, no_of_elems, fun):
    for ng in fun(inp, n, no_of_elems):
        print(*ng, file=out)


def tim_rec(inp, out, n, no_of_elems, fun):
    for ng in fun(inp, n, no_of_elems):
        print(ng, file=out)


def main():
    alternatives = {'product': ('Product:', ng_product, tim_rec, 'var'),  # Iterative fun returns strs not tuples
                    'cproduct': ('CProduct:', ng_cproduct, tim_rec, 'var'),  # Iterative fun returns strs not tuples
                    'cproduct2': ('CProduct2:', ng_cproduct2, tim_rec, 'var'),  # Iterative fun returns strs not tuples
                    'rec': ('Recursive:', ng_recursive, tim_rec, 'var'),  # Recursive fun returns strs not tuples
                    'iter-in': ('Iter (list in).:', ng_iter_list_in, tim, 'var'),
                    'iter-out': ('Iter (list out).:', ng_iter_list_out, tim, 'var'),
                    'iter-fixed': ('Iter. fixed:', ng_iter_fix_len, tim, 'fixed'),
                    'iter-fixed2': ('Iter. fixed2:', ng_iter_fix_len2, tim, 'fixed'),
                    }

    parser = ArgumentParser()
    parser.add_argument('--input-file', '-i', help='Input file', type=str)
    parser.add_argument('--ngram-length', '-n', help='n-gram length', type=int)
    parser.add_argument('--field-length', '-f', help='field length', type=int, default=3)
    parser.add_argument('--read-fun', '-u', choices=['padding', 'no-padding'], help='Read with or without padding',
                        type=str)
    parser.add_argument('--run-fun', '-r', help='Function to run', type=str)
    parser.add_argument('--mem', '-m', choices=['True', 'False'], help='Profile memory usage (True) or time (False)',
                        type=str)
    parser.add_argument('--write', '-w', choices=['True', 'False'], help='Write output to STDOUT (True) or not (False)',
                        type=str)

    args = parser.parse_args()
    if any(arg is None for arg in vars(args).values()):
        parser.print_help(sys.stderr)
        exit(2)

    in_file = args.input_file
    ngramlen = args.ngram_length
    no_of_elems = args.field_length
    if args.read_fun == 'padding':
        read_fun = readbywords_w_padding
    else:
        read_fun = readbywords_wo_padding
    if args.run_fun == 'all-variable':
        alternatives = {k: v for k, v in alternatives.items() if v[3] == 'var'}
    elif args.run_fun == 'all-fixed':
        alternatives = {k: v for k, v in alternatives.items() if v[3] == 'fixed'}
    elif args.run_fun == 'init':
        pass
    elif args.run_fun != 'all':
        alternatives = {args.run_fun: alternatives[args.run_fun]}  # Just one function (default all)

    if args.write == 'True':
        if args.run_fun in {'all', 'all-variable', 'all-fixed'}:
            print('ERROR: Can only write for one algorithm not all!', file=sys.stderr)
            exit(2)
        for _, (name, ngram_fun, tim_fun, _) in alternatives.items():
            print(name, file=sys.stderr)
            run_once(read_fun, in_file, ngramlen, no_of_elems, ngram_fun, tim_fun, out_file='-')
        exit(0)

    if args.mem == 'True':
        print('', 'PEAK MEMORY USAGE (MB)', '', sep='\n')
        for _, (name, ngram_fun, tim_fun, _) in alternatives.items():
            # Measure the complete workload in an isolated process
            # Sampling is approximate; very short peaks may be missed by the sampling interval
            samples = memory_usage((run_profiled_once, (read_fun, in_file, ngramlen, no_of_elems, ngram_fun, tim_fun),
                                    {'out_file': devnull}), interval=0.01)
            peak_mb = max(samples)
            baseline_mb = samples[0]
            additional_mb = max(0.0, peak_mb - baseline_mb)
            print(f'{name} peak={peak_mb:.2f} MB RSS; additional≈{additional_mb:.2f} MB above initial sample')
    elif args.run_fun == 'init':
        print('', 'INIT TIME', '', sep='\n')
        res = repeat(partial(init_once, in_file, read_fun, ngramlen), number=1, repeat=3)
        print(read_fun.__name__, f'{mean(res):.10f}', '(' + ', '.join(f'{r:.10f}' for r in res) + ')')
    else:
        print('', 'RUNNING TIME (seconds)', '', sep='\n')
        for _, (name, ngram_fun, tim_fun, _) in alternatives.items():
            res = repeat(partial(run_once, read_fun, in_file, ngramlen, no_of_elems, ngram_fun, tim_fun),
                         number=1, repeat=3)
            print(f'{name} mean={mean(res):.10f} median={median(res):.10f} stddev={stdev(res):.10f}')
            print('  runs:', ', '.join(f'{r:.10f}' for r in res))
        print()


if __name__ == '__main__':
    main()
