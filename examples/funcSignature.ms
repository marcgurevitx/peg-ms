// Parse function signatures: FUNCTION(a, b=null)


// ensureImport: Imports a module and caches it in `globals`.
// Use an existing function if present.
// (Some platforms don't have this or the user might have implemented their own `ensureImport`.)
if globals.hasIndex("ensureImport") then
	ensureImport = @globals.ensureImport
else
	// from /sys/lib/importUtil.ms
	ensureImport = function(moduleName)
		if globals.hasIndex(moduleName) then return
		globals[moduleName] = "PENDING"	// (module is being imported now)
		import moduleName
		globals[moduleName] = locals[moduleName]
	end function
end if


ensureImport "peg"


_noVal = {}


// abort: Prints error message and exits.
// Uses an existing function if present.
if globals.hasIndex("abort") then
	abort = @globals.abort
else
	maxStack = 15
	extraStack = 3
	abort = function(msg)
		print msg
		s = stackTrace[:-1]
		if s.len > maxStack + extraStack then s = s[:maxStack/2] + ["... (+" + (s.len - maxStack) + " lines) ..."] + s[-maxStack/2:]
		s.apply @print
		exit
	end function
end if


grammar = new peg.Grammar
grammar.init    "  signature    :   ( 'FUNCTION'  /  'function' )  '('  paramList ?  ')'  ! .  " +
                "  paramList    <-  param  ( ', '  param ) *  " +
                "  param        <-  ( identifier {identifier:}  ( '='  default {default:0} ) ? ) {param}  " +
                "  default      <-  'null' {null}  /  string {string}  /  number {number}  " +
                "  string       <-  '""'  char *  '""'  " +
                "  char         <-  '""""'  /  ! '""'  .  " +
                "  number       <-  '-' ?  [0-9] +  ( '.'  [0-9] + ) ?  ( [Ee]  [+-] ?  [0-9] + ) ?  " +
                "  identifier   <-  [a-zA-Z_]  [a-zA-Z0-9_] *  "


grammar.capture "null", function(match, subcaptures, arg, ctx)
	rv = {}
	rv.raw = "null"
	rv.value = null
	return rv
end function


grammar.capture "string", function(match, subcaptures, arg, ctx)
	rv = {}
	rv.raw = match.fragment
	rv.value = match.fragment[1:-1].replace("""""", """")
	return rv
end function


grammar.capture "number", function(match, subcaptures, arg, ctx)
	rv = {}
	rv.raw = match.fragment
	rv.value = match.fragment.val
	return rv
end function


paramCap = function(match, subcaptures, arg, ctx)
	rv = {}
	rv.paramName = subcaptures.map.identifier
	rv.default = subcaptures.map.get("default", _noVal)
	return rv
end function
grammar.capture "param", @paramCap


// ?
FunctionSignature = {}
FunctionSignature._name = "FunctionSignature"
FunctionSignature.signatureStr = null
FunctionSignature.paramList = null


FunctionSignature.init = function(signatureStr)
	self.signatureStr = signatureStr
	parseResult = grammar.parse(signatureStr)
	if parseResult.length == null then abort "Bad signature"
	self.paramList = parseResult.captures.list
end function


FunctionSignature.nParams = function
	return self.paramList.len
end function


FunctionSignature.asMap = function
	m = {}
	for param in self.paramList
		key = param.paramName
		value = param.get("default")
		if refEquals(value, _noVal) then
			m[key] = null
		else
			m[key] = value.value
		end if
	end for
	return m
end function


FunctionSignature.getParamName = function(index)
	param = self.paramList[index]
	return param.paramName
end function


FunctionSignature.hasDefault = function(index)
	param = self.paramList[index]
	value = param.get("default")
	return not refEquals(value, _noVal)
end function


FunctionSignature.getDefaultValue = function(index, fallback=null)
	param = self.paramList[index]
	value = param.get("default")
	if refEquals(value, _noVal) then return @fallback
	return value.value
end function


FunctionSignature.getDefaultRaw = function(index, fallback=null)
	param = self.paramList[index]
	value = param.get("default")
	if refEquals(value, _noVal) then return @fallback
	return value.raw
end function


FunctionSignature.hasSelf = function(index=null)
	if index == null then
		for param in self.paramList
			name = param.paramName
			if name == "self" then return true
		end for
		return false
	else
		return self.paramList[index].paramName == "self"
	end if
end function


