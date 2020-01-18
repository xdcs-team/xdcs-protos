#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <CL/cl.h>

#define CHECK_CL_ERR(err) do { if (err != CL_SUCCESS) { \
        printf("Error: line %d, %ld\n", __LINE__, (long) err); \
    } } while(0)

char *read_file(char * const filename, size_t *sizep) {
    FILE *kf = fopen(filename, "r");
    if (kf == NULL) goto err;

    if (fseek(kf, 0L, SEEK_END) != 0) goto err;
    size_t size = ftell(kf);
    *sizep = size;
    if (size < 0) goto err;

    char *kernel_source = malloc(size);
    if (fseek(kf, 0L, SEEK_SET) != 0) goto err;
    if (fread(kernel_source, sizeof(char), size, kf) != size) goto err;

    fclose(kf);

    return kernel_source;

err:
    perror("Cannot read kernel");
    if (kf) fclose(kf);
    return NULL;
}

int save_file(char *data, size_t size, char * const filename) {
    FILE *kf = fopen(filename, "wb");
    if (kf == NULL) goto err;

    if (fwrite(data, sizeof(char), size, kf) != size) goto err;

    fclose(kf);

    return 0;

err:
    perror("Cannot read kernel");
    if (kf) fclose(kf);
    return 1;
}

int main() {
    printf("CL_DEVICE_MAX_WORK_GROUP_SIZE: %d\n", CL_DEVICE_MAX_WORK_GROUP_SIZE);
    printf("CL_DEVICE_MAX_WORK_ITEM_SIZES: %d\n", CL_DEVICE_MAX_WORK_ITEM_SIZES);

    char *kernel_source = NULL;
    size_t kernel_source_size;
    char *image = NULL;
    size_t image_size;

    kernel_source = read_file("kernel.cl", &kernel_source_size);
    if (kernel_source == NULL) {
        goto error;
    }

    image = read_file("image.bmp", &image_size);
    if (image == NULL) {
        goto error;
    }

    cl_int err;
    cl_context_properties props[3] = { CL_CONTEXT_PLATFORM, 0, 0 };

    cl_platform_id platform;
    cl_device_id device;
    err = clGetPlatformIDs(1, &platform, NULL);
    CHECK_CL_ERR(err);
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 1, &device, NULL);
    CHECK_CL_ERR(err);
    props[1] = (cl_context_properties) platform;

    cl_context ctx = clCreateContext(props, 1, &device, NULL, NULL, &err);
    CHECK_CL_ERR(err);
    cl_command_queue queue = clCreateCommandQueue(ctx, device, 0, &err);
    CHECK_CL_ERR(err);
    cl_program program = clCreateProgramWithSource(ctx, 1, (const char **) &kernel_source, &kernel_source_size, &err);
    CHECK_CL_ERR(err);
    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    CHECK_CL_ERR(err);

    cl_kernel kernel_invert = clCreateKernel(program, "invert", &err);
    CHECK_CL_ERR(err);

    cl_mem buf_image = clCreateBuffer(ctx, CL_MEM_READ_WRITE, image_size, NULL, &err);
    CHECK_CL_ERR(err);
    err = clEnqueueWriteBuffer(queue, buf_image, CL_TRUE, 0, image_size, image, 0, NULL, NULL);
    CHECK_CL_ERR(err);
    err = clFinish(queue);
    CHECK_CL_ERR(err);
    err = clSetKernelArg(kernel_invert, 0, sizeof(cl_mem), &buf_image);
    CHECK_CL_ERR(err);
    int s2 = (int) image_size;
    err = clSetKernelArg(kernel_invert, 1, sizeof(int), &s2);
    CHECK_CL_ERR(err);
    size_t work = { image_size };
    err = clEnqueueNDRangeKernel(queue, kernel_invert, 1, NULL, &work, NULL, 0, NULL, NULL);
    CHECK_CL_ERR(err);
    err = clFinish(queue);
    CHECK_CL_ERR(err);

    char *image_result = calloc(1, image_size);
    err = clEnqueueReadBuffer(queue, buf_image, CL_TRUE, 0, image_size, image_result, 0, NULL, NULL);
    CHECK_CL_ERR(err);
    err = clFinish(queue);
    CHECK_CL_ERR(err);

    save_file(image_result, image_size, "result.bmp");

    clReleaseMemObject(buf_image);
    clReleaseCommandQueue(queue);
    clReleaseContext(ctx);

    free(kernel_source);
    free(image_result);
    free(image);

    return 0;

error:
    fprintf(stderr, "Error\n");
    if (kernel_source) free(kernel_source);
    if (image) free(image);
    return 1;
}
