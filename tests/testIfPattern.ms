import "qa"
import "peg"

_NL = peg._NL


testIfPattern = function
	g = new peg.Grammar
	g.init "_:  'a'  %if foo then%  'b'  %end if%  'c'  "
	
	arg = {}
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = false
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = true
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.match.fragment, "abc"
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.length, null
end function


testIfPatternWithElse = function
	g = new peg.Grammar
	g.init "_:  'a'  %if foo then%  'b'  %else%  'c'  %end if%  'd'  "
	
	arg = {}
	res = g.parse("abd", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("acd", 0, arg)
	qa.assertEqual res.match.fragment, "acd"
	
	arg = {}
	arg.foo = false
	res = g.parse("abd", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("acd", 0, arg)
	qa.assertEqual res.match.fragment, "acd"
	
	arg = {}
	arg.foo = true
	res = g.parse("abd", 0, arg)
	qa.assertEqual res.match.fragment, "abd"
	res = g.parse("acd", 0, arg)
	qa.assertEqual res.length, null
end function


testIfPatternNestedFlag = function
	g = new peg.Grammar
	g.init "_:  'a'  %if foo.bar then%  'b'  %end if%  'c'  "
	
	arg = {}
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = false
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = 42
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = {}
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = {}
	arg.foo.bar = false
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.length, null
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.match.fragment, "ac"
	
	arg = {}
	arg.foo = {}
	arg.foo.bar = true
	res = g.parse("abc", 0, arg)
	qa.assertEqual res.match.fragment, "abc"
	res = g.parse("ac", 0, arg)
	qa.assertEqual res.length, null
end function


testIfPatternRecognizesPositionFlags = function
	g = new peg.Grammar
	g.init "_:  'a'  %if xxx%  'b'  %end%  'c'  "
	res = g.parse("abc")
	qa.assertEqual res.length, null
	
	g = new peg.Grammar
	g.init "_:  (+xxx)  'a'  %if xxx%  'b'  %end%  'c'  "
	res = g.parse("abc")
	qa.assertEqual res.length, 3
	qa.assertEqual res.match.fragment, "abc"
end function

