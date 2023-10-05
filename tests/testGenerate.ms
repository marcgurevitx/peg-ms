import "qa"
import "peg"

_NL = peg._NL


testGenerateAnyChar = function
	p = peg.makeAnyChar
	qa.assertEqual p.generate, "."
	
	p = peg.makeAnyChar.withCaptureTag
	qa.assertEqual p.generate, ". {}"
	
	p = peg.makeAnyChar.withCaptureTag("xxx")
	qa.assertEqual p.generate, ". {xxx}"
	
	p = peg.makeAnyChar.withMatchTimeTag("yyy")
	qa.assertEqual p.generate, ". <yyy>"
	
	p = peg.makeAnyChar.withCaptureTag("xxx").withMatchTimeTag("yyy")
	qa.assertEqual p.generate, ". <yyy> {xxx}"
end function


testGenerateCharSet = function
	p = peg.makeCharSet("abc")
	qa.assertEqual p.generate, "[abc]"
	
	p = peg.makeCharSet("abc").withCaptureTag("xxx").withMatchTimeTag("yyy")
	qa.assertEqual p.generate, "[abc] <yyy> {xxx}"
	
	p = peg.makeCharSet("x-y")
	qa.assertEqual p.generate, "[xy-]"
	
	p = peg.makeCharSet(char(9) + "]""\")
	qa.assertEqual p.generate, "[\t\]\""\\]"
end function


testGenerateCharRange = function
	p = peg.makeCharRange("a", "c")
	qa.assertEqual p.generate, "[a-c]"
	
	p = peg.makeCharRange("a", "c").withCaptureTag("xxx").withMatchTimeTag("yyy")
	qa.assertEqual p.generate, "[a-c] <yyy> {xxx}"
	
	p = peg.makeCharRange(char(9), char(13))
	qa.assertEqual p.generate, "[\t-\r]"
end function


testGenerateLiteral = function
	p = peg.makeLiteral("foo")
	qa.assertEqual p.generate, "'foo'"
	
	p = peg.makeLiteral("foo").withCaptureTag("xxx").withMatchTimeTag("yyy")
	qa.assertEqual p.generate, "'foo' <yyy> {xxx}"
	
	p = peg.makeLiteral("'x'" + char(13) + char(10))
	qa.assertEqual p.generate, "'\'x\'\r\n'"
end function


testGenerateRuleRef = function
	p = peg.makeRuleRef("Foo")
	qa.assertEqual p.generate, "Foo"
	
	p = peg.makeRuleRef("Foo").withCaptureTag("xxx").withMatchTimeTag("yyy")
	qa.assertEqual p.generate, "Foo <yyy> {xxx}"
end function


testGenerateChoice = function
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
	])
	qa.assertEqual p.generate, "'foo'  /  'bar'"
	
	p = peg.makeChoice([
		peg.makeLiteral("foo").withCaptureTag("xxx"),
		peg.makeLiteral("bar"),
	])
	qa.assertEqual p.generate, "'foo' {xxx}  /  'bar'"
	
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar").withCaptureTag("xxx"),
	])
	qa.assertEqual p.generate, "'foo'  /  'bar' {xxx}"
	
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
	]).withCaptureTag("xxx")
	qa.assertEqual p.generate, "( 'foo'  /  'bar' ) {xxx}"
	
	p = peg.makeChoice([
		peg.makeLiteral("foo"),
		peg.makeChoice([
			peg.makeLiteral("bar"),
			peg.makeLiteral("baz"),
		]),
		peg.makeLiteral("bamf"),
	])
	qa.assertEqual p.generate, "'foo'  /  ( 'bar'  /  'baz' )  /  'bamf'"
end function


testGenerateConcat = function
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
	])
	qa.assertEqual p.generate, "'foo'  'bar'"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo").withCaptureTag("xxx"),
		peg.makeLiteral("bar"),
	])
	qa.assertEqual p.generate, "'foo' {xxx}  'bar'"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar").withCaptureTag("xxx"),
	])
	qa.assertEqual p.generate, "'foo'  'bar' {xxx}"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeLiteral("bar"),
	]).withCaptureTag("xxx")
	qa.assertEqual p.generate, "( 'foo'  'bar' ) {xxx}"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeChoice([
			peg.makeLiteral("bar"),
			peg.makeLiteral("baz"),
		]),
		peg.makeLiteral("bamf"),
	])
	qa.assertEqual p.generate, "'foo'  ( 'bar'  /  'baz' )  'bamf'"
	
	p = peg.makeConcat([
		peg.makeLiteral("foo"),
		peg.makeConcat([
			peg.makeLiteral("bar"),
			peg.makeLiteral("baz"),
		]),
		peg.makeLiteral("bamf"),
	])
	qa.assertEqual p.generate, "'foo'  ( 'bar'  'baz' )  'bamf'"
