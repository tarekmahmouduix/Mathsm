--!nocheck

local types = require(script.Parent.Types)

local Matrix = script.Parent.Core.Matrix
local Vec = script.Parent.Core.Vector

type Mathsm = types.Mathsm

export type Version = types.Version

local Mathsm : Mathsm = table.freeze {
	Version = {major = 0, minor = 1, path = 0};
	
	Matrix = require(Matrix);
	Vec = require(Vec);
}

return Mathsm
