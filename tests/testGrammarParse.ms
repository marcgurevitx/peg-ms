import "qa"
import "peg"

_NL = peg._NL


testGrammarParseNoCaptures = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo")
	g.setDefaultRule "Foo"
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
end function


testGrammarParseSyntaxError = function
	_p = peg.makeLiteral("foo")
	_p.matchTimeTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.errors[0].tag, "xxx"
	qa.assertEqual res.captures, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.errors[0].tag, "xxx"
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) :xxx:)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) :xxx:)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
end function


testGrammarParseCapture = function
	_p = peg.makeLiteral("foo")
	_p.captureTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	g.addCaptureAction "xxx", function(match, captures, arg)
		return "+ " + match.fragment + " +"
	end function
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, ["+ foo +"]
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, ["+ foo +"]
end function


testGrammarParseSemanticError = function
	_p = peg.makeLiteral("foo")
	_p.captureTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	peg = outer.peg
	_f = function(match, captures, arg)
		return peg.makeError("/ " + match.fragment + " /")
	end function
	g.addCaptureAction "xxx", @_f
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.errors[0].message, "/ foo /"
	qa.assertEqual res.captures, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.errors[0].message, "/ foo /"
	qa.assertEqual res.captures, []
end function