end function


testGenerateAnd = function
	p = peg.makeAnd(
		peg.makeLiteral("foo"))
	qa.assertEqual p.generate, "& 'foo'"
	
	p = peg.makeAnd(
		peg.makeLiteral("foo").withCaptureTag("xxx"))
	qa.assertEqual p.generate, "& 'foo' {xxx}"
	
	p = peg.makeAnd(
		peg.makeLiteral("foo")).withCaptureTag("xxx")
	qa.assertEqual p.generate, "( & 'foo' ) {xxx}"
	
	p = peg.makeAnd(
		peg.makeChoice([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "& ( 'foo'  /  'bar' )"
	
	p = peg.makeAnd(
		peg.makeConcat([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "& ( 'foo'  'bar' )"
end function


testGenerateNot = function
	p = peg.makeNot(
		peg.makeLiteral("foo"))
	qa.assertEqual p.generate, "! 'foo'"
	
	p = peg.makeNot(
		peg.makeLiteral("foo").withCaptureTag("xxx"))
	qa.assertEqual p.generate, "! 'foo' {xxx}"
	
	p = peg.makeNot(
		peg.makeLiteral("foo")).withCaptureTag("xxx")
	qa.assertEqual p.generate, "( ! 'foo' ) {xxx}"
	
	p = peg.makeNot(
		peg.makeChoice([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "! ( 'foo'  /  'bar' )"
	
	p = peg.makeNot(
		peg.makeConcat([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "! ( 'foo'  'bar' )"
end function


testGenerateOptional = function
	p = peg.makeOptional(
		peg.makeLiteral("foo"))
	qa.assertEqual p.generate, "'foo' ?"
	
	p = peg.makeOptional(
		peg.makeLiteral("foo").withCaptureTag("xxx"))
	qa.assertEqual p.generate, "'foo' {xxx} ?"
	
	p = peg.makeOptional(
		peg.makeLiteral("foo")).withCaptureTag("xxx")
	qa.assertEqual p.generate, "'foo' ? {xxx}"
	
	p = peg.makeOptional(
		peg.makeAnd(
			peg.makeLiteral("foo")))
	qa.assertEqual p.generate, "( & 'foo' ) ?"
	
	p = peg.makeOptional(
		peg.makeConcat([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "( 'foo'  'bar' ) ?"
end function


testGenerateZeroOrMore = function
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo"))
	qa.assertEqual p.generate, "'foo' *"
	
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo").withCaptureTag("xxx"))
	qa.assertEqual p.generate, "'foo' {xxx} *"
	
	p = peg.makeZeroOrMore(
		peg.makeLiteral("foo")).withCaptureTag("xxx")
	qa.assertEqual p.generate, "'foo' * {xxx}"
	
	p = peg.makeZeroOrMore(
		peg.makeAnd(
			peg.makeLiteral("foo")))
	qa.assertEqual p.generate, "( & 'foo' ) *"
	
	p = peg.makeZeroOrMore(
		peg.makeConcat([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "( 'foo'  'bar' ) *"
end function


testGenerateOneOrMore = function
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo"))
	qa.assertEqual p.generate, "'foo' +"
	
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo").withCaptureTag("xxx"))
	qa.assertEqual p.generate, "'foo' {xxx} +"
	
	p = peg.makeOneOrMore(
		peg.makeLiteral("foo")).withCaptureTag("xxx")
	qa.assertEqual p.generate, "'foo' + {xxx}"
	
	p = peg.makeOneOrMore(
		peg.makeAnd(
			peg.makeLiteral("foo")))
	qa.assertEqual p.generate, "( & 'foo' ) +"
	
	p = peg.makeOneOrMore(
		peg.makeConcat([
			peg.makeLiteral("foo"),
			peg.makeLiteral("bar"),
		]))
	qa.assertEqual p.generate, "( 'foo'  'bar' ) +"
end function


testGenerateGrammar = function
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeAnyChar
	g.addRule "Bar", peg.makeAnyChar
	g.setDefaultRule "Bar"
	qa.assertEqual g.generate(_NL), "  Foo  <-  .  " + _NL +
	                                "  Bar  :   .  "
	
	g = peg.makeGrammar
	g.addRule "Foo", peg.makeAnyChar
	g.addRule "Bar", peg.makeAnyChar
	g.setDefaultRule "Bar"
	g.withCaptureTag("xxx")
	qa.assertEqual g.generate(_NL), "(  Foo  <-  .  " + _NL +
	                                "  Bar  :   .  ) {xxx}"
end function

