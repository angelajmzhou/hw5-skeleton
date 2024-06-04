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
	mov [rsp], r12d			
	mov [rsp+4], r13		
	mov [rsp+12], r14		
	mov [rsp+20], r15		#saved reg. for newTable

	mov r12d, edi				#(int) size
	mov r13, rsi				#(* hashFunction)
	mov r14, rdx				#(* equalFunction)

	mov edi, 32 				#size of hashtable (arg1)
	mov esi, 1					#second arg (arg 2)
	call calloc
	mov r15, rax				#hashtable *newTable = malloc(sizeof(HashTable))

	mov [r15+24], r12d 			#newTable->size = size
	mov [r15+0], r13			#newTable->hashFunction = hashFunction;
	mov [r15+8], r14			#newTable->equalFunction = equalFunction;
	mov dword ptr [r15+28], 0 	#newTable->used = 0 | store as 32b register

	mov edi, r12d
	mov esi, 8

	call calloc
	
	mov [r15+16], rax		#newTable->data = malloc (size of...)

	mov rax, r15				#move newTable to return

	mov r12d, [rsp]
	mov r13, [rsp+4]
	mov r14, [rsp+12]	
	mov r15, [rsp+20]	#saved reg. for newTable

	add rsp, 56
	ret
	
# void insertData(HashTable *table, void *key, void *data);
insertData:
	sub rsp, 56

	#store the saved registers
	mov [rsp], r12
	mov [rsp+8], r13
	mov [rsp+16], r14

	#saved register for newBucket
	mov [rsp+24], r15	

	#move args into saved registers

	mov r12, rdi				#(* table)
	mov r13, rsi				#(* key)
	mov r14, rdx				#(* data)

	#calloc space for newBucket
	mov edi, 24
	mov esi, 1
	call calloc
	mov r15, rax					#r15 = * newBucket

	#move key into place
	mov rsi, r13					
	
	#call hashFunction
	call [r12]						#rax = hashFunction(key)

	mov	r11d, [r12+24]				#r11d =  table->size
	mov edx, 0						#zero out upper bits
	div r11d						#((table->hashFunction)(key)) % table->size
	#remainder is in rdx || location = rdx

	mov r10, [r12+16]				#r10 = table->data (the address)
	mov r11, [r10+8*rdx]			#r11 = table->data[location]

	#	data is double pointer... so now it is *data[location]

	mov [r15+16], r11				#newBucket -> next =table->data[location] 

	mov [r15+8], r14				#newBucket -> data = data	
	mov [r15], r13					#newBucket -> key = key

	mov [r10+8*rdx], r15		#table->data[location] = newBucket

	mov r9d, [r12+28]			#get hashTable->used
	add r9d, 1					#increment by 1
	mov [r10+28], r9d			#update hashTable->used

	#restore registers
	mov r12, [rsp]
	mov r13, [rsp+8]
	mov r14, [rsp+16]	
	mov r15, [rsp+24]
	
	add rsp, 56
	ret

# void *findData(HashTable *table, void *key);
findData:
	sub rsp, 24				#maintain stack pointer alignment

	mov [rsp], r12
	mov [rsp+8], r13
	mov [rsp+16], r14

	mov r12, rdi				#(* table)
	mov r13, rsi				#(* key)

	#get hashFunction
	mov r10, [r12]					#deref to get hashFunction
	
	#get the key
	mov rdi, r13					#move key to arg1
	
	#call hashFunction
	call r10						#rax = hashFunction(key)

	mov r11d, [r12+24]				#get table->size
									#takes rax as parameter
	mov edx, 0
	div r11d						#((table->hashFunction)(key)) % table->size
									#remainder is in rdx || location = rdx

	# struct HashBucket *lookAt = table->data[location];
	mov r10, [r12+16]				#r10 = table->data

	mov r14, [r10+8*rdx]			#lookAt = table->data[location] 
	# this is null - why?

while_start:
	cmp r14, 0
	je while_end
	mov rdi, r13					#arg1: key
	mov rsi, [r14]					#arg2: lookAt->key : invalid read

	#call equalFunction
	call 	[r12+8]					#rax = equalFunction(key, lookAt->key)

	cmp rax, 0
	cmovne rax, [r14+8]				#retval = lookAt -> data
	jne epilogue

	mov r14, [r14+16]				#lookAt = lookAt -> next
	jmp while_start
while_end:
	mov rax, 0
epilogue:
	mov r12, [rsp]
	mov r13, [rsp+8]
	mov r14, [rsp+16]	
	
	add rsp, 24
	ret
