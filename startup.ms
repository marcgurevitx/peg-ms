if env.hasIndex("cmdLineArgs") then
	cmdArgs = env.cmdLineArgs
else
	cmdArgs = shellArgs
end if

testNames = []

for cmdArg in cmdArgs
	if cmdArg[:4] == "test" then testNames.push cmdArg
end for

if env.hasIndex("importPaths") then
	env.importPaths.push "tests"
	env.importPaths.push "examples"
else
	env.MS_IMPORT_PATH += ":tests:examples"
end if

_import = function(moduleName)
	import moduleName
	return locals[moduleName]
end function

nTests = 0

for moduleName in file.children("tests") + file.children("examples")
	//if moduleName[:4] != "test" then continue
	print " " + moduleName + ":"
	module = _import(moduleName - ".ms")
	for kv in module
		if testNames.len > 0 then
			if testNames.indexOf(kv.key) == null then continue
		else
			if kv.key[:4] != "test" then continue
		end if
		print "   " + kv.key + "  ", ""
		kv.value
		nTests += 1
		print "OK"
	end for
	print
end for

print nTests + " OK"

