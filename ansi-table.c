/*
 * This is not a program for the emulator; it just produces
 * a state machine table for ANSI escape codes used by the
 * Scratch project.
 */

#include <stdio.h>
#include <ctype.h>

enum state {
	ESC = 1,
	CSI,
	CSI_2,
	SGR,
	FG,
	BG,
	FG_DIGIT,
	BG_DIGIT,
	CLEAR,
	SGR_DONE,
	SGR_RESET,
	INVALID
};

#define FINAL_STATES	CLEAR

int
main(void)
{
	for (int state = 1; state < FINAL_STATES; state++) {
		for (int c = 32; c < 127; c++) {
			int newstate = INVALID;
			switch (state) {
			case ESC:
				if (c == '[')		newstate = CSI;
				break;
			case CSI:
				if (c == '2')		newstate = CSI_2;
				else if (c == '3')	newstate = FG;
				else if (c == '4')	newstate = BG;
				else if (c == 'm')	newstate = SGR_RESET;
				break;
			case SGR:
				if (c == '3')		newstate = FG;
				else if (c == '4')	newstate = BG;
			case CSI_2:
				if (c == 'J')		newstate = CLEAR;
				break;
			case FG:
				if (isdigit(c))		newstate = FG_DIGIT;
				break;
			case BG:
				if (isdigit(c))		newstate = BG_DIGIT;
				break;
			case FG_DIGIT:
			case BG_DIGIT:
				if (c == 'm')		newstate = SGR_DONE;
				else if (c == ';')	newstate = SGR;
			}
			printf("%d\n", newstate);
		}
	}
}
