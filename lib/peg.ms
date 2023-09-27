// Pattern-matching library for MiniScript.


// ensureImport: Imports module and caches it in globals.
if globals.hasIndex("ensureImport") then
	ensureImport = @globals.ensureImport
else
	// (stolen from /sys/lib/importUtil.ms)
	ensureImport = function(moduleName)
		if globals.hasIndex(moduleName) then return
		globals[moduleName] = "PENDING"	// (module is being imported now)
		import moduleName
		globals[moduleName] = locals[moduleName]
	end function
end if


ensureImport "listUtil"
ensureImport "mapUtil"
ensureImport "stringUtil"


if version.hostName == "Command-Line (Linux)" then _NL = char(10) else _NL = char(13)


maxFragment = 20
maxRest = 10


// abort: Prints error message and dies.
if globals.hasIndex("abort") then
	abort = @globals.abort
else
	abort = function(msg)
		print msg
		stackTrace.apply @print
		exit
	end function
end if


// hexVal: convert a hexadecimal string to a number.
if globals.hasIndex("hexVal") then
	hexVal = @globals.hexVal
else
	// (stolen from /sys/startup.ms)
	hexVal = function(hexstr)
		result = 0
		digits = "0123456789ABCDEF"
		for c in hexstr
			cval = digits.indexOf(c.upper)
			if cval < 0 then break
			result = result * 16 + cval
		end for
		return result
	end function
end if


// Tree: Abstract tree class.
// Base class for Pattern and Match.
Tree = {}
Tree._name = "Tree"
Tree._isInstance = false
Tree.children = null
Tree.BREAK = {}
Tree.CONTINUE = {}


Tree.init = function
	self._isInstance = true
	self.children = []
end function


Tree._str = function
	if not self._isInstance then return self._name + " class"
	lines = [self.nodeToStr]
	for node in self.children
		for line in node._str.split(_NL)
			lines.push " " + line
		end for
	end for
	return lines.join(_NL)
end function


Tree.nodeToStr = function
	contents = []
	for kv in self
		if ["__isa", "_isInstance", "children"].indexOf(@kv.key) != null then continue
		contents.push @kv.key + ": " + @kv.value
	end for
	return self._name + "(" + contents.join(", ") + ")"
end function


// checkInstance: Aborts if x is not instance of Tree class/subclass.
Tree._checkInstance = function(x)
	if not x isa Tree then abort "Expected Tree, got `" + x + "`."
	if not x._isInstance then abort "Expected instance, got `" + x._str + "`."
end function


// addChild: Appends child to list of subnodes of this node.
Tree.addChild = function(child)
	self._checkInstance child
	self.children.push child
end function


// getOnlyChild: Retrieves subnode if there's only one.
Tree.getOnlyChild = function
	if self.children.len != 1 then abort "Expected one child, got `" + self.children + "`"
	return self.children[0]
end function


// Error: Base class for syntax and semantic errors.
Error = {}
Error._name = "Error"
Error.message = null


Error.init = function(message)
	self.message = message
end function


Error._str = function
	return self._name + "({message})".fill(self)
end function


makeError = function(message)
	e = new Error
	e.init message
	return e
end function


// SyntaxError: Errors at matching time.
SyntaxError = new Error
SyntaxError._name = "SyntaxError"


SyntaxError.init = function(ruleName, start, index, fragment, rest, tag, _message=null)
	self.ruleName = ruleName
	self.start = start
	self.index = index
	self.fragment = fragment
	self.rest = rest
	self.tag = tag
	self._message = _message
	if self._message == null then
		m = self.tag
	else
		m = self._message
	end if
	length = self.index - self.start
	if rest.len == 0 then
		r = "EOS"
	else
		r = "`" + rest + "`"
	end if
	self.message = ("error: {m}" +
	                "; attempted to match rule `{ruleName}`" +
	                "; consumed {length} symbols starting at index {start}: `{fragment}`" +
	                "; failed from index {index}: {r}").fill(locals)
end function


makeSyntaxError = function(ruleName, start, index, fragment, rest, tag, _message=null)
	e = new SyntaxError
	e.init ruleName, start, index, fragment, rest, tag, _message
	return e
end function


// SemanticError: Errors raised by capture functions.
SemanticError = new Error
SemanticError._name = "SemanticError"


makeSemanticError = function(message)
	e = new SemanticError
	e.init message
	return e
end function


// Match: Result of matching a subject with a pattern.
// If the pattern has subpatterns, their individual matches are stored in children subnodes.
Match = new Tree
Match._name = "Match"
Match.start = null
Match.length = null
Match.fragment = null
Match.pattern = null
Match.capture = null


Match.init = function(start, length, fragment, pattern)
	super.init
	self.start = start
	self.length = length
	self.fragment = fragment
	self.pattern = pattern
end function


Match.nodeToStr = function
	if self.pattern then
		p = self.pattern.nodeToStr
	else
		p = ""
	end if
	if @self.capture != null then
		c = ", +"
	else
		c = ""
	end if
	return "Match({start}, {length}, {fragment}, {p}{c})".fill(locals + self)
end function


