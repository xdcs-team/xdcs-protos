import random

def main():
    order = 10000000000000000
    generated = 0
    while generated < 50:
        number = random.randint(order, 10 * order)
        good = True
        for d in range(2, 1000):
            if number % d == 0:
                good = False

        if good:
            print(number)
            generated += 1


if __name__ == '__main__':
    main()
