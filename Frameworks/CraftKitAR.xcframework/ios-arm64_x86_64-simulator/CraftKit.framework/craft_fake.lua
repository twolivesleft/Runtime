craft = {}
craft.block = {}

function craft.block.create(name)
	local t = {}
	t.setTexture = function() end
	t.setColor = function() end
	t.static = {}
	return t	
end

function craft.block.addAssetPack()
end

function craft.block.addAsset()    
end

function craft.block.all()
end