// captureValues: Traverses Match tree and returns list of captured values.
// Only nodes that have .capture function produce values.
// Capture function signature should be .capture(match, subcaptures, arg)
// Predicates don't produce captures.
Match.captureValues = function(ctx, arg=null)
	if self.pattern isa And or self.pattern isa Not then return []
	caps = ctx.getSubcaptures(self)
	if caps == null then
		caps = []
		for child in self.children
			res = child.captureValues(ctx, arg)
			if res isa Error then return res
			caps += res
		end for
	end if
	if @self.capture != null then
		res = self.capture(self, caps, arg)
		if res isa Error then
			if res.__isa == Error then res.__isa = SemanticError  // transmogrifying to more specific type
			return res
		end if
		if not refEquals(res, caps) then caps = [res]
	end if
	return caps
end function


makeMatch = function(start, length, fragment, pattern)
	m = new Match
	m.init start, length, fragment, pattern
	return m
end function


// Pattern: Base class for patterns -- the grammar elements that match particular syntax.
// If the pattern has subpatterns, they're stored as children nodes.
Pattern = new Tree
Pattern._name = "Pattern"
Pattern.matchTimeTag = null
Pattern.captureTag = null


// matchSyntax: Matches a string and a pattern.
// `ctx` -- a ParsingContext object
// `arg` -- optional data passed to `Grammar.parse`
// Returns a Match object on successful match or null on failure.
Pattern.matchSyntax = function(ctx, arg=null)
	match = self._matchSyntaxLogic(ctx, arg)
	
	if self.matchTimeTag != null then
		if ctx.grammar != null then
			action = ctx.grammar.findMatchTimeAction(ctx.ruleName, self.matchTimeTag)
		else
			action = self.matchTimeTag
		end if
		if @action isa funcRef then
			subcaptures = function
				if match == null then return []
				caps = ctx.getSubcaptures(match)
				if caps == null then
					caps = match.captureValues(ctx, arg)
					ctx.putSubcaptures(match, caps)
				end if
				return caps
			end function
			match = action(match, @subcaptures, arg, ctx)
		else if match == null then
			ctx.addSyntaxError self.matchTimeTag, action
		end if
	end if
	
	if match != null and self.captureTag != null then
		if self.captureTag == "" then
			match.capture = function(match, subcaptures, arg)
				subcaptures.push match.fragment
				return subcaptures
			end function
		else if ctx.grammar != null then
			match.capture = ctx.grammar.findCaptureAction(ctx.ruleName, self.captureTag)
			if @match.capture == null then abort "Capture function not defined for {" + self.captureTag + "}"
		else
			abort "No grammar to search for capture function `" + self.captureTag + "`"
		end if
	end if
	
	return match
end function


// _matchSyntaxLogic: Implements specific matching logic for a pattern.
// Pattern subclasses override this method.
// Has the same parameters and a return value as `Pattern.matchSyntax`.
// If the pattern has subpatterns, this method is responsible to call their corresponding .matchSyntax method.
Pattern._matchSyntaxLogic = function(ctx, arg=null)
	
	abort "This method should be overridden"
	
end function


// withCaptureTag: Appends a capture tag to a pattern.
// If a pattern has a capture tag, the corresponding match(es) will be passed to a capture action of the same name.
Pattern.withCaptureTag = function(captureTag="")
	self.captureTag = captureTag
	return self
end function


// withMatchTimeTag: Appends a match-time tag to a pattern.
// If a pattern has a match-time tag, the corresponding match(es) will be passed to a match-time action of the same name.
Pattern.withMatchTimeTag = function(matchTimeTag)
	self.matchTimeTag = matchTimeTag
	return self
end function


// tags: Returns pattern's tags formatted as a string.
Pattern.tags = function
	rv = ""
	if self.captureTag != null then rv += " {" + self.captureTag + "}"
	if self.matchTimeTag != null then rv += " :" + self.matchTimeTag + ":"
	return rv
end function


// AnyChar: Pattern that matches a single character:  .
// Fails on empty lines or after end of line.
AnyChar = new Pattern
AnyChar._name = "AnyChar"


AnyChar.nodeToStr = function
	return "AnyChar()" + self.tags
end function


// _matchSyntaxLogic: Matches one character.
AnyChar._matchSyntaxLogic = function(ctx, arg=null)
	fragment = ctx.subject[ctx.index : ctx.index + 1]
	if fragment.len == 0 then
		return null
	end if
	match = new Match
	match.init ctx.index, 1, fragment, self
	return match
end function


makeAnyChar = function
	p = new AnyChar
	p.init
	return p
end function


// CharSet: Pattern that matches one character from a character set:  [abc]
CharSet = new Pattern
CharSet._name = "CharSet"
CharSet.characters = null


CharSet.init = function(characters)
	super.init
	self.characters = characters
end function


CharSet.nodeToStr = function
	return "CharSet({characters})".fill(self) + self.tags
end function


// _matchSyntaxLogic: Matches one character from a character set.
CharSet._matchSyntaxLogic = function(ctx, arg=null)
	fragment = ctx.subject[ctx.index : ctx.index + 1]
	if fragment.len == 0 or self.characters.indexOf(fragment) == null then
		return null
	end if
	match = new Match
	match.init ctx.index, 1, fragment, self
	return match
end function


makeCharSet = function(characters)
	p = new CharSet
	p.init characters
	return p
end function


// CharRange: Pattern that matches one character from a character range:  [a-z]
CharRange = new Pattern
CharRange._name = "CharRange"
CharRange.from = null
CharRange.to = null


