#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long;
use List::Util qw(all);

# CLI parameters
my $in_file  = '-';
my $out_file = '-';
my $ngramlen;
my $delimiter = '#';
my $padding_token = 'DUMMY_WORD';

GetOptions(
    'input|i=s'        => \$in_file,
    'output|o=s'       => \$out_file,
    'ngramlen|n=i'     => \$ngramlen,
    'delimiter|d=s'    => \$delimiter,
    'padding_token|p=s'=> \$padding_token,
) or die "Invalid options\n";

die "ngramlen is mandatory\n" unless defined $ngramlen;
die "padding_token is mandatory\n" unless defined $padding_token;

# Open input and output handles
my $IN  = $in_file eq '-' ? *STDIN  : do { open my $fh, '<:encoding(UTF-8)', $in_file or die $!; $fh };
my $OUT = $out_file eq '-' ? *STDOUT : do { open my $fh, '>:encoding(UTF-8)', $out_file or die $!; $fh };

# Preallocate sliding window
my @window;

# Cartesian product arrays
my (@arrays, @indices, @lengths, @combo);

# Main streaming loop
while (1) {
    # Fill sliding window
    while (@window < $ngramlen) {
        my $line = <$IN>;
        last unless defined $line;
        chomp $line;

        for my $word (split /\s+/, $line) {
            push @window, [ split /\Q$delimiter\E/, $word ];
        }
        push @window, [($padding_token)] for 1..($ngramlen-1);
    }
    last unless @window >= $ngramlen;

    # Prepare arrays and lengths for Cartesian product
    @arrays  = @window[0..$ngramlen-1];
    @lengths = map { scalar @$_ } @arrays;
    @indices = (0) x $ngramlen;
    @combo   = ('') x $ngramlen;

    # Iterative Cartesian product
    COMBO: while (1) {
        # Build current combination directly in preallocated buffer
        for my $i (0..$ngramlen-1) {
            $combo[$i] = $arrays[$i]->[$indices[$i]];
        }

        # Skip lines starting with padding or fully padding-only
        if ($combo[0] ne $padding_token && !all { $_ eq $padding_token } @combo) {
            print $OUT join(' ', @combo), "\n";
        }

        # Increment indices
        for (my $pos = $ngramlen-1; $pos >= 0; $pos--) {
            $indices[$pos]++;
            if ($indices[$pos] < $lengths[$pos]) {
                last;
            } else {
                $indices[$pos] = 0;
                next if $pos > 0;
                last COMBO;  # finished all combinations
            }
        }
    }

    # Slide the window
    shift @window;
}
