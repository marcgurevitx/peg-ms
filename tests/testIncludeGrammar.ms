import "qa"
import "peg"

_NL = peg._NL


testIncludeGrammar = function
	g = new peg.Grammar
	g.init "_: 'foo' {xxx}"
	g.capture "xxx", function(match,_,_,_)
		return match.fragment
	end function
	
	g2 = new peg.Grammar
	g2.init "A: B   B <- $"
	g2.addRule "B", g, true
	
	res = g2.parse("foo")
	qa.assertEqual res.capture, "foo"
end function