// init: Initializes instance of CharRange.
CharRange.init = function(from, to)
	super.init
	self.from = from
	self.to = to
end function


CharRange.nodeToStr = function
	return "CharRange({from}, {to})".fill(self) + self.tags
end function


// _matchSyntaxLogic: Matches one character from a character range.
CharRange._matchSyntaxLogic = function(ctx, arg=null)
	fragment = ctx.subject[ctx.index : ctx.index + 1]
	if not (self.from.code <= fragment.code <= self.to.code) then
		return null
	end if
	match = new Match
	match.init ctx.index, 1, fragment, self
	return match
end function


makeCharRange = function(from, to)
	p = new CharRange
	p.init from, to
	return p
end function


// Literal: Pattern that matches an exact string:  'foo' or "foo"
Literal = new Pattern
Literal._name = "Literal"
Literal.string_ = null


Literal.init = function(string_)
	super.init
	self.string_ = string_
end function


Literal.nodeToStr = function
	return "Literal({string_})".fill(self) + self.tags
end function


// _matchSyntaxLogic: Matches an exact string.
Literal._matchSyntaxLogic = function(ctx, arg=null)
	fragment = ctx.subject[ctx.index : ctx.index + self.string_.len]
	if fragment != self.string_ then
		return null
	end if
	match = new Match
	match.init ctx.index, self.string_.len, fragment, self
	return match
end function


makeLiteral = function(string_)
	p = new Literal
	p.init string_
	return p
end function


// And: Pattern that succeeds if its subpattern succeeds (AND-predicate):  & PATT
// It doesn't consume input and doesn't produce capture values.
And = new Pattern
And._name = "And"


And.init = function(pattern)
	super.init
	self.addChild pattern
end function


And.nodeToStr = function
	return "And()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if the subpattern matches but consumes no input.
And._matchSyntaxLogic = function(ctx, arg=null)
	pattern = self.getOnlyChild
	subm = pattern.matchSyntax(ctx + {"insidePredicate": true}, arg)
	if subm == null then
		return null
	end if
	match = new Match
	match.init ctx.index, 0, "", self
	match.addChild subm
	return match
end function


makeAnd = function(pattern)
	p = new And
	p.init pattern
	return p
end function


// Not: Pattern that succeeds if its subpattern fails (NOT-predicate):  ! PATT
// It doesn't consume characters and doesn't produce capture values.
Not = new Pattern
Not._name = "Not"


Not.init = function(pattern)
	super.init
	self.addChild pattern
end function


Not.nodeToStr = function
	return "Not()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if the subpattern fails, consumes no input.
Not._matchSyntaxLogic = function(ctx, arg=null)
	pattern = self.getOnlyChild
	subm = pattern.matchSyntax(ctx + {"insidePredicate": true}, arg)
	if subm != null then
		return null
	end if
	match = new Match
	match.init ctx.index, 0, "", self
	return match
end function


makeNot = function(pattern)
	p = new Not
	p.init pattern
	return p
end function


// Choice: Pattern that succeeds if one of its subpatterns succeeds:  PATT1  /  PATT2  /  ...
Choice = new Pattern
Choice._name = "Choice"


Choice.init = function(patterns)
	super.init
	for pattern in patterns
		self.addChild pattern
	end for
end function


Choice.nodeToStr = function
	return "Choice()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if one of subpattern succeeds.
Choice._matchSyntaxLogic = function(ctx, arg=null)
	for pattern in self.children
		subm = pattern.matchSyntax(ctx, arg)
		if subm != null then
			match = new Match
			match.init ctx.index, subm.length, subm.fragment, self
			match.addChild subm
			return match
		end if
	end for
	return null
end function


makeChoice = function(patterns)
	p = new Choice
	p.init patterns
	return p
end function


// Concat: Pattern that succeeds if all its subpatterns match in succession:  PATT1  PATT2  ...
Concat = new Pattern
Concat._name = "Concat"


Concat.init = function(patterns)
	super.init
	for pattern in patterns
		self.addChild pattern
	end for
end function


Concat.nodeToStr = function
	return "Concat()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if all the subpatterns match in succession.
Concat._matchSyntaxLogic = function(ctx, arg=null)
	subms = []
	index = ctx.index
	for pattern in self.children
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then
			return null
		end if
		subms.push subm
		index += subm.length
	end for
	length = index - ctx.index
	fragment = ctx.subject[ctx.index : index]
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


makeConcat = function(patterns)
	p = new Concat
	p.init patterns
	return p
end function


// Optional: Pattern that succeeds if one or zero occurrences of its subpattern match:  PATT ?
Optional = new Pattern
Optional._name = "Optional"


Optional.init = function(pattern)
	super.init
	self.addChild pattern
end function


Optional.nodeToStr = function
	return "Optional()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if one or zero occurrences of the subpattern match.
Optional._matchSyntaxLogic = function(ctx, arg=null)
	pattern = self.getOnlyChild
	subm = pattern.matchSyntax(ctx, arg)
	match = new Match
	if subm == null then
		match.init ctx.index, 0, "", self
	else
		match.init ctx.index, subm.length, subm.fragment, self
		match.addChild subm
	end if
	return match
end function


