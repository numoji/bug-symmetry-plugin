local function reflectVec(v, axis)
	return v - 2 * (axis * v:Dot(axis))
end

local function ReflectCFrame(cf: CFrame, overCFrame: CFrame, corner: boolean, attachment: boolean)
	-- Mirroring characteristics
	local mirrorPoint = overCFrame.Position
	local mirrorAxis = overCFrame.LookVector

	-- Break to components
	local position = cf.Position
	local x, y, z = position.X, position.Y, position.Z

	-- Mirror position
	local newPos = mirrorPoint + reflectVec(Vector3.new(x, y, z) - mirrorPoint, mirrorAxis)

	-- Get rotation axis components
	local xAxis = cf.XVector
	local yAxis = cf.YVector
	local zAxis = cf.ZVector

	-- Mirror them
	xAxis = reflectVec(xAxis, mirrorAxis)
	yAxis = reflectVec(yAxis, mirrorAxis)
	zAxis = reflectVec(zAxis, mirrorAxis)

	-- Handedness fix
	if attachment then
		-- For attachments, the X and Y axis are the actively used ones that
		-- we want to preserve.
		zAxis = -zAxis
	else
		-- X axis chosen so that WedgeParts will work
		xAxis = -xAxis
	end

	-- Corner fix
	if corner then
		xAxis, zAxis = -zAxis, xAxis
	end

	-- Reconstitute
	return CFrame.new(
		newPos.X,
		newPos.Y,
		newPos.Z,
		xAxis.X,
		yAxis.X,
		zAxis.X,
		xAxis.Y,
		yAxis.Y,
		zAxis.Y,
		xAxis.Z,
		yAxis.Z,
		zAxis.Z
	)
end

return ReflectCFrame
