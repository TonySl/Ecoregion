# matlab CUDA C codes for knn calculation. Author： Heng Zhang ######

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#define N 500
#define DIM 21

__device__ float gpuCalDis(float *A, float *B)
{
	float dis = 0.0;
	float temp;
    #pragma unroll
	for (int i = 0; i < DIM; i++)
	{
		temp = A[i] - B[i];
		dis += temp*temp;
	}
	return dis;
}

__device__ int gpuCmpQueue(float *queue_dis, float dis)
{
	if (queue_dis[N - 1] <= dis)
		return -1;                                     //Do not need to update the queue
	else
	{
		int index = 0;
		while (queue_dis[index] <= dis)
		{
			index++;
		}
		return index;                                  //Need to update the queue, return the position
	}
}

__device__ void gpuUpdateQueue(int *queue_id, float *queue_dis, int id, float dis)
{
	int index = gpuCmpQueue(queue_dis, dis);
	if (index != -1)
	{
		int i = N - 1;
		while (i > index)
		{
			queue_id[i] = queue_id[i - 1];
			queue_dis[i] = queue_dis[i - 1];
			i--;
		}
		queue_id[index] = id;
		queue_dis[index] = dis;
	}
}

__device__ void gpuCopyRecord(float *Array, float *X, int index)
{
	int offset = index*DIM;
    #pragma unroll
	for (int i = 0; i < DIM; i++)
	{
		X[i] = Array[offset + i];
	}
}

__device__ void gpuFillResult(int *Result, int *queue_id, int index)
{
	int offset = index*N;
    #pragma unroll
	for (int i = 0; i < N; i++)
	{
		Result[offset + i] = queue_id[i];
	}
}

__device__ void gpuFillDis(float *Dis, float *queue_dis, int index)
{
	int offset = index*N;
	for (int i = 0; i < N; i++)
	{
		Dis[offset + i] = queue_dis[i];
	}
}

__global__ void gpuFindNearestPoints(int *Result,  float *Array, int total, int start, int stop)
{
	int i = blockIdx.x*blockDim.x + threadIdx.x + start;
	if (i >= stop)
		return;
	else
	{
		float A[DIM] = { 0.0 };
		float B[DIM] = { 0.0 };
		float dis = 0.0;
		int queue_id[N] = { 0 };
		float queue_dis[N];
        #pragma unroll
		for (int k = 0; k < N; k++)
			queue_dis[k] = 9999.0;
		gpuCopyRecord(Array, A, i);
		for (int j = 0; j < total; j++)
		{
			if (j == i)
				continue;
			else
			{
				gpuCopyRecord(Array, B, j);
				dis = gpuCalDis(A, B);
				gpuUpdateQueue(queue_id, queue_dis, j, dis);
			}
		}
		gpuFillResult(Result, queue_id, i-start);
      
	}
}