makeOptional = function(pattern)
	p = new Optional
	p.init pattern
	return p
end function


// ZeroOrMore: Pattern that succeeds if zero or more occurrences of its subpattern match:  PATT *
ZeroOrMore = new Pattern
ZeroOrMore._name = "ZeroOrMore"


ZeroOrMore.init = function(pattern)
	super.init
	self.addChild pattern
end function


ZeroOrMore.nodeToStr = function
	return "ZeroOrMore()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if zero or more occurrences of the subpattern match.
ZeroOrMore._matchSyntaxLogic = function(ctx, arg=null)
	pattern = self.getOnlyChild
	subms = []
	index = ctx.index
	while true
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then break
		subms.push subm
		index += subm.length
	end while
	length = index - ctx.index
	fragment = ctx.subject[ctx.index : index]
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


makeZeroOrMore = function(pattern)
	p = new ZeroOrMore
	p.init pattern
	return p
end function


// OneOrMore: Pattern that succeeds if one or more occurrences of its subpattern match:  PATT +
OneOrMore = new Pattern
OneOrMore._name = "OneOrMore"


OneOrMore.init = function(pattern)
	super.init
	self.addChild pattern
end function


OneOrMore.nodeToStr = function
	return "OneOrMore()" + self.tags
end function


// _matchSyntaxLogic: Succeeds if zero or more occurrences of the subpattern match.
OneOrMore._matchSyntaxLogic = function(ctx, arg=null)
	pattern = self.getOnlyChild
	subms = []
	index = ctx.index
	while true
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then break
		subms.push subm
		index += subm.length
	end while
	if subms.len == 0 then
		return null
	end if
	length = index - ctx.index
	fragment = ctx.subject[ctx.index : index]
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


makeOneOrMore = function(pattern)
	p = new OneOrMore
	p.init pattern
	return p
end function


// ParseContext: Collection of data associated with a single call to `Grammar.parse`.
ParseContext = {}
ParseContext._name = "ParseContext"
ParseContext.cachedSubcaptures = null
ParseContext.grammar = null
ParseContext.index = null
ParseContext.insidePredicate = false
ParseContext.ruleName = null
ParseContext.ruleStart = null
ParseContext.subject = null
ParseContext.syntaxErrors = null


ParseContext.init = function(subject, index)
	self.subject = subject
	self.index = index
	self.cachedSubcaptures = []
	self.syntaxErrors = []
end function


// addSyntaxError: Appends a syntax error to the list of errors.
ParseContext.addSyntaxError = function(matchTimeTag, _message)
	if self.insidePredicate then return
	fragment = self.subject[self.ruleStart : self.index].ellideMiddle(maxFragment)
	rest = self.subject[self.index : ].ellideEnd(maxRest)
	self.syntaxErrors.push makeSyntaxError(self.ruleName, self.ruleStart, self.index, fragment, rest, matchTimeTag, _message)
end function


// putSubcaptures: Cache a list of captures as the subcaptures produced inside a particular match object.
ParseContext.putSubcaptures = function(match, subcaptures)
	self.cachedSubcaptures.push [match, subcaptures]
end function


// getSubcaptures: Retrives a list of captures that was previously cached by .putSubcaptures.
ParseContext.getSubcaptures = function(match)
	for elem in self.cachedSubcaptures
		if not refEquals(elem[0], match) then continue
		return elem[1]
	end for
	return null
end function


makeParseContext = function(subject, index)
	c = new ParseContext
	c.init subject, index
	return c
end function


// ParseResult: Collection of data that represents the result of a call to `Grammar.parse`.
ParseResult = {}
ParseResult._name = "ParseResult"
ParseResult.match = null
ParseResult.length = null
ParseResult.errors = null
ParseResult.captures = null


ParseResult.init = function
	self.errors = []
	self.captures = []
end function


ParseResult._str = function
	if self.length == null then
		l = "null"
	else
		l = self.length
	end if
	if self.match == null then
		m = "null"
	else
		m = self.match.nodeToStr + "..."
	end if
	return "ParseResult(length: {l}, match: {m}, errors: {errors}, captures: {captures})".fill(locals + self)
end function


// capture: Returns one capture from a list of captures if there's only one element, otherwise returns null.
ParseResult.capture = function
	if self.captures.len == 1 then return self.captures[0]
	return null
end function


makeParseResult = function
	r = new ParseResult
	r.init
	return r
end function


// Grammar: Collection of parsing rules:  RULE1  <-  PATT1  RULE2  <-  PATT2
// The main class of the `peg` library.
Grammar = new Pattern
Grammar._name = "Grammar"
Grammar.rules = null
Grammar.ruleOrder = null
Grammar.defaultRule = null
Grammar.captureActions = null
Grammar.matchTimeActions = null


// init: Initializes a grammar.
// `pegString` -- a grammar in PEG format.
// `defaultRuleName` -- the name of the rule, that will be matched first on the call to `Grammar.parse`.
Grammar.init = function(pegString=null, defaultRuleName=null)
	super.init
	self.pegString = pegString
	if self.pegString == null then
		self.rules = {}
		self.ruleOrder = []
	else
		rulesCapture = self._parsePegString(self.pegString)
		self.rules = rulesCapture.rules
		self.ruleOrder = rulesCapture.ruleOrder
	end if
	self.captureActions = {}
	self.matchTimeActions = {}
	if defaultRuleName != null then self.setDefaultRule defaultRuleName
