// Based on: https://github.com/turanszkij/WickedEngine GPU particles
#include "bgfx_compute.sh"

#include "particle_interop.sh"
#include "particle_params.sh"

BUFFER_RW(aliveBuffer_CURRENT, uint, 		0);
BUFFER_RW(deadBuffer, uint, 				1);
BUFFER_RW(counterBuffer, uint, 				2);

NUM_THREADS(THREAD_GROUP_SIZE, 1, 1)
void main()
{
	uint id = gl_GlobalInvocationID.x;
	aliveBuffer_CURRENT[id] = 0;
	deadBuffer[id] = id;

	if (id == 0)
	{
		counterBuffer[0] = 0;
		counterBuffer[1] = u_maxParticles;
	}
}
