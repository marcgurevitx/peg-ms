import "qa"
import "peg"

_NL = peg._NL


testSyntaxMatchTimeTag = function
	e = peg.makeSyntaxError("RULE", 10, 15, "XXXXX", "YYYYY", "TAG", null)
	qa.assertEqual e isa peg.SyntaxError, true
	qa.assertEqual e.tag, "TAG"
	qa.assertEqual e.message, "error: TAG; attempted to match rule `RULE`; consumed 5 symbols starting at index 10: `XXXXX`; failed from index 15: `YYYYY`"
	
	e = peg.makeSyntaxError("RULE", 10, 15, "XXXXX", "YYYYY", "TAG", "MESSAGE")
	qa.assertEqual e isa peg.SyntaxError, true
	qa.assertEqual e.tag, "TAG"
	qa.assertEqual e.message, "error: MESSAGE; attempted to match rule `RULE`; consumed 5 symbols starting at index 10: `XXXXX`; failed from index 15: `YYYYY`"
end function


testMatchTimeCaptureNull = function
	g = peg.makeGrammar(" A <- 'foo' :xxx: ")
	
	g.addMatchTimeAction "xxx", function(match, captures, arg, _ctx)
		return null
	end function
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
end function


testMatchTimeCaptureFakeMatch = function
	g = peg.makeGrammar(" A <- 'foo' :xxx: ")
	
	peg = outer.peg
	_f = function(match, captures, arg, _ctx)
		return peg.makeMatch(0, 3, "bar")
	end function
	
	g.addMatchTimeAction "xxx", @_f
	
	res = g.parse("")
	qa.assertEqual res.match._str,  "Match(0, 3, , Grammar(A))" + _NL +
	                                " Match(0, 3, , Choice())"  + _NL +
	                                "  Match(0, 3, , Concat())" + _NL +
	                                "   Match(0, 3, bar, )"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match._str,  "Match(0, 3, foo, Grammar(A))" + _NL +
	                                " Match(0, 3, foo, Choice())"  + _NL +
	                                "  Match(0, 3, foo, Concat())" + _NL +
	                                "   Match(0, 3, bar, )"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
end function


testMatchTimeCaptureAddSyntaxError = function
	g = peg.makeGrammar(" A <- 'foo' :xxx: ")
	
	_f = function(match, captures, arg, _ctx)
		_ctx.addSyntaxError "xxx", "foo bar"
		return null
	end function
	
	g.addMatchTimeAction "xxx", @_f
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.errors[0].message.indexOf("foo bar") != 0, true
	qa.assertEqual res.errors[0].tag, "xxx"
	qa.assertEqual res.captures, []
	
	res = g.parse("foo")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.errors[0].message.indexOf("foo bar") != 0, true
	qa.assertEqual res.errors[0].tag, "xxx"
	qa.assertEqual res.captures, []
end function


testMatchTimeCaptureSubcaptures = function
	g = peg.makeGrammar(" A <- ( 'foo' {}  'bar' {} ) :xxx: ")
	
	sss = null
	_f = function(match, captures, arg, _ctx)
		outer.sss = captures
		return match
	end function
	
	g.addMatchTimeAction "xxx", @_f
	
	res = g.parse("")
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, []
	qa.assertEqual sss, []
	
	res = g.parse("foobar")
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, foobar, Grammar(A))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, ["foo", "bar"]
	qa.assertEqual sss, ["foo", "bar"]
end function


testMatchTimeCaptureSubcapturesAreCached = function
	g = peg.makeGrammar(" A <- ( 'foo' {fff}  'bar' {} ) :xxx: ")
	
	n = 0
	_fff = function(match, captures, arg)
		outer.n += 1
		return match.fragment
	end function
	
	g.addCaptureAction "fff", @_fff
	
	sss = null
	_xxx = function(match, captures, arg, _ctx)
		outer.sss = captures
		return match
	end function
	
	g.addMatchTimeAction "xxx", @_xxx
	
	res = g.parse("foobar")
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, foobar, Grammar(A))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures, ["foo", "bar"]
	qa.assertEqual sss, ["foo", "bar"]
	qa.assertEqual n, 1
end function


testMatchTimeSemanticError = function
	g = peg.makeGrammar(" A <- ( 'foo' {ERR} ) :xxx: ")
	
	peg = outer.peg
	_ERR = function(match, captures, arg)
		return peg.makeError(match.fragment)
	end function
	
	g.addCaptureAction "ERR", @_ERR
	
	_xxx = function(match, captures, arg, ctx)
		c = captures
		match.capture = function(_,_,_)
			return c
		end function
		return match
	end function
	
	g.addMatchTimeAction "xxx", @_xxx
	
	res = g.parse("foo")
	qa.assertEqual res.match.nodeToStr, "Match(0, 3, foo, Grammar(A))"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.errors[0].message, "foo"
	qa.assertEqual res.captures, []
end function


testMatchTimeShortcut = function
	g = new peg.Grammar
	g.init "A<-'foo':xxx:"
	
	g.matchTime "xxx", function(match, subcaptures, arg, ctx)
		match.capture = function(_,_,_)
			return match.fragment
		end function
		return match
	end function
	
	qa.assertEqual g.parse("foo").capture, "foo"
end function

