import "qa"
import "peg"

_NL = peg._NL


testExampleParseList = function
	g = new peg.Grammar
	g.init  "list   <- '[' space number (',' space number)* space ']' " +
	        "number <- ([+-]? [0-9]+) {tonumber} " +
	        "space <- ' '* ",
	        "list"
	
	g.addCaptureAction "tonumber", function(match, subcaptures, arg)
		return match.fragment.val
	end function
	
	qa.assertEqual g.parse("[]").captures, []
	qa.assertEqual g.parse("[11,22,33]").captures, [11, 22, 33]
	qa.assertEqual g.parse("[ 44, 55 ]").captures, [44, 55]
end function


testLpegExampleAB = function
	g = new peg.Grammar
	g.init  " S <- 'a' B / 'b' A / '' " +
	        " A <- 'a' S / 'b' A A " +
	        " B <- 'b' S / 'a' B B ",
	        "S"
	
	qa.assertEqual g.parse("abba").length, 4
	qa.assertEqual g.parse("abbbbbbb").length, 2
	qa.assertEqual g.parse("bbbbbbb").length, 0
end function


testLpegExampleAddNumerals = function
	g = peg.makeGrammar("  number  <-  [0-9]+ {tonumber}                    " +
	                    "  sum     <-  ( number  ( ','  number ) * ) {sum}  ")
	g.setDefaultRule "sum"
	
	g.addCaptureAction "tonumber", function(match, subcaptures, arg)
		return match.fragment.val
	end function
	
	g.addCaptureAction "sum", function(match, subcaptures, arg)
		return sum(subcaptures)
	end function
	
	qa.assertEqual g.parse("10,30,43").capture, 83
end function


testLpegExampleStringUpper = function
	g = peg.makeGrammar("  name  <-  [a-z]+ {}               " +
	                    "  up    <-  ( name  '^'? {} ) {up}  ")
	g.setDefaultRule "up"
	
	g.addCaptureAction "up", function(match, subcaptures, arg)
		if subcaptures[-1] == "^" then return subcaptures[0].upper
		return subcaptures[0]
	end function
	
	qa.assertEqual g.parse("hello").capture, "hello"
	qa.assertEqual g.parse("hello^").capture, "HELLO"
end function


testLpegExampleNameValueList = function
	g = peg.makeGrammar("  space  <-  [ " + char(9) + char(10) + char(13) + "] *  " +
	                    "  name   <-  [a-zA-Z] + {}  space                        " +
	                    "  sep    <-  [,;]  space                                 " +
	                    "  pair   <-  ( name  '='  space  name  sep ? ) {pair}    " +
	                    "  list   <-  pair * {list}                               ")
	g.setDefaultRule "list"
	
	g.addCaptureAction "pair", function(match, subcaptures, arg)
		return subcaptures[:]
	end function
	
	g.addCaptureAction "list", function(match, subcaptures, arg)
		res = {}
		for cap in subcaptures
			res[cap[0]] = cap[1]
		end for
		return res
	end function
	
	res = g.parse("a=b, c = hi; next = pi")
	qa.assertEqual res.capture.a, "b"
	qa.assertEqual res.capture.c, "hi"
	qa.assertEqual res.capture.next, "pi"
end function


testLpegExampleSplitString = function
	g = peg.makeGrammar(" sep     <-  $ " +
	                    " elem    <-  ( ! sep  . ) * {} " +
	                    " result  <-  elem  ( sep  elem ) * ")
	g.setDefaultRule "result"
	
	res = g.parse("a b c", null, {"sep": peg.makeLiteral(" ")})
	qa.assertEqual res.captures, ["a", "b", "c"]
	
	res = g.parse("a--b--c", null, {"sep": peg.makeLiteral("--")})
	qa.assertEqual res.captures, ["a", "b", "c"]
end function


testLpegExampleSearchPattern = function
	g = peg.makeGrammar("  pattern  <-  $                                " +
	                    "  search   <-  pattern {pattern}  /  .  search  ")
	g.setDefaultRule "search"
	
	g.addCaptureAction "pattern", function(match, subcaptures, arg)
		return [match.start, match.start + match.length]
	end function
	
	res = g.parse("", null, {"pattern": peg.makeLiteral("foo")})
	qa.assertEqual res.capture, null
	
	res = g.parse("foo", null, {"pattern": peg.makeLiteral("foo")})
	qa.assertEqual res.capture, [0, 3]
	
	res = g.parse("  foo", null, {"pattern": peg.makeLiteral("foo")})
	qa.assertEqual res.capture, [2, 5]
end function


testLpegExampleBalancedParentheses = function
	g = peg.makeGrammar("  bparen  <-  '('  ( ! [()]  .  /  bparen ) *  ')'  ")
	
	res = g.parse("")
	qa.assertEqual res.length, null
	
	res = g.parse("()")
	qa.assertEqual res.length, 2
	
	res = g.parse("(  ((()  ) ))")
	qa.assertEqual res.length, 13
	
	res = g.parse("(()")
	qa.assertEqual res.length, null
end function


