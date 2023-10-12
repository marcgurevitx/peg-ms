import "qa"
import "peg"

_NL = peg._NL


testPegSpace = function
	g = new peg.pegGrammar
	g.setDefaultRule "Space"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 0, , Grammar(Space))"
	qa.assertEqual res.length, 0
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse(" ", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 1,  , Grammar(Space))"
	qa.assertEqual res.length, 1
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse(" " + char(13) + " ", null, arg)
	qa.assertEqual res.match.length, 3
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testPegComment = function
	g = new peg.pegGrammar
	g.setDefaultRule "Comment"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("# foo", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, # foo, Grammar(Comment))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("# foo" + _NL, null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, # foo" + _NL + ", Grammar(Comment))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("# foo" + _NL + "xxx", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, # foo" + _NL + ", Grammar(Comment))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testPegSpaceComment = function
	g = new peg.pegGrammar
	g.setDefaultRule "Space"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("# foo" + _NL + "   " + _NL + "# bar" + _NL + char(9) + "xxx", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 17, # foo" + _NL + "   " + _NL + "# bar" + _NL + char(9) + ", Grammar(Space))"
	qa.assertEqual res.length, 17
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testPegIdentifier = function
	g = new peg.pegGrammar
	g.setDefaultRule "Identifier"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("foo", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 3, foo, Grammar(Identifier))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["foo"]
end function


testPegEscape = function
	g = new peg.pegGrammar
	g.setDefaultRule "Escape"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("\", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("\abc", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("\tabc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, \t, Grammar(Escape))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, char(9)
	
	res = g.parse("\nabc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, \n, Grammar(Escape))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, char(10)
	
	res = g.parse("\rabc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, \r, Grammar(Escape))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, char(13)
	
	res = g.parse("\u0026abc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, \u0026, Grammar(Escape))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, "&"
	
	res = g.parse("\\abc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, \\, Grammar(Escape))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, "\"
	
	res = g.parse("\""abc", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, \"", Grammar(Escape))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture, """"
end function


testPegCharClass = function
	g = new peg.pegGrammar
	g.setDefaultRule "CharClass"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("[x]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 3, [x], Grammar(CharClass))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"     + _NL +
	                                            " Literal(x)"
	
	res = g.parse("[a-c]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, [a-c], Grammar(CharClass))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"      + _NL +
	                                            " CharRange(a, c)"
	
	res = g.parse("[xa-c]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, [xa-c], Grammar(CharClass))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"      + _NL +
	                                            " Literal(x)"   + _NL +
	                                            " CharRange(a, c)"
	
	res = g.parse("[]", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
	
	res = g.parse("[a-c", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegCharClassWithEscapes = function
	g = new peg.pegGrammar
	g.setDefaultRule "CharClass"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("[a\tb]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, [a\tb], Grammar(CharClass))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str,    "Choice()"                  + _NL +
	                                    " Literal(a)"               + _NL +
	                                    " Literal(" + char(9) + ")" + _NL +
	                                    " Literal(b)"
	
	res = g.parse("[a\xb]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, [a\xb], Grammar(CharClass))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str,    "Choice()"                  + _NL +
	                                    " Literal(a)"               + _NL +
	                                    " Literal(\)"               + _NL +
	                                    " Literal(x)"               + _NL +
	                                    " Literal(b)"
end function


testPegLiteralSingleQuotes = function
	g = new peg.pegGrammar
	g.setDefaultRule "Literal"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("''", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, '', Grammar(Literal))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "Literal()"
	
	res = g.parse("'foo'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, 'foo', Grammar(Literal))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "Literal(foo)"
	
	res = g.parse("'foo", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegLiteralDoubleQuotes = function
	g = new peg.pegGrammar
	g.setDefaultRule "Literal"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("""""", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, """", Grammar(Literal))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "Literal()"
	
	res = g.parse("""foo""", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, ""foo"", Grammar(Literal))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "Literal(foo)"
	
	res = g.parse("""foo", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegLiteralWithEscapes = function
	g = new peg.pegGrammar
	g.setDefaultRule "Literal"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("'a\tb'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, 'a\tb', Grammar(Literal))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str, "Literal(a" + char(9) + "b)"
	
	res = g.parse("'a\xb'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, 'a\xb', Grammar(Literal))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str, "Literal(a\xb)"
	
	res = g.parse("'a\'b'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, 'a\'b', Grammar(Literal))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str, "Literal(a'b)"
	
	res = g.parse("""a\""b""", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, ""a\""b"", Grammar(Literal))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.capture._str, "Literal(a""b)"
end function


testPegAnyChar = function
	g = new peg.pegGrammar
	g.setDefaultRule "AnyChar"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("x", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse(".", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 1, ., Grammar(AnyChar))"
	qa.assertEqual res.length, 1
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "AnyChar()"
end function


testPegPrimaryAnyChar = function
	g = new peg.pegGrammar
	g.setDefaultRule "Primary"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse(".", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 1, ., Grammar(Primary))"
	qa.assertEqual res.length, 1
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "AnyChar()"
end function


testPegPrimaryCharClass = function
	g = new peg.pegGrammar
	g.setDefaultRule "Primary"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("[a-cx]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, [a-cx], Grammar(Primary))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"      + _NL +
	                                            " CharRange(a, c)"  + _NL +
	                                            " Literal(x)"
end function


testPegPrimaryIdentifier = function
	g = new peg.pegGrammar
	g.setDefaultRule "Primary"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("Foo", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 3, Foo, Grammar(Primary))"
	qa.assertEqual res.length, 3
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "RuleRef(Foo)"
	
	res = g.parse("Foo <-", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
end function


testPegPrimaryLiteral = function
	g = new peg.pegGrammar
	g.setDefaultRule "Primary"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("'bar'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, 'bar', Grammar(Primary))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "Literal(bar)"
end function


testPegMatchTimeTag = function
	g = new peg.pegGrammar
	g.setDefaultRule "MatchTimeTag"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("<>", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, <>, Grammar(MatchTimeTag))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["<"]
	
	res = g.parse("<foo>", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, <foo>, Grammar(MatchTimeTag))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["<foo"]
	
	res = g.parse("<foo", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegCaptureTag = function
	g = new peg.pegGrammar
	g.setDefaultRule "CaptureTag"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, []
	
	res = g.parse("{}", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, {}, Grammar(CaptureTag))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["{"]
	
	res = g.parse("{foo}", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, {foo}, Grammar(CaptureTag))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list, ["{foo"]
	
	res = g.parse("{foo", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegWithSuffixStar = function
	g = new peg.pegGrammar
	g.setDefaultRule "WithSuffix"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse(".*", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 2, .*, Grammar(WithSuffix))"
	qa.assertEqual res.length, 2
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "ZeroOrMore()" + _NL +
	                                            " AnyChar()"
end function


testPegWithSuffixPlus = function
	g = new peg.pegGrammar
	g.setDefaultRule "WithSuffix"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("'foo'+", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, 'foo'+, Grammar(WithSuffix))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "OneOrMore()" + _NL +
	                                            " Literal(foo)"
end function


testPegWithSuffixQuestion = function
	g = new peg.pegGrammar
	g.setDefaultRule "WithSuffix"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("[a-z]?", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, [a-z]?, Grammar(WithSuffix))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Optional()"    + _NL +
	                                            " Choice()"     + _NL +
	                                            "  CharRange(a, z)"
end function


testPegWithSuffixColon = function
	g = new peg.pegGrammar
	g.setDefaultRule "WithSuffix"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("Foo <bar>", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 9, Foo <bar>, Grammar(WithSuffix))"
	qa.assertEqual res.length, 9
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str, "RuleRef(Foo) <bar>"
	qa.assertEqual res.captures.list[0].matchTimeTag, "bar"
end function


testPegWithSuffixBrace = function
	g = new peg.pegGrammar
	g.setDefaultRule "WithSuffix"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("[x] {bar}", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 9, [x] {bar}, Grammar(WithSuffix))"
	qa.assertEqual res.length, 9
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice() {bar}" + _NL +
	                                            " Literal(x)"
	qa.assertEqual res.captures.list[0].captureTag, "bar"
end function


testPegAlternativeNoPrefix = function
	g = new peg.pegGrammar
	g.setDefaultRule "Alternative"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse(".", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 1, ., Grammar(Alternative))"
	qa.assertEqual res.length, 1
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Concat()" + _NL +
	                                            " AnyChar()"
end function


testPegAlternativeNot = function
	g = new peg.pegGrammar
	g.setDefaultRule "Alternative"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("!'foo'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 6, !'foo', Grammar(Alternative))"
	qa.assertEqual res.length, 6
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Concat()"        + _NL +
	                                            " Not()"          + _NL +
	                                            "  Literal(foo)"
end function


testPegAlternativeAnd = function
	g = new peg.pegGrammar
	g.setDefaultRule "Alternative"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("&Foo+", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5, &Foo+, Grammar(Alternative))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Concat()"        + _NL +
	                                            " And()"          + _NL +
	                                            "  OneOrMore()"   + _NL +
	                                            "   RuleRef(Foo)"
end function


testPegAlternativeConcat = function
	g = new peg.pegGrammar
	g.setDefaultRule "Alternative"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  &B  C  !D  E", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 15, A  &B  C  !D  E, Grammar(Alternative))"
	qa.assertEqual res.length, 15
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Concat()"        + _NL +
	                                            " RuleRef(A)"     + _NL +
	                                            " And()"          + _NL +
	                                            "  RuleRef(B)"    + _NL +
	                                            " RuleRef(C)"     + _NL +
	                                            " Not()"          + _NL +
	                                            "  RuleRef(D)"    + _NL +
	                                            " RuleRef(E)"
end function


testPegAlternativeNoPatternError = function
	g = new peg.pegGrammar
	g.setDefaultRule "Alternative"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("!", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
	
	res = g.parse("&", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegPattern = function
	g = new peg.pegGrammar
	g.setDefaultRule "Pattern"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  /  B  C  /  D", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 16, A  /  B  C  /  D, Grammar(Pattern))"
	qa.assertEqual res.length, 16
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"        + _NL +
	                                            " Concat()"       + _NL +
	                                            "  RuleRef(A)"    + _NL +
	                                            " Concat()"       + _NL +
	                                            "  RuleRef(B)"    + _NL +
	                                            "  RuleRef(C)"    + _NL +
	                                            " Concat()"       + _NL +
	                                            "  RuleRef(D)"
end function


testPegPatternSyntaxError = function
	g = new peg.pegGrammar
	g.setDefaultRule "Pattern"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  /  B  C  /  ", null, arg)
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
end function


testPegPrimaryPattern = function
	g = new peg.pegGrammar
	g.setDefaultRule "Primary"
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("(Foo+ / Bar*)", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 13, (Foo+ / Bar*), Grammar(Primary))"
	qa.assertEqual res.length, 13
	qa.assertEqual res.errors, []
	qa.assertEqual res.captures.list[0]._str,   "Choice()"         + _NL +
	                                            " Concat()"        + _NL +
	                                            "  OneOrMore()"    + _NL +
	                                            "   RuleRef(Foo)"  + _NL +
	                                            " Concat()"        + _NL +
	                                            "  ZeroOrMore()"   + _NL +
	                                            "   RuleRef(Bar)"
end function


testPegGrammarOneRule = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  'foo'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 12, A  <-  'foo', Grammar(Grammar))"
	qa.assertEqual res.length, 12
	qa.assertEqual res.errors, []
	
	rules = res.captures.list[0].rules
	ruleOrder = res.captures.list[0].ruleOrder
	qa.assertEqual ruleOrder, ["A"]
	qa.assertEqual rules.A._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  Literal(foo)"
end function


testPegGrammarManyRules = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  B  B  <-  C  C  <-  'foo'", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 32, A  <-  B  B  <-  C  C  <-  'foo', Grammar(Grammar))"
	qa.assertEqual res.length, 32
	qa.assertEqual res.errors, []
	
	rules = res.captures.list[0].rules
	ruleOrder = res.captures.list[0].ruleOrder
	qa.assertEqual ruleOrder, ["A", "B", "C"]
	qa.assertEqual rules.A._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  RuleRef(B)"
	qa.assertEqual rules.B._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  RuleRef(C)"
	qa.assertEqual rules.C._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  Literal(foo)"
end function


testPegGrammarErrorNoRuleDef = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarErrorNoArrow = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarErrorNoRuleDefs = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("", null, arg)
	qa.assertEqual res.match, null
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SyntaxError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarErrorMissingRule = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  B", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 8, A  <-  B, Grammar(Grammar))"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarInclusion = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  B  B  <-  $", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 18, A  <-  B  B  <-  $, Grammar(Grammar))"
	qa.assertEqual res.length, 18
	qa.assertEqual res.errors, []
	
	rules = res.captures.list[0].rules
	ruleOrder = res.captures.list[0].ruleOrder
	qa.assertEqual ruleOrder, ["A", "B"]
	qa.assertEqual rules.A._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  RuleRef(B)"
end function


testPegGrammarErrorNoNoninclusionRules = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  $  B  <-  $", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 18, A  <-  $  B  <-  $, Grammar(Grammar))"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarErrorRepeatingRuleNames = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  [x]  A  <-  [y]", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 22, A  <-  [x]  A  <-  [y], Grammar(Grammar))"
	qa.assertEqual res.length, null
	qa.assertEqual res.errors[0] isa peg.SemanticError, true
	qa.assertEqual res.captures.list, []
end function


testPegGrammarInitialSpaces = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse(" A<-.", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 5,  A<-., Grammar(Grammar))"
	qa.assertEqual res.length, 5
	qa.assertEqual res.errors, []
	
	rules = res.captures.list[0].rules
	qa.assertEqual rules.A._str,    "Choice()"      + _NL +
	                                " Concat()"     + _NL +
	                                "  AnyChar()"
end function


testPegGrammarInclusions = function
	g = peg.pegGrammar
	
	//
	arg = {}
	arg.ruleNames = {}
	//
	
	res = g.parse("A  <-  B  B  <-  C  C  <-  $", null, arg)
	qa.assertEqual res.match.nodeToStr, "Match(0, 28, A  <-  B  B  <-  C  C  <-  $, Grammar(Grammar))"
	qa.assertEqual res.length, 28
	qa.assertEqual res.errors, []
	
	rules = res.captures.list[0].rules
	ruleOrder = res.captures.list[0].ruleOrder
	qa.assertEqual ruleOrder, ["A", "B", "C"]
	qa.assertEqual rules.A._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  RuleRef(B)"
	qa.assertEqual rules.B._str, "Choice()"        + _NL +
	                             " Concat()"       + _NL +
	                             "  RuleRef(C)"
end function


testPegGenerate = function
	p = peg.pegGrammar.getRulePattern("Comment")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Space")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Identifier")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Escape")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("CharClass")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Literal")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("AnyChar")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Primary")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("MatchTimeTag")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("CaptureTag")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("WithSuffix")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Alternative")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Pattern")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Definition")
	qa.assertEqual p.generate, p._DEBUG_PEG
	
	p = peg.pegGrammar.getRulePattern("Grammar")
	qa.assertEqual p.generate, p._DEBUG_PEG
end function


testPegGrammarParseGenerate = function
	s = peg.pegGrammar.generate(_NL)
	
	g = new peg.Grammar
	g.init s
	
	qa.assertEqual g.generate(_NL), s
end function

