# peg.ms

**peg.ms** is a pattern-matching library for [MiniScript](https://miniscript.org/), based on [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar) (PEGs).

(To debug or pretty print large objects there is a `._str` method implemented for each class.)


## Example

Parse a comma-separated list of numbers surrounded by brackets.

```
import "peg"

listOfNumbers = new peg.Grammar
listOfNumbers.init  "list   <- '[' space number (',' space number)* space ']' " +
                    "number <- ([+-]? [0-9]+) {tonumber} " +
                    "space <- ' '* ",
                    "list"

listOfNumbers.capture "tonumber", function(match, subcaptures, arg)
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
| `result.length` | `number` or `null` | length of the parsed portion of a subject |
| `result.match` | `Match` or `null` | syntax tree |
| `result.errors` | `list` of `Error`s | list of syntax and/or semantic errors |
| `result.captures` | `list` | list of captured values |

To check for success/failure, compare `ParseResult.length` with `null`.

If exactly one value was captured, it can be exrtacted with `ParseResult.capture`.


## Match Object

Syntax trees are stored as Match objects.

| Field | Type | Description |
| --- | --- | --- |
| `match.start` | `number` | starting position in the subject |
| `match.length` | `number` | length of a match |
| `match.fragment` | `string` | matched text (`subject[start : start + length]`) |
| `match.pattern` | `Pattern` | pattern instance that created a match |
| `match.children` | `list` of `Match`es | submatches |


## Examples

(Most of these come from the [LPeg manual](https://www.inf.puc-rio.br/~roberto/lpeg/).)


### Strings of a's and b's that have the same number of a's and b's

```
import "peg"

equalAB = new peg.Grammar
equalAB.init    " S <- 'a' B / 'b' A / '' " +
	            " A <- 'a' S / 'b' A A " +
	            " B <- 'b' S / 'a' B B ",
	            "S"

result = equalAB.parse("abbabbbbbb")
print result.length         // 4
print result.match.fragment // "abba"
print result.errors         // []
print result.captures       // []
```


### Adding a list of numbers

```
import "peg"

addNumbers = new peg.Grammar
addNumbers.init "  number      <-  [0-9]+ {}  " +
	            "  addNumbers  <-  ( number  ( ','  number ) * ) {add}  ",
	            "addNumbers"

addNumbers.capture "add", function(match, subcaptures, arg)
	add = 0
	for s in subcaptures
		add += s.val
	end for
	return add
end function

print addNumbers.parse("10,30,43").capture  // 83
```


### String upper

```
import "peg"

stringUpper = new peg.Grammar
stringUpper.init    "  name  <-  [a-z]+ {}  " +
	                "  stringUpper    <-  ( name  '^' {} ? ) {upper}  ",
	                "stringUpper"

stringUpper.capture "upper", function(match, subcaptures, arg)
	if subcaptures.len == 1 then return subcaptures[0] else return subcaptures[0].upper
end function

print stringUpper.parse("foo").capture  // "foo"
print stringUpper.parse("foo^").capture  // "FOO"
```


### Name-value lists

```
import "peg"

nameValueList = new peg.Grammar
nameValueList.init  "  space  <-  [ \t\n\r] *  " +
                    "  name   <-  [a-zA-Z] + {}  space  " +
                    "  sep    <-  [,;]  space  " +
                    "  pair   <-  ( name  '='  space  name  sep ? )  " +
                    "  list   <-  pair * {list}  ",
	                "list"

nameValueList.capture "list", function(match, subcaptures, arg)
	vals = {}
	for i in range(0, subcaptures.len - 1, 2)
		vals[subcaptures[i]] = subcaptures[i + 1]
	end for
	return vals
end function

vals = nameValueList.parse("a=b, c = hi; next = pi").capture
print vals.a    // "b"
print vals.c    // "hi"
print vals.next  // "pi"
```


### Splitting a string

```
import "peg"

splitString = new peg.Grammar
splitString.init    " sep     <-  $ " +
                    " elem    <-  ( ! sep  . ) * {} " +
                    " result  <-  elem  ( sep  elem ) * ",
	                "result"

split = function(s, sep)
	sep = peg.patternOrLiteral(sep)
	return splitString.parse(s, 0, {"sep": sep}).captures
end function

print split("a b c", " ")  // ["a", "b", "c"]
print split("a//b//c", "//")  // ["a", "b", "c"]
```


### Searching for a pattern

```
import "peg"

searchForPatt = new peg.Grammar
searchForPatt.init  "  pattern  <-  $                                " +
	                "  search   <-  pattern {patt}  /  .  search  ",
	                "search"

searchForPatt.capture "patt", function(match, subcaptures, arg)
	return [match.start, match.start + match.length]
end function

search = function(s, pattern)
	pattern = peg.patternOrLiteral(pattern)
	return searchForPatt.parse(s, 0, {"pattern": pattern}).capture
end function

result = search("hello world!", "world")
print result                               // [6, 11]
print "hello world!"[result[0]:result[1]]  // "world"
```


### Balanced parentheses

```
import "peg"

balanced = new peg.Grammar
balanced.init "  bparen  <-  '('  ( ! [()]  .  /  bparen ) *  ')'  "

isBalanced = function(s)
	return balanced.parse(s).length == s.len
end function

print isBalanced("(  ((()  ) () ))")  // 1
print isBalanced("((()")              // 0
```


### Global substitution

```
import "peg"

gsubGrammar = new peg.Grammar
gsubGrammar.init    "  pattern  <-  $  " +
	                "  gsub     <-  ( ( pattern {sub}  /  . {} ) * )  "

gsubGrammar.capture "sub", function(match, subcaptures, arg)
	return arg.repl
end function

gsub = function(s, patt, repl)
	arg = {}
	arg.pattern = peg.patternOrLiteral(patt)
	arg.repl = repl
	return gsubGrammar.parse(s, 0, arg).captures.join("")
end function

print gsub("hello foo!", "foo", "world")  // "hello world!"
```


### Comma-Separated Values (CSV)

```
import "peg"

csvGrammar = new peg.Grammar
csvGrammar.init "  quot     <-  [""]  " +
                "  newline  <-  [\r\n]  " +
                "  qstr     <-  quot  ( ! quot  .  /  quot  quot ) * {qstr}  quot  " +
                "  str      <-  ( ! ( ','  /  newline  /  quot )  . ) * {}  " +
                "  field    <-  qstr  /  str  " +
                "  record   <-  field  ( ','  field ) *  ( newline  /  !. )  ",
                "record"

csvGrammar.capture "qstr", function(match, subcaptures, arg)
	return match.fragment.replace("""" + """", """")
end function

print csvGrammar.parse("foo,""bar"",baz").captures  // ["foo", "bar", "baz"]
```


### Lua's long strings

```
import "peg"

longStr = new peg.Grammar
longStr.init    "  longstr  <-  open  ( ! close  . ) * {}  close  " +
                "  open     <-  '['  '=' * :startEq:  '['         " +
                "  close    <-  ']'  '=' * :endEq:  ']'           ",
                "longstr"

longStr.matchTime "startEq", function(match, subcaptures, arg, ctx)
	if match != null then
		arg.startEq = match.fragment
	end if
	return match
end function

longStr.matchTime "endEq", function(match, subcaptures, arg, ctx)
	if match != null then
		if match.fragment.len == arg.startEq.len then return match
		match = null
	end if
	return match
end function

print longStr.parse("[==[foo]=]bar]==]", 0, {}).capture  // "foo]=]bar"
```


### Arithmetic expressions

```
import "peg"

arithExp = new peg.Grammar
arithExp.init   "  Space     <-  [ " + char(9) + char(10) + char(13) + "] *  " +
                "  Number    <-  ( '-' ?  [0-9] + ) {}  Space                " +
                "  TermOp    <-  [+-] {}  Space                              " +
                "  FactorOp  <-  [*/] {}  Space                              " +
                "  Open      <-  '('  Space                                  " +
                "  Close     <-  ')'  Space                                  " +
                "  Exp       <-  Space ( Term  ( TermOp  Term ) * ) {eval}   " +
                "  Term      <-  ( Factor  ( FactorOp  Factor ) * ) {eval}   " +
                "  Factor    <-  Number  /  Open  Exp  Close                 ",
                "Exp"

arithExp.capture "eval", function(match, subcaptures, arg)
	_val = function(x)
		if x isa string then return x.val else return x
	end function
	acc = _val(subcaptures[0])
	for i in range(1, subcaptures.len - 1, 2)
		op = subcaptures[i]
		x = _val(subcaptures[i + 1])
		if op == "+" then
			acc += x
		else if op == "-" then
			acc -= x
		else if op == "*" then
			acc *= x
		else if op == "/" then
			acc /= x
		end if
	end for
	return acc
end function


print arithExp.parse("3 + 5*9 / (1+1) - 12").capture  // 13.5
```





