--!nocheck

local HttpService = game:GetService("HttpService")
local Types = require(script.Parent.Parent.Types)
local vecs = require(script.Parent.Vector)
local config = require(script.Parent.Parent.config)

local matrix = {}
matrix.__index = matrix

matrix._matrices = {}
matrix._idCounter = 0

function matrix.new(Data : {number}, Name : string | nil) : Types.Matrix<{number}>
	local self = setmetatable({}, matrix)
	matrix._idCounter += 1
	
	self.values = Data
	self._id = Name or `Matrix_{matrix._idCounter}`
	self.rows = #self.values
	self.cols = #self.values[1]
	
	matrix._matrices[self._id] = self
	return self
end

function matrix:add(B: Types.Matrix<{number}>) : Types.Matrix<{number}>
	assert(typeof(B) == "table", `[adding] failed: Expected a table got {typeof(B)}`)
	assert(B.rows == B.rows, `[adding] failed: Expected 2 matrices simliar in dimension got [m1: {self.values}, m2: {B.values}`)

	local newMatrix = self:clone()

	for i, row in ipairs(newMatrix.values) do
		for k, v in ipairs(row) do
			newMatrix.values[i][k] = v + B.values[i][k]
		end
	end

	return newMatrix
end

function matrix:subtract(B: Types.Matrix<{number}>) : Types.Matrix<{number}>
	assert(typeof(B) == "table", `[adding] failed: Expected a table got {typeof(B)}`)
	assert(B.rows == B.rows, `[adding] failed: Expected 2 matrices simliar in dimension got [m1: {self.values}, m2: {B.values}`)

	local newMatrix = self:clone()

	for i, row in ipairs(newMatrix.values) do
		for k, v in ipairs(row) do
			newMatrix.values[i][k] = v - B.values[i][k]
		end
	end

	return newMatrix
end

function matrix:multiply(B : Types.Matrix<{number}> | Types.Vec<{number}>) : Types.Matrix<{number}>
	assert(typeof(B) == "table" or typeof(B) == "number", `[multiply] failed: Expected a matrix/vec/number got [v: {B}]`)
	if typeof(B) ~= "number" then
		if B.dimension then
			assert(B.dimension == self.cols, `[multiply] failed: Matrix dimensions incompatible: [m1: {self:getDimension()}, v1: {"vec" .. B.dimension .. "D"}]`)
		elseif self.rows and B.cols then
			assert(self.rows == B.cols, `[multiply] failed: Expected another {self:getDimension()} matrix got {B:getDimension()}`)
		end
	end

	local new = {}

	if typeof(B) ~= "number" then
		if B.rows and B.cols then
			for i, row in ipairs(self.values) do
				local resultRow = {}
				for j = 1, #B.values[1] do
					local sum = 0
					for i = 1, #row do
						sum += row[i] * B.values[i][j]
					end
					table.insert(resultRow, sum)
				end
				table.insert(new, resultRow)
			end
			return matrix.new(new)
		elseif B.dimension then
			for i = 1, #self.values do
				local sum = 0
				for e = 1, #self.values[i] do
					sum += self.values[i][e] * B.vec[e]
				end
				table.insert(new, sum)
			end
			return vecs.new(new)
		end
	else
		if typeof(B) == "number" then
			for i = 1, #self.values do
				new[i] = {}
				for j = 1, #self.values[i] do
					new[i][j] = self.values[i][j] * B
				end
			end
		end
		return matrix.new(new)
	end
end

function matrix:divide(B : Types.Matrix<{number}> | number) : Types.Matrix<{number}>
	local result = {}
	if typeof(B) == "number" then
		for i = 1, #self.values do
			result[i] = {}
			for j = 1, #self.values[i] do
				result[i][j] = self.values[i][j] / B
			end
		end
		return matrix.new(result)
	elseif typeof(B) == "table" then
		return self * B:inverse()
	end

end

function matrix.__mul(A : Types.Matrix<{number}> | Types.Vec<{number}>, B : Types.Matrix<{number}> | number) : Types.Matrix<{number}>
	if (typeof(A) == "table" and typeof(B) == "table" or typeof(B) == "number") then
		return A:multiply(B)
	end
end

function matrix.__add(A : Types.Matrix<{number}>, B : Types.Matrix<{number}>) : Types.Matrix<{number}>
	if (typeof(A) == "table" and typeof(B) == "table") then
		return A:add(B)
	end
