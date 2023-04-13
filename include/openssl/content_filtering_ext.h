#ifndef __CONTENT_FILTERING_EXT_H__
#define __CONTENT_FILTERING_EXT_H__

#include <stdint.h>

#define SCHEMA_NAME_LENGTH      64
#define EC_NAME_LENGTH          64

/* Structure for content filtering extension data */
typedef struct content_filtering_ext_st {
    char schema_name[SCHEMA_NAME_LENGTH];
    char elliptic_curve_name[EC_NAME_LENGTH];
    uint16_t params_length;
    unsigned char *params;
} CONTENT_FILTERING_EXTENSION;

/* Create and initialize a new content filtering extension */
CONTENT_FILTERING_EXTENSION *create_content_filtering_ext(const char* schema_name,
                                                          const char* ec_name,
                                                          const unsigned char *params,
                                                          uint16_t params_length);

/* Frees the content_filtering extension */
void free_content_filtering_ext(CONTENT_FILTERING_EXTENSION *content_filtering_ext);

#endif /* endif __CONTENT_FILTERING_EXT_H__ */
