local types = require(script.Parent.Parent.Types)

local RuntimeDiagnostics = {}

function RuntimeDiagnostics.handle(err: types.RuntimeError)
	if err.type == "INFO" then
		print(`[INFO] ({err.code}) {err.message}`)
	elseif err.type == "WARNING" then
		warn(`[WARNING] ({err.code}) {err.message}`)
	elseif err.type == "ERROR" then
		assert(false, `[ERROR] ({err.code}) {err.message}\nTrace: {err.trace or "N/A"}`)
	elseif err.type == "CRITICAL" then
		assert(false, `[CRITICAL] ({err.code}) {err.message}\nTrace: {err.trace or "N/A"}`)
	end
end

function RuntimeDiagnostics.create(severity : types.ErrorTypes, code : number, message : string, trace : string?) : types.RuntimeError
	local errorObj = {
		type = severity,
		code = code,
		message = message,
		trace = trace,
	}

	RuntimeDiagnostics.handle(errorObj)
	return errorObj
end

return RuntimeDiagnostics
