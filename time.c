#include "lib.h"

void showtime(void);

void
main(void)
{
	for (;;) {
		showtime();
		readchar();
	}
}

void
showtime(void)
{
	unsigned time_lo, time_hi, time_of_day;
	long long time;

	asm ("rdtime %0\n"
	     "rdtimeh %1\n"
	     : "=r" (time_lo), "=r" (time_hi));
	time = (long long)time_hi<<32 | time_lo;
	time_of_day = (time/1000) % 86400;
	writenum(time_of_day / 3600);
	writechar(':');
	writenum((time_of_day % 3600) / 60);
	writechar(':');
	writenum(time_of_day % 60);
	writestr(" UTC");
}
