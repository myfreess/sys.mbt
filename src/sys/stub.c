#ifndef moonbit_h_INCLUDED
#include "moonbit.h"
typedef int32_t Bool;
#endif

#if defined (_WIN32) || defined (_WIN64)
#define UNICODE
#include <stdbool.h>
#include <windows.h>
#else
#pragma clang diagnostic ignored "-Wpointer-sign"
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#endif

#if defined (_WIN32) || defined (_WIN64)
MOONBIT_EXPORT Bool moonbit_os_iswin32() {
    return true;
}
#else
MOONBIT_EXPORT Bool moonbit_os_iswin32() {
    return false;
}
#endif

// Errno related functions
#if defined (_WIN32) || defined (_WIN64)
#else
MOONBIT_EXPORT int32_t moonbit_errno_is_interrupted() {
    return EINTR == errno;
}

MOONBIT_EXPORT moonbit_bytes_t moonbit_errno_get_errmsg() {
    const char* err_msg = strerror(errno);
    int32_t len = strlen(err_msg);
    moonbit_bytes_t err_msg_ret = moonbit_make_bytes(len, 0);
    memcpy(err_msg_ret, err_msg, len);
    return err_msg_ret;
}
#endif 

// FileSystem related functions
#if defined (_WIN32) || defined (_WIN64)

#define FILE HANDLE

MOONBIT_EXPORT Bool moonbit_file_is_invalid(FILE file) {
    return INVALID_HANDLE_VALUE == file;
}

MOONBIT_EXPORT FILE moonbit_file_open(moonbit_bytes_t filename) {
    return CreateFileW(filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);
}

MOONBIT_EXPORT FILE moonbit_file_create(moonbit_bytes_t filename) {
    return CreateFileW(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);
}

typedef LPBY_HANDLE_FILE_INFORMATION FILE_STAT;

MOONBIT_EXPORT FILE_STAT moonbit_file_metadata_new() {
    return malloc(sizeof(LPBY_HANDLE_FILE_INFORMATION));
}

MOONBIT_EXPORT Bool moonbit_file_metadata(FILE file, FILE_STAT stat) {
    return GetFileInformationByHandle(file, stat);
}

#else

#define FILE int32_t

MOONBIT_EXPORT Bool moonbit_file_is_invalid(FILE file) {
    return -1 == file;
}

MOONBIT_EXPORT FILE moonbit_file_open(moonbit_bytes_t filename) {
    return open(filename,O_CLOEXEC | O_RDONLY);
}

MOONBIT_EXPORT FILE moonbit_file_create(moonbit_bytes_t filename) {
    // 0o666 = (6 × 8^2) + (6 × 8^1) + (6 × 8^0) = 384 + 48 + 6 = 438
    return open(filename, O_CLOEXEC | O_WRONLY | O_CREAT, 438);
}


MOONBIT_EXPORT int32_t moonbit_file_read_all(FILE file, moonbit_bytes_t buf, int32_t n) {
    // asssert filesize == len(buf) == n
    int32_t capacity = n;
    int32_t have_read = 0;
    while (have_read < capacity) {
        int32_t ret = read(file, buf + have_read, capacity - have_read);
        if (-1 == ret) {
            if (moonbit_errno_is_interrupted()) {
                continue; // retry on interrupt
            } else {
                return -1;
            }
        }
        if (0 == ret) {
            break; // EOF
        } else {
            have_read += ret;
        }
        
    }
    return have_read;
}


MOONBIT_EXPORT int32_t moonbit_file_write_all(FILE file, moonbit_bytes_t buf, int32_t n) {
    // asssert len(buf) == n
    int32_t capacity = n;
    int32_t written = 0;
    while (written < capacity) {
        int32_t ret = write(file, buf + written, capacity - written);
        if (-1 == ret) {
            if (moonbit_errno_is_interrupted()) {
                continue; // retry on interrupt
            } else {
                return -1;
            }
            
        }
        written += ret;
    }
    return written;
}

MOONBIT_EXPORT Bool moonbit_file_close(FILE file) {
    return close(file) != -1;
}

typedef struct stat* FILE_STAT;


MOONBIT_EXPORT FILE_STAT moonbit_file_metadata_new() {
    return malloc(sizeof(FILE_STAT));
}

// TODO: use `statx` on Linux if
// defined (LINUX_VERSION_CODE) && defined (__GLIBC__) && LINUX_VERSION_CODE >= KERNEL_VERSION(4, 11, 0) && __GLIBC__ >= 2 && __GLIBC_MINOR__ >= 28
MOONBIT_EXPORT Bool moonbit_file_metadata(FILE file, FILE_STAT stat) {
    return fstat(file, stat) != -1;
}

MOONBIT_EXPORT Bool moonbit_file_symlink_metadata(moonbit_bytes_t file, FILE_STAT stat) {
    return lstat(file, stat) != -1;
}

MOONBIT_EXPORT int32_t moonbit_file_metadata_filesize(FILE_STAT stat) {
    return stat->st_size;
}

typedef mode_t FILE_TYPE;

MOONBIT_EXPORT FILE_TYPE moonbit_file_metadata_filetype(FILE_STAT stat) {
    return stat->st_mode;
}

MOONBIT_EXPORT FILE_TYPE moonbit_metadata_filetype_mask(FILE_TYPE filetype) {
    return (filetype & S_IFMT);
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_dir(FILE_TYPE filetype) {
    return (moonbit_metadata_filetype_mask(filetype) == S_IFDIR);
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_file(FILE_TYPE filetype) {
    return (moonbit_metadata_filetype_mask(filetype) == S_IFREG);
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_symlink(FILE_TYPE filetype) {
    return (moonbit_metadata_filetype_mask(filetype) == S_IFLNK);
}

typedef mode_t FILE_PERMISSIONS;

MOONBIT_EXPORT FILE_PERMISSIONS moonbit_file_metadata_permissions(FILE_STAT stat) {
    return stat->st_mode;
}

MOONBIT_EXPORT int32_t moonbit_metadata_permissions_readonly(FILE_PERMISSIONS perm) {
    // 0o222 = (2 × 8^2) + (2 × 8^1) + (2 × 8^0) = 128 + 16 + 2 = 146
    return (perm & 146) == 0;
}

#endif