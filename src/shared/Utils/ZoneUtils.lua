local CollectionService = game:GetService "CollectionService"

return {
	getTaggedForZone = function(tagName): Folder
		local folder = Instance.new "Folder"
		for _, zoneInstance in CollectionService:GetTagged(tagName) do
			zoneInstance.Parent = folder
		end
		return folder
	end,
}
