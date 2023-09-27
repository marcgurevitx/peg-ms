import "qa"
import "peg"

_NL = peg._NL


testAnyCharSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeAnyChar
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("a", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str, "Match(0, 1, a, AnyChar() {capTag}, +)"
end function


testCharSetSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeCharSet("abc")
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("a", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str, "Match(0, 1, a, CharSet(abc) {capTag}, +)"
end function


testCharRangeSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeCharRange("a", "c")
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("a", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str, "Match(0, 1, a, CharRange(a, c) {capTag}, +)"
end function


testLiteralSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeLiteral("foo")
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str, "Match(0, 3, foo, Literal(foo) {capTag}, +)"
end function


testAndSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeAnd(
		peg.makeLiteral("foo"))
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 0, , And() {capTag}, +)" + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
end function


testNotSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeNot(
		peg.makeLiteral("foo"))
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("x", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str, "Match(0, 0, , Not() {capTag}, +)"
end function


testChoiceSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("bar", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 3, bar, Choice() {capTag}, +)" + _NL +
	                        " Match(0, 3, bar, Literal(bar))"
end function


testConcatSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foobarbaz", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 9, foobarbaz, Concat() {capTag}, +)" + _NL +
	                        " Match(0, 3, foo, Literal(foo))" + _NL +
	                        " Match(3, 3, bar, Literal(bar))" + _NL +
	                        " Match(6, 3, baz, Literal(baz))"
end function


testOptionalSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeOptional(
		peg.makeLiteral("foo"))
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("x", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 0, , Optional() {capTag}, +)"
end function


testZeroOrMoreSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo"))
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("x", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 0, , ZeroOrMore() {capTag}, +)"
end function


testOneOrMoreSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo"))
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, OneOrMore() {capTag}, +)" + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
end function


testGrammarSetSemantics = function
	_g = new peg.Grammar
	_g.init
	_g.addCaptureAction "capTag", function
	end function
	
	g = new peg.Grammar
	g.init
	g.addRule "Foo", peg.makeLiteral("foo")
	g.setDefaultRule "Foo"
	g.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	
	m = g.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, Grammar(Foo) {capTag}, +)" + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
end function


testRuleRefSetSemantics = function
	_g = peg.makeGrammar
	_g.addRule "Foo", peg.makeLiteral("foo")
	_g.setDefaultRule "Foo"
	_g.addCaptureAction "capTag", function
	end function
	
	p = peg.makeRuleRef("Foo")
	p.captureTag = "capTag"
	
	ctx = peg.makeParseContext("foo", 0)
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m._str,  "Match(0, 3, foo, RuleRef(Foo) {capTag}, +)" + _NL +
	                        " Match(0, 3, foo, Literal(foo))"
end function


testAddCaptureWithoutRuleName = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo").withCaptureTag("xxx")
	
	g.addCaptureAction "xxx", function(match, subcaptures, arg)
		return 42
	end function
	
	ctx = peg.makeParseContext("foo", 0)
	m = g.matchSyntax(ctx)
	c = m.captureValues(ctx)
	qa.assertEqual c, [42]
end function


testAddCaptureWithRuleName = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo").withCaptureTag("xxx")
	
	g.addCaptureAction "Foo", "xxx", function(match, subcaptures, arg)
		return 42
	end function
	
	ctx = peg.makeParseContext("foo", 0)
	m = g.matchSyntax(ctx)
	c = m.captureValues(ctx)
	qa.assertEqual c, [42]
end function


testCaptureShortcut = function
	g = new peg.Grammar
	g.init "A<-'foo'{xxx}"
	
	g.capture "xxx", function(match, subcaptures, arg)
		return match.fragment
	end function
	
	qa.assertEqual g.parse("foo").capture, "foo"
end function

