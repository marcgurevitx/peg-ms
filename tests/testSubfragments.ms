import "qa"
import "peg"

_NL = peg._NL


testSubfragmentChoice = function
	g = new peg.Grammar
	g.init "A<- . :xxx: / ."
	
	_xxx = function(match, subcaptures, arg, ctx)
		match.fragment = "foo"
		return match
	end function
	
	g.matchTime "xxx", @_xxx
	
	qa.assertEqual g.parse("-").match._str, "Match(0, 1, foo, Grammar(A))"          + _NL +
	                                        " Match(0, 1, foo, Choice())"           + _NL +
	                                        "  Match(0, 1, foo, AnyChar() :xxx:)"
end function


testSubfragmentConcat = function
	g = new peg.Grammar
	g.init "A<- . :xxx:  ."
	
	_xxx = function(match, subcaptures, arg, ctx)
		match.fragment = "foo"
		return match
	end function
	
	g.matchTime "xxx", @_xxx
	
	qa.assertEqual g.parse("--").match._str,"Match(0, 2, foo-, Grammar(A))"         + _NL +
	                                        " Match(0, 2, foo-, Concat())"          + _NL +
	                                        "  Match(0, 1, foo, AnyChar() :xxx:)"   + _NL +
	                                        "  Match(1, 1, -, AnyChar())"
end function


testSubfragmentZeroOrMore = function
	g = new peg.Grammar
	g.init "A<- ( . :xxx: )*"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match then match.fragment = "foo"
		return match
	end function
	
	g.matchTime "xxx", @_xxx
	
	qa.assertEqual g.parse("--").match._str,"Match(0, 2, foofoo, Grammar(A))"       + _NL +
	                                        " Match(0, 2, foofoo, ZeroOrMore())"    + _NL +
	                                        "  Match(0, 1, foo, AnyChar() :xxx:)"   + _NL +
	                                        "  Match(1, 1, foo, AnyChar() :xxx:)"
end function


testSubfragmentOneOrMore = function
	g = new peg.Grammar
	g.init "A<- ( . :xxx: )+"
	
	_xxx = function(match, subcaptures, arg, ctx)
		if match then match.fragment = "foo"
		return match
	end function
	
	g.matchTime "xxx", @_xxx
	
	qa.assertEqual g.parse("--").match._str,"Match(0, 2, foofoo, Grammar(A))"       + _NL +
	                                        " Match(0, 2, foofoo, OneOrMore())"     + _NL +
	                                        "  Match(0, 1, foo, AnyChar() :xxx:)"   + _NL +
	                                        "  Match(1, 1, foo, AnyChar() :xxx:)"
end function

