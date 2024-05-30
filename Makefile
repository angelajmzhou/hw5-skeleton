cflags = -g -c -m64 
ldflags = -g -m64 -no-pie
asmflags = -g -c -m64 


all: main.o hashtable_asm.o hashtable.o
	gcc ${ldflags} -o hashtable_asm main.o hashtable_asm.o
	gcc ${ldflags} -o hashtable_c main.o hashtable.o

main.o: main.c hashtable.h
	gcc ${cflags} -o main.o main.c

hashtable.o: hashtable.c hashtable.h
	gcc ${cflags} -o hashtable.o hashtable.c

hashtable_asm.o: hashtable_asm.s hashtable.h
	gcc ${asmflags} -o hashtable_asm.o hashtable_asm.s

clean:
	rm *.o

realclean:
	rm *.o hashtable_c hashtable_asm
