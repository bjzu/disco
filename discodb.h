
#ifndef __DISCODB_H__
#define __DISCODB_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <Judy.h>

typedef struct {
        const uint8_t *data;
        uint32_t len;
        uint32_t id;
} ddb_attr_t;

typedef struct {
        FILE *toc_f;
        FILE *data_f;
        FILE *valmap_f;
        FILE *valtoc_f;
        
        char *toc_name;
        char *data_name;
        char *valmap_name;
        char *valtoc_name;
        
        uint32_t data_offs;

        uint32_t num_keys;
        Pvoid_t valmap;

        /* It doesn't matter if these values oveflow.
           If they do, the db grows necessarily over 4GB and 
           discodb_build() fails. */
        uint32_t next_id;
        uint32_t valmap_offs;

        uint8_t *tmpbuf;
        uint32_t tmpbuf_len;

} discodb_t;

discodb_t *discodb_new(const char *path_prefix);
void discodb_free(discodb_t *db);
int discodb_add(discodb_t *db, const ddb_attr_t *key,
        ddb_attr_t *values, uint32_t num_values);
int discodb_build(discodb_t *db, int outfd);

/* util.c */

uint32_t read_bits(const uint8_t *src, uint64_t offs, uint32_t bits);
void write_bits(uint8_t *dst, uint64_t offs, uint32_t val);
int copy_to_buf(discodb_t *db, const void *src, uint32_t len);
uint32_t allocate_bits(discodb_t *db, uint32_t size_in_bits);
uint32_t bits_needed(uint32_t max);
int id_cmp(const void *p1, const void *p2);



#endif /* __DISCODB_H__ */
