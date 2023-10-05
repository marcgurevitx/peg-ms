import "qa"
import "peg"

_NL = peg._NL


testOptimizeChoiceOfOnePatternToPattern = function
	g = new peg.Grammar
	g.init "A <- 'foo' / 'bar'"
	qa.assertEqual g.getRulePattern("A")._str,  "Choice()" + _NL +
	                                            " Literal(foo)" + _NL +
	                                            " Literal(bar)"
	
	g = new peg.Grammar
	g.init "A <- 'a' 'b'"
	qa.assertEqual g.getRulePattern("A")._str,  "Concat()" + _NL +
	                                            " Literal(a)" + _NL +
	                                            " Literal(b)"
	
	g = new peg.Grammar
	g.init "A <- ."
	qa.assertEqual g.getRulePattern("A")._str,  "AnyChar()"
	
	g = new peg.Grammar
	g.init "A <- (.)"
	qa.assertEqual g.getRulePattern("A")._str,  "AnyChar()"
end function


testOptimizeConcatOfOnePatternToPattern = function
	g = new peg.Grammar
	g.init "A <- 'a' 'b'"
	qa.assertEqual g.getRulePattern("A")._str,  "Concat()" + _NL +
	                                            " Literal(a)" + _NL +
	                                            " Literal(b)"
	
	g = new peg.Grammar
	g.init "A <- 'foo'"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo)"
	
	g = new peg.Grammar
	g.init "A <- ('foo')"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo)"
	
	g = new peg.Grammar
	g.init "A <- ('foo' {xxx})"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) {xxx}"
	
	g = new peg.Grammar
	g.init "A <- ('foo') {yyy}"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) {yyy}"
	
	g = new peg.Grammar
	g.init "A <- ('foo' {xxx}) {yyy}"
	qa.assertEqual g.getRulePattern("A")._str,  "Choice() {yyy}"    + _NL +
	                                            " Literal(foo) {xxx}"
	
	g = new peg.Grammar
	g.init "A <- ('foo' <xxx>)"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) <xxx>"
	
	g = new peg.Grammar
	g.init "A <- ('foo') <yyy>"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) <yyy>"
	
	g = new peg.Grammar
	g.init "A <- ('foo' <xxx>) <yyy>"
	qa.assertEqual g.getRulePattern("A")._str,  "Choice() <yyy>"    + _NL +
	                                            " Literal(foo) <xxx>"
	
	g = new peg.Grammar
	g.init "A <- ('foo' {xxx}) <yyy>"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) <yyy> {xxx}"
	
	g = new peg.Grammar
	g.init "A <- ('foo' <xxx>) {yyy}"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(foo) <xxx> {yyy}"
end function


testOptimizeChoiceToCharSet = function
	g = new peg.Grammar
	g.init "A<-[a]"
	qa.assertEqual g.getRulePattern("A")._str,  "CharSet(a)"
	
	g = new peg.Grammar
	g.init "A<-[abc]"
	qa.assertEqual g.getRulePattern("A")._str,  "CharSet(abc)"
	
	g = new peg.Grammar
	g.init "A<- 'a' / 'b' / 'c'"
	qa.assertEqual g.getRulePattern("A")._str,  "CharSet(abc)"
	
	g = new peg.Grammar
	g.init "A<- 'a' {xxx}"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(a) {xxx}"
	
	g = new peg.Grammar
	g.init "A<- 'a' {xxx} / 'b' / 'c'"
	qa.assertEqual g.getRulePattern("A")._str,  "Choice()"          + _NL +
	                                            " Literal(a) {xxx}" + _NL +
	                                            " CharSet(bc)"
	
	g = new peg.Grammar
	g.init "A<- 'a' <xxx>"
	qa.assertEqual g.getRulePattern("A")._str,  "Literal(a) <xxx>"
	
	g = new peg.Grammar
	g.init "A<- 'a' <xxx> / 'b' / 'c'"
	qa.assertEqual g.getRulePattern("A")._str,  "Choice()"          + _NL +
	                                            " Literal(a) <xxx>" + _NL +
	                                            " CharSet(bc)"
end function

