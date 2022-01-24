int readnum(void);
void writenum(int x);
int fib(int n);

void
main(void)
{
    writenum(fib(readnum()));
}

int
fib(int n)
{
    if (n == 0) return 0;
    if (n == 1) return 1;
    return fib(n - 1) + fib(n - 2);
}
