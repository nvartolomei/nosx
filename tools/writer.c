#include <stdio.h>
#include <errno.h>
#include <string.h>

int main(int argc, const char * argv[])
{
    FILE * loader_file;
    FILE * kernel_file;
    FILE * boot_file;

    char buffer[512] = { 0 };

    if (argc != 4) {
        printf("OS Image Writer\n\n");
        printf("Usage: %s loader kernel out\n", argv[0]);

        return 1;
    }

    loader_file = fopen(argv[1], "r");
    if (!loader_file) {
        printf("Could not open loader binary: %s\n", strerror(errno));

        return 2;
    }

    if (fseek(loader_file, 0, SEEK_END)) {
        printf("Could not find loader binary end: %s\n", strerror(errno));

        return 2;
    }

    long loader_size = ftell(loader_file);
    if (loader_size > 512) {
        printf("Loader binary too big. Boot record could not exceed 512 bytes.\n");

        return 3;
    }

    if (fseek(loader_file, 0, SEEK_SET)) {
        printf("Could not find loader binary start: %s\n", strerror(errno));

        return 2;
    }

    int read = fread(buffer, 1, 512, loader_file);
    fclose(loader_file);

    boot_file = fopen(argv[3], "w+");
    if (!boot_file) {
        printf("Could not write boot sector to out: %s\n", strerror(errno));

        return 2;
    }

    int write = fwrite(buffer, 1, read, boot_file);

    if (write != read) {
        printf("Error occured when trying to write boot sector(loader): %s", strerror(errno));

        return 2;
    }

    kernel_file = fopen(argv[2], "r");
    if (!kernel_file) {
        printf("Could not open kernel binary: %s\n", strerror(errno));
        printf("Boot sector will containt bootloader only...");

        return 2;
    }

    if (fseek(boot_file, 33 * 512, SEEK_SET)) {
        printf("%s\n", strerror(errno));

        return 2;
    }

    for (;;) {
        read = fread(buffer, 1, 512, kernel_file);
        write = fwrite(buffer, 1, read, boot_file);

        if (write != read) {
            printf("Error occured when trying to write boot sector(kernel): %s", strerror(errno));

            return 2;
        }

        /* File end */
        if (read < 512) break;
    }

    /* Make file right size: 1.44MB */
    buffer[0] = 0;
    fseek(boot_file, 1440 * 1024 - 1, SEEK_SET);
    fwrite(buffer, 1, 1, boot_file);

    fclose(kernel_file);
    fclose(boot_file);

    return 0;
}