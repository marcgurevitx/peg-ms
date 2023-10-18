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
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
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
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.errors[0].tag, "xxx"
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) <xxx>)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) <xxx>)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testGrammarParseCapture = function
	_p = peg.makeLiteral("foo")
	_p.captureTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	g.addCaptureAction "xxx", function(match, captures, arg, ctx)
		return "+ " + match.fragment + " +"
	end function
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["+ foo +"]
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["+ foo +"]
end function


testGrammarParseSemanticError = function
	_p = peg.makeLiteral("foo")
	_p.captureTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	peg = outer.peg
	_f = function(match, captures, arg, ctx)
		return peg.makeError("/ " + match.fragment + " /")
	end function
	g.addCaptureAction "xxx", @_f
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.errors[0].message, "/ foo /"
	qa.assertEqual res.captures.list, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match._str,  "Match(2, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(2, 3, foo, Literal(foo) {xxx}, +)"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.errors[0].message, "/ foo /"
	qa.assertEqual res.captures.list, []
end function


testGrammarParseInitialRule = function
	g = new peg.Grammar
	g.init "A: 'foo' {}  B <- 'bar' {}"
	
	res = g.parse("foo")
	qa.assertEqual res.capture, "foo"
	
	res = g.parse("bar")
	qa.assertEqual res.capture, null
	
	res = g.parse("bar", 0, null, "B")
	qa.assertEqual res.capture, "bar"
end function


testGrammarParseInitialRuleDoesNotPropagate = function
	g = new peg.Grammar
	g.init "A: 'foo' {}  B <- 'bar' {}"
	
	g2 = new peg.Grammar
	g2.init "A: 'hello' {}  B <- _B  _B <- $"
	
	res = g2.parse("hello")
	qa.assertEqual res.capture, "hello"
	
	res = g2.parse("foo", 0, {"_B": g}, "B")
	qa.assertEqual res.capture, "foo"
end function

