# peg.ms

**peg.ms** is a pattern-matching library for [MiniScript](https://miniscript.org/), based on [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar) (PEGs).

To debug or pretty print large objects you may want to use a `._str` method implemented for each `peg.ms` class.


## Example

Parse a comma-separated list of numbers surrounded by brackets.

```
import "peg"

listOfNumbers = new peg.Grammar
listOfNumbers.init  "list   <- '[' space number (',' space number)* space ']' " +
                    "number <- ([+-]? [0-9]+) {tonumber} " +
                    "space <- ' '* ",
                    "list"

listOfNumbers.addCaptureAction "tonumber", function(match, subcaptures, arg)
	return match.fragment.val
end function

print listOfNumbers.parse("[]").captures            // []
print listOfNumbers.parse("[11,22,33]").captures    // [11, 22, 33]
print listOfNumbers.parse("[ 44, 55 ]").captures    // [44, 55]
```


## Grammar syntax

Most of [standard PEG](https://bford.info/pub/lang/peg.pdf) syntax is implemented.

| Syntax | Description | Precedence |
| --- | --- | --- |
| `'string'` or `"string"` | literal string | |
| `[class]` | character class | |
| `.` | any character | |
| `name` | non terminal | |
| `( p )` | grouping / control of precedence | |
| `p ?` | optional match | 4 |
| `p *` | zero or more repetitions | 4 |
| `p +` | one or more repetitions | 4 |
| `& p` | and predicate | 3 |
| `! p` | not predicate | 3 |
| `p1 p2` | concatenation | 2 |
| `p1 / p2` | ordered choice | 1 |
| `name1 <- p1  name2 <- p2 ...` | rule definitions | |

Comments begin with `#` and go until the end of line.

Character classes and literals may include escapes: `\t`, `\r`, `\n`, `\[`, `\]`, `\'`, `\"`, `\\` and `\uXXXX` (hexadecimal unicode).


## Capture syntax

A __capture__ is a pattern that produces values (the so called semantic information) according to what it matches.

Captures are expressed with (non standard) suffixes which have the same precedence as `?*+`.

| Syntax | Description | Precedence |
| --- | --- | --- |
| `p {}` | simple capture | 4 |
| `p {name}` | function capture | 4 |
| `p :name:` | match-time capture | 4 |


## ParseResult object

`Grammar.parse` returns the result as a `ParseResult` object.

| Field | Type | Description |
| --- | --- | --- |
| `.length` | `number` or `null` | length of the parsed portion of a subject |
| `.match` | `Match` or `null` | syntax tree |
| `.errors` | `list` of `Error`s | list of syntax and/or semantic errors |
| `.captures` | `list` | list of captured values |

To check for success/failure, compare `ParseResult.length` with `null`.

If exactly one value was captured, it can be exrtacted it with `ParseResult.capture`.


(Look in tests/ and examples/.)

