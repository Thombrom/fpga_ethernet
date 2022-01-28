#include <stdio.h>
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')

#include <stddef.h>
#include <stdint.h>

void print_binary(uint32_t value) {
    printf(BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN,
            BYTE_TO_BINARY((value >> 24) & 0xff), BYTE_TO_BINARY((value >> 16) & 0xff), BYTE_TO_BINARY((value >> 8) & 0xff), BYTE_TO_BINARY((value >> 0) & 0xff));
}

void print_hex(uint32_t value) {
    printf("%02hhx%02hhx%02hhx%02hhx",
            (value >> 24) & 0xff, (value >> 16) & 0xff, (value >> 8) & 0xff, (value >> 0) & 0xff);
}


uint32_t crc32(const char *s,size_t n) {
    uint32_t crc=0xFFFFFFFF;

    for(size_t i=0;i<n;i++) {
        char ch=s[i];
        for(size_t j=0;j<8;j++) {
            uint32_t b=(ch^crc)&1;
            printf("\n-------------------\n%ld:%ld - "BYTE_TO_BINARY_PATTERN"\n", i, j, BYTE_TO_BINARY(ch));
            print_hex(crc);  printf("\n");
            print_hex(~crc); printf("\n");
            //printf(BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"\n",
            //        BYTE_TO_BINARY((crc >> 24) & 0xff), BYTE_TO_BINARY((crc >> 16) & 0xff), BYTE_TO_BINARY((crc >> 8) & 0xff), BYTE_TO_BINARY((crc >> 0) & 0xff));
            crc>>=1;
            print_hex(crc); printf("\n");
            print_hex(0xEDB88320); printf(" & %d\n", b ? 1 : 0);
            //printf(BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"\n",
            //        BYTE_TO_BINARY((crc >> 24) & 0xff), BYTE_TO_BINARY((crc >> 16) & 0xff), BYTE_TO_BINARY((crc >> 8) & 0xff), BYTE_TO_BINARY((crc >> 0) & 0xff));
            //printf(BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN"_"BYTE_TO_BINARY_PATTERN" & %d\n",
            //        BYTE_TO_BINARY((0xEDB88320 >> 24) & 0xff), BYTE_TO_BINARY((0xEDB88320 >> 16) & 0xff), BYTE_TO_BINARY((0xEDB88320 >> 8) & 0xff), BYTE_TO_BINARY((0xEDB88320 >> 0) & 0xff), b ? 1 : 0);
            if(b) crc=crc^0xEDB88320;
            ch>>=1;
        }
    }

    return ~crc;
}


char data[] = {
    0x10, 0x65, 0x30, 0x70, 0x3d, 0x6d,
    0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc,
    0x08, 0x06,
    0x00, 0x01, 0x08, 0x00, 0x06, 0x04,
    0x00, 0x01,
    0x70, 0x4d, 0x7b, 0x63, 0x18, 0x8f,
    0x0a, 0x1f, 0x55, 0x6a,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x0a, 0x1f, 0x55, 0xff,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // padding
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // padding
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // padding
};

int main(int argc, char** argv) {
    for (size_t itt = 0; itt < sizeof(data) / sizeof(char); itt++)
        printf("%02hhx", data[itt]);

    uint32_t real_crc = crc32(data, sizeof(data) / sizeof(char));
    printf("Real: \t%02hhx%02hhx%02hhx%02hhx\n",
            (real_crc >> 24) & 0xff, (real_crc >> 16) & 0xff, (real_crc >> 8) & 0xff, (real_crc >> 0) & 0xff);

    return 0;
}