end function


// _parsePegString: Parses grammar in PEG format and returns defined rules and their associated pattern.
Grammar._parsePegString = function(pegString)
	arg = {}
	arg.ruleNames = {}
	res = pegGrammar.parse(self.pegString, 0, arg)
	if res.length == null then
		reasons = []
		for err in res.errors
			reasons.push err.message
		end for
		abort "Bad grammar; possible reasons: " + reasons
	end if
	return res.capture
end function


Grammar._str = function
	if not self._isInstance then return self._name + " class"
	lines = [self.nodeToStr]
	for ruleName in self.ruleOrder
		lines.push " " + ruleName + "->"
		for line in self.rules[ruleName]._str.split(_NL)
			lines.push "  " + line
		end for
	end for
	return lines.join(_NL)
end function


Grammar.nodeToStr = function
	return "Grammar(" + self.getDefaultRule + ")" + self.tags
end function


// addRule: Adds a new rule to a grammar.
Grammar.addRule = function(ruleName, pattern)
	if not ruleName isa string then abort "Expected string, got `" + ruleName + "`"
	Pattern._checkInstance pattern
	if self.rules.hasIndex(ruleName) then abort "Rule already defined `" + ruleName + "`"
	self.rules[ruleName] = pattern
	self.ruleOrder.push ruleName
end function


// setDefaultRule: Sets one of existing rules as "default".
// Default rule is matched first on the call to `Grammar.parse`.
Grammar.setDefaultRule = function(ruleName)
	if not self.rules.hasIndex(ruleName) then abort "Unable to set default rule, not found `" + ruleName + "`"
	self.defaultRule = ruleName
end function


// getDefaultRule: Returns the name of the default rule (or the name of the only rule).
Grammar.getDefaultRule = function
	if self.defaultRule != null then return self.defaultRule
	if self.rules.len == 1 then return self.ruleOrder[0]
	return null
end function


// _matchSyntaxLogic: Succeeds if grammar's default rule succeeds.
Grammar._matchSyntaxLogic = function(ctx, arg=null)
	ruleName = self.getDefaultRule
	if ruleName == null then abort "Unable to match syntax, default rule not set"
	pattern = self.rules[ruleName]
	subm = pattern.matchSyntax(ctx + {"grammar": self, "ruleName": ruleName, "ruleStart": ctx.index}, arg)
	if subm == null then
		return null
	end if
	match = new Match
	match.init ctx.index, subm.length, subm.fragment, self
	match.addChild subm
	return match
end function


// getRulePattern: Returns the pattern of one of rules.
Grammar.getRulePattern = function(ruleName, arg)
	if self.rules.hasIndex(ruleName) then return self.rules[ruleName]
	pattern = arg.get(ruleName)
	if pattern == null then abort "Pattern not found for rule `" + ruleName + "`"
	if not pattern isa Pattern then abort "Expected Pattern subclass, got `" + pattern + "`"
	return pattern
end function


// addCaptureAction: Registers a capture action.
// The callback will later be associated with a match if that match has the corresponding capture tag.
// The callback should have a signature: f(match, subcaptures, arg) -> capture.
// Optional first arg is the name of the rule whose definition contains the tag.
Grammar.addCaptureAction = function(arg1, arg2, arg3=null)
	if arg3 == null then
		ruleName = null
		tag = arg1
		action = @arg2
	else
		ruleName = arg1
		tag = arg2
		action = @arg3
		if not ruleName isa string then abort "Expected string, got `" + ruleName + "`"
	end if
	if not tag isa string then abort "Expected string, got `" + tag + "`"
	self.captureActions[[ruleName, tag]] = @action
end function


// findCaptureAction: Returns the callback previously registered with `.addCaptureAction`.
Grammar.findCaptureAction = function(ruleName, captureTag)
	_NOVAL = {}
	action = self.captureActions.get([ruleName, captureTag], _NOVAL)
	if not refEquals(@action, _NOVAL) then return @action
	return self.captureActions.get([null, captureTag])
end function


// addMatchTimeAction: Registers a match-time action.
// The callback will be invoked in the match time when the tagged pattern either succeeds or fails.
// The callback should have a signature: f(match, subcaptures, arg, ctx) -> capture.
// If the callback is a string, then it will be used as an error message if the match fails.
// Optional first arg is the name of the rule whose definition contains the tag.
Grammar.addMatchTimeAction = function(arg1, arg2, arg3=null)
	if arg3 == null then
		ruleName = null
		tag = arg1
		errorMessage = @arg2
	else
		ruleName = arg1
		tag = arg2
		errorMessage = @arg3
		if not ruleName isa string then abort "Expected string, got `" + ruleName + "`"
	end if
	if not tag isa string then abort "Expected string, got `" + tag + "`"
	self.matchTimeActions[[ruleName, tag]] = @errorMessage
end function


// findMatchTimeAction: Returns the callback previously registered with `.addMatchTimeAction`.
Grammar.findMatchTimeAction = function(ruleName, matchTimeTag)
	_NOVAL = {}
	action = self.matchTimeActions.get([ruleName, matchTimeTag], _NOVAL)
	if not refEquals(@action, _NOVAL) then return @action
	return self.matchTimeActions.get([null, matchTimeTag])
