__kernel void grayscale(
    uint agent_no,
    uint agent_count,
    __global uchar *input,
    __global uchar *output)
{
    int idx = get_global_id(0);

    if (idx <= 0x7a) {
        output[idx] = input[idx];
        return;
    }

    if ((idx - 0x7a) % 4 != 0) {
        return;
    }

    int pixel_no = (idx - 0x7a) / 4;

    if (pixel_no % agent_count != agent_no) return;

    uint shade = (((input[idx + 1]) & 0xFF) +
                  ((input[idx + 2]) & 0xFF) +
                  ((input[idx + 0]) & 0xFF)) / 3;


    output[idx + 1] = shade;
    output[idx + 2] = shade;
    output[idx + 0] = shade;
}
