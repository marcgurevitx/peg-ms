import "qa"
import "peg"

_NL = peg._NL


testPositionFlagsWithoutMoveBack = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   (+foo)   'y' <xxx>   (/foo)   'z' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = ""
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, []
	
	text = "x"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0]
	
	text = "xy"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 1]
	
	text = "xyz"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 3
	qa.assertEqual arg.foo, [0, 1, 0]
end function


testPositionFlagsWithMoveBack = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   ( 'y' <xxx>  (+foo)   'z' <xxx>   /   'y' <xxx>   'w' <xxx> ) "
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = ""
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, []
	
	text = "x"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0]
	
	text = "xy"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 0, 0]
	
	text = "xyz"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 3
	qa.assertEqual arg.foo, [0, 0, 1]
	
	text = "xyw"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 3
	qa.assertEqual arg.foo, [0, 0, 0, 0]
end function


testPositionFlagsNested = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   (+foo)   'y' <xxx>   (+foo)   'z' <xxx>   (/foo)   'w' <xxx>   (/foo)   'v' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = ""
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, []
	
	text = "x"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0]
	
	text = "xy"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 1]
	
	text = "xyz"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 1, 1]
	
	text = "xyzw"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 1, 1, 1]
	
	text = "xyzwv"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 5
	qa.assertEqual arg.foo, [0, 1, 1, 1, 0]
end function


testPositionFlagsNested2 = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   (+foo)   'y' <xxx>   (+foo)   'z' <xxx>   (-foo)   'w' <xxx>   (/foo)   'v' <xxx>   (/foo)   'u' <xxx>   (/foo)   't' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = "xyzwvut"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 7
	qa.assertEqual arg.foo, [0, 1, 1, 0, 1, 1, 0]
end function


testPositionFlagsUnbalanced = function
	g = new peg.Grammar
	g.init "_:  'a'  (/foo)  'b' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = "ab"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 2
	qa.assertEqual arg.foo, [0]
end function


testPositionFlagsAnnihilation = function
	g = new peg.Grammar
	g.init "_:  'a'  (+foo)  (/foo)  'b' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then arg.foo.push ctx.getFlag(match.start, "foo")
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = "ab"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 2
	qa.assertEqual arg.foo, [0]
end function


testPositionFlagsClash = function
	g = new peg.Grammar
	g.init "_:  'a'  (+foo)  (+bar)  'b' <xxx>"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match != null then
			arg.foo.push ctx.getFlag(match.start, "foo")
			arg.bar.push ctx.getFlag(match.start, "bar")
		end if
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	text = "ab"
	arg = {}
	arg.foo = []
	arg.bar = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 2
	qa.assertEqual arg.foo, [1]
	qa.assertEqual arg.bar, [1]
end function


testPositionFlagsGeneratePeg = function
	g = new peg.Grammar
	g.init "  _ :   (+foo)  (-bar)  (/baz)  "
	qa.assertEqual g.generatePegString, "  _  :   (+foo)  (-bar)  (/baz)  "
end function


testPositionFlagsToString = function
	g = new peg.Grammar
	g.init "  _ :   (+foo)  (-bar)  (/baz)  "
	qa.assertEqual g.getRulePattern("_")._str,  "Concat()"  + _NL +
	                                            " PositionFlag(+foo)"   + _NL +
	                                            " PositionFlag(-bar)"   + _NL +
	                                            " PositionFlag(/baz)"
end function

