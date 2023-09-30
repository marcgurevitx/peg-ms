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

`Grammar.parse` returns a `ParseResult` object.

| Field | Type | Description |
| --- | --- | --- |
| `result.length` | `number` or `null` | length of the parsed portion of a subject |
| `result.match` | `Match` or `null` | syntax tree |
| `result.errors` | `list` of `Error`s | list of syntax and/or semantic errors |
| `result.captures` | `list` | list of captured values |
| `result.capture` | | a value from `result.captures` if there's exactly one value, otherwise `null` |

To check for success/failure, compare `ParseResult.length` with `null`.


## Match Object

Syntax trees built by patterns are represented as `Match` objects.

| Field | Type | Description |
| --- | --- | --- |
| `match.start` | `number` | starting position in the subject |
| `match.length` | `number` | length of a match |
| `match.fragment` | `string` | matched text (`subject[start : start + length]`) |
| `match.pattern` | `Pattern` | pattern instance that created a match |
| `match.children` | `list` of `Match`es | submatches |

One optional field is a `match.capture` which normally is a _function capture_ callback of a corresponding pattern (if any).


## Simple capture

The suffix `{}` creates a _simple capture_ which captures the text fragment and _appends_ it to the list of all captures.


## Function capture

The suffix `{name}` creates a _function capture_ which invokes a callback function registered by `Grammar.capture name, @func`.

The callback is invoked with the following arguments.

| Argument | Type | Description |
| --- | --- | --- |
| `match` | `Match` | matched fragment or tree |
| `subcaptures` | `list` | list of values captured by the subpatterns |
| `arg` | | optional argument to `Grammar.parse` |

The returned value becomes a new capture. Unlike with simple capture, it replaces the **subcaptures**.

To append _many_ captures, push them into `subcaptures` and return the list. Returning some other list of values will make it an individual capture. It will not flatten into the total list of captures.

To append _no_ captures, remove everything from `subcaptures` and return the list. Returning `none` will append the actual `none` value to the total captures.

To interrupt the parsing and finish it with an error, return a `peg.Error` object. This error will show up in `ParseResult.errors`.


## Match-time capture

The suffix `:name:` creates a _match-time capture_ which invokes a callback function registered by `Grammar.matchTime name, @func` at the matching stage of parsing.

Unlike _function capture_ that only handles successful match tree nodes after the whole grammar matched, _match-time capture_ allows to handle all pattern matching results, including failed ones and ones which initially succeeded but whose containing pattern still failed later.

The callback is invoked with the following arguments.

| Argument | Type | Description |
| --- | --- | --- |
| `match` | `Match` or `null` | matched fragment or tree (or `null` if the pattern failed) |
| `subcaptures` | `function` that returns a `list` | list of subcaptures (only evaluated if gets invoked) |
| `arg` | | optional argument to `Grammar.parse` |
| `ctx` | `ParseConrext` | collection of data associated with current call to `Grammar.parse` |

The return value of the callback defines whether the match should be considered successfull.

- a `Match` object -- success
- `null` -- failure

It's impossible to interrupt the parsing by returning `null`, because patterns may fail and it's a normal thing. However, errors still can be signalled by either pushing them to the `ctx.errors` list or by calling `ctx.addSyntaxError name, errMsg`.

When no callback is defined for `name`, the suffix `:name:` acts as a shortcut for "report syntax error on the pattern's failure".


## Examples

(The examples use `import "peg"` for simple looks, but to avoid rebuilding `pegGrammar` use `ensureImport`.)

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





