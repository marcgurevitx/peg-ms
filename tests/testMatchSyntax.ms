import "qa"
import "peg"

_NL = peg._NL


testAnyCharMatchSyntax = function
	p = peg.makeAnyChar
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("a", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(0, 1, a, AnyChar())"
	
	ctx = peg.makeParseContext("a", 2)
	m = p.matchSyntax(0, ctx)  // start after end of line
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("  a", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(2, 1, a, AnyChar())"
end function


testCharSetMatchSyntax = function
	p = peg.makeCharSet("abc")
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("b", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(0, 1, b, CharSet(abc))"
	
	ctx = peg.makeParseContext("  b", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(2, 1, b, CharSet(abc))"
end function


testCharRangeMatchSyntax = function
	p = peg.makeCharRange("a", "c")
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("b", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(0, 1, b, CharRange(a, c))"
	
	ctx = peg.makeParseContext("  b", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(2, 1, b, CharRange(a, c))"
end function


testLiteralMatchSyntax = function
	p = peg.makeLiteral("foo")
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str, "Match(2, 3, foo, Literal(foo))"
end function


testAndMatchSyntax = function
	p = peg.makeAnd(
		peg.makeLiteral("foo"))
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 0, , And())"             + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 0, , And())"             + _NL +
	                        " Match(2, 3, foo, Literal(foo))"
end function


testNotMatchSyntax = function
	p = peg.makeNot(
		peg.makeLiteral("foo"))
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("  foo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 0, , Not())"
	
	ctx = peg.makeParseContext("x", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 0, , Not())"
end function


testChoiceMatchSyntax = function
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("bar", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, bar, Choice())" + _NL +
	                        " Match(0, 3, bar, Literal(bar))"
	
	ctx = peg.makeParseContext("  bar", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 3, bar, Choice())" + _NL +
	                        " Match(2, 3, bar, Literal(bar))"
end function


testConcatMatchSyntax = function
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("x", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("bar", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foobarbaz", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 9, foobarbaz, Concat())" + _NL +
	                        " Match(0, 3, foo, Literal(foo))" + _NL +
	                        " Match(3, 3, bar, Literal(bar))" + _NL +
	                        " Match(6, 3, baz, Literal(baz))"
	
	ctx = peg.makeParseContext("  foobarbaz", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 9, foobarbaz, Concat())" + _NL +
	                        " Match(2, 3, foo, Literal(foo))" + _NL +
	                        " Match(5, 3, bar, Literal(bar))" + _NL +
	                        " Match(8, 3, baz, Literal(baz))"
end function


testOptionalMatchSyntax = function
	p = peg.makeOptional(
		peg.makeLiteral("foo"))
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 0, , Optional())"
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, Optional())"     + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 3, foo, Optional())"     + _NL +
	                        " Match(2, 3, foo, Literal(foo))"
end function


testZeroOrMoreMatchSyntax = function
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo"))
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 0, , ZeroOrMore())"
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, ZeroOrMore())"        + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("foofoo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 6, foofoo, ZeroOrMore())"     + _NL +
	                        " Match(0, 3, foo, Literal(foo))"       + _NL +
	                        " Match(3, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("foofoofoo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 9, foofoofoo, ZeroOrMore())"  + _NL +
	                        " Match(0, 3, foo, Literal(foo))"       + _NL +
	                        " Match(3, 3, foo, Literal(foo))"       + _NL +
	                        " Match(6, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foofoofoo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 9, foofoofoo, ZeroOrMore())"  + _NL +
	                        " Match(2, 3, foo, Literal(foo))"       + _NL +
	                        " Match(5, 3, foo, Literal(foo))"       + _NL +
	                        " Match(8, 3, foo, Literal(foo))"
end function


testOneOrMoreMatchSyntax = function
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo"))
	
	ctx = peg.makeParseContext("", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m,       null
	
	ctx = peg.makeParseContext("foo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, OneOrMore())"        + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("foofoo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 6, foofoo, OneOrMore())"     + _NL +
	                        " Match(0, 3, foo, Literal(foo))"      + _NL +
	                        " Match(3, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("foofoofoo", 0)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 9, foofoofoo, OneOrMore())"  + _NL +
	                        " Match(0, 3, foo, Literal(foo))"      + _NL +
	                        " Match(3, 3, foo, Literal(foo))"      + _NL +
	                        " Match(6, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foofoofoo", 2)
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 9, foofoofoo, OneOrMore())"  + _NL +
	                        " Match(2, 3, foo, Literal(foo))"      + _NL +
	                        " Match(5, 3, foo, Literal(foo))"      + _NL +
	                        " Match(8, 3, foo, Literal(foo))"
end function


testGrammarMatchSyntax = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo")
	g.setDefaultRule "Foo"
	
	ctx = peg.makeParseContext("", 0)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m,       null
	
	ctx = peg.makeParseContext("foo", 0)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, Grammar(Foo))"   + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foo", 2)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 3, foo, Grammar(Foo))"   + _NL +
	                        " Match(2, 3, foo, Literal(foo))"
end function


testRuleRefMatchSyntax = function
	_g = peg.makeGrammar
	_g.addRule "Foo", peg.makeLiteral("foo")
	_g.setDefaultRule "Foo"
	
	p = peg.makeRuleRef("Foo")
	
	ctx = peg.makeParseContext("", 0)
	ctx.grammar = _g
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, RuleRef(Foo))"   + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
	
	ctx = peg.makeParseContext("  foo", 2)
	ctx.grammar = _g
	m = p.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 3, foo, RuleRef(Foo))"   + _NL +
	                        " Match(2, 3, foo, Literal(foo))"
end function


testRuleRefMatchSyntaxManyRules = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeRuleRef("Bar")
	g.addRule "Bar", peg.makeRuleRef("Baz")
	g.addRule "Baz", peg.makeLiteral("baz")
	g.setDefaultRule "Foo"
	
	qa.assertEqual g._str,  "Grammar(Foo)"      + _NL +
	                        " Foo->"            + _NL +
	                        "  RuleRef(Bar)"    + _NL +
	                        " Bar->"            + _NL +
	                        "  RuleRef(Baz)"    + _NL +
	                        " Baz->"            + _NL +
	                        "  Literal(baz)"
	
	ctx = peg.makeParseContext("", 0)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("foo", 0)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m, null
	
	ctx = peg.makeParseContext("baz", 0)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(0, 3, baz, Grammar(Foo))"     + _NL +
	                        " Match(0, 3, baz, RuleRef(Bar))"    + _NL +
	                        "  Match(0, 3, baz, RuleRef(Baz))"   + _NL +
	                        "   Match(0, 3, baz, Literal(baz))"
	
	ctx = peg.makeParseContext("  baz", 2)
	m = g.matchSyntax(0, ctx)
	qa.assertEqual m._str,  "Match(2, 3, baz, Grammar(Foo))"     + _NL +
	                        " Match(2, 3, baz, RuleRef(Bar))"    + _NL +
	                        "  Match(2, 3, baz, RuleRef(Baz))"   + _NL +
	                        "   Match(2, 3, baz, Literal(baz))"
end function

