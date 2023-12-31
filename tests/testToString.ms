import "qa"
import "peg"

_NL = peg._NL


testTree = function
	A = new peg.Tree
	A._name = "A"
	A.init = function(x)
		super.init
		self.x = x
	end function
	
	qa.assertEqual A._str, "A class"
	
	a = new A
	a.init "foo"
	
	qa.assertEqual a._str, "A(x: foo)"
	
	a2 = new A
	a2.init "bar"
	a.addChild a2
	
	qa.assertEqual a._str,  "A(x: foo)"   + _NL +
	                        " A(x: bar)"
	
	a3 = new A
	a3.init "baz"
	a.addChild a3
	
	qa.assertEqual a._str,  "A(x: foo)"   + _NL +
	                        " A(x: bar)"  + _NL +
	                        " A(x: baz)"
	
	a4 = new A
	a4.init "bamf"
	a3.addChild a4
	
	qa.assertEqual a._str,  "A(x: foo)"     + _NL +
	                        " A(x: bar)"    + _NL +
	                        " A(x: baz)"    + _NL +
	                        "  A(x: bamf)"
end function


testMatchToString = function
	qa.assertEqual peg.Match._str, "peg.Match class"
	
	m = new peg.Match
	m.init 0, 5, "hello"
	
	qa.assertEqual m._str,  "Match(0, 5, hello, )"
	
	m2 = new peg.Match
	m2.init 0, 4, "hell"
	m.addChild m2
	
	qa.assertEqual m._str,  "Match(0, 5, hello, )" + _NL +
	                        " Match(0, 4, hell, )"
	
	m3 = new peg.Match
	m3.init 4, 1, "o"
	m.addChild m3
	
	qa.assertEqual m._str,  "Match(0, 5, hello, )" + _NL +
	                        " Match(0, 4, hell, )" + _NL +
	                        " Match(4, 1, o, )"
end function


testPatternToString = function
	qa.assertEqual peg.Pattern._str, "peg.Pattern class"
end function


testAnyCharToString = function
	qa.assertEqual peg.AnyChar._str, "peg.AnyChar class"
	
	p = peg.makeAnyChar
	qa.assertEqual p._str, "AnyChar()"
end function


testCharSetToString = function
	qa.assertEqual peg.CharSet._str, "peg.CharSet class"
	
	p = peg.makeCharSet("abc")
	qa.assertEqual p._str, "CharSet(abc)"
end function


testCharRangeToString = function
	qa.assertEqual peg.CharRange._str, "peg.CharRange class"
	
	p = peg.makeCharRange("a", "c")
	qa.assertEqual p._str, "CharRange(a, c)"
end function


testLiteralToString = function
	qa.assertEqual peg.Literal._str, "peg.Literal class"
	
	p = peg.makeLiteral("foo")
	qa.assertEqual p._str, "Literal(foo)"
end function


testAndToString = function
	qa.assertEqual peg.And._str, "peg.And class"
	
	p = peg.makeAnd(
		peg.makeLiteral("foo"))
	
	qa.assertEqual p._str,  "And()"          + _NL +
	                        " Literal(foo)"
end function


testNotToString = function
	qa.assertEqual peg.Not._str, "peg.Not class"
	
	p = peg.makeNot(
		peg.makeLiteral("foo"))
	
	qa.assertEqual p._str,  "Not()"          + _NL +
	                        " Literal(foo)"
end function


testChoiceToString = function
	qa.assertEqual peg.Choice._str, "peg.Choice class"
	
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	
	qa.assertEqual p._str,  "Choice()"       + _NL +
	                        " Literal(foo)"  + _NL +
	                        " Literal(bar)"  + _NL +
	                        " Literal(baz)"
end function


testConcatToString = function
	qa.assertEqual peg.Concat._str, "peg.Concat class"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	
	qa.assertEqual p._str,  "Concat()"       + _NL +
	                        " Literal(foo)"  + _NL +
	                        " Literal(bar)"  + _NL +
	                        " Literal(baz)"
end function


testOptionalToString = function
	qa.assertEqual peg.Optional._str, "peg.Optional class"
	
	p = peg.makeOptional(
		peg.makeLiteral("foo"))
	
	qa.assertEqual p._str,  "Optional()"     + _NL +
	                        " Literal(foo)"
end function


testZeroOrMoreToString = function
	qa.assertEqual peg.ZeroOrMore._str, "peg.ZeroOrMore class"
	
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo"))
	
	qa.assertEqual p._str,  "ZeroOrMore()"   + _NL +
	                        " Literal(foo)"
end function


testOneOrMoreToString = function
	qa.assertEqual peg.OneOrMore._str, "peg.OneOrMore class"
	
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo"))
	
	qa.assertEqual p._str,  "OneOrMore()"    + _NL +
	                        " Literal(foo)"
end function


testGrammarToString = function
	qa.assertEqual peg.Grammar._str, "peg.Grammar class"
	
	g = peg.makeGrammar
	
	qa.assertEqual g._str,  "Grammar()"
	
	g.addRule "Foo", peg.makeLiteral("foo")
	
	qa.assertEqual g._str,  "Grammar(Foo)"    + _NL +
	                        " Foo->"          + _NL +
	                        "  Literal(foo)"
	
	g.setDefaultRule "Foo"
	
	qa.assertEqual g._str,  "Grammar(Foo)"    + _NL +
	                        " Foo->"          + _NL +
	                        "  Literal(foo)"
	
	g.addRule "Bar", null
	
	qa.assertEqual g._str,  "Grammar(Foo)"    + _NL +
	                        " Foo->"          + _NL +
	                        "  Literal(foo)"  + _NL +
	                        " Bar->"          + _NL +
	                        "  $"
end function


testRuleRefToString = function
	qa.assertEqual peg.RuleRef._str, "peg.RuleRef class"
	
	p = peg.makeRuleRef("Foo")
	qa.assertEqual p._str,  "RuleRef(Foo)"
end function


testParseResultToString = function
	g = peg.makeGrammar("xxx <- ('foo' {} 'bar' {}) {}")
	res = g.parse("foobar")
	qa.assertEqual res._str, "ParseResult(length: 6, match: Match(0, 6, foobar, Grammar(xxx))..., errors: [], captures.list: [""foo"", ""bar"", ""foobar""], captures.map: {})"
end function


testParseResultToStringWithErrors = function
	g = peg.makeGrammar("xxx <- 'a' <a!>  /  'b' <b!>  /  'c' <c!>")
	res = g.parse("c")
	qa.assertEqual res._str, "ParseResult(length: 1, match: Match(0, 1, c, Grammar(xxx))..., errors: [peg.SyntaxError(a), peg.SyntaxError(b)], captures.list: [], captures.map: {})"
end function


testErrorToString = function
	err = new peg.Error
	err.init "foo"
	qa.assertEqual err._str, "peg.Error(foo)"
end function

