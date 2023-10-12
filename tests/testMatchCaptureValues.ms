import "qa"
import "peg"

_NL = peg._NL


testMatchCaptureValuesNoCaptures = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	m2 = new peg.Match
	m2.init 1, 1, "B"
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	qa.assertEqual m._str,  "Match(0, 1, A, )"    + _NL +
	                        " Match(1, 1, B, )"   + _NL +
	                        "  Match(2, 1, C, )"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx)
	
	qa.assertEqual captures.list, []
end function


testMatchCaptureValuesOneCapture = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	m2 = new peg.Match
	m2.init 1, 1, "B"
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	_capture = function(match, captures, arg)
		return ([match.fragment] + captures.list).join(" : ")
	end function
	m.capture = @_capture
	m3.capture = @_capture
	
	qa.assertEqual m._str,  "Match(0, 1, A, , +)"    + _NL +
	                        " Match(1, 1, B, )"      + _NL +
	                        "  Match(2, 1, C, , +)"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx)
	
	qa.assertEqual captures.list, ["A : C"]
end function


testMatchCaptureValuesManyCaptures = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	m2 = new peg.Match
	m2.init 1, 1, "B"
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	_capture = function(match, captures, arg)
		captures.list.push match.fragment
		return captures
	end function
	m.capture = @_capture
	m3.capture = @_capture
	
	qa.assertEqual m._str,  "Match(0, 1, A, , +)"    + _NL +
	                        " Match(1, 1, B, )"      + _NL +
	                        "  Match(2, 1, C, , +)"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx)
	
	qa.assertEqual captures.list, ["C", "A"]
end function


testMatchCaptureValuesArg = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	m2 = new peg.Match
	m2.init 1, 1, "B"
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	_capture = function(match, captures, arg)
		captures.list.push match.fragment + arg
		return captures
	end function
	m.capture = @_capture
	m3.capture = @_capture
	
	qa.assertEqual m._str,  "Match(0, 1, A, , +)"    + _NL +
	                        " Match(1, 1, B, )"      + _NL +
	                        "  Match(2, 1, C, , +)"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx, "!!!")
	
	qa.assertEqual captures.list, ["C!!!", "A!!!"]
end function


testMatchCaptureValuesError = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	m2 = new peg.Match
	m2.init 1, 1, "B"
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	peg = outer.peg
	_capture = function(match, captures, arg)
		error = new peg.Error
		error.init "error " + match.fragment
		return error
	end function
	m.capture = @_capture
	m3.capture = @_capture
	
	qa.assertEqual m._str,  "Match(0, 1, A, , +)"    + _NL +
	                        " Match(1, 1, B, )"      + _NL +
	                        "  Match(2, 1, C, , +)"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx)
	
	qa.assertEqual captures isa peg.Error, true
	qa.assertEqual captures.message, "error C"
end function


testMatchCaptureValuesNoCapturesInPredicates = function
	m = new peg.Match
	m.init 0, 1, "A"
	
	_p1 = new peg.AnyChar
	_p1.init
	_p = new peg.And
	_p.init _p1
	
	m2 = new peg.Match
	m2.init 1, 1, "B", _p
	m.addChild m2
	
	m3 = new peg.Match
	m3.init 2, 1, "C"
	m2.addChild m3
	
	_capture = function(match, captures, arg)
		return ([match.fragment] + captures.list).join(" : ")
	end function
	m.capture = @_capture
	m3.capture = @_capture
	
	qa.assertEqual m._str,  "Match(0, 1, A, , +)"        + _NL +
	                        " Match(1, 1, B, And())"     + _NL +
	                        "  Match(2, 1, C, , +)"
	
	ctx = peg.makeParseContext
	
	captures = m.captureValues(ctx)
	
	qa.assertEqual captures.list, ["A"]
end function

