
/*
 * This is so the C preprocessor does not try to include multiple copies
 * of the header file if someone uses multiple //include directives.
 */
//ifndef _HASHTABLE_H_
//define _HASHTABLE_H_
//include <stdint.h>



//ifndef NULL
//define NULL ((void *)0)
//endif

/*
 * This header file defines an interface to a generic hashtable.
 * It stores void* data, and uses two function, int (*) (void *) to
 * compute the hash and an int (*) (void *, void *) for equal true/false
 */

struct HashBucket {
  void *key;
  void *data;
  struct HashBucket *next;
};

typedef struct HashTable {
  uint64_t (*hashFunction)(void *);
  int32_t (*equalFunction)(void *, void *);
  struct HashBucket **data;
  uint32_t size;
  uint32_t used;
} HashTable;

extern HashTable *createHashTable(int size,
                                  uint64_t (*hashFunction)(void *),
                                  int32_t (*equalFunction)(void *, void *));

/*
 * If you insert with a key that already exists this is undefined behavior:
 * Future fetches may sometimes get the new data or sometimes the old data,
 * but that is OK for this application
 */
extern void insertData(HashTable *table, void *key, void *data);

extern void *findData(HashTable *table, void *key);

//endif