end

function matrix.__sub(A : Types.Matrix<{number}>, B : Types.Matrix<{number}>) : Types.Matrix<{number}>
	assert(typeof(A) == "table" and typeof(B) == "table", `[subtracting] failed: Expected 2 matrices(tables) got [m1: {typeof(A)}, m2: {typeof(B)}]`)
	return A:subtract(B)
end

function matrix.__div(A : Types.Matrix<{number}>, B : Types.Matrix<{number}> | number): Types.Matrix<{number}>
	assert(typeof(A) == "table" and typeof(B) == "table" or typeof(B) == "number", `[division] failed: Expected a matrix and a matrix/number got [m1: {typeof(A)}, m2: {typeof(B)}]`)
	return A:divide(B)
end

function matrix:determinant() : number
	-- det(a) = det(l) * det(u)
	local L, U = self:luDecompose()
	local detL = 1
	local detU = 1
	for i = 1, #U.values do
		detU *= U.values[i][i]
	end
	return detL * detU
end

function matrix:forwardSub(b : Types.Vec<{number}>) : Types.Vec<{number}>
	local n = self.rows
	local y = {}

	for i = 1, n do
		local sum = 0
		for j = 1, i - 1 do
			sum += self.values[i][j] * y[j]
		end
		y[i] = (b.vec[i] - sum) / self.values[i][i]
	end

	return vecs.new(y)
end

function matrix:backwardSub(b : Types.Vec<{number}>) : Types.Vec<{number}>
	local n = self.rows
	local y = {}

	for i = n, 1, -1 do
		local sum = 0
		for j = i + 1, n do
			sum += self.values[i][j] * y[j]
		end
		y[i] = (b.vec[i] - sum) / self.values[i][i]
	end

	return vecs.new(y)
end

function matrix:inverse() : Types.Matrix<{number}>
	local L, U, P = self:luDecompose()

	local n = self.rows
	local selfInverse = matrix.zero(n)

	for i = 1, n do
		local e = vecs.unit(n, i)
		local b = P * e
		local y = L:forwardSub(b)
		local x = U:backwardSub(y)

		for j = 1, n do
			selfInverse.values[j][i] = x.vec[j]
		end
	end

	return selfInverse
end

function matrix:rref() : Types.Matrix<{number}>
	local newMatrix = self:clone()
	local rows = newMatrix.rows
	local cols = newMatrix.cols
	local mat = newMatrix.values
	local lead = 1

	for r = 1, rows do
		if lead > cols then
			break
		end

		local i = r
		while mat[i][lead] == 0 do
			i += 1
			if i > rows then
				i = r
				lead += 1
				if lead > cols then
					return newMatrix
				end
			end
		end

		mat[i], mat[r] = mat[r], mat[i]

		local lv = mat[r][lead]
		for j = 1, cols do
			mat[r][j] /= lv
			if math.abs(mat[r][j]) < 1e-10 then
				mat[r][j] = 0
			end
		end

		for i2 = 1, rows do
			if i2 ~= r then
				local factor = mat[i2][lead]
				for j = 1, cols do
					mat[i2][j] -= factor * mat[r][j]
					if math.abs(mat[i2][j]) < 1e-10 then
						mat[i2][j] = 0
					end
				end
			end
		end

		lead += 1
	end

	return newMatrix
end

function matrix:getRank() : number
	local newMatrix = self:rref()
	local rank = 0

	for _, row in ipairs(newMatrix) do
		local isNoneZero = false
		for _, v in ipairs(row) do
			if math.abs(v) > 1e-10 then
				isNoneZero = true
				break
			end
		end

		if isNoneZero then
			rank += 1
		end
	end
	return rank
end