end function


// parse: Matches a string and a grammar and returns an object of ParseResult class.
Grammar.parse = function(subject, start=null, arg=null)
	if start == null then start = 0
	res = makeParseResult
	ctx = makeParseContext(subject, start)
	res.match = self.matchSyntax(ctx, arg)
	res.errors = ctx.syntaxErrors
	if res.match == null then
		return res
	end if
	captures = res.match.captureValues(ctx, arg)
	if captures isa Error then
		err = captures
		if err.__isa == Error then err.__isa = SemanticError
		res.errors.push err
		return res
	end if
	res.length = res.match.length
	res.captures = captures
	return res
end function


makeGrammar = function(pegString=null, defaultRuleName=null)
	g = new Grammar
	g.init pegString, defaultRuleName
	return g
end function


// RuleRef: Pattern that succeeds if the grammar rule of that name succeeds:  Foo
RuleRef = new Pattern
RuleRef._name = "RuleRef"
RuleRef.ruleName = null


RuleRef.init = function(ruleName)
	super.init
	self.ruleName = ruleName
end function


RuleRef.nodeToStr = function
	return "RuleRef(" + self.ruleName + ")" + self.tags
end function


// _matchSyntaxLogic: Succeeds if the grammar rule of that name succeeds.
RuleRef._matchSyntaxLogic = function(ctx, arg=null)
	pattern = ctx.grammar.getRulePattern(self.ruleName, arg)
	subm = pattern.matchSyntax(ctx + {"ruleName": self.ruleName, "ruleStart": ctx.index}, arg)
	if subm == null then
		return null
	end if
	match = new Match
	match.init ctx.index, subm.length, subm.fragment, self
	match.addChild subm
	return match
end function


makeRuleRef = function(ruleName)
	p = new RuleRef
	p.init ruleName
	return p
end function


