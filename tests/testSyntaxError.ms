import "qa"
import "peg"

_NL = peg._NL


testAnyCharSyntaxError = function
	p = peg.makeAnyChar
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abc", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testCharSetSyntaxError = function
	p = peg.makeCharSet("abc")
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testCharRangeSyntaxError = function
	p = peg.makeCharRange("a", "c")
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testLiteralSyntaxError = function
	p = peg.makeLiteral("foo")
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testAndSyntaxError = function
	p = peg.makeAnd(
		peg.makeLiteral("foo"))
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testAndNoSubpatternSyntaxError = function
	_p = peg.makeLiteral("foo")
	_p.matchTimeTag = "xxx!"
	
	p = peg.makeAnd(_p)
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors, []
end function


testNotSyntaxError = function
	p = peg.makeNot(
		peg.makeLiteral("foo"))
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcfoo", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testNotNoSubpatternSyntaxError = function
	_p = peg.makeLiteral("foo")
	_p.matchTimeTag = "xxx!"
	
	p = peg.makeNot(_p)
	
	ctx = peg.makeParseContext("abcfoo", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors, []
end function


testChoiceSyntaxError = function
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testConcatSyntaxError = function
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
		peg.makeLiteral("baz")])
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testOneOrMoreSyntaxError = function
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo"))
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Foo"
	ctx.ruleStart = 0
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testGrammarSyntaxError = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo")
	g.setDefaultRule "Foo"
	g.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Bar"
	ctx.ruleStart = 0
	
	m = g.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testRuleRefSyntaxError = function
	_g = peg.makeGrammar
	_g.addRule "Foo", peg.makeLiteral("foo")
	_g.setDefaultRule "Foo"
	
	p = peg.makeRuleRef("Foo")
	p.matchTimeTag = "xxx!"
	
	ctx = peg.makeParseContext("abcx", 3)
	ctx.ruleName = "Bar"
	ctx.ruleStart = 0
	ctx.grammar = _g
	
	m = p.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
end function


testCustomSyntaxError = function
	_p = peg.makeLiteral("foo")
	_p.matchTimeTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	g.addMatchTimeAction "xxx", function(match,_,_,ctx)
		if match == null then ctx.addSyntaxError "xxx", "Foo failed"
		return match
	end function
	
	ctx = peg.makeParseContext("x", 0)
	m = g.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
	qa.assertEqual ctx.syntaxErrors[0]._message, "Foo failed"
end function


testCustomSyntaxErrorWithRuleName = function
	_p = peg.makeLiteral("foo")
	_p.matchTimeTag = "xxx"
	
	g = peg.makeGrammar
	g.addRule "Foo", _p
	g.setDefaultRule "Foo"
	
	g.addMatchTimeAction "xxx", function(match,_,_,ctx)
		if match == null then ctx.addSyntaxError "xxx", "Foo failed"
		return match
	end function
	
	ctx = peg.makeParseContext("x", 0)
	m = g.matchSyntax(ctx)
	qa.assertEqual m, null
	qa.assertEqual ctx.syntaxErrors[0] isa peg.SyntaxError, true
	qa.assertEqual ctx.syntaxErrors[0].tag, "xxx"
	qa.assertEqual ctx.syntaxErrors[0]._message, "Foo failed"
end function

