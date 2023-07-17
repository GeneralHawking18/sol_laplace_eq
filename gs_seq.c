#include <stdio.h>
#include <malloc.h>
#include <stdlib.h>

#define MAX_ITER 100
#define MAX 100 // maximum value of the matrix element
#define ERROR 0.000001


void print_mat(float** a, int m, int n) {
    int i, j;
    for (i = 0; i < m; i++) {
        for (j = 0; j < n; j++) {
            printf("%f ", a[i][j]);
        }
        printf("\n");
    }
}

void init_boundary_condition(float*** u, int m, int n) {
    int i, j;
    // Allocate memory
    *u = (float**) malloc(sizeof(float*) * (m));
    for (i = 0; i < m; i++) {
        (*u)[i] = (float*) malloc(sizeof(float) * (n));
    }

    // Initialize boundary conditon
    for (j = 1; j < n - 1; j++) {
        (*u)[0][j] = 50;
        (*u)[m - 1][j] = 300;
    }
    for (i = 1; i < m - 1; i++) {
        (*u)[i][0] = 75;
        (*u)[i][n - 1] = 100;

    }
}

void solve(float*** u, int m, int n) {
    int i, j,
        done = 0, iter = 0;

    float diff, temp;


    while((!done) && (iter < MAX_ITER)) {
        diff = 0;
        for (i = 1; i < m - 1; i++) {
            for (j = 1; j < n - 1; j++) {
                temp = (*u)[i][j];
                (*u)[i][j] = 0.25 *((*u)[i - 1][j] + (*u)[i][j-1] + (*u)[i][j+1] + (*u)[i + 1][j]);
                diff += abs((*u)[i][j] - temp);
            }
        }
        if (diff < ERROR) done = 1;
        iter++;
    }

    if (done) printf("The algorithm coverges after %d iterations.\n", iter);
    else printf("The algorihm does not converge\n");
}

int main() {
    int m, n;
    float **u;

    m = 6; n = 5;
    init_boundary_condition(&u, m, n);
    print_mat(u, m, n);
    solve(&u, m, n);
    print_mat(u, m, n);
    return 0;

}