testFuncSignature = function
	import "qa"
	
	f = function ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 0
	qa.assertEqual s.asMap, {}
	
	f = function() ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 0
	qa.assertEqual s.asMap, {}
	
	f = function(foo) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 1
	qa.assertEqual s.asMap, {"foo": null}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), false
	qa.assertEqual s.getDefaultValue(0), null
	qa.assertEqual s.getDefaultValue(0, "noval"), "noval"
	qa.assertEqual s.getDefaultRaw(0), null
	qa.assertEqual s.getDefaultRaw(0, "noval"), "noval"
	
	f = function(foo, bar) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"foo": null, "bar": null}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), false
	qa.assertEqual s.getDefaultValue(0), null
	qa.assertEqual s.getDefaultValue(0, "noval"), "noval"
	qa.assertEqual s.getDefaultRaw(0), null
	qa.assertEqual s.getDefaultRaw(0, "noval"), "noval"
	qa.assertEqual s.getParamName(1), "bar"
	qa.assertEqual s.hasDefault(1), false
	qa.assertEqual s.getDefaultValue(1), null
	qa.assertEqual s.getDefaultValue(1, "noval"), "noval"
	qa.assertEqual s.getDefaultRaw(1), null
	qa.assertEqual s.getDefaultRaw(1, "noval"), "noval"
	
	f = function(foo=42, bar) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"foo": 42, "bar": null}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), true
	qa.assertEqual s.getDefaultValue(0), 42
	qa.assertEqual s.getDefaultValue(0, "noval"), 42
	qa.assertEqual s.getDefaultRaw(0), "42"
	qa.assertEqual s.getDefaultRaw(0, "noval"), "42"
	qa.assertEqual s.getParamName(1), "bar"
	qa.assertEqual s.hasDefault(1), false
	qa.assertEqual s.getDefaultValue(1), null
	qa.assertEqual s.getDefaultValue(1, "noval"), "noval"
	qa.assertEqual s.getDefaultRaw(1), null
	qa.assertEqual s.getDefaultRaw(1, "noval"), "noval"
	
	f = function(foo, bar="hi") ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"foo": null, "bar": "hi"}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), false
	qa.assertEqual s.getDefaultValue(0), null
	qa.assertEqual s.getDefaultValue(0, "noval"), "noval"
	qa.assertEqual s.getDefaultRaw(0), null
	qa.assertEqual s.getDefaultRaw(0, "noval"), "noval"
	qa.assertEqual s.getParamName(1), "bar"
	qa.assertEqual s.hasDefault(1), true
	qa.assertEqual s.getDefaultValue(1), "hi"
	qa.assertEqual s.getDefaultValue(1, "noval"), "hi"
	qa.assertEqual s.getDefaultRaw(1), """hi"""
	qa.assertEqual s.getDefaultRaw(1, "noval"), """hi"""
	
	f = function(foo="a, b", bar="hi ""bob""") ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"foo": "a, b", "bar": "hi ""bob"""}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), true
	qa.assertEqual s.getDefaultValue(0), "a, b"
	qa.assertEqual s.getDefaultValue(0, "noval"), "a, b"
	qa.assertEqual s.getDefaultRaw(0), """a, b"""
	qa.assertEqual s.getDefaultRaw(0, "noval"), """a, b"""
	qa.assertEqual s.getParamName(1), "bar"
	qa.assertEqual s.hasDefault(1), true
	qa.assertEqual s.getDefaultValue(1), "hi ""bob"""
	qa.assertEqual s.getDefaultValue(1, "noval"), "hi ""bob"""
	qa.assertEqual s.getDefaultRaw(1), """hi """"bob"""""""
	qa.assertEqual s.getDefaultRaw(1, "noval"), """hi """"bob"""""""
	
	f = function(foo=42, foo=43) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"foo": 43}
	qa.assertEqual s.getParamName(0), "foo"
	qa.assertEqual s.hasDefault(0), true
	qa.assertEqual s.getDefaultValue(0), 42
	qa.assertEqual s.getDefaultValue(0, "noval"), 42
	qa.assertEqual s.getDefaultRaw(0), "42"
	qa.assertEqual s.getDefaultRaw(0, "noval"), "42"
	qa.assertEqual s.getParamName(1), "foo"
	qa.assertEqual s.hasDefault(1), true
	qa.assertEqual s.getDefaultValue(1), 43
	qa.assertEqual s.getDefaultValue(1, "noval"), 43
	qa.assertEqual s.getDefaultRaw(1), "43"
	qa.assertEqual s.getDefaultRaw(1, "noval"), "43"
	
	f = function(self) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 1
	qa.assertEqual s.asMap, {"self": null}
	qa.assertEqual s.hasSelf, true
	qa.assertEqual s.hasSelf(0), true
	
	f = function(x, self) ; end function
	s = new FunctionSignature
	s.init str(@f)
	qa.assertEqual s.nParams, 2
	qa.assertEqual s.asMap, {"self": null, "x": null}
	qa.assertEqual s.hasSelf, true
	qa.assertEqual s.hasSelf(0), false
	qa.assertEqual s.hasSelf(-1), true
end function


if refEquals(locals, globals) then
	print " * funcSignature.ms: ", ""
	testFuncSignature
	print "OK"
end if
