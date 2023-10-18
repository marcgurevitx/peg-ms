// expandVars("  $foo  ", {"foo": "bar"})  =>  "  bar  "


import "mapUtil"
import "peg"


_grammar = peg.Grammar
_grammar.init   "  expandVars   <-  text  ( var  text ) *  " +
                "  text         <-  ( ! var  . ) * {}  " +
                "  var          <-  dollar  /  dollarBrace  /  dollarParen  /  percent  " +
                "  dollar       <-  '$'  varName {varName}  " +
                "  dollarBrace  <-  '${'  space  varName {varName}  space  '}'  " +
                "  dollarParen  <-  '$('  space  varName {varName}  space  ')'  " +
                "  percent      <-  '%'  varName {varName}  '%'  " +
                "  varName      <-  [a-zA-Z_]  [a-zA-Z_0-9]*  " +
                "  space        <-  [ \t]*  ",
                "expandVars"


// _varName: Captures the value of `vars[varName]`.
// Manages missing values and cycles.
_varName = function(match, subcaptures, arg, ctx)
	name = match.fragment
	if arg.cache.get(name) != null then return arg.cache[name]
	arg.cache[name] = arg.recurring
	if arg.vars.get(name) == null then return arg.missing
	value = arg.vars[name]
	res = _grammar.parse(value, 0, arg).captures.list.join("")
	arg.cache[name] = res
	return res
end function
_grammar.addCaptureAction "varName", @_varName


// expandVars: Substitutes occurrences of $VAR in a string using the `vars` map.
expandVars = function(str, vars, params=null)
	if params == null then params = {}
	if params.get("missing") == null then params.missing = ""
	if params.get("recurring") == null then params.recurring = ""
	
	arg = params + {}
	arg.vars = vars
	arg.cache = {}
	
	return _grammar.parse(str, 0, arg).captures.list.join("")
end function


testExpandVars = function
	import "qa"
	
	res = expandVars("", {})
	qa.assertEqual res, ""
	
	res = expandVars("..$foo..", {"foo": "hi"})
	qa.assertEqual res, "..hi.."
	
	res = expandVars("..${ foo }..", {"foo": "hi"})
	qa.assertEqual res, "..hi.."
	
	res = expandVars("..$( foo )..", {"foo": "hi"})
	qa.assertEqual res, "..hi.."
	
	res = expandVars("..%foo%..", {"foo": "hi"})
	qa.assertEqual res, "..hi.."
	
	res = expandVars("..$foo..", {"foo": "--$bar--", "bar": "  $baz  ", "baz": "hi"})
	qa.assertEqual res, "..--  hi  --.."
	
	res = expandVars("..$foo..", {"foo": "--$foo--"})
	qa.assertEqual res, "..----.."
	
	res = expandVars("..$foo..", {"foo": "--$foo--"}, {"recurring": "?"})
	qa.assertEqual res, "..--?--.."
	
	res = expandVars("..$foo..", {})
	qa.assertEqual res, "...."
	
	res = expandVars("..$foo..", {}, {"missing": "!"})
	qa.assertEqual res, "..!.."
	
	i = 1
	_f = function
		outer.i += 1
		return ["hi", "bye"][i % 2]
	end function
	res = expandVars("..$foo..$foo..", {"foo": @_f})
	qa.assertEqual res, "..hi..hi.."
	
	res = expandVars("..$ foo..", {"foo": "hi"})
	qa.assertEqual res, "..$ foo.."
	
	res = expandVars("..${ foo..", {"foo": "hi"})
	qa.assertEqual res, "..${ foo.."
	
	res = expandVars("..$( foo..", {"foo": "hi"})
	qa.assertEqual res, "..$( foo.."
	
	res = expandVars("..%foo..", {"foo": "hi"})
	qa.assertEqual res, "..%foo.."
end function


if refEquals(locals, globals) then
	print " * expandVars.ms: ", ""
	testExpandVars
	print "OK"
end if

