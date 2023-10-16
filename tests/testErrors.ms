import "qa"
import "peg"

_NL = peg._NL


testHasErrorTag = function
	g = new peg.Grammar
	g.init "A <- 'foo'<expectedFoo> ('bar'<expectedBar> / 'baz'<expectedBaz>)"
	res = g.parse("foo")
	qa.assertEqual res.hasErrorTag("expectedFoo"), false
	qa.assertEqual res.hasErrorTag("expectedBar"), true
	qa.assertEqual res.hasErrorTag("expectedBaz"), true
end function

