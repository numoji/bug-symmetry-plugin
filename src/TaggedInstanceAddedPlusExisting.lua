local CollectionService = game:GetService("CollectionService")

local TaggedInstanceAddedPlusExisting = function(tagName, callback)
	local taggedInstances = CollectionService:GetTagged(tagName)
	for _, taggedInstance in ipairs(taggedInstances) do
		callback(taggedInstance)
	end

	CollectionService:GetInstanceAddedSignal(tagName):Connect(callback)
end

return TaggedInstanceAddedPlusExisting
