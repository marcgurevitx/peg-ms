import "qa"
import "peg"

_NL = peg._NL


testNamedCaptures = function
	g = new peg.Grammar
	g.init "A <- ( 'foo' {foo:} 'bar' {bar:} ) {foobar:}"
	
	res = g.parse("foobar")
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	qa.assertEqual res.captures.map.foo, "foo"
	qa.assertEqual res.captures.map.bar, "bar"
	qa.assertEqual res.captures.map.foobar, "foobar"
end function


testNamedCapturesInCallback = function
	g = new peg.Grammar
	g.init "A <- ( 'foo' {foo:} 'bar' {bar:} ) {xxx}"
	
	_xxx = function(match, subcaptures, arg)
		return subcaptures.map["bar"] + subcaptures.map["foo"]
	end function
	g.capture "xxx", @_xxx
	
	qa.assertEqual g.parse("foobar").capture, "barfoo"
end function

