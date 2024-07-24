-- Example World Generation
landscape = merge
(

	fill("air"),
	layer("grass"),
	layer("dirt", 63),
	layer("stone", 60)
)

landscape = warp
(
    landscape,
    hills(10, 0.1)
)
landscape:apply()

-- Scatter cave systems on surface
--if math.random() < 0.125 then
   --Places individual blocks on the surface at random points with exclusion radius
   --placeBlocks("CaveSystem", scatterSurface(1))
--end

-- Places individual blocks on the surface using density function threshold and exclusion radius
-- placeBlocks("Tree", scatterSurface(noise.perlin2d(1.0, 0.1, 3), 5, 0.05))