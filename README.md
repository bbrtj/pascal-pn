# Polish notation implementation in Pascal

This program parses strings containing mathematical calculation in standard
notation and translates it to Polish notation (PN). Polish notation can express
a calculation in an unambigous way, such as:

```
2 + 2
  becomes + 2 2

3 * 3 * 3
  becomes * 3 * 3 3

2 + 3 * (4 + 1)
  becomes + 2 * 3 + 4 1

2 + -2
  becomes + 2 - 2
  (the minus is unary)
```

This notation is stored as a simple stack can be exported to a string. The
program can later import the stack from a string and perform the calculation on
it. It uses a recursive descent parser and a binary tree to transform a string
into a calculation. The final calculation is expressed as a stack.

## Features

- Translates standard notation to polish notation
- Recognizes textual variables that can be assigned for calculation
- Saves the offset at which an operator / number / variable was found
- Fast string export / import
- Evaluation based on Extended (64 - 80 bit) floating point numbers
- Compiled into a CLI program or can be linked statically in your program

## Supported operators

This library supports a range of operators and functions. Full and up to date
list is available when running `cli --help`.

### Export format

This program can only export and import from its own custom format:

```
2 + 2
  o+#2#2

2 + 3 * a
  o+#2#o*#3#va
```

The idea is that it unambigously describes the stack:
- stack items are separated by a `#` (hash) character, which should be less error prone than a space character
- any stack item prefixed with a `o` character is an operation (binary, infix)
- any stack item prefixed with a `p` character is an operation (unary, prefix)
- any stack item prefixed with a `v` character is a variable
- any other stack item must contain a number, and is considered a constant

Since there's no need to do any parsing on such string, its importing should be
very fast. This exported format can be stored and only imported on demand to
perform calculations without any need for parsing the original calculation in
standard notation.

Transforming this format into a regular Polish notation should be easy enough
with any text manipulation tool:

```
cat exported.txt | perl -pn -e '
	s/^[opv]//;
	s/(?<=#)[ov]//g;
	y/#/ /;
'
```

## Building

The CLI program is build through Lazarus. You also can use `lazbuild` or the
contents of the `makefile`. Free Pascal Compiler with Object Pascal RTL is
required to build.

```
make build
```

## Testing

Unit tests are written in Pascal, while end to end tests are written in Perl
(querying the CLI program for results). Any Perl should be able to run them out
of the box.

```
make test
```

## Benchmarking and performance

The CLI program allows usage of flag `-b`, which makes the program perform the
operation a number of times. This way it can be used to benchmark the
performance of the library, for example:

```
make build
time ./cli -p "2.81 + 3E5 / 5 * var1 ^ 4 - (8.81 - 16 * 32 + (51 * 49.999))" -v var1 50 -b 500000
```

Benchmarking on a T480 machine with i7-8650U on FreeBSD 14.1 has shown around
12 microseconds is required to do the entire parsing and calculation of the
expression above.

## Author and License

Copyright Bartosz Jarzyna. Licensed with 2-clause BSD license.

