#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <stdint.h>

__device__ uint8_t merge_colors(uint8_t a, uint8_t b, uint8_t c){
    return (a+b+c)/3;
}

__device__ float blur_effect(size_t x, size_t y) {
    float xp = 1920/2;
    float yp = 1080/2;

    float v = ((x-xp)*(x-xp) + (y-yp)*(y-yp)) / (800*800);
    v = 1 - 1 /(1 + v);
    return v > 1 ? 1 : v;
}

__global__ void process_color(size_t width, size_t height,
        uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *res) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx > (width * 3 * height)) return;

    int x = idx % (width*3);
    int y = idx / (width*3);
    int radius = 40 * blur_effect(x/3, y);

    int sum = 0;
    int count = 0;
    for (int i = x - radius*3; i <= x + radius*3; i += 3) {
        for (int j = y - radius; j <= y + radius; j += 1) {
            if ((i < 0) || (i >= width*3) || (j < 0) || (j >= height)) {
                continue;
            }

            if((i-x)*(i-x)/9 + (j-y)*(j-y) > radius*radius){
                continue;
            }

            int l_idx = i + j * width * 3;
            sum += merge_colors(a[l_idx], b[l_idx], c[l_idx]);
            ++count;
        }
    }

    bool is_red = idx % 3 == 0;
    bool is_green = idx % 3 == 1;
    bool is_blue = idx % 3 == 2;

    float be = 1.f;
    res[idx] = (uint8_t)((sum / count) * be + b[idx] * (1 - be));
}

void read_image(const char *path, uint8_t *data,
        size_t start, size_t size) {
    FILE *fp = fopen(path, "r");
    if (fp == NULL) {
        perror("Error while opening the file.\n");
        exit(EXIT_FAILURE);
    }
    fseek(fp, start, SEEK_SET);
    for (int i = 0; i < size; ++i) {
        data[i] = getc(fp);
    }
    fclose(fp);
}

void write_image(const char *path, uint8_t *data,
        size_t start, size_t size) {
    FILE *fp = fopen(path, "r+");
    if (fp == NULL) {
        perror("Error while opening the file.\n");
        exit(EXIT_FAILURE);
    }
    if (fseek(fp, start, SEEK_SET) != 0) {
        perror("Error while seeking.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < size; ++i) {
        putc(data[i], fp);
    }
    fclose(fp);
}

void copy_header(const char *from, const char *to, size_t till) {
    FILE *fp_from = fopen(from, "r");
    FILE *fp_to = fopen(to, "w");
    if (fp_from == NULL || fp_to == NULL) {
        perror("Error while opening the file.\n");
        exit(EXIT_FAILURE);
    }
    if (fseek(fp_to, 0, SEEK_SET) != 0) {
        perror("Error while seeking.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < till; ++i) {
        putc(getc(fp_from), fp_to);
    }
    fclose(fp_from);
    fclose(fp_to);
}

int main(void) {
    srand(time(NULL));
    printf("start\n");

    int count;
    int err;
    if ((err = cudaGetDeviceCount(&count)) != cudaSuccess) {
        printf("error: %d\n", err);
        exit(1);
    }
    printf("count: %d\n", count);

    for (int i = 0; i < count; ++i) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        printf("%d maxTexture1D: %d\n", i, prop.maxTexture1D);
        printf("%d maxTexture2D: %d\n", i, prop.maxTexture2D);
        printf("%d maxTexture3D: %d\n", i, prop.maxTexture3D);
        printf("%d name: %s\n", i, prop.name);
    }

    size_t image_size = sizeof(uint8_t) * 3 * 1920 * 1080;
    uint8_t *a_img = (uint8_t *) malloc(image_size);
    uint8_t *b_img = (uint8_t *) malloc(image_size);
    uint8_t *c_img = (uint8_t *) malloc(image_size);
    uint8_t *result_img = (uint8_t *) malloc(image_size);

    uint8_t *d_a, *d_b, *d_c, *d_result;
    cudaMalloc((void **) &d_a, image_size);
    cudaMalloc((void **) &d_b, image_size);
    cudaMalloc((void **) &d_c, image_size);
    cudaMalloc((void **) &d_result, image_size);

    size_t start = 0x7a;
    read_image("input/a.bmp", a_img, start, image_size);
    read_image("input/b.bmp", b_img, start, image_size);
    read_image("input/c.bmp", c_img, start, image_size);
    read_image("input/a.bmp", result_img, start, image_size);

    cudaMemcpy(d_a, a_img, image_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b_img, image_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_c, c_img, image_size, cudaMemcpyHostToDevice);

    printf("STARTED\n");
    clock_t t;
    t = clock();
    process_color <<< 1920 * 1080 * 3 / 512 + 1, 512 >>>
        (1920, 1080, d_a, d_b, d_c, d_result);
    cudaDeviceSynchronize();
    t = clock() - t;
    double time_taken = ((double)t)/CLOCKS_PER_SEC;
    printf("ENDED\n");
    printf("time: %lf pic/s\n", 1000.f / time_taken);

    cudaMemcpy(result_img, d_result, image_size,
        cudaMemcpyDeviceToHost);

    copy_header("input/a.bmp", "input/result.bmp", start);
    write_image("input/result.bmp", result_img, start, image_size);

    free(a_img);
    free(b_img);
    free(c_img);
    free(result_img);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    cudaFree(d_result);
    return 0;
}
