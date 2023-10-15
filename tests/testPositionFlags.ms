import "qa"
import "peg"

_NL = peg._NL


testPositionFlagsWithoutMoveBack = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   (+foo)   'y' <xxx>   (-foo)   'z' <xxx>"
	
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
	g.init "A <- 'x' <xxx>   ( 'y' <xxx>  (+foo)  /  'z' <xxx> )   'w' <xxx>"
	
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
	qa.assertEqual arg.foo, [0, 0]
	
	text = "xyw"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 3
	qa.assertEqual arg.foo, [0, 0, 1]
	
	text = "xz"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 0]
	
	text = "xzw"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 3
	qa.assertEqual arg.foo, [0, 0, 0]
end function


testPositionFlagsNested = function
	g = new peg.Grammar
	g.init "A <- 'x' <xxx>   (+foo)   'y' <xxx>   (+foo)   'z' <xxx>   (-foo)   'w' <xxx>   (-foo)   'v' <xxx>"
	
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
	qa.assertEqual arg.foo, [0, 1, 2]
	
	text = "xyzw"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, null
	qa.assertEqual arg.foo, [0, 1, 2, 1]
	
	text = "xyzwv"
	arg = {}
	arg.foo = []
	res = g.parse(text, 0, arg)
	qa.assertEqual res.length, 5
	qa.assertEqual arg.foo, [0, 1, 2, 1, 0]
end function

