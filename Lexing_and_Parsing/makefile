a.out: y.tab.c lex.yy.c
	g++ -O3 lex.yy.c y.tab.c

y.tab.c: CS22B075.y 
	yacc -d CS22B075.y

lex.yy.c: CS22B075.l y.tab.h
	lex CS22B075.l

clean:
	@rm lex.yy.c y.tab.h y.tab.c a.out
