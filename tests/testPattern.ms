import "qa"
import "peg"

_NL = peg._NL


testPatternOrLiteral = function
	x = "foo"
	p = peg.patternOrLiteral(x)
	qa.assertEqual p isa peg.Literal, true
	
	x = peg.makeLiteral("foo")
	p = peg.patternOrLiteral(x)
	qa.assertEqual p isa peg.Literal, true
	qa.assertEqual refEquals(x, p), true
	
	x = peg.makeCharRange("a", "z")
	p = peg.patternOrLiteral(x)
	qa.assertEqual p isa peg.CharRange, true
	qa.assertEqual refEquals(x, p), true
	
	x = peg.makeGrammar("A<-'foo'")
	p = peg.patternOrLiteral(x)
	qa.assertEqual p isa peg.Grammar, true
	qa.assertEqual refEquals(x, p), true
end function

