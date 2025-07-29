--!nocheck
local HttpService = game:GetService("HttpService")
local Types = require(script.Parent.Parent.Types)
local config = require(script.Parent.Parent.config)

local vecs = {}
vecs.__index = vecs

vecs._counter = 0

function vecs.new(Data : {number}, Name : string | nil)
	assert(#Data > 0, `Vector must contain at least one value`)
	vecs._counter += 1
	local self = setmetatable({}, vecs)

	self.vec = Data
	self.dimension = #Data
	self.isHomogeneous  = false
	self._id = Name or `Vec_{vecs._counter}`

	return self
end

function vecs.axis(n : number, i : number) : Types.Vec<{number}>
	assert(typeof(n) == "number", `[creation]:failed Expected a number value got {n}`)
	assert(typeof(i) == "number", `[creation]:failed Expected a number value got {i}`)
	assert(n > 0, `[creation]:failed index{n} must satisfy n > 0`)
	assert(i > 0, `[creation]:failed index{i} must satisfy i > 0`)

	local result = {}
	for j = 1, n do
		if i == j then
			table.insert(result, i)
		else
			table.insert(result, 0)
		end
	end

	return vecs.new(result)
end

function vecs.unit(n : number, i : number) : Types.Vec<{number}>
	assert(typeof(n) == "number" and typeof(i) == "number", `[unit]:failed Expected numbers`)
	assert(n > 0 and i >= 1 and i <= n, `[unit]:failed Index i({i}) must be within 1 and n({n})`)

	local result = vecs.zero(n)
	result.vec[i] = 1

	return result
end

function vecs.mask(... : number) : Types.Vec<{number}>
	assert(typeof(...) == "number", `[creation]:failed Expected a number value got {...}`)

	local args = { ... }
	local result = {}
	for i = 1, args[1] do
		local verified = false
		for j = 2, #args do
			if args[j] == i then
				verified = true
				break
			end
		end

		if verified then
			table.insert(result, 1)
		else
			table.insert(result, 0)
		end
	end

	return vecs.new(result)
end

function vecs.zero(n : number) : Types.Vec<{number}>
	assert(typeof(n) == "number", `[creation]:failed Expected number value got {typeof(n)}`)
	assert(n > 0, `[creation]:failed The size n({n}) must satisfy n > 0`)

	local result = {}
	for i = 1, n do
		result[i] = 0
	end

	return vecs.new(result)
end

function vecs:add(b : Types.Vec<{number}> | number) : Types.Vec<{number}>
	if typeof(b) == "table" then
		assert(self.dimension == b.dimension, `[addition]:failed ({self._id}): Expected another {self.dimension .. "vec"} got {b.dimension .. "vec"}`)
	end
	assert(typeof(b) == "table" or typeof(b) == "number", `[addition]:failed ({self._id}): Expected a number/vec value got {typeof(b)}`)
	local result = {}
	if typeof(b) == "number" then
		for i = 1, #self.vec do
			result[i] = (self.vec[i] + b)
		end
	elseif typeof(b) == "table" then
		for i = 1, math.min(#self.vec, #b.vec) do
			result[i] = self.vec[i] + b.vec[i]
		end
	end

	return vecs.new(result)
end

function vecs:subtract(b : Types.Vec<{number}> | number) : Types.Vec<{number}>
	assert(typeof(b) == "table" or typeof(b) == "number", `[substraction]:failed ({self._id}): Expected a vec value got {typeof(b)}`)
	assert(self.dimension == b.dimension, `[substraction]:failed ({self._id}): Expected another {self.dimension .. "D" .. "vec"} got {b.dimension .. "D" .. "vec"}`)

	local result = {}
	if typeof(b) == "table" then
		for i = 1, math.min(#self.vec, #b.vec) do
			result[i] = self.vec[i] - b.vec[i]
		end
	elseif typeof(b) == "number" then
		for i = 1, #self.vec do
			result[i] = self.vec[i] - b
		end
	end

	return vecs.new(result)
end

function vecs:multiply(v : Types.Vec<{number}> | number) : Types.Vec<{number}>
	if typeof(v) == "table" then
		assert(self.dimension == v.dimension, `[multiplication]:failed ({self._id}): Expected another {self.dimension .. "D" .. "vec"} got {v.dimension .. "D" .. "vec"}`) 
	end
	assert(typeof(v) == "number" or typeof(v) == "table", `[multiplication]:failed ({self._id}): Expected a number/vec value got {typeof(v)}`)
	local result = {}
	if typeof(v) == "number" then
		for i = 1, #self.vec do
			result[i] = (self.vec[i] * v)
		end
	elseif typeof(v) == "table" then
		for i = 1, math.min(#self.vec, #v.vec) do
			result[i] = self.vec[i] * v.vec[i]
		end
	end

	return vecs.new(result)
end

function vecs:divide(v : Types.Vec<{number}> | number) : Types.Vec<{number}>
	assert(typeof(v) == "number" or typeof(v) == "table", `[division]:failed ({self._id}): Expected a number/vec value got {typeof(v)}`)
	if typeof(v) == "table" then
		assert(self.dimension == v.dimension, `[division]:failed ({self._id}): Expected another {self.dimension .. "D" .. "vec"} got {v.dimension .. "D" .. "vec"}`) 
	end

	local result = {}
	if typeof(v) == "number" then
		for i = 1, #self.vec do
			result[i] = (self.vec[i] / v)
		end
	elseif typeof(v) == "table" then
		for i = 1, math.min(#self.vec, #v.vec) do
			assert(v.vec[i] ~= 0, `[division]:failed at index {i} Attempt to divide by zero. [trace: {vecs.printv(v.vec)}]`)
			result[i] = self.vec[i] / v.vec[i]
		end
	end

	return vecs.new(result)
end

function vecs:cross(b : Types.Vec<{number}>) : Types.Vec<{number}>
	assert(self.dimension == 3, `[cross]:failed Expected 2 vecs of 3 dimension [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(b.vec)}`)
	assert(b.dimension == 3, `[cross]:failed Expected 2 vecs of 3 dimension [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(b.vec)}`)
	--[[
	e.g. (a1, a2, a3) * (b1, b2, b3)
	(a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1)
	]]

	local result = {}
	local x = (self.vec[2] * b.vec[3]) - (self.vec[3] * b.vec[2])
	local y = (self.vec[3] * b.vec[1]) - (self.vec[1] * b.vec[3])
	local z = (self.vec[1] * b.vec[2]) - (self.vec[2] * b.vec[1])

	table.insert(result, x)
	table.insert(result, y)
	table.insert(result, z)

	return vecs.new(result)
end

function vecs:rotate2D(deg : number) : Types.Vec<{number}>
	assert(self.dimension == 2, `[cross]:failed Expected a vec of 2 dimension [v1: {vecs.printv(self.vec)}]`)
	assert(typeof(deg) == "number", `[rotate2D]:failed Expected a degree(number value) got {typeof(deg)}`)

	local result = {}

	deg = deg * math.pi / 180
	local sin, cos = math.sin(deg), math.cos(deg)
	local xe, ye = self.vec[1], self.vec[2]

	result[1] = (xe * cos) - (ye * sin)
	result[2] = (xe * sin) + (ye * cos)

	return vecs.new(result)
end

function vecs:magnitude() : number
	local total = 0
	for i = 1, #self.vec do
		total += (self.vec[i]^2)
	end

	return math.sqrt(total)
end

function vecs:normalize() : Types.Vec<{number}>
	return self / self:magnitude()
end

function vecs:dot(b : Types.Vec<{number}>) : number
	if typeof(b) == "table" then
		assert(self.dimension == b.dimension, `[dot]:failed Vectors must have the same dimension. [v1: {self.dimension}, v2: {b.dimension}]`)
	end
	local count = 0
	for i = 1, #self.vec do
		count += (self.vec[i] * b.vec[i])
	end

	return count
end

function vecs:distance(b : Types.Vec<{number}>) : number
	local newVec = (self - b)
	return newVec:magnitude()
end

function vecs:project(b : Types.Vec<{number}>) : Types.Vec<{number}>
	local dot = (self:dot(b))
	local magnitude = (b:magnitude()^2)

	return b * (dot / magnitude)
end

function vecs:reflect(normal : Types.Vec<{number}>) : Types.Vec<{number}>
	assert(math.abs(normal:magnitude() - 1) < 1e-6, `[reflect]:failed Expected a normalized vec got [{vecs.printv(normal.vec)}]`)

	local dot = self:dot(normal)
	local scaled = normal * (2 * dot)
	local reflected = self - scaled

	return reflected
end

function vecs:clamp(min : number, max : number) : Types.Vec<{number}>
	local result = {}
	for i = 1, #self.vec do
		result[i] = self.vec[i]
		if (result[i] < min) then
			result[i] = min
		elseif (result[i] > max) then
			result[i] = max
		end
	end

	return vecs.new(result)
end

function vecs:toHomogeneous() : Types.Vec<{number}>
	assert(self.dimension == 2 or self.dimension == 3, `[toHomogeneous] failed: Expected a 2d/3d vec got {"vec"..self.dimension.."D"}`)
	local result = self:clone()
	table.insert(result.vec, 1)
	result.dimension = #result.vec
	result.isHomogeneous = true

	return result
end

function vecs:fromHomogeneous() : Types.Vec<{number}>
	assert(self.isHomogeneous == true, `[toHomogeneous] failed: {self._id} is not in a homogeneous form`)

	local newVec = self:clone()
	local dimension = newVec.dimension
	local currentDimension = dimension + 1

	local w = newVec.vec[#newVec.vec]
	assert(w ~= 0, "[fromHomogeneous] failed: w (last index) cannot be 0")

	for i = 1, #newVec.vec - 1 do
		newVec.vec[i] /= w
	end

	table.remove(newVec.vec, #newVec.vec)
	newVec.dimension = #newVec.vec
	newVec.isHomogeneous = false

	return newVec
end

function vecs:homogeneousEquals(v2 : Types.Vec<{number}>) : boolean
	assert(self.isHomogeneous and v2.isHomogeneous, `[homogeneousEquals] both vectors must be in homogeneous form`)

	local a, b = self.vec, v2.vec
	assert(#a == #b, `[homogeneousEquals] vectors must be the same dimension`)

	local scaleA = a[#a]
	local scaleB = b[#b]

	for i = 1, #a - 1 do
		local scaledA = a[i] / scaleA
		local scaledB = b[i] / scaleB

		if math.abs(scaledA - scaledB) > 1e-6 then
			return false
		end
	end

	return true
end

function vecs:inHomogeneous() : boolean
	return (self.isHomogeneous and true or false)
end

function vecs:angleBetween(b : Types.Vec<{number}>) : number
	local dot = self:dot(b)
	local magA = self:magnitude()
	local magB = b:magnitude()
	local cosTheta = (dot / (magA * magB))

	cosTheta = math.clamp(cosTheta, -1, 1)
	local theta = math.acos(cosTheta)

	return math.deg(theta)
end

local function isParallelTo(a : Types.Vec<{number}>, b : Types.Vec<{number}>)
	return math.abs(a:normalize():dot(b:normalize()) - 1) < 1e-6
end

local function isOrthogonal(a : Types.Vec<{number}>, b : Types.Vec<{number}>)
	return math.abs(a:normalize():dot(b:normalize())) < 1e-6
end

function vecs:isParallel(b : Types.Vec<{number}>) : boolean
	assert(self.dimension == b.dimension, `[isParallel]:failed Expected 2 vecs of the same dimension got [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(b.vec)}]`)
	local info = isParallelTo(self, b)
	if info then
		return true
	else
		return false
	end
end

function vecs:isOrthogonal(b : Types.Vec<{number}>) : boolean
	assert(self.dimension == b.dimension, `[isParallel]:failed Expected 2 vecs of the same dimension got [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(b.vec)}]`)
	local info = isOrthogonal(self, b)
	if info then
		return true
	else
		return false
	end
end

function vecs:equals(b : Types.Vec<{number}>, tolerance : number) : boolean
	assert(self.dimension == b.dimension, `[equals]:failed Expected 2 vecs similar in dimension [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(b.vec)}]`)
	tolerance = tolerance or 1e-6
	--[[
		in order for 2 vecs to be equal
		the absolute of (self.vec[i] - b.vec[i]) == 0 (thats a must)
		but since we integrate tolerance to give more flexibility we need to count it
	]]

	for i = 1, #self.vec do 
		if math.abs(self.vec[i] - b.vec[i]) > tolerance then -- 3.4 - 2, 1.4 - > 1
			return false
		end
	end

	return true
end

function vecs:lerp(to : Types.Vec<{number}>, t : number) : Types.Vec<{number}>
	assert(self.dimension == to.dimension, `[lerp]:failed Expected 2 vecs similar in dimension [v1: {vecs.printv(self.vec)}, v2: {vecs.printv(to.vec)}`)

	local result = {}
	for i = 1, #self.vec do
		result[i] = self.vec[i] + (to.vec[i] - self.vec[i]) * t
	end

	return vecs.new(result)
end

function vecs:clone()
	local result = {}
	for i = 1, #self.vec do
		result[i] = self.vec[i]
	end	
	return vecs.new(result)
end

function vecs:__add(b : Types.Vec<{number}>) : Types.Vec<{number}>
	assert(self.dimension == b.dimension, `[addition]:failed ({self._id}): Expected another {self.dimension .. "vec"} got {b.dimension .. "vec"}`)
	return self:add(b)
end

function vecs:__sub(b : Types.Vec<{number}> | number) : Types.Vec<{number}>
	assert(self.dimension == b.dimension, `[substraction]:failed Expected another {self.dimension .. "vec"} got {b.dimension .. "vec"}`)
	return self:subtract(b)
end

function vecs:__mul(n : Types.Vec<{number}> | number) : Types.Vec<{number}>
	assert(typeof(n) == "number" or typeof(n) == "table", `[multiplication]:failed Expected a number/vec value got {typeof(n)}`)
	return self:multiply(n)
end

function vecs:__div(n : Types.Vec<{number}> | number) : Types.Vec<{number}>
	assert(typeof(n) == "number" or typeof(n) == "table", `[division]:failed ({self._id}): Expected a number/vec value got {typeof(n)}`)
	return self:divide(n)
end

function vecs.printv(... : Types.Vec<{number}>) : string
	return HttpService:JSONEncode(...)
end

return vecs