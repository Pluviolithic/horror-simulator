local CollectionService = game:GetService "CollectionService"

return {
	getTaggedForZone = function(tagName)
		local folder = Instance.new "Folder"
		for _, zoneInstance in CollectionService:GetTagged(tagName) do
			zoneInstance.Parent = folder
		end
		return folder
	end,
}
