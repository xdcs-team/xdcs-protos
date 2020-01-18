#!/usr/bin/python3

import sys
import numpy as np

a1 = sys.argv[1]
a2 = sys.argv[2]

result1 = np.fromfile(a1 + '/3_output', dtype=np.uint8)
result2 = np.fromfile(a2 + '/3_output', dtype=np.uint8)

result = np.empty_like(result1)
result[0::8] = result2[0::8]
result[1::8] = result2[1::8]
result[2::8] = result1[2::8]
result[3::8] = result1[3::8]
result[4::8] = result1[4::8]
result[5::8] = result1[5::8]
result[6::8] = result2[6::8]
result[7::8] = result2[7::8]

result.tofile('result.bmp')
