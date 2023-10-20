# peg.ms

**peg.ms** is a pattern-matching library for [MiniScript](https://miniscript.org/), based on [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar) (PEGs).

(To debug or pretty print large objects there is a `._str` method implemented for almost each class.)

(The examples use `import "peg"` for simple looks. Use `ensureImport` to avoid rebuilding `pegGrammar`.)


## Example

Parse a comma-separated list of numbers surrounded by brackets.

```
import "peg"

listOfNumbers = new peg.Grammar
listOfNumbers.init  "list   :  '[' space number (',' space number)* space ']' " +
                    "number <- ([+-]? [0-9]+) {tonumber} " +
                    "space  <- ' '* "

listOfNumbers.capture "tonumber", function(match, subcaptures, arg, ctx)
	return match.fragment.val
end function

print listOfNumbers.parse("[]").captures.list            // []
print listOfNumbers.parse("[11,22,33]").captures.list    // [11, 22, 33]
print listOfNumbers.parse("[ 44, 55 ]").captures.list    // [44, 55]
```


## Syntax

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

Additionally, the library supports some nonstandard syntax:

| Syntax | Description | Precedence |
| --- | --- | --- |
| `p {}` | anonymous capture | 4 |
| `p {name}` | function capture | 4 |
| `p {name:}` | key capture | 4 |
| `p <name>` | match-time action | 4 |
| `p <name!>` | match-time error | 4 |
| `name <- $` | dynamic inclusion rule | |
| `name : p` | default initial rule | |

Suffixes `{…}` and `<…>` have the same precedence as `?*+`.


## API highlight

Create a grammar with `new` and initialize it with `.init(DEFINITIONS)`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+"
```

If the grammar has many rules, one of them can be set as the initial rule by passing its name as the second parameter to `.init`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+  C <- B  B <- A",
       "C"
```

Alternatively, mark the initial rule with `:`

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+  C: B  B <- A"  // (C: B) is the initial rule
```

To inspect the pattern tree built from the PEG string use `._str`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+  C: B  B <- A"

print g._str  // Grammar(C) ...
```

To parse a subject text, use `.parse(TEXT)`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+  C: B  B <- A"
result = g.parse("aaa")
```

The full list of parameters to `.parse` are the following:

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `subject` | `string` | | text to parse |
| `start` | `number` | `0` | (optional) position in the subject to start parsing |
| `arg` | | `null` | (optional) parameter for capture and match-time action callbacks |
| `initialRule` | `string` | `null` | (optional) initial rule |

The `.parse` method returns a result map with the following fields:

| Field | Type | Description |
| --- | --- | --- |
| `result.length` | `number` or `null` | length of the parsed portion of a subject |
| `result.match` | `Match` or `null` | tree of matched fragments |
| `result.errors` | `list` of `Error`s | list of encountered errors |
| `result.captures.list` | `list` | list of values captured by `{}` and `{name}` |
| `result.captures.map` | `map` | map of values captured by `{key:}` |
| `result.capture` | | if there's exactly one value in the `result.captures.list`, returns that value (otherwise `null`) |

There's also a `._str` method to inspect the result object:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+"
result = g.parse("aaa")

print result._str  // ParseResult( ... )
```

To check for success or failure, compare `result.length` with `null`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+"

result = g.parse("aaa")
print result.length  // 3  (successful parsing)

result = g.parse("bbb")
print result.length == null  // 1  (parsing failed)
```

If the subject matches, the `result.match` field will contain the tree of matched fragments (which also has `._str`):

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+"
result = g.parse("aaa")

print result.match._str  // Match( ... ) ...
```

Each `Match` node has the following fields:

| Field | Type | Description |
| --- | --- | --- |
| `match.start` | `number` | starting position in the subject |
| `match.length` | `number` | length of a match |
| `match.fragment` | `string` | matched text (`subject[start : start + length]`) |
| `match.pattern` | `Pattern` | pattern object that produced the match |
| `match.children` | `list` of `Match`es | submatches |

Match is only returned for inspection/debugging. To extract useful info from parsed texts, use **captures**:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+{} "
result = g.parse("aaa")
print result.captures.list  // ["aaa"]
```

Here we used an _anonymous capture_ suffix (`{}`, empty braces) after `'a'+`. Changing it to `'a'{}+` will capture each individual `'a'`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a' {} + "
result = g.parse("aaa")
print result.captures.list  // ["a", "a", "a"]
```

The field `result.captures.list` is always a list. If you know that only one value should be captured, use `result.capture` (no -s):

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+{}"
result = g.parse("aaa")
print result.capture  // "aaa"
```

Another form of capture is a _key capture_ suffix (`{key:}`) which puts captured values into `result.captures.map`:

```
import "peg"
g = new peg.Grammar
g.init "A <- [0-9]+{int:} '.' [0-9]+{fract:}"
result = g.parse("3.14")
print result.captures.map.int  // 3
print result.captures.map.fract  // 14
```

And at last, a _function capture_ suffix (`{name}`). It invokes a callback `name` registered with `grammar.capture(NAME, CALLBACK)`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a' {} + {slashes}"

g.capture "slashes", function(_,subs,_,_)
	return subs.list.join("/")
end function

result = g.parse("aaa")
print result.capture  // "a/a/a"
```

In the example above we only use the second parameter to the callback (`subs`). Similar to `ParseResult.captures` it has fields `.list` and `.map` that contain values produced by subpatterns. The full callback's signature is as follows:

| Parameter | Type | Description |
| --- | --- | --- |
| `match` | `Match` | matched portion of the subject |
| `subcaptures` | `{"list":..., "map":...}` | values captured by the subpatterns |
| `arg` | | optional third parameter to `.parse` |
| `ctx` | `ParseContext` | collection of data associated with current call to `.parse` |

The return value of the callback becomes the sole capture inside `captures.list` (all other subcaptures from `subs.list` and `subs.map` get dropped). If it's desired to keep the subcaptures, then instead of returning a capture, modify `subs` in place **AND** return the very `subs` object:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a' {} + {slashes}"

g.capture "slashes", function(_,subs,_,_)
	subs.list.push subs.list.join("/")
	return subs
end function

result = g.parse("aaa")
print result.captures.list  // ["a", "a", "a", "a/a/a"]
```

Another special case is when the callback returns an instance of the `peg.Error` class which will immediately stop the parsing and populate `result.errors` with the error.

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'+{crash}"

g.capture "crash", function(match,_,_,_)
	error = new peg.Error
	error.init "message - " + match.fragment
	return error
end function

result = g.parse("aaa")
print result.length == null  // 1  (failure)
print result.errors[0]._str  // SemanticError(message - aaa)
```

Note, captures are never produced inside predicates `&` and `!`.

While _capture_ callbacks are executed only after the whole grammar matched, the **match-time actions** (`<name>`) are invoked immediately when the corresponding pattern matches. The callbacks are registered with `grammar.matchTime(NAME, CALLBACK)`.

```
import "peg"
g = new peg.Grammar
g.init "A <- ('a'  'b' <upper>  'c') {}"

g.matchTime "upper", function(match,_,_,_)
	match.fragment = match.fragment.upper
	return match
end function

result = g.parse("abc")
print result.capture  // "aBc"
```

In the example above we modify the match object converting it to upper case. The full callback's signature is this:

| Parameter | Type | Description |
| --- | --- | --- |
| `match` | `Match` or `null` | matched fragment (or `null` if the pattern failed) |
| `subcaptures` | `function` that returns `{"list":..., "map":...}` object | captures from subpatterns (only evaluated if gets invoked) |
| `arg` | | optional argument to `.parse` |
| `ctx` | `ParseContext` | collection of data associated with current call to `.parse` |

Unlike in function captures, the parameter `match` may be `null`, so check before manipulating.

The return value determines whether the _match_ succeeds or fails: returning `null` means failure and returning a `Match` objects means success (it doesn't have to be the same match object as in the `match` parameter). Even if `null` is returned and thus the match fails, the parsing itself doesn't stop because failure of a pattern doesn't yet mean failure of the whole grammar.

Still, if it's desired to signal an error, it can be pushed into `ctx.syntaxErrors` or passed to `ctx.addSyntaxError(NAME, MESSAGE)`:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'  'b' <whine>  'c'"

g.matchTime "whine", function(_,_,_,ctx)
	ctx.addSyntaxError "whine", "just complaining"
	return null
end function

result = g.parse("abc")
print result.errors[0]._str  // SyntaxError(just complaining; ... )
```

And the following black magic can be used to set capture values inside a match-time action:

```
import "peg"
g = new peg.Grammar
g.init "A <- 'a'  'b' <brackets>  'c'"

g.matchTime "brackets", function(match,_,_,_)
	match.capture = function(_,_,_,_)
		return "[" + match.fragment + "]"
	end function
	return match
end function

result = g.parse("abc")
print result.capture  // "[b]"
```

A form with an exclamation mark (`<name!>`) is a shortcut for "report syntax error if the pattern fails". You don't have to define a callback.

It's not necessary to use a PEG string to create a grammar. It's possible to build the grammar from library level classes:

```
import "peg"
g = new peg.Grammar
g.init
g.addRule "A",
          peg.makeRuleRef("B").withCaptureTag
g.addRule "B",
          peg.makeLiteral("foo")
g.setDefaultRule "A"

result = g.parse("foo")
print result.capture  // "foo"
```

In the example above, the call to `grammar.init` even without args is still mandatory.

The full list of pattern classes:

| "Classic" new / init | Factory | Equivalent in PEG |
| --- | --- | --- |
| <pre>p = new peg.Literal<br>p.init "string"</pre> | <pre>p = peg.makeLiteral("string")</pre> | `'string'` |
| <pre>p = new peg.CharSet<br>p.init "!@#"</pre> | <pre>p = peg.makeCharSet("!@#")</pre> | `[!@#]` |
| <pre>p = new peg.CharRange<br>p.init "0", "9"</pre> | <pre>p = peg.makeCharRange("0", "9")</pre> | `[0-9]` |
| <pre>p = new peg.AnyChar<br>p.init</pre> | <pre>p = peg.makeAnyChar</pre> | `.` |
| <pre>p = new peg.RuleRef<br>p.init "Foo"</pre> | <pre>p = peg.makeRuleRef("Foo")</pre> | `Foo` |
| <pre>p = new peg.Optional<br>p.init q</pre> | <pre>p = peg.makeOptional(q)</pre> | `q ?` |
| <pre>p = new peg.ZeroOrMore<br>p.init q</pre> | <pre>p = peg.makeZeroOrMore(q)</pre> | `q *` |
| <pre>p = new peg.OneOrMore<br>p.init q</pre> | <pre>p = peg.makeOneOrMore(q)</pre> | `q +` |
| <pre>p = new peg.And<br>p.init q</pre> | <pre>p = peg.makeAnd(q)</pre> | `& q` |
| <pre>p = new peg.Not<br>p.init q</pre> | <pre>p = peg.makeNot(q)</pre> | `! q` |
| <pre>p = new peg.Concat<br>p.init [q, r, ...]</pre> | <pre>p = peg.makeConcat([q, r, ...])</pre> | `q r ...` |
| <pre>p = new peg.Choice<br>p.init [q, r, ...]</pre> | <pre>p = peg.makeChoice([q, r, ...])</pre> | `q / r / ...` |
| <pre>p = new peg.Grammar<br>p.init "A <- q B <- r"</pre> | <pre>p = peg.makeGrammar("A <- q B <- r")</pre> | `A <- q B <- r` |

The `Grammar` itself is also a pattern and so one grammar can be embedded inside another grammar.

The capture and match-time markers don't have pattern classes of their own. Instead, a property ("tag") is assigned to a subpattern `p`:

| Method | PEG |
| --- | --- |
| <pre>p.withCaptureTag</pre> | `p {}` |
| <pre>p.withCaptureTag "key:"</pre> | `p {key:}` |
| <pre>p.withCaptureTag "name"</pre> | `p {name}` |
| <pre>p.withMatchTimeTag "name"</pre> | `p <name>` |

To create a grammar where some rules only become known at the time of invokation of the `.parse` method, use **dynamic inclusions** (`Rule <- $`). To make it work, the `arg` parameter to `.parse` should be a map with a pair `RULENAME -> PATTERN`.

```
import "peg"
g = new peg.Grammar
g.init "A: B {}  B <- $"
result = g.parse("foo", 0, {"B": peg.patternOrLiteral("foo")})
print result.capture  // "foo"
```


## Examples

(Most of these are ported from the [LPeg manual](https://www.inf.puc-rio.br/~roberto/lpeg/).)


### Strings of a's and b's that have the same number of a's and b's

In this example we don't use capture syntax, so `result.captures` is empty.

```
import "peg"

equalAB = new peg.Grammar
equalAB.init    " S :  'a' B / 'b' A / '' " +
                " A <- 'a' S / 'b' A A " +
                " B <- 'b' S / 'a' B B "

result = equalAB.parse("abbabbbbbb")
print result.length         // 4
print result.match.fragment // "abba"
print result.errors         // []
print result.captures.list  // []
print result.captures.map   // {}
```

We know that the parse was successful because `result.length` is not `null`.


### Adding a list of numbers

Here we use a simple (anonymous) capture for each individual number and then we add the whole list with `{add}`.

```
import "peg"

addNumbers = new peg.Grammar
addNumbers.init "  number      <-  [0-9]+ {}  " +
                "  addNumbers  :   ( number  ( ','  number ) * ) {add}  "

addNumbers.capture "add", function(match, subcaptures, arg, ctx)
	add = 0
	for s in subcaptures.list
		add += s.val
	end for
	return add
end function

print addNumbers.parse("10,30,43").capture  // 83
```


### String upper

This example illustrates the use of `{key:}` captures:

```
import "peg"

stringUpper = new peg.Grammar
stringUpper.init    "  name         <-  [a-z]+ {str:}  " +
                    "  stringUpper  :   ( name  '^' {up:} ? ) {upper}  "

stringUpper.capture "upper", function(match, subcaptures, arg, ctx)
	s = subcaptures.map.str
	if subcaptures.map.hasIndex("up") then s = s.upper
	return s
end function

print stringUpper.parse("foo").capture  // "foo"
print stringUpper.parse("foo^").capture  // "FOO"
```

Here the construction `'^' {up:} ?` only produces a capture if optional `^` symbol is matched, so the `{upper}` callback checks `subcaptures.map.hasIndex("up")` to make its desision.

Note that a different sequence `'^' ? {up:}` would instead capture an empty string if the `^` symbol was missing.


### Name-value lists

```
import "peg"

nameValueList = new peg.Grammar
nameValueList.init  "  space  <-  [ \t\n\r] *  " +
                    "  name   <-  [a-zA-Z] + {}  space  " +
                    "  sep    <-  [,;]  space  " +
                    "  pair   <-  ( name  '='  space  name  sep ? )  " +
                    "  list   :   pair * {list}  "

nameValueList.capture "list", function(match, subcaptures, arg, ctx)
	vals = {}
	for i in range(0, subcaptures.list.len - 1, 2)
		vals[subcaptures.list[i]] = subcaptures.list[i + 1]
	end for
	return vals
end function

vals = nameValueList.parse("a=b, c = hi; next = pi").capture
print vals.a    // "b"
print vals.c    // "hi"
print vals.next  // "pi"
```


### Splitting a string

In this example we use a dynamic inclusion `sep <- $` the pattern of which becomes known only in the call to the `split` function.

```
import "peg"

splitString = new peg.Grammar
splitString.init    " sep     <-  $ " +
                    " elem    <-  ( ! sep  . ) * {} " +
                    " result  :   elem  ( sep  elem ) * "

split = function(s, sep)
	sep = peg.patternOrLiteral(sep)
	return splitString.parse(s, 0, {"sep": sep}).captures.list
end function

print split("a b c", " ")  // ["a", "b", "c"]
print split("a//b//c", "//")  // ["a", "b", "c"]

spaces = peg.makeOneOrMore(
	peg.makeCharSet(" " + char(9)))

print split("a            b     c", spaces)  // ["a", "b", "c"]
```

We used `patternOrLiteral` to convert the `sep` string to a `Literal` pattern in case it wasn't already a pattern. This allows us to use complex patterns as string separators.


### Searching for a pattern

Parsing with `Grammar.parse` is always rooted -- it tries to match only at the beginning of the subject (or beginning from index `start` if it's given as a second parameter to `parse`).

This example shows how to use recursive rules to search for a pattern anywhere in the subject.

```
import "peg"

searchForPatt = new peg.Grammar
searchForPatt.init  "  pattern  <-  $  " +
                    "  search   :   pattern {patt}  /  .  search  "

searchForPatt.capture "patt", function(match, subcaptures, arg, ctx)
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
balanced.init "  bparen  :  '('  ( ! [()]  .  /  bparen ) *  ')'  "

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
                    "  gsub     :   ( ( pattern {sub}  /  . {} ) * )  "

gsubGrammar.capture "sub", function(match, subcaptures, arg, ctx)
	return arg.repl
end function

gsub = function(s, patt, repl)
	arg = {}
	arg.pattern = peg.patternOrLiteral(patt)
	arg.repl = repl
	return gsubGrammar.parse(s, 0, arg).captures.list.join("")
end function

print gsub("hello foo! goodbye foo!", "foo", "world")  // "hello world! goodbye world!"
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
                "  record   :   field  ( ','  field ) *  ( newline  /  !. )  "

csvGrammar.capture "qstr", function(match, subcaptures, arg, ctx)
	return match.fragment.replace("""" + """", """")
end function

print csvGrammar.parse("foo,""bar"",baz").captures.list  // ["foo", "bar", "baz"]
```


### Lua's long strings

This example demonstrates the use of the _match-time actions_.

```
import "peg"

longStr = new peg.Grammar
longStr.init    "  longstr  :   open  ( ! close  . ) * {}  close  " +
                "  open     <-  '['  '=' * <startEq>  '['         " +
                "  close    <-  ']'  '=' * <endEq>  ']'           "

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

First, we used the match-time callback `<startEq>` to record the sequence of initial `=` symbols into `arg` map.

Then we used `<endEq>` to compare the number of closing `=`s with what we've previously recorded. If they don't match we return `null` forcing the `parse` method to believe that the match failed and thus it needs to keep searching for the next closing `]=*]`.


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
                "  Exp       :   Space ( Term  ( TermOp  Term ) * ) {eval}   " +
                "  Term      <-  ( Factor  ( FactorOp  Factor ) * ) {eval}   " +
                "  Factor    <-  Number  /  Open  Exp  Close                 "

arithExp.capture "eval", function(match, subcaptures, arg, ctx)
	_val = function(x)
		if x isa string then return x.val else return x
	end function
	acc = _val(subcaptures.list[0])
	for i in range(1, subcaptures.list.len - 1, 2)
		op = subcaptures.list[i]
		x = _val(subcaptures.list[i + 1])
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