testLpegExampleGlobalSubstitution = function
	g = peg.makeGrammar("  pattern  <-  $                                        " +
	                    "  gsub     <-  ( ( pattern {sub}  /  . {} ) * ) {gsub}  ")
	
	g.addCaptureAction "sub", function(match, subcaptures, arg)
		return arg.repl
	end function
	
	g.addCaptureAction "gsub", function(match, subcaptures, arg)
		return subcaptures.join("")
	end function
	
	arg = {}
	arg.pattern = peg.makeLiteral("foo")
	arg.repl = "bar"
	
	res = g.parse("", null, arg)
	qa.assertEqual res.capture, ""
	
	res = g.parse("foo", null, arg)
	qa.assertEqual res.capture, "bar"
	
	res = g.parse("hello, foo! goodbye, foo!", null, arg)
	qa.assertEqual res.capture, "hello, bar! goodbye, bar!"
end function


testLpegExampleCommaSeparatedValues = function
	g = peg.makeGrammar("  quot     <-  [""]                                               " +
	                    "  newline  <-  [" + char(10) + char(13) + "]                      " +
	                    "  qstr     <-  quot  ( ! quot  .  /  quot  quot ) * {qstr}  quot  " +
	                    "  str      <-  ( ! ( ','  /  newline  /  quot )  . ) * {}         " +
	                    "  field    <-  qstr  /  str                                       " +
	                    "  record   <-  field  ( ','  field ) *  ( newline  /  !. )        ")
	g.setDefaultRule "record"
	
	g.addCaptureAction "qstr", function(match, subcaptures, arg)
		return match.fragment.replace("""" + """", """")
	end function
	
	res = g.parse("")
	qa.assertEqual res.captures, [""]
	
	res = g.parse("foo,bar,baz")
	qa.assertEqual res.captures, ["foo", "bar", "baz"]
	
	res = g.parse("foo,""bar"",baz")
	qa.assertEqual res.captures, ["foo", "bar", "baz"]
	
	res = g.parse("foo,bar,baz" + char(13) + "alice,bob,charlie")
	qa.assertEqual res.captures, ["foo", "bar", "baz"]
end function


testLpegExampleLuaLongStrings = function
	g = peg.makeGrammar("  longstr  <-  open  ( ! close  . ) * {}  close  " +
	                    "  open     <-  '['  '=' * :startEq:  '['         " +
	                    "  close    <-  ']'  '=' * :endEq:  ']'           ")
	g.setDefaultRule "longstr"
	
	g.addMatchTimeAction "startEq", function(match, subcaptures, arg, ctx)
		if match != null then
			arg.startEq = match.fragment
		end if
		return match
	end function
	
	g.addMatchTimeAction "endEq", function(match, subcaptures, arg, ctx)
		if match != null then
			if match.fragment.len == arg.startEq.len then return match
			match = null
		end if
		return match
	end function
	
	res = g.parse("", 0, {})
	qa.assertEqual res.captures, []
	
	res = g.parse("[=[]]", 0, {})
	qa.assertEqual res.captures, []
	
	res = g.parse("[[]]", 0, {})
	qa.assertEqual res.capture, ""
	
	res = g.parse("[==[]==]", 0, {})
	qa.assertEqual res.capture, ""
	
	res = g.parse("[==[foo]=]bar]==]", 0, {})
	qa.assertEqual res.capture, "foo]=]bar"
	
	res = g.parse("[==[foo]=====]bar]==]", 0, {})
	qa.assertEqual res.capture, "foo]=====]bar"
end function


testLpegExampleArithmeticExpressionsTree = function
	g = peg.makeGrammar("  Space     <-  [ " + char(9) + char(10) + char(13) + "] *  " +
	                    "  Number    <-  ( '-' ?  [0-9] + ) {}  Space                " +
	                    "  TermOp    <-  [+-] {}  Space                              " +
	                    "  FactorOp  <-  [*/] {}  Space                              " +
	                    "  Open      <-  '('  Space                                  " +
	                    "  Close     <-  ')'  Space                                  " +
	                    "  Exp       <-  Space ( Term  ( TermOp  Term ) * ) {eval}   " +
	                    "  Term      <-  ( Factor  ( FactorOp  Factor ) * ) {eval}   " +
	                    "  Factor    <-  Number  /  Open  Exp  Close                 ")
	g.setDefaultRule "Exp"
	
	g.addCaptureAction "eval", function(match, subcaptures, arg)
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
	
	res = g.parse("3 + 5*9 / (1+1) - 12")
	qa.assertEqual res.capture, 13.5
end function


testLpegExampleArithmeticExpressionsOnTheFly = function
	g = peg.makeGrammar("  Space     <-  [ " + char(9) + char(10) + char(13) + "] *  " +
	                    "  Number    <-  ( '-' ?  [0-9] + ) {}  Space                " +
	                    "  TermOp    <-  [+-] {}  Space                              " +
	                    "  FactorOp  <-  [*/] {}  Space                              " +
	                    "  Open      <-  '('  Space                                  " +
	                    "  Close     <-  ')'  Space                                  " +
	                    "  Exp       <-  Space ( Term  ( TermOp  Term ) * ) :eval:   " +
	                    "  Term      <-  ( Factor  ( FactorOp  Factor ) * ) :eval:   " +
	                    "  Factor    <-  Number  /  Open  Exp  Close                 ")
	g.setDefaultRule "Exp"
	
	g.addMatchTimeAction "eval", function(match, subcaptures, arg, ctx)
		if match == null then return null
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
		match.capture = function(_, _, _)
			return acc
		end function
		return match
	end function
	
	res = g.parse("3 + 5*9 / (1+1) - 12")
	qa.assertEqual res.capture, 13.5
end function

