import "qa"
import "peg"

_NL = peg._NL


testHasErrorTag = function
	g = new peg.Grammar
	g.init "A <- 'foo'<expectedFoo!> ('bar'<expectedBar!> / 'baz'<expectedBaz!>)"
	res = g.parse("foo")
	qa.assertEqual not res.hasErrorTag("expectedFoo"), true
	qa.assertEqual res.hasErrorTag("expectedBar"), true
	qa.assertEqual res.hasErrorTag("expectedBaz"), true
end function


testHasErrorType = function
	E1 = new peg.Error
	E2 = new peg.Error
	
	g = new peg.Grammar
	g.init "A <- 'foo'<xxx>"
	
	_xxx = function(match, _, _, ctx)
		e = new E1
		e.message = "hello"
		ctx.syntaxErrors.push e
		return match
	end function
	g.matchTime "xxx", @_xxx
	
	res = g.parse("foo")
	qa.assertEqual res.hasErrorType(E1), true
	qa.assertEqual res.hasErrorType(E2), false
end function

