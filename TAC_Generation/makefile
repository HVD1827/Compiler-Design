a.out: a2.l a2.y
	bison -d a2.y
	flex a2.l
	g++ -o $@ a2.tab.c lex.yy.c -lfl