// Based on: https://github.com/turanszkij/WickedEngine GPU particles

#include "bgfx_compute.sh"

#include "particle_interop.sh"
#include "particle_params.sh"

BUFFER_RW(counterBuffer, uint, 0);
BUFFER_WR(indirectBuffer, uvec4, 1);

NUM_THREADS(1, 1, 1)
void main()
{
	uint particleCount = counterBuffer[PARTICLE_COUNTER_ALIVE_AFTER_UPDATE];
	drawIndexedIndirect(indirectBuffer, INDIRECT_DRAW, 6, particleCount, 0, 0, 0);

	// Create draw argument buffer (VertexCountPerInstance, InstanceCount, StartVertexLocation, StartInstanceLocation):
	//indirectBuffers.Store4(ARGUMENTBUFFER_OFFSET_DRAWPARTICLES, uint4(particleCount * 6, 1, 0, 0));
}
