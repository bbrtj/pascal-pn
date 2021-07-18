# Polish notation implementation in Pascal

This program parses strings containing mathematical calculation in standard notation and translates it to Polish notation (PN):

```
2 + 2
  becomes + 2 2

3 * 3 * 3
  becomes * 3 * 3 3

2 + 3 * (4 + 1)
  becomes + 2 * 3 + 4 1
```

This notation is stored as a simple stack can be exported to a string. The program can later import the stack from a string and perform the calculation on it.

## Current state

In development. Most of the features listed are missing.

## Features

- Recognizes textual variables
- Fast string export / import
- Evaluation based on 64 bit (double) floating point values
- Compiled into a CLI program or into a shared library

### Export format

This program can only export and import from its own custom format:

```
2 + 2
  o+#2#2

2 + 3 * a
  o+#2#o*#3#va
```

The idea is that it unambigously describes the calculation:
- stack items are separated by a `#` (hash) character, which should be less error prone than a space character
- any stack item prefixed with a `o` character is an operation
- any stack item prefixed with a `v` character is a variable
- any other stack item must contain a number, and is considered a constant

Since there's no need to do any parsing on such string, its importing should be very fast. This exported format can be stored and only imported on demand to perform calculations without any need for parsing the original calculation in standard notation.

Transforming this format into a regular Polish notation should be easy enough with any text manipulation tool:

```
cat exported.txt | perl -pn -e '
	s/^[ov]//;
	s/(?<=#)[ov]//g;
	y/#/ /;
'
```

## Building

Free Pascal Compiler with Object Pascal RTL is required to build.

Makefile contents should suffice for most building needs. To build an optimized CLI binary:

```
O_LEVEL=3 make build
```

To build an optimized shared library:

```
O_LEVEL=3 make build-library
```

## Author and License

Copyright Bartosz Jarzyna. Licensed with 2-clause BSD license.

