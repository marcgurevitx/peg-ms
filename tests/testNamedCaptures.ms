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


testNamedCapturesWithIndex = function
	g = new peg.Grammar
	g.init "A <- ( 'foo' {up} ) {xxx:0}"
	
	_up = function(match, subcaptures, arg)
		return match.fragment.upper
	end function
	g.capture "up", @_up
	
	qa.assertEqual g.parse("foo").captures.map, {"xxx": "FOO"}
end function


testNamedCapturesWithNegativeIndex = function
	g = new peg.Grammar
	g.init "A <- ( 'foo' {up}  'bar' {up} ) {xxx:-1}"
	
	_up = function(match, subcaptures, arg)
		return match.fragment.upper
	end function
	g.capture "up", @_up
	
	qa.assertEqual g.parse("foobar").captures.map, {"xxx": "BAR"}
end function

