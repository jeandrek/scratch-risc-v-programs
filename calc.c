#include "lib.h"

int isdigit(int c);

void
main(void)
{
	int stack[30];
	int k = 0;

	writestr("RPN calculator\n");
	while (1) {
		int c = readchar();
		int negnum = 0;

existingchar:
		if (isdigit(c)) {
			int n = 0;
			while (isdigit(c)) {
				n = 10*n + c - '0';
				c = readchar();
			}
			stack[k++] = negnum ? -n : n;
			goto existingchar;
		} else if (c == '+') {
			stack[k - 2] = stack[k - 2] + stack[k - 1];
			k--;
		} else if (c == '-') {
			c = readchar();
			if (isdigit(c)) {
				negnum = 1;
			} else {
				stack[k - 2] = stack[k - 2] - stack[k - 1];
				k--;
			}
			goto existingchar;
		} else if (c == '*') {
			stack[k - 2] = stack[k - 2] * stack[k - 1];
			k--;
		} else if (c == '/') {
			stack[k - 2] = stack[k - 2] / stack[k - 1];
			k--;
		} else if (c == 'R') {
			stack[k - 2] = stack[k - 2] % stack[k - 1];
			k--;
		} else if (c == '\n') {
			while (k > 0) {
				writenum(stack[--k]);
				writechar('\n');
			}
		}
	}
}

int
isdigit(int c)
{
	return c >= '0' && c <= '9';
}
