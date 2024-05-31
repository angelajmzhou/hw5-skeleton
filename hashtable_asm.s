/*  
 * We are using GCC's assembler for this, which
 * allow C style comments.  GCC defaults to AT&T syntax (op src, dest)
 * but we'd much rather use Intel syntax (op dest, src) because it is
 * more similar to RISC-V and Intel's reference material uses Intel 
 * syntax (naturally).  So we have the following directive.
 *
 * Intel syntax is better because it also automatically infers the types
 * based on the register specifier, eliminating the need to include types
 * in most operations which would otherwise prove tedious and annoying.
 */
.intel_syntax noprefix

/*
 * However, compiler directives remain in the GNU format.
 */
.file "hashtable.s"
.text
.section .rodata

todo:	.string "Need to implement!"

.text
	.globl createHashTable
	.globl insertData
	.globl findData


#rbp, rbx, r12-r15 are callee saved
#rax, rcx, rdx, rsi, rdi, r8-r11 are caller-saved

#hashbucket: 24 bits (key, data, next)
#hashtable: 32 bits (hashfcn, equalfcn, data, size, used)
createHashTable:

	#don't need to save ra, rip alr on stack
	sub rsp, 56				#maintain stack pointer alignment

	#store saved registers rather than args on stack.
	mov [rsp], rdi			#store arg1 (size)
	mov [rsp+4], rsi		#store arg2 (hashFunction pointer)
	mov [rsp+12], rdx		#arg3 (equalFunction pointer)

	mov [rsp+20], r12		#saved reg. for newTable


	mov edi, 32 			#size of hashtable
	mov esi, 1	
	call calloc
	mov r12, rax			#hashtable *newTable = malloc(sizeof(HashTable))

	mov r8, [rsp]
	#offset = 8 + 8 + 8 = 24
	mov [r12+24], r8 		#newTable->size = size

	mov eax, 8				#size of hashbucket pointer
	mul r8					#hashbucket * size
	mov esi, 1

	call calloc
	mov [r12+16], rax		#newTable->data = malloc (size of...)

	mov r10, 0				#initialize the counter variable to scratch reg

	mov r12, [rsp+4]		#newTable->hashFunction = hashFunction;

	mov r8, [r12+8]
	mov r8, [rsp+12]		#newTable->equalFunction = equalFunction;

	mov rax, r12				#move newTable to return

	mov rdi, [rsp]			#store arg1 (size)
	mov rsi, [rsp+4]		#store arg2 (hashFunction pointer)
	mov rdx, [rsp+12]		#arg3 (equalFunction pointer)
	mov r12, [rsp+20]		#saved reg. for newTable

	add rsp, 56
	ret
	
# void insertData(HashTable *table, void *key, void *data);
insertData:
	sub rsp, 56

	#store the arguments on stack
	mov [rsp], rdi
	mov [rsp+8], rsi
	mov [rsp+16], rdx

	#saved register for newBucket
	mov [rsp+24], r12	

	#malloc space for newBucket
	mov edi, 24
	call malloc

	mov r12, rax					#r12 = newBucket

	#get hashFunction
	mov r10, [rsp]					#deref to get hashtable
	mov r10, [r9]					#deref to get hashFunction
	
	#get the key
	mov r11, [rsp+8]				#get key off stack
	mov rdi, [r11]					#double deref for key
	
	#call hashFunction
	call r10						#rax = hashFunctin(key)

	mov r11, [rsp]					#get table
	mov	r11, [r11+24]				#get table->size

	div r11							#((table->hashFunction)(key)) % table->size
	#remainder is in rdx || location = rdx
	#both sides can't have brackets
	mov r10, [rsp]
	mov r10, [r10+16]				#deref twice to get table->data

	mov r8, [r12+16]
	mov r8, [r10 + 8*rdx]		#newBucket->next = table->data[location]

	mov r8, [r12+8]
	mov r8, [rsp+16]			#newBucket -> data = data	

	mov r8, [r12]
	mov r8, [rsp+8]				#newBucket -> key = key

	mov [r10+8*rdx], r12		#table->data[location] = newBucket

	mov r10, [rsp]					#deref hashTable
	mov r9d, [r10+28]			#get hashTable->used
	add r9d, 1					#increment by 1
	mov [r10+28], r9			#update hashTable->used

	mov rdi, [rsp]			#store arg1 (size)
	mov rsi, [rsp+4]		#store arg2 (hashFunction pointer)
	mov rdx, [rsp+12]		#arg3 (equalFunction pointer)
	mov r12, [rsp+20]		#saved reg. for newTable
	
	add rsp, 56
	ret

# void *findData(HashTable *table, void *key);
findData:
	sub rsp, 24				#maintain stack pointer alignment

	mov [rsp], rdi			#store arg1 (hashTable pointer)
	mov [rsp+8], rsi		#store arg2 (key pointer)
	mov [rsp+16], r12			#saved register (for lookAt)

	#get hashFunction
	mov r10, [rsp]					#deref to get hashtable
	
	#get the key
	mov r11, [rsp+8]				#get key off stack
	mov rdi, [r11]					#rdi = double deref for key
	
	#call hashFunction
	call [r10]						#rax = hashFunction(key)

	mov r11, [rsp]					#get table
	mov	r11, [r11+24]				#get table->size

	div r11							#((table->hashFunction)(key)) % table->size
									#remainder is in rdx || location = rdx

#  struct HashBucket *lookAt = table->data[location];
	mov r10, [rsp]					#deref for hashTable
	mov r10, [r10+16]				#deref to get table->data


	mov r12, [r10+8*rdx]			#lookAt = table->data[location]

while_start:
	cmp r12, 0
	je while_end
	mov rdi, [rsp+8] 				#prep 1st argument (key)
	mov r12, [r12]					#1st deref: get hashBucket lookAt
	mov rsi, [r12]					#2nd deref: prep 2nd argument	(lookAt->key)

	#get equalFunction
	mov r10, [rsp]					#deref to get hashTable
	mov r10, [r10+8]				#deref to get equalFunction

	#call equalFunction
	call [r10]						#rax = equalFunction(key, lookAt->key)

	cmp rax, 0
	cmovnz rax, [r12+8]				#lookAt -> data
	jnz epilogue

	mov r12, [r12+16]				#lookAt = lookAt -> next
while_end:
	mov rax, 0
epilogue:
	mov rdi, [rsp]			
	mov rsi, [rsp+8]		
	mov r12, [rsp+16]		
	
	add rsp, 24
	ret

	
