// Based on: https://github.com/turanszkij/WickedEngine GPU particles

#include "bgfx_compute.sh"

#include "particle_interop.sh"
#include "particle_params.sh"

BUFFER_RW(counterBuffer, uint, 0);
BUFFER_WR(indirectBuffer, uvec4, 1);

NUM_THREADS(1, 1, 1)
void main()
{
    // Load dead particle count:
	uint deadCount = counterBuffer[PARTICLE_COUNTER_DEAD];

	// Load alive particle count:
	uint aliveCount_NEW = counterBuffer[PARTICLE_COUNTER_ALIVE_AFTER_UPDATE];

	// we can not emit more than there are free slots in the dead list:
	uint realEmitCount = min(deadCount, u_emitCount);

	// Fill dispatch argument buffer for emitting (ThreadGroupCountX, ThreadGroupCountY, ThreadGroupCountZ):
    dispatchIndirect(indirectBuffer, INDIRECT_DISPATCH_EMIT, ceil((float)realEmitCount / (float)THREAD_GROUP_SIZE), 1, 1);

	// Fill dispatch argument buffer for simulation (ThreadGroupCountX, ThreadGroupCountY, ThreadGroupCountZ):
    dispatchIndirect(indirectBuffer, INDIRECT_DISPATCH_UPDATE, ceil((float)(aliveCount_NEW + realEmitCount) / (float)THREAD_GROUP_SIZE), 1, 1);

	// copy new alivelistcount to current alivelistcount:
    counterBuffer[PARTICLE_COUNTER_ALIVE] = aliveCount_NEW;

	// reset new alivecount:
    counterBuffer[PARTICLE_COUNTER_ALIVE_AFTER_UPDATE] = 0;

	// and write real emit count:
    counterBuffer[PARTICLE_COUNTER_REAL_EMIT] = realEmitCount;
}
