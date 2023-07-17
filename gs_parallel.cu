#include <stdio.h>
#include <cuda.h>
#include <stdlib.h>

#include <sys/time.h>

#define MAX_ITER 1000
#define MAX 100 // maximum value of the matrix element
#define ERROR 0.000001

// Allocate 2D matrix

void init_bound_cond(float ***u, int m, int n)
{
    int i, j;
    *u = (float **)malloc(sizeof(float *) * (m));
    for (i = 0; i < m; i++)
    {
        (*u)[i] = (float *)malloc(sizeof(float) * (n));
    }

    // Initialize boundary conditon
    for (j = 1; j < n - 1; j++)
    {
        (*u)[0][j] = 50;
        (*u)[m - 1][j] = 300;
    }
    for (i = 1; i < m - 1; i++)
    {
        (*u)[i][0] = 75;
        (*u)[i][n - 1] = 100;
    }
}

void print_mat(float **a, int m, int n)
{
    int i, j;
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            printf("%f ", a[i][j]);
        }
        printf("\n");
    }
}

// solver

__global__ void solve(float **matdi, float **matdo, int n, int m, float *diff)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    

    // printf("%d, %d\n", i, j);
    if ((i > 0) && (j > 0) && (i < (n - 1)) && (j < (m - 1)))
    {
        (matdo)[i][j] = 0.25 * ((matdi)[i][j - 1] + (matdi)[i - 1][j] + (matdi)[i][j + 1] + (matdi)[i + 1][j]);
        atomicAdd(diff, abs((matdo)[i][j] - (matdi)[i][j]));
    }
}

int main(int argc, char *argv[])
{

    int n, m, cnt_iter = 0;
    float **a, **adi, **ado, *d_diff;
    
    n = 6; m = 5;
    init_bound_cond(&a, n, m);

    // float **temp;
    float **temi, **temo;
    temi = new float *[n];
    temo = new float *[n];


    print_mat(a, n, m);
 

    cudaMalloc(&adi, n * sizeof(float *));
    cudaMalloc(&ado, n * sizeof(float *));
    for (int i = 0; i < n; i++)
    {
        cudaMalloc(&(temi[i]), m * sizeof(float));
        cudaMalloc(&(temo[i]), m * sizeof(float));
        cudaMemcpy(temi[i], a[i], m * sizeof(float), cudaMemcpyHostToDevice);
        cudaMemcpy(temo[i], a[i], m * sizeof(float), cudaMemcpyHostToDevice);
    }
    cudaMemcpy(adi, temi, n * sizeof(float *), cudaMemcpyHostToDevice);
    cudaMemcpy(ado, temo, n * sizeof(float *), cudaMemcpyHostToDevice);
    float h_diff = n * m;
    dim3 DimBlock(32, 8);
    dim3 DimGrid((n + DimBlock.x - 1) / DimBlock.x, (m + DimBlock.y - 1) / DimBlock.y);

    // So luong grid tren moi chieu sao cho, grid_dim_x * block_dim_x >= n; tuong tu voi m

    cudaMalloc(&d_diff, sizeof(float));
    cudaMemset(d_diff, 0, sizeof(float));
    while ((cnt_iter < MAX_ITER) && ((h_diff / (n * m)) > ERROR))
    {
        solve<<<DimGrid, DimBlock>>>(adi, ado, n, m, d_diff);
        cudaMemcpy(&h_diff, d_diff, sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemset(d_diff, 0, sizeof(float));
        cnt_iter++;
        float **adt = adi; // Swap current result voi cai cu
        adi = ado;
        ado = adt;
    }

    printf("The algorithm converges after %d with difference = %f\n", cnt_iter, h_diff / (n * m));
    for (int i = 0; i < n; i++)
    {
        cudaMemcpy(a[i], temi[i], m * sizeof(float), cudaMemcpyDeviceToHost);
    }

    print_mat(a, n, m);

    return 0;
}