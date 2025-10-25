#!/bin/bash

mosaic_ngram="mawk -v maxn=$1 -v delimit='#' -v padding_token='DUMMY_WORD' 'function cartesian_product(maxn, pool, sizes) {
                                                                                # Initialize index array
                                                                                for (i = 1; i <= maxn; i++)
                                                                                    idx[i] = 1

                                                                                done = 0
                                                                                while (!done) {
                                                                                    # Build the current combination
                                                                                    out = pool[1 \",\" idx[1]]
                                                                                    for (i = 2; i <= maxn; i++) {
                                                                                        out = out \" \" pool[i \",\" idx[i]]
                                                                                    }
                                                                                    print out   # or store: result_arr[++count] = out

                                                                                    # Increment indices like an odometer
                                                                                    for (i = maxn; i >= 1; i--) {
                                                                                        idx[i]++
                                                                                        if (idx[i] <= sizes[i])
                                                                                            break
                                                                                        idx[i] = 1
                                                                                        if (i == 1)
                                                                                            done = 1
                                                                                    }
                                                                                }
                                                                            }
                                                                            {
                                                                                # Add padding tokens
                                                                                old_NF = NF;
                                                                                NF += maxn - 1;
                                                                                for (i = old_NF + 1; i <= NF; i++) {
                                                                                    \$i = padding_token;
                                                                                }
                                                                                num_words = split(\$0, words)

                                                                                # Loop over all n-grams in the line
                                                                                for (start = 1; start <= num_words - maxn + 1; start++) {
                                                                                    # Build flattened pool arrays for n-gram words
                                                                                    for (i = 0; i < maxn; i++) {
                                                                                        # Split each word into sub-elements by delimiter
                                                                                        word = words[start + i]
                                                                                        size = split(word, elems, delimit)
                                                                                        sizes[i + 1] = size
                                                                                        for (j = 1; j <= size; j++) {
                                                                                            pool[(i + 1) \",\" j] = elems[j]
                                                                                        }
                                                                                    }
                                                                                    # Compute and print Cartesian product of the n-gram pools
                                                                                    cartesian_product(maxn, pool, sizes)
                                                                                }
                                                                            }'"
# echo '<s> Az#az#DET alma#alma#FN.NOM nem#nem#HA esett#esik#IGE.MULT messze#messze#HAT a#a#DET fájától#fa#FN.POSS.TÓL !#!#PUNCT </s>' |
eval "${mosaic_ngram}"
