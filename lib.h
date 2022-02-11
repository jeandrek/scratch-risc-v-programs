typedef unsigned char uint8_t;
typedef unsigned long uint32_t;
typedef unsigned long long uint64_t;
typedef long long int64_t;

#define NULL ((void *)0)

void writestr(char *);
void writenum(int);
int readchar(void);
int peekchar(void);
void writechar(int);

void enable_timer(void);
void set_timer(int, void (*)(void));

extern int line_buffer_flag, echo_flag;
