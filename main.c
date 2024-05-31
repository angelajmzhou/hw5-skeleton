#include <stdio.h>
#include <stdlib.h>
#include "hashtable.h"
#include <string.h>
#include <assert.h>

uint64_t strhash(void *s){
  return 23098;
}

int32_t streq(void *s1, void *s2){
  return !strcmp( (char *)s1, (char *)s2);
}

uint64_t inthash(void *i){
  return (uint64_t) i;
}

int32_t inteq(void *i, void *j){
  return i == j;
}

int main(){
  HashTable *t;
  
  int64_t i = 0;
  printf("Hash Table Testing\n");

  t = createHashTable(32, strhash, streq);
  assert( !findData(t, (void *) "foo"));
  insertData(t, (void *) "foo", (void *) "bar");
  printf("Foo's value is \"%s\"\n", (char *) findData(t, "foo"));

  t = createHashTable(63, inthash, inteq);

  for(i = 0; i < 2000; ++i){
    assert(!findData(t, (void *)i));
    insertData(t, (void *)i, (void *) (i+1));
    assert( (int64_t) findData(t, (void *)i) == (i+1));
  }
  for(i = 0; i < 2000; ++i){
    assert( (int64_t) findData(t, (void *)i) == (i + 1));
  }
  
  printf("Testing complete!\n");
  return 0;
}
