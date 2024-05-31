
#include "hashtable.h"
#include <stdlib.h>
#include <stdio.h>

HashTable *createHashTable(int32_t size, uint64_t (*hashFunction)(void *),
                           int32_t (*equalFunction)(void *, void *)) {
  int i = 0;
  HashTable *newTable = malloc(sizeof(HashTable));
  newTable->size = size;
  newTable->used = 0;
  newTable->data = malloc(sizeof(struct HashBucket *) * size);
  for (i = 0; i < size; ++i) {
    newTable->data[i] = NULL;
  }
  newTable->hashFunction = hashFunction;
  newTable->equalFunction = equalFunction;
  return newTable;
}


void insertData(HashTable *table, void *key, void *data) {
  unsigned int location  = 0;
  struct HashBucket *newBucket =
      (struct HashBucket *)malloc(sizeof(struct HashBucket));

  /*
   * This is where we would check occupancy and resize, but we aren't
   * doing that here...
   */ 
  location  = ((table->hashFunction)(key)) % table->size;
  newBucket->next = table->data[location];
  newBucket->data = data;
  newBucket->key = key;
  table->data[location] = newBucket;
  table->used += 1;
}

void *findData(HashTable *table, void *key) {
  unsigned int location = ((table->hashFunction)(key)) % table->size;
  struct HashBucket *lookAt = table->data[location];
  while (lookAt != NULL) {
    if ((table->equalFunction)(key, lookAt->key) != 0) {
      return lookAt->data;
    }
    lookAt = lookAt->next;
  }
  return NULL;
}
