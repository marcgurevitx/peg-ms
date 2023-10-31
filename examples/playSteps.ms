// ?



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


ensureImport "stringUtil"
ensureImport "peg"


peg.getStepRecorder = function
	
	rec = {}
	
	maxRows = 26
	branchRows = 16
	flagRows = 6
	maxColumns = 68
	indexColumn = 20
	steps = []
	currentIndex = 0
	branches = []
	subject = null
	defaultCommand = "n"
	commands = []
	exitP = false
	flagPad = 0
	
	rec.recordStep = function(step)
		steps.push step
	end function
	
	rec.stepsReady = function(subject)
		outer.subject = subject
		rec._calculateVisuals
		while true
			step = steps[currentIndex]
			rec._printScreen step
			rec._processInput
			if exitP then break
		end while
	end function
	
	rec._calculateVisuals = function
		for flagName in steps[1].flags.indexes
			if flagName.len > flagPad then
				outer.flagPad = flagName.len
			end if
		end for
		for idx in steps.indexes
			step = steps[idx]
			branch = []
			if step.type == peg.stepType.match or step.type == peg.stepType.success or step.type == peg.stepType.failure then
				m = {"arrowP": false}
			else
				m = {}
			end if
			if idx > 0 then
				for info in branches[-1]
					branch.push info + m
				end for
			end if
			if step.type == peg.stepType.match then
				for i in range(branch.len - 1, 0, -1)
					if branch[i].depth <= step.depth then break
					branch.remove i
				end for
				info = {}
				info.depth = step.depth
				info.box = "☐"
				info.peg = step.pattern.generatePegString
				info.arrowP = true
				info.captureP = false
				branch.push info
			else if step.type == peg.stepType.success then
				for i in range(branch.len - 1, 0, -1)
					if branch[i].depth == step.depth then
						info = branch[i]
						info.box = "☑"
						info.arrowP = true
						break
					end if
				end for
			else if step.type == peg.stepType.failure then
				for i in range(branch.len - 1, 0, -1)
					if branch[i].depth == step.depth then
						info = branch[i]
						info.box = "☒"
						info.arrowP = true
						break
					end if
				end for
			else if step.type == peg.stepType.callMT then
				for i in range(branch.len - 1, 0, -1)
					if branch[i].arrowP then
						info = branch[i]
						info.box = "?"
						break
					end if
				end for
			else if step.type == peg.stepType.captureAlreadySet then
				//...
			else if step.type == peg.stepType.setCapture then
				for i in range(branch.len - 1, 0, -1)
					if branch[i].arrowP then
						info = branch[i]
						info.captureP = true
						break
					end if
				end for
			else
				print "Unknown step type `" + step.type + "`"
				exit
			end if
			branches.push branch
		end for
	end function
	
	rec._printScreen = function(step)
		print "-" * (maxColumns - 1)
		
		rows = []
		
		s = currentIndex + "/[0-" + (steps.len - 1) + "] "
		if step.type == peg.stepType.match then
			s += "match"
		else if step.type == peg.stepType.success then
			s += "success"
		else if step.type == peg.stepType.failure then
			s += "failure"
		else if step.type == peg.stepType.callMT then
			s += "call match-time action: """ + step.info.matchTimeTag + """"
		else if step.type == peg.stepType.captureAlreadySet then
			s += "(capture already set in match-time action...)"
		else if step.type == peg.stepType.setCapture then
			s += "set capture: """ + step.info.captureTag + """"
		else
			print "Unknown step type `" + step.type + "`"
			exit
		end if
		
		
		//
		s += " matchId=/" + step.info.matchId + "/"
		//
		
		
		rows.push s
		rows.push ""
		
		branch = branches[currentIndex]
		arrowIndex = null
		for i in branch.indexes
			if branch[i].arrowP then
				arrowIndex = i
				break
			end if
		end for
		for i in range(branchRows * 2, 0)
			low = arrowIndex - i/2
			if low < 0 then low = 0
			_branch = branch[low : arrowIndex + i/2]
			if _branch.len <= branchRows then break
		end for
		branch = _branch
		for info in branch
			arrow = "  "
			if info.arrowP then arrow = "→ "
			if info.captureP then arrow = arrow[0] + "*"
			p = info.peg
			if p[0] != " " then p = "  " + p
			rows.push " " * info.depth + arrow + info.box + p
		end for
		for _ in range(branch.len, branchRows - 1, 1)
			rows.push ""
		end for
		rows.push ""
		
		indexString = str(step.index)
		if step.index < subject.len then
			indexString += ",char(" + subject[step.index].code + ")"
		end if
		subjShift = 0
		while (step.index - subjShift) > indexColumn
			if subject.len - subjShift < maxColumns - 2 then break
			subjShift += 1
		end while
		s = " " * (step.index - subjShift) + "↓"
		if step.index - subjShift < maxColumns / 2 then
			s += indexString
		else
			s = s[: step.index - subjShift - indexString.len] + indexString + "↓"
		end if
		rows.push s
		s = subject.replace(char(13), " ").replace(char(10), " ") + "¬"
		if subjShift > 0 then s = "…" + s[subjShift + 1:]
		rows.push s
		s = ""
		if step.match != null then
			s = " " * (step.match.start - subjShift) + "=" * step.match.length + step.match.length
		end if
		rows.push s
		rows.push ""
		
		truths = 0
		for flag in step.flags.values
			if flag then truths += 1
		end for
		s = "FLAGS(" + truths + "/" + step.flags.len + ") ERRORS(" + step.errors.len + ")"
		rows.push s
		rows.push ""
		
		cc = []
		for c in commands
			cc.push c.cmd
		end for
		s = cc.join(",") + " [" + defaultCommand + "]>"
		rows.push s
		
		for i in rows.indexes
			rows[i] = rows[i].ellideEnd(maxColumns - 1)
		end for
		
		print rows.join(peg._NL), ""
	end function
	
	cmdHelp = {}
	cmdHelp.cmd = "?"
	cmdHelp.help = "show help"
	cmdHelp.func = function(arg)
		for c in commands
			print " " + c.cmd.pad(6) + c.help
		end for
		return false  // don't print screen
	end function
	commands.push cmdHelp
	
	cmdNext = {}
	cmdNext.cmd = "n"
	cmdNext.help = "Next step"
	cmdNext.func = function(arg)
		outer.currentIndex += 1
		if currentIndex >= steps.len then outer.currentIndex = steps.len - 1
		return true  // print screen
	end function
	commands.push cmdNext
	
	cmdSkipForward = {}
	cmdSkipForward.cmd = "nn"
	cmdSkipForward.help = "Fast forward to the same matchId"
	cmdSkipForward.func = function(arg)
		step = steps[currentIndex]
		for i in range(currentIndex + 1, steps.len - 1, 1)
			if steps[i].info.matchId == step.info.matchId then
				outer.currentIndex = i
				break
			end if
		end for
		return true  // print screen
	end function
	commands.push cmdSkipForward
	
	cmdBack = {}
	cmdBack.cmd = "b"
	cmdBack.help = "Previous step"
	cmdBack.func = function(arg)
		outer.currentIndex -= 1
		if currentIndex < 0 then outer.currentIndex = 0
		return true  // print screen
	end function
	commands.push cmdBack
	
	cmdSkipBackward = {}
	cmdSkipBackward.cmd = "bb"
	cmdSkipBackward.help = "Fast backward to the same matchId"
	cmdSkipBackward.func = function(arg)
		step = steps[currentIndex]
		for i in range(currentIndex - 1, 0, -1)
			if steps[i].info.matchId == step.info.matchId then
				outer.currentIndex = i
				break
			end if
		end for
		return true  // print screen
	end function
	commands.push cmdSkipBackward
	
	cmdFlags = {}
	cmdFlags.cmd = "f"
	cmdFlags.help = "Show flags"
	cmdFlags.func = function(arg)
		step = steps[currentIndex]
		print
		for flagName in step.flags.indexes.sort
			v = step.flags[flagName]
			if v == null then v = "null"
			print " " + flagName.pad(flagPad, " ", false) + " = " + v
		end for
		return false  // don't print screen
	end function
	commands.push cmdFlags
	
	cmdErrors = {}
	cmdErrors.cmd = "e"
	cmdErrors.help = "Show errors"
	cmdErrors.func = function(arg)
		step = steps[currentIndex]
		print
		for error in step.errors
			print " " + error.tag + " / " + error.message
		end for
		return false  // don't print screen
	end function
	commands.push cmdErrors
	
	cmdCancelThis = {}
	cmdCancelThis.cmd = "x"
	cmdCancelThis.help = "Exit this replay"
	cmdCancelThis.func = function(arg)
		outer.exitP = true
		return true
	end function
	commands.push cmdCancelThis
	
	cmdCancelAll = {}
	cmdCancelAll.cmd = "xx"
	cmdCancelAll.help = "Exit this replay and cancel all future replays"
	cmdCancelAll.func = function(arg)
		outer.exitP = true
		peg.getStepRecorder = null
		return true
	end function
	commands.push cmdCancelAll
	
	cmdSetDefault = {}
	cmdSetDefault.cmd = "="
	cmdSetDefault.help = "Set default command"
	cmdSetDefault.func = function(arg)
		outer.defaultCommand = arg
		return true  // print screen
	end function
	commands.push cmdSetDefault
	
	_commands = commands[:]
	_commands.sort "cmd"
	
	rec._processInput = function
		inp = input.lower
		if inp == "" then inp = defaultCommand
		c = null
		arg = null
		for i in range(_commands.len - 1, 0)
			_c = _commands[i]
			if inp.startsWith(_c.cmd) then
				c = _c
				arg = inp[_c.cmd.len:]
				break
			end if
		end for
		if c == null then
			print "unknown command `" + inp + "`, try again> ", ""
			return rec._processInput
		else
			prnScr = c.func(arg)
			if not prnScr then
				print "ENTER to continue> ", ""
				input
			end if
		end if
	end function
	
	return rec
end function

