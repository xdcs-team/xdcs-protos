import math
import sys


def find_divisor(n):
    for i in range(2, math.ceil(math.sqrt(n))):
        if n % i == 0:
            return i
    return None


def main():
    if len(sys.argv) != 5:
        print("Wrong number of arguments passed")
        return

    agent_id = int(sys.argv[1])
    agent_count = int(sys.argv[2])
    input_filename = sys.argv[3]
    output_filename = sys.argv[4]

    input_file = open(input_filename, "r")
    output_file = open(output_filename, "w")

    line_num = 0
    for line in input_file:
        line_num += 1
        if line_num % agent_count != agent_id:
            continue
        number = int(line)

        divisor = find_divisor(number)
        if divisor is None:
            print("The number {} is prime".format(number))
            output_file.write("{} = {}\n".format(number, number))
        else:
            print("The number {} is divisible by {}".format(number, divisor))
            output_file.write("{} = {} * {}\n".format(number, divisor, (number / divisor)))

    input_file.close()
    output_file.close()


if __name__ == '__main__':
    main()
