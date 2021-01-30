#include <stdio.h>

int main()
{
    return 0;
}

int fact(int n)
{
    if (n < 2)
        return 1;
    else
        return n * fact(n - 1);
}

int fib(int n)
{
    if (n < 2)
        return 1;
    else
        return fib(n - 1) + fib(n - 2);
}
