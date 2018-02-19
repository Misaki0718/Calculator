/*
 *   Header for calculator program
*/

#define NSYMS 20   /* maximum number of symbols */

struct symtab {
        char *name;
        double (*funcptr)();
        double value;
} symtab[NSYMS];

struct symchar{
        char *name;
        char *(*funcptr)();
        char *character;
} symchar[NSYMS];

struct symtab *symlook();

struct symchar *sclook();
