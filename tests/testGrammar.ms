import "qa"
import "peg"

_NL = peg._NL


testGrammarGetRulePattern = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo")
	g.setDefaultRule "Foo"
	qa.assertEqual g.getRulePattern("Foo")._str, "Literal(foo)"
end function


testGrammarGetRulePatternArg = function
	g = peg.makeGrammar
	arg = {}
	arg.Foo = peg.makeLiteral("foo")
	qa.assertEqual g.getRulePattern("Foo", arg)._str, "Literal(foo)"
end function


testGrammarOnlyRuleIsDefaultRule = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo")
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(Foo))" + _NL +
	                                " Match(0, 3, foo, Literal(foo))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testGrammarParseResultOneCapture = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeLiteral("foo").withCaptureTag
	
	res = g.parse("foo")
	qa.assertEqual res.captures.list, ["foo"]
	qa.assertEqual res.capture, "foo"
	
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeConcat([
		peg.makeLiteral("foo").withCaptureTag,
		peg.makeLiteral("bar").withCaptureTag,
	])
	
	res = g.parse("foobar")
	qa.assertEqual res.captures.list, ["foo", "bar"]
	qa.assertEqual res.capture, null
end function


testGrammarInitWithPegLiteral = function
	g = peg.makeGrammar("A<-'foo'")
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo")
	qa.assertEqual res.match.nodeToStr, "Match(0, 3, foo, Grammar(A))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("  foo", 2)
	qa.assertEqual res.match.nodeToStr, "Match(2, 3, foo, Grammar(A))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testGrammarInitWithDefaultRule = function
	g = peg.makeGrammar("B <- C  A <- B  C <- 'foo' {}", "A")
	qa.assertEqual g.parse("foo").capture, "foo"
end function


testGrammarDefaultRuleSyntax = function
	g = peg.makeGrammar("B <- C  A: B  C <- 'foo' {}")
	qa.assertEqual g.parse("foo").capture, "foo"
end function


testGrammarUsedFlags = function
	g = new peg.Grammar
	g.init "_: (+xxx) (-yyy) (/zzz) %if www% . %end if%"
	
	qa.assertEqual g.usedFlags.len, 4
	qa.assertEqual g.usedFlags.xxx, true
	qa.assertEqual g.usedFlags.yyy, true
	qa.assertEqual g.usedFlags.zzz, true
	qa.assertEqual g.usedFlags.www, true
end function