-- LU Decomposition
function matrix:luDecompose() : Types.Matrix<{number}>
	assert(self.rows == self.cols, `[LU Decompose]: Expected a square matrix got {matrix.printm(self.values)}`)
	local n = self.rows

	local L = matrix.identity(n)
	local U = matrix.zero(n)
	local P = matrix.identity(n)

	local function swapPivots()
		for col = 1, #self.values do
			local maxIndex = col
			local maxValue = math.abs(self.values[col][col])

			for row = col + 1, #self.values do
				if math.abs(self.values[row][col]) > maxValue then
					maxIndex = row
					maxValue = math.abs(self.values[row][col])
				end
			end

			if maxIndex ~= col then
				self.values[col], self.values[maxIndex] = self.values[maxIndex], self.values[col]
				P.values[col], P.values[maxIndex] = P.values[maxIndex], P.values[col]
			end
		end
	end
	swapPivots()

	for i = 1, n do
		for j = i, n do
			local sum = 0
			for k = 1, i - 1 do
				sum += L.values[i][k] * U.values[k][j]
			end
			U.values[i][j] = self.values[i][j] - sum
		end

		for j = i + 1, n do
			local sum = 0
			for k = 1, i - 1 do
				sum += L.values[j][k] * U.values[k][i]
			end
			L.values[j][i] = (self.values[j][i] - sum) / U.values[i][i]
		end
	end
	return L, U, P
end

function matrix:transpose() : Types.Matrix<{number}>
	local result = {}

	for i = 1, #self.values[1] do
		result[i] = {}
		for j = 1, #self.values do
			result[i][j] = self.values[i][j]
		end
	end
	return matrix.new(result)
end

function flipHorizontal(m) : Types.Matrix<{number}>
	local result = {}

	for i, row in ipairs(m) do
		result[i] = {}
		for j = #row, 1, -1 do
			table.insert(result[i], row[j])
		end
	end

	return matrix.new(result)
end

function flipVertically(m) : Types.Matrix<{number}>
	local result = {}

	for i = #m, 1, -1 do
		table.insert(result, m[i])
	end

	return matrix.new(result)
end

function matrix:flip(direction : Types.flipDirection) : Types.Matrix<{number}>
	if string.lower(direction) == "x" or string.lower(direction) == "horizontal" then 
		return flipHorizontal(self.values)
	elseif string.lower(direction) == "y" or string.lower(direction) == "vertical" then
		return flipVertically(self.values)
	end
end

function matrix:fromTransform(position, rotationMatrix, scaleVec)
	local scaleMatrix = matrix.new({
		{scaleVec.vec[1], 0, 0, 0};
		{0, scaleVec.vec[2], 0, 0};
		{0, 0, scaleVec.vec[3], 0};
		{0, 0, 0, 1};
	})
	
	local translationMatrix = matrix.new({
		{1, 0, 0, position.vec[1]};
		{0, 1, 0, position.vec[2]};
		{0, 0, 1, position.vec[3]};
		{0, 0, 0, 1};
	})
	
	return (translationMatrix * rotationMatrix * scaleMatrix)
end

function matrix:toHomogeneous()
	local size = #self.values
	assert(size == 3, "[toHomogeneous] failed: Only 3x3 matrices can be converted to 4x4 homogeneous form")
	
	local result = {}
	for i = 1, 3 do
		result[1] = table.clone(self.values[i])
		table.insert(result[i], 0)
	end
	
	table.insert(result, {0, 0, 0, 1})
	
	return matrix.new(result)
end

--[[
	A function used to rotate matrices clockwise (90deg)
]]
function matrix:rotate90() : Types.Matrix<{number}>
	local rows = #self.values
	local columns = #self.values[1]
	local result = {}

	for i= 1, columns do -- e.g. 1, 3
		result[i] = {}
		for j = rows, 1, -1 do
			result[i][rows-j+1] = self.values[j][i]
		end
	end

	return matrix.new(result)
end

function matrix:transformVec(vec : Types.Vec<{number}>) : Types.Vec<{number}>
	assert(vec, `[transformVector] failed: Expected a vector got [v1: {typeof(vec)}`)
	
	local homogeneousVec = vec
	if config.settings.autoTransform then
		if not homogeneousVec.isHomogeneous then
			homogeneousVec:toHomogeneous()
		end
	end
	
	local resultVec = self * homogeneousVec
	resultVec.isHomogeneous = true
	return resultVec:fromHomogeneous()
end

function matrix:getLength() : number
	local rows: number = #self.values
	if not rows or rows == 0 then
		return nil, nil, nil
	end
	local expectedColumns = #self.values[1] -- First row column count

	for i, row in ipairs(self.values) do
		if #row ~= expectedColumns then
			local ERROR_ROW = HttpService:JSONEncode(row)
			warn(`row {i} has inconsistent columns. Expected {expectedColumns}, got {#row}: {ERROR_ROW}`)
			return nil, nil, nil
		end
		local columns = #row
	end

	local totalEntries = rows * expectedColumns
	return rows, expectedColumns, totalEntries