// _makePegGrammar: Build a grammar object that parses PEGs.
_makePegGrammar = function
	abort               = @outer.abort
	hexVal              = @outer.hexVal
	makeSemanticError   = @outer.makeSemanticError
	makeAnd             = @outer.makeAnd
	makeAnyChar         = @outer.makeAnyChar
	makeChoice          = @outer.makeChoice
	makeConcat          = @outer.makeConcat
	makeLiteral         = @outer.makeLiteral
	makeNot             = @outer.makeNot
	makeOneOrMore       = @outer.makeOneOrMore
	makeOptional        = @outer.makeOptional
	makeCharRange       = @outer.makeCharRange
	makeRuleRef         = @outer.makeRuleRef
	makeZeroOrMore      = @outer.makeZeroOrMore
	
	
	g = makeGrammar
	
	
	// Comment  <-  '#'  ( ! ( <char(10)>  /  <char(13)> )  . ) *  ( <char(10)>  /  <char(13)>  /  !. )
	
	g.addRule "Comment",
		makeConcat([
			makeLiteral("#"),
			makeZeroOrMore(
				makeConcat([
					makeNot(
						makeCharSet(char(10) + char(13))),
					makeAnyChar,
				])),
			makeChoice([
				makeCharSet(char(10) + char(13)),
				makeNot(
					makeAnyChar),
			]),
		])
	
	
	// Space  <-  ( Comment  /  ( ' '  /  <char(9)>  /  <char(10)>  /  <char(13)> ) ) *
	
	g.addRule "Space",
		makeZeroOrMore(
			makeChoice([
				makeRuleRef("Comment"),
				makeCharSet(" " + char(9) + char(10) + char(13)),
			]))
	
	
	// Identifier  <-  ( [a-zA-Z_]  [a-zA-Z_0-9] * ) {}  Space
	
	g.addRule "Identifier",
		makeConcat([
			makeConcat([
				makeChoice([
					makeCharRange("a", "z"),
					makeCharRange("A", "Z"),
					makeLiteral("_"),
				]),
				makeZeroOrMore(
					makeChoice([
						makeCharRange("a", "z"),
						makeCharRange("A", "Z"),
						makeLiteral("_"),
						makeCharRange("0", "9"),
					])),
			]).withCaptureTag,
			makeRuleRef("Space"),
		])
	
	
	// Escape  <-  '\\'  ( [tnr\[\]\'\"\\]  /  'u'  [0-9A-Fa-f]+ ) {escape}
	
	g.addRule "Escape",
		makeConcat([
			makeLiteral("\"),
			makeChoice([
				makeCharSet("tnr[]'""\"),
				makeConcat([
					makeLiteral("u"),
					makeOneOrMore(
						makeCharRange("0", "9")),
				]),
			]).withCaptureTag("escape"),
		])
	
	_escapeSemantics = function(match, subcaptures, arg)
		if match.fragment[0] == "u" then
			return char(hexVal(match.fragment[1:]))
		else if match.fragment[0] == "t" then
			return char(9)
		else if match.fragment[0] == "n" then
			return char(10)
		else if match.fragment[0] == "r" then
			return char(13)
		else
			return match.fragment[0]
		end if
	end function
	
	g.addCaptureAction "escape", @_escapeSemantics
	
	
	// CharClass  <-  '['  ( !']'  ( Escape  /  ( .  '-'  !']'  . ) {}  /  . {} ) ) + :noElems: {charClass}  ']' :noClosing:  Space
	
	g.addRule "CharClass",
		makeConcat([
			makeLiteral("["),
			makeOneOrMore(
				makeConcat([
					makeNot(
						makeLiteral("]")),
					makeChoice([
						makeRuleRef("Escape"),
						makeConcat([
							makeAnyChar,
							makeLiteral("-"),
							makeNot(
								makeLiteral("]")),
							makeAnyChar,
						]).withCaptureTag,
						makeAnyChar.withCaptureTag,
					]),
				])).withMatchTimeTag("noElems").withCaptureTag("charClass"),
			makeLiteral("]").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	_charClassSemantics = function(match, subcaptures, arg)
		elems = []
		for cap in subcaptures
			if cap.len == 1 then
				elems.push makeLiteral(cap)
			else if cap.len == 3 then
				elems.push makeCharRange(cap[0], cap[2])
			else
				abort "Strange class element: `" + cap + "`"
			end if
		end for
		return makeChoice(elems)
	end function
	
	g.addCaptureAction "charClass", @_charClassSemantics
	
	
	// Literal  <-  ( [']  ( ![']  ( Escape  /  . {} ) ) * {literal}  ['] :noClosing:  /  ["]  ( !["]  ( Escape  /  . {} ) ) * {literal}  ["] :noClosing: )  Space
	
	g.addRule "Literal",
		makeConcat([
			makeChoice([
				makeConcat([
					makeLiteral("'"),
					makeZeroOrMore(
						makeConcat([
							makeNot(
								makeLiteral("'")),
							makeChoice([
								makeRuleRef("Escape"),
								makeAnyChar.withCaptureTag,
							]),
						])).withCaptureTag("literal"),
					makeLiteral("'").withMatchTimeTag("noClosing"),
				]),
				makeConcat([
					makeLiteral(""""),
					makeZeroOrMore(
						makeConcat([
							makeNot(
								makeLiteral("""")),
							makeChoice([
								makeRuleRef("Escape"),
								makeAnyChar.withCaptureTag,
							]),
						])).withCaptureTag("literal"),
					makeLiteral("""").withMatchTimeTag("noClosing"),
				]),
			]),
			makeRuleRef("Space"),
		])
	
	_literalSemantics = function(match, subcaptures, arg)
		return makeLiteral(subcaptures.join(""))
	end function
	
	g.addCaptureAction "literal", @_literalSemantics
	
	
	// AnyChar  <-  '.' {anyChar}  Space
	
	g.addRule "AnyChar",
		makeConcat([
			makeLiteral(".").withCaptureTag("anyChar"),
			makeRuleRef("Space"),
		])
	
	_anyCharSemantics = function(match, subcaptures, arg)
		return makeAnyChar()
	end function
	
	g.addCaptureAction "anyChar", @_anyCharSemantics
	
	
	// Primary  <-  '('  Space  Pattern  ')'  Space  /  AnyChar  /  Literal  /  CharClass  /  Identifier {ruleRef}  !'<-'
	
	g.addRule "Primary",
		makeChoice([
			makeConcat([
				makeLiteral("("),
				makeRuleRef("Space"),
				makeRuleRef("Pattern"),
				makeLiteral(")"),
				makeRuleRef("Space"),
			]),
			makeRuleRef("AnyChar"),
			makeRuleRef("Literal"),
			makeRuleRef("CharClass"),
			makeConcat([
				makeRuleRef("Identifier").withCaptureTag("ruleRef"),
				makeNot(
					makeLiteral("<-")),
			]),
		])
	
	_ruleRefSemantics = function(match, subcaptures, arg)
		ruleName = subcaptures[-1]
		arg.ruleNames[ruleName] = true
		return makeRuleRef(ruleName)
	end function
	
	g.addCaptureAction "ruleRef", @_ruleRefSemantics
	
	
	// MatchTimeTag  <-  ':'  Space  Identifier ? {matchTimeTag}  ':' :noClosing:  Space
	
	g.addRule "MatchTimeTag",
		makeConcat([
			makeLiteral(":"),
			makeRuleRef("Space"),
			makeOptional(
				makeRuleRef("Identifier")).withCaptureTag("matchTimeTag"),
			makeLiteral(":").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	_matchTimeTagSemantics = function(match, subcaptures, arg)
		if subcaptures.len == 0 then tag = "" else tag = subcaptures[-1]
		return ":" + tag
	end function
	
	g.addCaptureAction "matchTimeTag", @_matchTimeTagSemantics
	
	
	// CaptureTag  <-  '{'  Space  Identifier ? {captureTag}  '}' :noClosing:  Space
	
	g.addRule "CaptureTag",
		makeConcat([
			makeLiteral("{"),
			makeRuleRef("Space"),
			makeOptional(
				makeRuleRef("Identifier")).withCaptureTag("captureTag"),
			makeLiteral("}").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	_captureTagSemantics = function(match, subcaptures, arg)
		if subcaptures.len == 0 then tag = "" else tag = subcaptures[-1]
		return "{" + tag
	end function
	
	g.addCaptureAction "captureTag", @_captureTagSemantics
	
	
	// WithSuffix  <-  ( Primary  ( [*+?] {}  Space  /  MatchTimeTag  /  CaptureTag ) * ) {withSuffix}
	
	g.addRule "WithSuffix",
		makeConcat([
			makeRuleRef("Primary"),
			makeZeroOrMore(
				makeChoice([
					makeConcat([
						makeCharSet("*+?").withCaptureTag,
						makeRuleRef("Space"),
					]),
					makeRuleRef("MatchTimeTag"),
					makeRuleRef("CaptureTag"),
				])),
		]).withCaptureTag("withSuffix")
	
	_withSuffixSemantics = function(match, subcaptures, arg)
		pattern = subcaptures[0]
		for suffix in subcaptures[1:]
			if suffix[0] == "*" then
				pattern = makeZeroOrMore(pattern)
			else if suffix[0] == "+" then
				pattern = makeOneOrMore(pattern)
			else if suffix[0] == "?" then
				pattern = makeOptional(pattern)
			else if suffix[0] == ":" then
				pattern.matchTimeTag = suffix[1:]
			else if suffix[0] == "{" then
				pattern.captureTag = suffix[1:]
			else
				abort "Strange suffix `" + suffix + "`"
			end if
		end for
		return pattern
	end function
	
	g.addCaptureAction "withSuffix", @_withSuffixSemantics
	
	
	// Alternative  <-  ( ( [!&] {}  Space  WithSuffix :noPattern: ) {prefixed}  /  WithSuffix ) + {concat}
	
	g.addRule "Alternative",
		makeOneOrMore(
			makeChoice([
				makeConcat([
					makeCharSet("!&").withCaptureTag,
					makeRuleRef("Space"),
					makeRuleRef("WithSuffix").withMatchTimeTag("noPattern"),
				]).withCaptureTag("prefixed"),
				makeRuleRef("WithSuffix"),
			])).withCaptureTag("concat")
	
	_prefixedSemantics = function(match, subcaptures, arg)
		prefix = subcaptures[0]
		pattern = subcaptures[1]
		if prefix == "!" then
			pattern = makeNot(pattern)
		else if prefix == "&" then
			pattern = makeAnd(pattern)
		else
			abort "Strange prefix `" + prefix + "`"
		end if
		return pattern
	end function
	
	g.addCaptureAction "prefixed", @_prefixedSemantics
	
	_concatSemantics = function(match, subcaptures, arg)
		return makeConcat(subcaptures)
	end function
	
	g.addCaptureAction "concat", @_concatSemantics
	
	
	// Pattern  <-  ( Alternative  ( '/'  Space  Alternative :noAlternative: ) * ) {alternatives}
	
	g.addRule "Pattern",
		makeConcat([
			makeRuleRef("Alternative"),
			makeZeroOrMore(
				makeConcat([
					makeLiteral("/"),
					makeRuleRef("Space"),
					makeRuleRef("Alternative").withMatchTimeTag("noAlternative"),
				])),
		]).withCaptureTag("alternatives")
	
	_alternativesSemantics = function(match, subcaptures, arg)
		return makeChoice(subcaptures)
	end function
	
	g.addCaptureAction "alternatives", @_alternativesSemantics
	
	
	// Definition  <-  Identifier  '<-' :noArrow:  Space  ( Pattern  /  '$' {}  Space ) :noRulePattern:
	
	g.addRule "Definition",
		makeConcat([
			makeRuleRef("Identifier"),
			makeLiteral("<-").withMatchTimeTag("noArrow"),
			makeRuleRef("Space"),
			makeChoice([
				makeRuleRef("Pattern"),
				makeConcat([
					makeLiteral("$").withCaptureTag,
					makeRuleRef("Space"),
				]),
			]).withMatchTimeTag("noRulePattern"),
		])
	
	
	// Grammar  <-  Space  Definition + {ruleDefs} :noRuleDefs:  !.
	
	g.addRule "Grammar",
		makeConcat([
			makeRuleRef("Space"),
			makeOneOrMore(
				makeRuleRef("Definition")).withCaptureTag("ruleDefs").withMatchTimeTag("noRuleDefs"),
			makeNot(
				makeAnyChar),
		])
	
	_ruleDefsSemantics = function(match, subcaptures, arg)
		rules = {}
		ruleOrder = []
		for i in range(0, subcaptures.len - 1, 2)
			ruleName = subcaptures[i]
			rulePattern = subcaptures[i + 1]
			if rules.hasIndex(ruleName) then return makeSemanticError("Multiple definitions for rule `" + ruleName + "`")
			rules[ruleName] = rulePattern
			ruleOrder.push ruleName
		end for
		missingRules = []
		for ruleName in arg.ruleNames.indexes
			if not rules.hasIndex(ruleName) then missingRules.push ruleName
		end for
		if missingRules.len > 0 then return makeSemanticError("Rules used but not defined: " + missingRules)
		for ruleName in rules.indexes
			if rules[ruleName] == "$" then
				rules.remove ruleName
				ruleOrder.removeVal ruleName
			end if
		end for
		if ruleOrder.len == 0 then return makeSemanticError("At least one non-inclusion rule should be defined")
		return {"rules": rules, "ruleOrder": ruleOrder}
	end function
	
	g.addCaptureAction "ruleDefs", @_ruleDefsSemantics
	
	g.setDefaultRule "Grammar"
	
	return g
end function


// Library level grammar object to parse PEG strings.
pegGrammar = _makePegGrammar

