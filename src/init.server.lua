local CollectionService = game:GetService("CollectionService")

local TaggedInstanceAddedPlusExisting = require(script.TaggedInstanceAddedPlusExisting)
local Janitor = require(script.Janitor)
local ReflectCFrame = require(script.ReflectCFrame)

local bugJanitors = {}

CollectionService:GetInstanceRemovedSignal("BugSymmetry"):Connect(function(bugModel)
	bugJanitors[bugModel]:Cleanup()
	bugJanitors[bugModel] = nil
end)

local propertiesToCopy = {
	"Reflectance",
	"Color",
	"DoubleSided",
	"Material",
	"Size",
}

local function reconcileReflection(sourceLocation, reflectionLocation, reflectionCFrame)
	local reflectionPartsAccountedFor = {}

	for _, sourcePart in ipairs(sourceLocation:GetChildren()) do
		if not sourcePart:FindFirstChild("ReflectionPart") then
			local reflectionPart = sourcePart:Clone()
			reflectionPart.CFrame = ReflectCFrame(sourcePart.CFrame, reflectionCFrame)
			reflectionPart.Parent = reflectionLocation

			local reflectionPartValue = Instance.new("ObjectValue")
			reflectionPartValue.Name = "ReflectionPart"
			reflectionPartValue.Value = reflectionPart
			reflectionPartValue.Parent = sourcePart
			reflectionPartsAccountedFor[reflectionPart] = true
		else
			local reflectionPart = sourcePart.ReflectionPart.Value
			reflectionPart.CFrame = ReflectCFrame(sourcePart.CFrame, reflectionCFrame)
			for _, propertyKey in ipairs(propertiesToCopy) do
				local sourceProperty = sourcePart[propertyKey]
				local reflectionProperty = reflectionPart[propertyKey]
				if sourceProperty ~= reflectionProperty then
					reflectionPart[propertyKey] = sourceProperty
				end
			end
			reflectionPartsAccountedFor[reflectionPart] = true
		end
	end

	for _, reflectionPart in ipairs(reflectionLocation:GetChildren()) do
		if not reflectionPartsAccountedFor[reflectionPart] then
			reflectionPart:Destroy()
		end
	end
end

local function isBugReady(bugModel)
	return bugModel:FindFirstChild("Source")
		and bugModel:FindFirstChild("Reflection")
		and bugModel.PrimaryPart
		and bugModel.PrimaryPart:FindFirstChild("ReflectionPoint")
end

TaggedInstanceAddedPlusExisting("BugSymmetry", function(bugModel)
	if isBugReady(bugModel) then
		local janitor = Janitor.new()

		local sourceFolder = bugModel:FindFirstChild("Source")
		local reflectionFolder = bugModel:FindFirstChild("Reflection")

		local function reconcileReflectionForBug()
			local reflectionCFrame = bugModel.PrimaryPart.ReflectionPoint.WorldCFrame
			reconcileReflection(sourceFolder, reflectionFolder, reflectionCFrame)
		end

		local function listenToPartChanges(part)
			janitor:Add(part.Changed:Connect(reconcileReflectionForBug))
		end

		-- Listen for changes
		for _, part in ipairs(sourceFolder:GetChildren()) do
			if part:IsA("BasePart") then
				listenToPartChanges(part)
			end
		end
		janitor:Add(sourceFolder.ChildAdded:Connect(function(part)
			if part:FindFirstChild("ReflectionPart") then
				part.ReflectionPart:Destroy()
			end
			reconcileReflectionForBug()
			listenToPartChanges(part)
		end))
		janitor:Add(bugModel.PrimaryPart.ReflectionPoint.Changed:Connect(reconcileReflectionForBug))

		-- Delete removed source parts
		janitor:Add(sourceFolder.ChildRemoved:Connect(reconcileReflectionForBug))

		reconcileReflectionForBug()

		bugJanitors[bugModel] = janitor
	else
		warn(string.format("Tagged bug '%s' is not ready to be symmetrical.. shes shy", bugModel.Name))
	end
end)
