#include "lib.h"

#define SCALE 256
#define NCOLS 55
#define NROWS 16

#define PLAYER_APPEARANCE "\33[30;43m:-)\33[m"
#define VILLIAN_APPEARANCE "\33[30;41m>:|\33[m"

enum sprite_types {PLAYER, VILLIAN, PROJECTILE};

typedef struct sprite SPRITE;

struct sprite {
	int	 row, col;
	int	 x, y, vx, vy;
	char	*appearance;
	int	 width;
	int	 type;
	SPRITE	*prev, *next;
};

SPRITE *thesprites;

void controls(void);
void tick();
void screen(void);
void projectile(SPRITE *);
void randpos(SPRITE *);
SPRITE *newsprite(int, int, char *, int, int);
void deletesprite(SPRITE *);

int rand(void);
#define sqrt	intsqrt
int sqrt(int);
int abs(int);

int health, score;
SPRITE *player, *villian;

void
main(void)
{
	line_buffer_flag = 0;
	echo_flag = 0;

	thesprites = NULL;
	health = 20;
	score = 0;
	player = newsprite(5, 5, PLAYER_APPEARANCE, 3, PLAYER);
	villian = newsprite(10, 40, VILLIAN_APPEARANCE, 3, VILLIAN);

	set_timer(200, tick);
	enable_timer();
	controls();
}



void
controls(void)
{
	int c;

	for (;;) {
		c = readchar();
		if (c == '\33') {
			readchar();
			switch (readchar()) {
			case 'A': player->vx = 0; player->vy = -SCALE; break;
			case 'B': player->vx = 0; player->vy = SCALE; break;
			case 'C': player->vx = 2*SCALE; player->vy = 0; break;
			case 'D': player->vx = -2*SCALE; player->vy = 0; break;
			}
		}
	}
}

void
tick(void)
{
	static int nticks = 0;
	int newrow, newcol;
	int newx, newy;
	SPRITE *next;

	if (++nticks == 96) {
		randpos(newsprite(1, 1, VILLIAN_APPEARANCE, 3, VILLIAN));
		nticks = 0;
	}
	for (SPRITE *s = thesprites; s != NULL; s = next) {
		next = s->next;
		if (s->type == VILLIAN) {
			int dx, dy, magnitude;
			if (nticks % 6 == 0)
				projectile(s);
			dx = SCALE*player->col - s->x;
			dy = SCALE*player->row - s->y;
			magnitude = sqrt(dx*dx + dy*dy);
			s->vx = 3*SCALE/2*dx/magnitude;
			s->vy = 3*SCALE/4*dy/magnitude;
		}
		newx = s->x + s->vx;
		newy = s->y + s->vy;
		newrow = newy/SCALE;
		newcol = newx/SCALE;
		if (newrow < 2 || newrow > NROWS - 1 ||
		    newcol - s->width/2 < 1 ||
		    newcol + s->width/2 > NCOLS) {
			if (s->type == PROJECTILE) {
				score++;
				deletesprite(s);
			}
		} else {
			s->x = newx;
			s->y = newy;
			s->row = newrow;
			s->col = newcol;
		}
		if (s != player &&
		    s->row == player->row &&
		    abs(s->col - player->col) <= 1) {
			if (s->type == VILLIAN) {
				randpos(s);
				health--;
				writechar('\a');
			} else if (s != player) {
				health--;
				deletesprite(s);
				writechar('\a');
			}
		}
	}
	screen();	
	if (health <= 0) {
		writestr("\nGame over\n");
		for (;;) asm volatile ("wfi");
	}
	set_timer(200, tick);
}



void
screen(void)
{
	//writestr("\33[2J\33[1;1H\33[47m");
	writestr("\33[2J\33[47m");
	for (int col = 1; col <= NCOLS; col++) writechar(' ');
	writestr("\33[m\n");
	for (int row = 2; row <= NROWS - 1; row++) {
		for (int col = 1; col <= NCOLS; col++) {
			int is_sprite = 0;
			for (SPRITE *s = thesprites; s != NULL; s = s->next) {
				if (row == s->row &&
				    col == s->col - s->width/2) {
					is_sprite = 1;
					writestr(s->appearance);
					col += s->width - 1;
					break;
				}
			}
			if (!is_sprite) writechar(' ');
		}
		writechar('\n');
	}
	writestr("\33[30;47mHealth: ");
	writenum(health);
	writestr("  Score:    ");
	writenum(score);
	for (int col = 24; col <= NCOLS; col++) writechar(' ');
	writestr("\33[m");
}



void
projectile(SPRITE *from)
{
	int dx, dy, magnitude;
	SPRITE *proj;

	proj = newsprite(from->row, from->col, "\33[37m*\33[m", 1,
			 PROJECTILE);
	dx = SCALE*player->col - from->x;
	dy = SCALE*player->row - from->y;
	magnitude = sqrt(dx*dx + dy*dy);
	proj->vx = 4*SCALE*dx/magnitude;
	proj->vy = 2*SCALE*dy/magnitude;
}

void
randpos(SPRITE *s)
{
	s->row = (rand() % (NROWS - 2)) + 2;
	s->col = (rand() % NCOLS) + 1;
	s->x = SCALE*s->col;
	s->y = SCALE*s->row;
}



SPRITE sprites[26];
SPRITE *freesprite;
int n_used_sprites;

SPRITE *
newsprite(int row, int col, char *appearance, int width, int type)
{
	SPRITE *s;

	if (freesprite == NULL) {
		s = &sprites[n_used_sprites++];
	} else {
		s = freesprite;
		freesprite = freesprite->next;
		if (freesprite != NULL) freesprite->prev = NULL;
	}
	s->row = row;
	s->col = col;
	s->x = SCALE*col;
	s->y = SCALE*row;
	s->vx = 0;
	s->vy = 0;
	s->appearance = appearance;
	s->width = width;
	s->type = type;
	s->prev = NULL;
	s->next = thesprites;
	if (thesprites != NULL)
		thesprites->prev = s;
	thesprites = s;
	return s;
}

void
deletesprite(SPRITE *s)
{
	if (s == thesprites)
		thesprites = s->next;
	else if (s->prev != NULL)
		s->prev->next = s->next;
	s->next->prev = s->prev;
	s->prev = NULL;
	s->next = freesprite;
	freesprite = s;
}



int
rand(void)
{
	static int seed = 9231136;

	seed = (5*seed + 1) % (1<<20);
	return seed;
}

int
sqrt(int x)
{
	int y = 10;
	for (int i = 0; i < 13; i++)
		y = (y + x/y)/2;
	return y;
}

int
abs(int x)
{
	return x < 0 ? -x : x;
}
