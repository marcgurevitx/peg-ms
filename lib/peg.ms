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


if version.hostName == "Mini Micro" then _NL = char(13) else _NL = char(10)


maxErrorFragment = 20
maxErrorRest = 20

escapes = {}
escapes[char(9)] = "t"
escapes[char(10)] = "n"
escapes[char(13)] = "r"
escapes["["] = "["
escapes["]"] = "]"
escapes["'"] = "'"
escapes[""""] = """"
escapes["\"] = "\"


// abort: Prints error message and dies.
if globals.hasIndex("abort") then
	abort = @globals.abort
else
	maxStack = 15
	extraStack = 3
	abort = function(msg)
		print msg
		s = stackTrace[:]
		if s.len > maxStack + extraStack then s = s[:maxStack/2] + ["... (+" + (s.len - maxStack) + " lines) ..."] + s[-maxStack/2:]
		s.apply @print
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
Tree._inited = false
Tree.children = null


Tree.init = function
	self._inited = true
	self.children = []
end function


Tree._str = function
	if not self._inited then return self._name + " class"
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
		if ["__isa", "_inited", "children"].indexOf(@kv.key) != null then continue
		contents.push @kv.key + ": " + @kv.value
	end for
	return self._name + "(" + contents.join(", ") + ")"
end function


// checkInstance: Aborts if x is not instance of Tree class/subclass.
Tree._checkInstance = function(x)
	if not x isa Tree then abort "Bad tree node, expected Tree, got `" + x + "`."
	if not x._inited then abort "Bad tree node, expected instance, got `" + x._str + "`."
end function


// addChild: Appends child to list of subnodes of this node.
Tree.addChild = function(child)
	self._checkInstance child
	self.children.push child
end function


// getOnlyChild: Retrieves subnode if there's only one.
Tree.getOnlyChild = function
	if self.children.len != 1 then abort "Unable to get the only subnode, has " + self.children.len + ": " + self.children
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
	self.message = ("{m}" +
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
	if self.pattern isa And or self.pattern isa Not then return {"list": [], "map": {}}
	caps = ctx.getSubcaptures(self)
	if caps == null then
		caps = {}
		caps.list = []
		caps.map = {}
		for child in self.children
			res = child.captureValues(ctx, arg)
			if res isa Error then return res
			caps.list += res.list
			caps.map += res.map
		end for
	end if
	if @self.capture != null then
		res = self.capture(self, caps, arg)
		if res isa Error then
			if res.__isa == Error then res.__isa = SemanticError  // transmogrifying to more specific type
			return res
		end if
		if not refEquals(res, caps) then
			caps.list = [res]
			caps.map = {}
		end if
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


// normalize: Tries to make the pattern tree less nested by fusing nodes.
Pattern.normalize = function
	children = []
	for child in self.children
		children.push child.normalize
	end for
	self.children = children
	if self.get("_normalizeNode") != null then
		pattern = self._normalizeNode
	else
		pattern = self
	end if
	return pattern
end function


// _tryFuseOnlyChild: If the pattern has the only subnode, returns it to be used instead self (if possible).
// Concat() and Choice() call it.
Pattern._tryFuseOnlyChild = function
	if self.children.len > 1 then return self
	child = self.children[0]
	
	selfHasTags = self.matchTimeTag != null or self.captureTag != null
	childHasTags = child.matchTimeTag != null or child.captureTag != null
	
	if selfHasTags and childHasTags then return self
	
	if selfHasTags then
		child.matchTimeTag = self.matchTimeTag
		child.captureTag = self.captureTag
	end if
	
	return child
end function


// matchSyntax: Matches a string and a pattern.
// `ctx` -- a ParsingContext object
// `arg` -- optional data passed to `Grammar.parse`
// Returns a Match object on successful match or null on failure.
Pattern.matchSyntax = function(ctx, arg=null)
	ctx.removeFlagsToRight
	match = self._matchSyntaxLogic(ctx, arg)
	
	if self.matchTimeTag != null then
		if ctx.grammar != null then
			action = ctx.grammar.findMatchTimeAction(ctx.ruleName, self.matchTimeTag)
		else
			action = self.matchTimeTag
		end if
		if @action isa funcRef then
			subcaptures = function
				if match == null then return {"list": [], "map": {}}
				caps = ctx.getSubcaptures(match)
				if caps == null then
					caps = match.captureValues(ctx, arg)
					ctx.putSubcaptures(match, caps)
				end if
				return caps
			end function
			match = action(match, @subcaptures, arg, ctx)
			if match != null and not match isa Match then abort "Bad return value from match-time action: expected null or Match, got `" + match + "`"
		else if match == null then
			ctx.addSyntaxError self.matchTimeTag, action
		end if
	end if
	
	if match != null and @match.capture == null and self.captureTag != null then
		tag = self.captureTag
		tagParts = tag.split(":")
		isKeyCapture = tagParts.len > 1
		if tag == "" then
			match.capture = function(match, subcaptures, arg)
				subcaptures.list.push match.fragment
				return subcaptures
			end function
		else if isKeyCapture then
			key = tagParts[0]
			subIndex = tagParts[1]
			if subIndex == "" then
				match.capture = function(match, subcaptures, arg)
					subcaptures.map[key] = match.fragment
					return subcaptures
				end function
			else
				subIndex = subIndex.val
				match.capture = function(match, subcaptures, arg)
					subcaptures.map[key] = subcaptures.list[subIndex]
					return subcaptures
				end function
			end if
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
	
	abort "Method ._matchSyntaxLogic should be overridden"
	
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
	if self.matchTimeTag != null then rv += " <" + self.matchTimeTag + ">"
	if self.captureTag != null then rv += " {" + self.captureTag + "}"
	return rv
end function


// generatePegString: Returns a PEG string of the pattern.
Pattern.generatePegString = function
	
	abort "Method .generatePegString should be overridden"
	
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


AnyChar.generatePegString = function
	return "." + self.tags
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


CharSet.generatePegString = function
	characters = []
	hasMinus = false
	for c in self.characters
		if c == "-" then
			hasMinus = true
		else if escapes.hasIndex(c) then
			characters.push "\" + escapes[c]
		else
			characters.push c
		end if
	end for
	if hasMinus then characters.push "-"
	return "[" + characters.join("") + "]" + self.tags
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


CharRange.generatePegString = function
	characters = []
	for c in [self.from, self.to]
		if escapes.hasIndex(c) then
			characters.push "\" + escapes[c]
		else
			characters.push c
		end if
	end for
	return "[" + characters[0] + "-" + characters[1] + "]" + self.tags
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


Literal.generatePegString = function
	characters = []
	for c in self.string_
		if escapes.hasIndex(c) then
			characters.push "\" + escapes[c]
		else
			characters.push c
		end if
	end for
	return "'" + characters.join("") + "'" + self.tags
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


And.generatePegString = function
	pattern = self.getOnlyChild
	innerParens = ["", ""]
	if pattern.tags == "" then
		for cls in [Concat, Choice, Grammar]
			if pattern isa cls then innerParens = ["( ", " )"]
		end for
	end if
	tags = self.tags
	if tags != "" then
		outerParens = ["( ", " )"]
	else
		outerParens = ["", ""]
	end if
	return outerParens[0] + "& " + innerParens[0] + pattern.generatePegString + innerParens[1] + outerParens[1] + tags
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


Not.generatePegString = function
	pattern = self.getOnlyChild
	innerParens = ["", ""]
	if pattern.tags == "" then
		for cls in [Concat, Choice, Grammar]
			if pattern isa cls then innerParens = ["( ", " )"]
		end for
	end if
	tags = self.tags
	if tags != "" then
		outerParens = ["( ", " )"]
	else
		outerParens = ["", ""]
	end if
	return outerParens[0] + "! " + innerParens[0] + pattern.generatePegString + innerParens[1] + outerParens[1] + tags
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
	if patterns.len == 0 then abort "Choices of zero patterns are not supported"
	super.init
	for pattern in patterns
		self.addChild pattern
	end for
end function


Choice.nodeToStr = function
	return "Choice()" + self.tags
end function


// _normalizeNode: Fuses single character literals into a CharSet and/or uses the only subpattern as self.
Choice._normalizeNode = function
	characters = []
	charIndexes = []
	for i in self.children.indexes
		child = self.children[i]
		if not child isa Literal then continue
		if child.string_.len != 1 then continue
		if child.matchTimeTag != null then continue
		if child.captureTag != null then continue
		characters.push child.string_
		charIndexes.push i
	end for
	if characters.len > 0 then
		for i in charIndexes.reversed
			self.children.remove i
		end for
		self.addChild makeCharSet(characters.join(""))
	end if
	pattern = self._tryFuseOnlyChild
	return pattern
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


Choice.generatePegString = function
	children = []
	for pattern in self.children
		innerParens = ["", ""]
		if pattern.tags == "" then
			for cls in [Choice, Grammar]
				if pattern isa cls then innerParens = ["( ", " )"]
			end for
		end if
		children.push innerParens[0] + pattern.generatePegString + innerParens[1]
	end for
	tags = self.tags
	if tags != "" then
		outerParens = ["( ", " )"]
	else
		outerParens = ["", ""]
	end if
	return outerParens[0] + children.join("  /  ") + outerParens[1] + tags
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
	if patterns.len == 0 then abort "Concatenations of zero patterns are not supported"
	super.init
	for pattern in patterns
		self.addChild pattern
	end for
end function


Concat.nodeToStr = function
	return "Concat()" + self.tags
end function


// _normalizeNode: Uses the only subpattern as self (if possible).
Concat._normalizeNode = function
	pattern = self._tryFuseOnlyChild
	return pattern
end function


// _matchSyntaxLogic: Succeeds if all the subpatterns match in succession.
Concat._matchSyntaxLogic = function(ctx, arg=null)
	subms = []
	index = ctx.index
	fragments = []
	for pattern in self.children
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then
			return null
		end if
		subms.push subm
		index += subm.length
		fragments.push subm.fragment
	end for
	length = index - ctx.index
	fragment = fragments.join("")
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


Concat.generatePegString = function
	children = []
	for pattern in self.children
		innerParens = ["", ""]
		if pattern.tags == "" then
			for cls in [Concat, Choice, Grammar]
				if pattern isa cls then innerParens = ["( ", " )"]
			end for
		end if
		children.push innerParens[0] + pattern.generatePegString + innerParens[1]
	end for
	tags = self.tags
	if tags != "" then
		outerParens = ["( ", " )"]
	else
		outerParens = ["", ""]
	end if
	return outerParens[0] + children.join("  ") + outerParens[1] + tags
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


Optional.generatePegString = function
	pattern = self.getOnlyChild
	innerParens = ["", ""]
	if pattern.tags == "" then
		for cls in [Concat, Choice, And, Not, Grammar]
			if pattern isa cls then innerParens = ["( ", " )"]
		end for
	end if
	return innerParens[0] + pattern.generatePegString + innerParens[1] + " ?" + self.tags
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
	fragments = []
	while true
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then break
		subms.push subm
		index += subm.length
		fragments.push subm.fragment
	end while
	length = index - ctx.index
	fragment = fragments.join("")
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


ZeroOrMore.generatePegString = function
	pattern = self.getOnlyChild
	innerParens = ["", ""]
	if pattern.tags == "" then
		for cls in [Concat, Choice, And, Not, Grammar]
			if pattern isa cls then innerParens = ["( ", " )"]
		end for
	end if
	return innerParens[0] + pattern.generatePegString + innerParens[1] + " *" + self.tags
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
	fragments = []
	while true
		subm = pattern.matchSyntax(ctx + {"index": index}, arg)
		if subm == null then break
		subms.push subm
		index += subm.length
		fragments.push subm.fragment
	end while
	if subms.len == 0 then
		return null
	end if
	length = index - ctx.index
	fragment = fragments.join("")
	match = new Match
	match.init ctx.index, length, fragment, self
	for subm in subms
		match.addChild subm
	end for
	return match
end function


OneOrMore.generatePegString = function
	pattern = self.getOnlyChild
	innerParens = ["", ""]
	if pattern.tags == "" then
		for cls in [Concat, Choice, And, Not, Grammar]
			if pattern isa cls then innerParens = ["( ", " )"]
		end for
	end if
	return innerParens[0] + pattern.generatePegString + innerParens[1] + " +" + self.tags
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
ParseContext._initialRule = null
ParseContext.insidePredicate = false
ParseContext.ruleName = null
ParseContext.ruleStart = null
ParseContext.subject = null
ParseContext.syntaxErrors = null
ParseContext.flags = null


ParseContext.init = function(subject, index, initialRule=null)
	self.subject = subject
	self.index = index
	self._initialRule = initialRule
	self.cachedSubcaptures = []
	self.syntaxErrors = []
	self.flags = {}
end function


// addSyntaxError: Appends a syntax error to the list of errors.
ParseContext.addSyntaxError = function(matchTimeTag, _message)
	if self.insidePredicate then return
	fragment = self.subject[self.ruleStart : self.index].ellideMiddle(maxErrorFragment)
	rest = self.subject[self.index : ].ellideEnd(maxErrorRest)
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


// getFlag: Computes the value of a position flag from start upto `index`.
ParseContext.getFlag = function(index, flagName)
	if not index isa number then abort ".getFlag expected an index, got `" + index + "`"
	flagStack = { "_flag": false }
	for i in self.flags.indexes.sort
		if i > index then break
		pattern = self.flags[i]
		if pattern.flag != flagName then continue
		if pattern.action == flagAction.setTrue then
			flagStack = { "_flag": true, "prevStack": flagStack }
		else if pattern.action == flagAction.setFalse then
			flagStack = { "_flag": false, "prevStack": flagStack }
		else if pattern.action == flagAction.unset then
			flagStack = flagStack.prevStack
		else
			abort "Unknown flag action: `" + pattern.action + "`"
		end if
	end for
	return flagStack._flag
end function


// removeFlagsToRight: Removes position flags to the right of the current index.
ParseContext.removeFlagsToRight = function
	for i in self.flags.indexes
		if i > self.index then self.flags.remove i
	end for
end function


makeParseContext = function(subject, index, initialRule=null)
	c = new ParseContext
	c.init subject, index, initialRule
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
	self.captures = {"list": [], "map": {}}
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
	ee = []
	for error in self.errors
		ee.push error._name + "(" + error.tag + ")"
	end for
	ee = ee.join(", ")
	list_ = self.captures.list
	map_ = self.captures.map
	return "ParseResult(length: {l}, match: {m}, errors: [{ee}], captures.list: {list_}, captures.map: {map_})".fill(locals)
end function


// capture: Returns one capture from a list of captures if there's only one element, otherwise returns null.
ParseResult.capture = function
	if self.captures.list.len == 1 then return self.captures.list[0]
	return null
end function


// testHasErrorTag: Returns true if one of the errors has the given tag.
ParseResult.hasErrorTag = function(tag)
	for error in self.errors
		if error.tag == tag then return true
	end for
	return false
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
		self.defaultRule = rulesCapture.defaultRule
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
			reasons.push "  - " + err.message
		end for
		abort "Bad grammar; possible reasons: " + _NL + reasons.join(_NL)
	end if
	for kv in res.capture.rules
		res.capture.rules[kv.key] = kv.value.normalize
	end for
	return res.capture
end function


Grammar._str = function
	if not self._inited then return self._name + " class"
	lines = [self.nodeToStr]
	for ruleName in self.ruleOrder
		lines.push " " + ruleName + "->"
		if not self.rules.hasIndex(ruleName) then
			lines.push "  $"
		else
			for line in self.rules[ruleName]._str.split(_NL)
				lines.push "  " + line
			end for
		end if
	end for
	return lines.join(_NL)
end function


Grammar.nodeToStr = function
	return "Grammar(" + self.getDefaultRule + ")" + self.tags
end function


// addRule: Adds a new rule to a grammar.
Grammar.addRule = function(ruleName, pattern=null)
	if not ruleName isa string then abort "Expected string, got `" + ruleName + "`"
	if self.rules.hasIndex(ruleName) then abort "Rule already defined `" + ruleName + "`"
	if pattern != null then
		Pattern._checkInstance pattern
		self.rules[ruleName] = pattern
	end if
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
	if self.rules.len == 1 then return self.rules.indexes[0]
	return null
end function


// _matchSyntaxLogic: Succeeds if grammar's default rule succeeds.
Grammar._matchSyntaxLogic = function(ctx, arg=null)
	if ctx._initialRule == null then
		ruleName = self.getDefaultRule
		if ruleName == null then abort "Unable to match, default rule not set"
	else
		if not self.rules.hasIndex(ctx._initialRule) then abort "Unable to use initial rule `" + ctx._initialRule + "`, no such rule"
		ruleName = ctx._initialRule
		ctx.remove "_initialRule"
	end if
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
	if not pattern isa Pattern then abort "Bad pattern for rule `" + ruleName + "`, expected Pattern, got `" + pattern + "`"
	return pattern
end function


// addCaptureAction: Registers a capture action.
// The callback will later be associated with a match if that match has the corresponding capture tag.
// The callback should have a signature: f(match, subcaptures, arg) -> capture.
// Optional first arg is the name of the rule whose definition contains the tag.
Grammar.addCaptureAction = function(arg1, arg2, arg3=null)
	if @arg3 == null then
		ruleName = null
		tag = arg1
		action = @arg2
	else
		ruleName = arg1
		tag = arg2
		action = @arg3
		if not ruleName isa string then abort "Bad rule name, expected string, got `" + ruleName + "`"
	end if
	if not tag isa string then abort "Bad capture tag, expected string, got `" + tag + "`"
	self.captureActions[[ruleName, tag]] = @action
end function

Grammar.capture = @Grammar.addCaptureAction


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
	if @arg3 == null then
		ruleName = null
		tag = arg1
		errorMessage = @arg2
	else
		ruleName = arg1
		tag = arg2
		errorMessage = @arg3
		if not ruleName isa string then abort "Bad rule name, expected string, got `" + ruleName + "`"
	end if
	if not tag isa string then abort "Bad capture tag, expected string, got `" + tag + "`"
	self.matchTimeActions[[ruleName, tag]] = @errorMessage
end function

Grammar.matchTime = @Grammar.addMatchTimeAction


// findMatchTimeAction: Returns the callback previously registered with `.addMatchTimeAction`.
Grammar.findMatchTimeAction = function(ruleName, matchTimeTag)
	_NOVAL = {}
	action = self.matchTimeActions.get([ruleName, matchTimeTag], _NOVAL)
	if not refEquals(@action, _NOVAL) then return @action
	return self.matchTimeActions.get([null, matchTimeTag])
end function


// parse: Matches a string and a grammar and returns an object of ParseResult class.
Grammar.parse = function(subject, start=null, arg=null, initialRule=null)
	if start == null then start = 0
	res = makeParseResult
	ctx = makeParseContext(subject, start, initialRule)
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


Grammar.generatePegString = function(delimiter="")
	defs = []
	maxNameLength = 0
	for ruleName in self.ruleOrder
		if ruleName.len > maxNameLength then maxNameLength = ruleName.len
		def = {}
		def.ruleName = ruleName
		if not self.rules.hasIndex(ruleName) then
			def.pattern = "$"
			def.arrow = "<-"
		else
			pattern = self.rules[ruleName]
			innerParens = ["", ""]
			if pattern.tags == "" then
				for cls in [Grammar]
					if pattern isa cls then innerParens = ["(", ")"]
				end for
			end if
			def.pattern = innerParens[0] + pattern.generatePegString + innerParens[1]
			if self.defaultRule == ruleName then
				def.arrow = ": "
			else
				def.arrow = "<-"
			end if
		end if
		defs.push def
	end for
	lines = []
	for def in defs
		lines.push "  " + def.ruleName.pad(maxNameLength) + "  " + def.arrow + "  " + def.pattern + "  "
	end for
	tags = self.tags
	if tags != "" then
		outerParens = ["(", ")"]
	else
		outerParens = ["", ""]
	end if
	return outerParens[0] + lines.join(delimiter) + outerParens[1] + tags
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


RuleRef.generatePegString = function
	return self.ruleName + self.tags
end function


makeRuleRef = function(ruleName)
	p = new RuleRef
	p.init ruleName
	return p
end function


// flagAction: Enum for flag actions.
flagAction = {}
flagAction.setTrue = 1
flagAction.setFalse = 2
flagAction.unset = 3


flagAction.toString = function(a)
	return {flagAction.setTrue: "+", flagAction.setFalse: "-", flagAction.unset: "/"}[a]
end function


// PositionFlag: Pattern that manipulates a boolean flag associated with a position in the subject:  (+foo)  (-foo)  (/foo)
// This pseudo-pattern always succeeds.
PositionFlag = new Pattern
PositionFlag._name = "PositionFlag"
PositionFlag.action = null
PositionFlag.flag = null


PositionFlag.init = function(action, flag)
	super.init
	self.action = action
	self.flag = flag
end function


PositionFlag.nodeToStr = function
	s = flagAction.toString[self.action]
	return "PositionFlag(" + s + self.flag + ")"
end function


// _matchSyntaxLogic: Registers a position flag (and always succeeds).
PositionFlag._matchSyntaxLogic = function(ctx, arg=null)
	ctx.flags[ctx.index] = self
	match = new Match
	match.init ctx.index, 0, "", self
	return match
end function


PositionFlag.generatePegString = function
	s = flagAction.toString[self.action]
	return "(" + s + self.flag + ")"
end function


makePositionFlag = function(action, flag)
	p = new PositionFlag
	p.init action, flag
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
	makePositionFlag    = @outer.makePositionFlag
	makeRuleRef         = @outer.makeRuleRef
	makeZeroOrMore      = @outer.makeZeroOrMore
	flagAction          = outer.flagAction
	
	
	g = makeGrammar
	
	
	// Comment
	
	_commentPeg = "'#'  ( ! [\n\r]  . ) *  ( [\n\r]  /  ! . )"
	
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
	
	g.getRulePattern("Comment")._DEBUG_PEG = _commentPeg
	
	
	// Space
	
	_spacePeg = "( Comment  /  [ \t\n\r] ) *"
	
	g.addRule "Space",
		makeZeroOrMore(
			makeChoice([
				makeRuleRef("Comment"),
				makeCharSet(" " + char(9) + char(10) + char(13)),
			]))
	
	g.getRulePattern("Space")._DEBUG_PEG = _spacePeg
	
	
	// Identifier
	
	_identifierPeg = "( ( [a-z]  /  [A-Z]  /  [_] )  ( [a-z]  /  [A-Z]  /  [0-9]  /  [_] ) * ) {}  Space"
	
	g.addRule "Identifier",
		makeConcat([
			makeConcat([
				makeChoice([
					makeCharRange("a", "z"),
					makeCharRange("A", "Z"),
					makeCharSet("_"),
				]),
				makeZeroOrMore(
					makeChoice([
						makeCharRange("a", "z"),
						makeCharRange("A", "Z"),
						makeCharRange("0", "9"),
						makeCharSet("_"),
					])),
			]).withCaptureTag,
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("Identifier")._DEBUG_PEG = _identifierPeg
	
	
	// Escape
	
	_escapePeg = "'\\'  ( [tnr\[\]\'\""\\]  /  'u'  ( [0-9]  /  [A-F]  /  [a-f] ) + <fourHex> ) {escape}"
	
	g.addRule "Escape",
		makeConcat([
			makeLiteral("\"),
			makeChoice([
				makeCharSet("tnr[]'""\"),
				makeConcat([
					makeLiteral("u"),
					makeOneOrMore(
						makeChoice([
							makeCharRange("0", "9"),
							makeCharRange("A", "F"),
							makeCharRange("a", "f"),
						])).withMatchTimeTag("fourHex"),
				]),
			]).withCaptureTag("escape"),
		])
	
	g.getRulePattern("Escape")._DEBUG_PEG = _escapePeg
	
	_fourHexMT = function(match, subcaptures, arg, ctx)
		if not match then
			ctx.addSyntaxError("fourHex", "Missing hexadecimals after `\u`")
			return null
		end if
		if match.fragment.len < 4 then
			ctx.addSyntaxError("fourHex", "Expected four hexadecimals after `\u`, got only " + match.fragment.len + ": `" + match.fragment + "`")
			return null
		end if
		match.length = 4
		match.fragment = match.fragment[:4]
		return match
	end function
	g.addMatchTimeAction "fourHex", @_fourHexMT
	
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
	
	
	// CharClass
	
	_charClassPeg = "'\['  ( ( ! '\]'  ( Escape  /  ( .  '-'  ! '\]'  . ) {}  /  . {} ) ) + <noElems> ) {charClass}  '\]' <noClosing>  Space"
	
	g.addRule "CharClass",
		makeConcat([
			makeLiteral("["),
			makeConcat([
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
					])).withMatchTimeTag("noElems"),
			]).withCaptureTag("charClass"),
			makeLiteral("]").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("CharClass")._DEBUG_PEG = _charClassPeg
	
	_charClassSemantics = function(match, subcaptures, arg)
		elems = []
		for cap in subcaptures.list
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
	
	
	// Literal
	
	_literalPeg = "( '\''  ( ! '\''  ( Escape  /  . {} ) ) * {literal}  '\'' <noClosing>  /  '\""'  ( ! '\""'  ( Escape  /  . {} ) ) * {literal}  '\""' <noClosing> )  Space"
	
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
	
	g.getRulePattern("Literal")._DEBUG_PEG = _literalPeg
	
	_literalSemantics = function(match, subcaptures, arg)
		return makeLiteral(subcaptures.list.join(""))
	end function
	g.addCaptureAction "literal", @_literalSemantics
	
	
	// AnyChar
	
	_anyCharPeg = "'.' {anyChar}  Space"
	
	g.addRule "AnyChar",
		makeConcat([
			makeLiteral(".").withCaptureTag("anyChar"),
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("AnyChar")._DEBUG_PEG = _anyCharPeg
	
	_anyCharSemantics = function(match, subcaptures, arg)
		return makeAnyChar
	end function
	g.addCaptureAction "anyChar", @_anyCharSemantics
	
	
	// Primary
	
	_primaryPeg = "'('  Space  Pattern  ')'  Space  /  AnyChar  /  Literal  /  CharClass  /  Identifier {ruleRef}  ! ( '<-'  /  [:] )"
	
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
					makeChoice([
						makeLiteral("<-"),
						makeCharSet(":"),
					])),
			]),
		])
	
	g.getRulePattern("Primary")._DEBUG_PEG = _primaryPeg
	
	_ruleRefSemantics = function(match, subcaptures, arg)
		ruleName = subcaptures.list[-1]
		arg.ruleNames[ruleName] = true
		return makeRuleRef(ruleName)
	end function
	g.addCaptureAction "ruleRef", @_ruleRefSemantics
	
	
	// MatchTimeTag
	
	_matchTimeTagPeg = "'<'  Space  Identifier ? {matchTimeTag}  '>' <noClosing>  Space"
	
	g.addRule "MatchTimeTag",
		makeConcat([
			makeLiteral("<"),
			makeRuleRef("Space"),
			makeOptional(
				makeRuleRef("Identifier")).withCaptureTag("matchTimeTag"),
			makeLiteral(">").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("MatchTimeTag")._DEBUG_PEG = _matchTimeTagPeg
	
	_matchTimeTagSemantics = function(match, subcaptures, arg)
		if subcaptures.list.len == 0 then tag = "" else tag = subcaptures.list[-1]
		return "<" + tag
	end function
	g.addCaptureAction "matchTimeTag", @_matchTimeTagSemantics
	
	
	// CaptureTag
	
	_captureTagPeg = "'{'  Space  ( Identifier  ( [:]  ( [-] ?  [0-9] + ) ? ) ? {} ) ? {captureTag}  '}' <noClosing>  Space"
	
	g.addRule "CaptureTag",
		makeConcat([
			makeLiteral("{"),
			makeRuleRef("Space"),
			makeOptional(
				makeConcat([
					makeRuleRef("Identifier"),
					makeOptional(
						makeConcat([
							makeCharSet(":"),
							makeOptional(
								makeConcat([
									makeOptional(
										makeCharSet("-")),
									makeOneOrMore(
										makeCharRange("0", "9")),
								])),
						])).withCaptureTag,
				])).withCaptureTag("captureTag"),
			makeLiteral("}").withMatchTimeTag("noClosing"),
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("CaptureTag")._DEBUG_PEG = _captureTagPeg
	
	_captureTagSemantics = function(match, subcaptures, arg)
		tag = subcaptures.list.join("")
		return "{" + tag
	end function
	g.addCaptureAction "captureTag", @_captureTagSemantics
	
	
	// WithSuffix
	
	_withSuffixPeg = "( Primary  ( [*+?] {}  Space  /  MatchTimeTag  /  CaptureTag ) * ) {withSuffix}"
	
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
	
	g.getRulePattern("WithSuffix")._DEBUG_PEG = _withSuffixPeg
	
	_withSuffixSemantics = function(match, subcaptures, arg)
		pattern = subcaptures.list[0]
		for suffix in subcaptures.list[1:]
			if suffix[0] == "*" then
				pattern = makeZeroOrMore(pattern)
			else if suffix[0] == "+" then
				pattern = makeOneOrMore(pattern)
			else if suffix[0] == "?" then
				pattern = makeOptional(pattern)
			else if suffix[0] == "<" then
				if pattern.matchTimeTag != null or pattern.captureTag != null then pattern = makeConcat([pattern])
				pattern.matchTimeTag = suffix[1:]
			else if suffix[0] == "{" then
				if pattern.matchTimeTag != null or pattern.captureTag != null then pattern = makeConcat([pattern])
				pattern.captureTag = suffix[1:]
			else
				abort "Strange suffix `" + suffix + "`"
			end if
		end for
		return pattern
	end function
	g.addCaptureAction "withSuffix", @_withSuffixSemantics
	
	
	// PositionFlag
	
	_positionFlagPeg = "( '('  [+/-] {}  Space  Identifier <noIdentifier>  ')' <noClosing> ) {positionFlag}  Space"
	
	g.addRule "PositionFlag",
		makeConcat([
			makeConcat([
				makeLiteral("("),
				makeCharSet("+/-").withCaptureTag,
				makeRuleRef("Space"),
				makeRuleRef("Identifier").withMatchTimeTag("noIdentifier"),
				makeLiteral(")").withMatchTimeTag("noClosing"),
			]).withCaptureTag("positionFlag"),
			makeRuleRef("Space"),
		])
	
	g.getRulePattern("PositionFlag")._DEBUG_PEG = _positionFlagPeg
	
	_positionFlagSemantics = function(match, subcaptures, arg)
		marker = subcaptures.list[0]
		ident = subcaptures.list[1]
		action = {"+": flagAction.setTrue, "-": flagAction.setFalse, "/": flagAction.unset}[marker]
		pattern = makePositionFlag(action, ident)
		return pattern
	end function
	g.addCaptureAction "positionFlag", @_positionFlagSemantics
	
	
	// Alternative
	
	_alternativePeg = "( ( [!&] {}  Space  WithSuffix <noPattern> ) {prefixed}  /  WithSuffix  /  PositionFlag ) + {concat}"
	
	g.addRule "Alternative",
		makeOneOrMore(
			makeChoice([
				makeConcat([
					makeCharSet("!&").withCaptureTag,
					makeRuleRef("Space"),
					makeRuleRef("WithSuffix").withMatchTimeTag("noPattern"),
				]).withCaptureTag("prefixed"),
				makeRuleRef("WithSuffix"),
				makeRuleRef("PositionFlag"),
			])).withCaptureTag("concat")
	
	g.getRulePattern("Alternative")._DEBUG_PEG = _alternativePeg
	
	_prefixedSemantics = function(match, subcaptures, arg)
		prefix = subcaptures.list[0]
		pattern = subcaptures.list[1]
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
		return makeConcat(subcaptures.list)
	end function
	g.addCaptureAction "concat", @_concatSemantics
	
	
	// Pattern
	
	_patternPeg = "( Alternative  ( '/'  Space  Alternative <noAlternative> ) * ) {alternatives}"
	
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
	
	g.getRulePattern("Pattern")._DEBUG_PEG = _patternPeg
	
	_alternativesSemantics = function(match, subcaptures, arg)
		return makeChoice(subcaptures.list)
	end function
	g.addCaptureAction "alternatives", @_alternativesSemantics
	
	
	// Definition
	
	_definitionPeg = "Identifier  ( ( '<-'  /  [:] ) <noArrowOrColon> ) {}  Space  ( Pattern  /  '$' {}  Space  ( & Definition  /  ! . ) <notNextDef> ) <noRulePattern>"
	
	g.addRule "Definition",
		makeConcat([
			makeRuleRef("Identifier"),
			makeConcat([
				makeChoice([
					makeLiteral("<-"),
					makeCharSet(":"),
				]).withMatchTimeTag("noArrowOrColon"),
			]).withCaptureTag,
			makeRuleRef("Space"),
			makeChoice([
				makeRuleRef("Pattern"),
				makeConcat([
					makeLiteral("$").withCaptureTag,
					makeRuleRef("Space"),
					makeChoice([
						makeAnd(
							makeRuleRef("Definition")),
						makeNot(
							makeAnyChar),
					]).withMatchTimeTag("notNextDef"),
				]),
			]).withMatchTimeTag("noRulePattern"),
		])
	
	g.getRulePattern("Definition")._DEBUG_PEG = _definitionPeg
	
	
	// Grammar
	
	_grammarPeg = "Space  ( Definition + <noRuleDefs> ) {ruleDefs}  ( ! . ) <noEos>"
	
	g.addRule "Grammar",
		makeConcat([
			makeRuleRef("Space"),
			makeConcat([
				makeOneOrMore(
					makeRuleRef("Definition")).withMatchTimeTag("noRuleDefs"),
			]).withCaptureTag("ruleDefs"),
			makeNot(
				makeAnyChar).withMatchTimeTag("noEos"),
		])
	
	g.getRulePattern("Grammar")._DEBUG_PEG = _grammarPeg
	
	_ruleDefsSemantics = function(match, subcaptures, arg)
		rules = {}
		ruleOrder = []
		defaultRule = null
		for i in range(0, subcaptures.list.len - 1, 3)
			ruleName = subcaptures.list[i]
			ruleMarker = subcaptures.list[i + 1]
			rulePattern = subcaptures.list[i + 2]
			if rules.hasIndex(ruleName) then return makeSemanticError("Multiple definitions for rule `" + ruleName + "`")
			if ruleMarker == ":" then
				if defaultRule != null then return makeSemanticError("Multiple default rules: `" + defaultRule + "` and `" + ruleName + "`")
				if rulePattern == "$" then return makeSemanticError("Inclusion rule can't be default: `" + ruleName + "`")
				defaultRule = ruleName
			end if
			rules[ruleName] = rulePattern
			ruleOrder.push ruleName
		end for
		missingRules = []
		for ruleName in arg.ruleNames.indexes
			if not rules.hasIndex(ruleName) then missingRules.push ruleName
		end for
		if missingRules.len > 0 then return makeSemanticError("Rules used but not defined: " + missingRules)
		for ruleName in rules.indexes
			if rules[ruleName] == "$" then rules.remove ruleName
		end for
		if rules.len == 0 then return makeSemanticError("At least one non-inclusion rule should be defined")
		result = {}
		result.rules = rules
		result.ruleOrder = ruleOrder
		result.defaultRule = defaultRule
		return result
	end function
	g.addCaptureAction "ruleDefs", @_ruleDefsSemantics
	
	g.setDefaultRule "Grammar"
	
	return g
end function


// Library level grammar object to parse PEG strings.
pegGrammar = _makePegGrammar


// patternOrLiteral: Converts `x` to a Literal unless it's already a Pattern.
patternOrLiteral = function(x)
	if x isa Pattern then return x
	if x isa string then return makeLiteral(x)
	abort "Bad arg to patternOrLiteral, expected string or Pattern, got `" + x + "`"
end function

