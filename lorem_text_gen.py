#!/usr/bin/env python3
# -*- coding: utf-8, vim: expandtab:ts=4 -*-

import sys
from argparse import ArgumentParser
from random import sample, randint, choice


def sentence(field_length_min, field_length_max, no_of_words_min, no_of_words_max, no_of_sent_parts_min,
             no_of_sent_parts_max):
    """
    Original source: github.com/TheAbhijeet/lorem_text
    Under the MIT license
    Return a randomly generated sentence of lorem ipsum text.
    The first word is capitalized, and the sentence ends in either a period or
    question mark. Commas are added at random.
    """
    words = (
        'exercitationem', 'perferendis', 'perspiciatis', 'laborum', 'eveniet',
        'sunt', 'iure', 'nam', 'nobis', 'eum', 'cum', 'officiis', 'excepturi',
        'odio', 'consectetur', 'quasi', 'aut', 'quisquam', 'vel', 'eligendi',
        'itaque', 'non', 'odit', 'tempore', 'quaerat', 'dignissimos',
        'facilis', 'neque', 'nihil', 'expedita', 'vitae', 'vero', 'ipsum',
        'nisi', 'animi', 'cumque', 'pariatur', 'velit', 'modi', 'natus',
        'iusto', 'eaque', 'sequi', 'illo', 'sed', 'ex', 'et', 'voluptatibus',
        'tempora', 'veritatis', 'ratione', 'assumenda', 'incidunt', 'nostrum',
        'placeat', 'aliquid', 'fuga', 'provident', 'praesentium', 'rem',
        'necessitatibus', 'suscipit', 'adipisci', 'quidem', 'possimus',
        'voluptas', 'debitis', 'sint', 'accusantium', 'unde', 'sapiente',
        'voluptate', 'qui', 'aspernatur', 'laudantium', 'soluta', 'amet',
        'quo', 'aliquam', 'saepe', 'culpa', 'libero', 'ipsa', 'dicta',
        'reiciendis', 'nesciunt', 'doloribus', 'autem', 'impedit', 'minima',
        'maiores', 'repudiandae', 'ipsam', 'obcaecati', 'ullam', 'enim',
        'totam', 'delectus', 'ducimus', 'quis', 'voluptates', 'dolores',
        'molestiae', 'harum', 'dolorem', 'quia', 'voluptatem', 'molestias',
        'magni', 'distinctio', 'omnis', 'illum', 'dolorum', 'voluptatum', 'ea',
        'quas', 'quam', 'corporis', 'quae', 'blanditiis', 'atque', 'deserunt',
        'laboriosam', 'earum', 'consequuntur', 'hic', 'cupiditate',
        'quibusdam', 'accusamus', 'ut', 'rerum', 'error', 'minus', 'eius',
        'ab', 'ad', 'nemo', 'fugit', 'officia', 'at', 'in', 'id', 'quos',
        'reprehenderit', 'numquam', 'iste', 'fugiat', 'sit', 'inventore',
        'beatae', 'repellendus', 'magnam', 'recusandae', 'quod', 'explicabo',
        'doloremque', 'aperiam', 'consequatur', 'asperiores', 'commodi',
        'optio', 'dolor', 'labore', 'temporibus', 'repellat', 'veniam',
        'architecto', 'est', 'esse', 'mollitia', 'nulla', 'a', 'similique',
        'eos', 'alias', 'dolore', 'tenetur', 'deleniti', 'porro', 'facere',
        'maxime', 'corrupti',
    )

    # Determine the number of comma-separated sections and number of words in
    # each section for this sentence.
    # Random number of elements
    words_with_anal = ['#'.join(f'{i}:{word}' for i in range(1, randint(field_length_min, field_length_max) + 1))
                       for word in words]
    sections = [' '.join(sample(words_with_anal, randint(no_of_words_min, no_of_words_max)))
                for _ in range(randint(no_of_sent_parts_min, no_of_sent_parts_max))]
    s = ', '.join(sections)
    # Convert to sentence case and add end punctuation.
    return ''.join((s[0].upper(), s[1:], choice('?.')))


parser = ArgumentParser()
parser.add_argument('--sentences', '-s', help='Number of dummy sentences (one sentence per line)', type=int)
parser.add_argument('--field-length-min', help='field length min', type=int)
parser.add_argument('--field-length-max', help='field length max', type=int)
parser.add_argument('--no-of-words-min', help='no. of words per sentence part min', type=int, default=1)
parser.add_argument('--no-of-words-max', help='no. of words per sentence part max', type=int, default=12)
parser.add_argument('--no-of-sent-parts-min', help='no. of sentence parts min', type=int, default=1)
parser.add_argument('--no-of-sent-parts-max', help='no. of sentence parts max', type=int, default=5)


args = parser.parse_args()
if any(arg is None for arg in vars(args).values()):
    parser.print_help(sys.stderr)
    exit(2)

for _ in range(args.sentences):
    print(sentence(args.field_length_min, args.field_length_max, args.no_of_words_min, args.no_of_words_max,
                   args.no_of_sent_parts_min, args.no_of_sent_parts_max))
