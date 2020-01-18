__kernel void invert(__global uchar* image, const uint size) {
    size_t ix = get_global_id(0);
    if (ix < 0x7a || ix > size) return;
    image[ix] = 255 - image[ix];
}
