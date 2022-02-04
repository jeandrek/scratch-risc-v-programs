#include "lib.h"

int64_t gettime(void);
void showtime(int64_t);

void
main(void)
{
	for (;;) {
		showtime(gettime());
		readchar();
	}
}

int64_t
gettime(void)
{
	unsigned lo, hi;

	asm ("rdtime %0\n"
	     "rdtimeh %1\n"
	     : "=r" (lo), "=r" (hi));

	return (int64_t)hi<<32 | lo;
}

void
showtime(int64_t time)
{
	int time_of_day;

	time_of_day = (time/1000) % 86400;
	writenum(time_of_day / 3600);
	writechar(':');
	writenum((time_of_day / 60) % 60);
	writechar(':');
	writenum(time_of_day % 60);
	writestr(" UTC");
}