end

function matrix:clone() : Types.Matrix<{number}>
	--[[
		getting a clone of the initiated 
		matrix using rows
	]]

	local Rows = {}
	for i, row in ipairs(self.values) do
		local newRow = {}
		for j, val in ipairs(row) do
			newRow[j] = val
		end
		Rows[i] = newRow
	end
	
	return matrix.new(Rows)
end

function matrix:getId() : string
	return self._id
end

function matrix:trace() : number
	if not self:isSquare() then return warn(`Matrix ({self._id}): Expected a square matrix got {self:dimension()}`) end
	local sum = 0
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			if i == j then
				sum += self.values[i][j]
			end
		end
	end
	return sum
end

function matrix:fill(n : number) : {}
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			self.values[i][j] = n
		end
	end
	return self
end

function matrix.zero(n : number) : Types.Matrix<{number}>
	local newMatrix = {}
	for i = 1, n do
		newMatrix[i] = {}
		for j = 1, n do
			newMatrix[i][j] = 0
		end
	end

	return matrix.new(newMatrix)
end

function matrix:isZero() : boolean
	local _flag = false
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			if self.values[i][j] == 0 then
				_flag = true
			else
				_flag = false
				return false
			end
		end
	end

	if _flag then
		return true
	else
		return false
	end
end

function matrix:forEach(fn : (value: number, rows: number, cols: number) -> ()) : nil
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			fn(self.values[i][j], i, j)
		end
	end
	return nil
end

--[[
	A function Used to iterate over entries and apply a function to them
]]
function matrix:map(fn : (value: number, rows: number, cols: number) -> ()) : Types.Matrix<{number}>
	local newMatrix = {}
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			local c = fn(self.values[i][j], i, j) --> 6
			table.insert(newMatrix, c)
		end
	end
	return matrix.unFlatten(newMatrix, self.rows, self.cols)
end

--[[
	returns a 1D table
]]

function matrix:find(target : number) : {}
	if (typeof(target) ~= "number") then return warn(`Expected a number value got {target}`) end

	local matches = {}
	for i, row in ipairs(self.values) do
		for j, v in ipairs(row) do
			if v == target then
				table.insert(matches, {Row = i, Column = j})
			end
		end
	end
	return matches
end

function matrix:flatten() : {number} -- does not return a matrix
	local newRow = {}
	for i = 1, #self.values do
		for j = 1, #self.values[i] do
			table.insert(newRow, self.values[i][j])
		end
	end

	return newRow
end

function matrix:getDimension() : string
	return `{self:shape().Rows}x{self:shape().Columns}`
end

function matrix:shape() : {number}
	return {Rows = self.rows, Columns = self.cols}
end

function matrix:isSquare() : boolean
	return true and (self.rows == self.cols) or false
end

--[[function matrix:__tostring() : string
	return `{HttpService:JSONEncode(self.values)}`
end--]]
--[[
	A function that transforms flatten tables (1D) to 2D Matrices
]]
function matrix.unFlatten(T : {}, rows, cols) : Types.Matrix<{number}>
	local newMatrix = {}
	local currentRow = {}

	for i, v in ipairs(T) do
		table.insert(currentRow, v)
		if #currentRow == cols then
			table.insert(newMatrix, currentRow)
			currentRow = {}
		end
	end
	return matrix.new(newMatrix)
end

function matrix.isEqual(A: Types.Matrix<{number}>, B: Types.Matrix<{number}>) : boolean
	if #A.values ~= #B.values or #A.values[1] ~= #B.values[1] then
		return false
	end

	for i = 1, #A.values do
		for j = 1, #A.values[i] do
			if A.values[i][j] ~= B.values[i][j] then
				return false
			end
		end
	end
	return true
end

function matrix.getMatrixFromId(id : string) : Types.Matrix<{number}>
	return matrix._matrices[id]
end

function matrix.identity(n : number) : Types.Matrix<{number}>
	local newMatrix = {}
	for i = 1, n do
		newMatrix[i] = {}
		for j = 1, n do
			newMatrix[i][j] = (i == j) and 1 or 0
		end
	end
	return matrix.new(newMatrix)
end

function matrix.printm(... : Types.Matrix<{number}>) : string
	return HttpService:JSONEncode(...)
end

return matrix
