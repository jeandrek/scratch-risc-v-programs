#include "lib.h"

#define CHRS	"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

void
image(uint8_t *start, uint8_t *end)
{
	uint32_t lo, hi_octet;
	uint8_t *p;
	int n, r;

	if (start == end) return;
	n = 0;
	while (start + 5 < end) {
		hi_octet = *start++;
		lo = 0;
		for (int i = 0; i < 4; i++)
			lo = lo << 8 | *start++;

		writechar(CHRS[hi_octet >> 3]);
		writechar(CHRS[(hi_octet & 7) << 2 | lo >> 30]);
		for (int i = 6; i > 0;)
			writechar(CHRS[(lo >> (5*--i)) & 0x1f]);
		if (++n % 10 == 0)
			writechar('\n');
	}
	p = start;
	hi_octet = *p++;
	lo = 0;
	while (p < end)
		lo = lo << 8 | *p++;
	r = start + 5 - p;
	lo <<= 8*r;

	writechar(CHRS[hi_octet >> 3]);
	writechar(CHRS[(hi_octet & 7) << 2 | lo >> 30]);
	for (int i = 6; i > 8*r/5;)
		writechar(CHRS[(lo >> (5*--i)) & 0x1f]);
	for (int i = 0; i < 8*r/5; i++)
		writechar('=');
	writechar('\n');
}
