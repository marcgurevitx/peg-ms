import "qa"
import "peg"

_NL = peg._NL


testMTErrors = function
	g = new peg.Grammar
	g.init "_: 'a' <xxx!>"
	
	res = g.parse("a")
	qa.assertEqual res.errors, []
	
	res = g.parse("")
	qa.assertEqual res.hasErrorTag("xxx"), true
end function

