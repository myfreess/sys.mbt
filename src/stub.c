#ifndef moonbit_h_INCLUDED
#include "moonbit.h"
typedef int32_t Bool;
void moonbit_release_common_object(void* self) {}
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
MOONBIT_EXPORT int32_t moonbit_errno_get_errcode() {
    // implicit convert DWORD error code to int32_t
    return GetLastError();
}

Bool moonbit_errno_is_interrupted() {
    return false;
}

#else
int32_t moonbit_errno_is_interrupted() {
    return EINTR == errno;
}

MOONBIT_EXPORT int32_t moonbit_errno_get_errcode() {
    return errno;
}
#endif 

// FileSystem related functions
#if defined (_WIN32) || defined (_WIN64)

#define FILE HANDLE

MOONBIT_EXPORT Bool moonbit_file_is_invalid(FILE file) {
    return INVALID_HANDLE_VALUE == file;
}

MOONBIT_EXPORT FILE moonbit_file_open(moonbit_bytes_t filename) {
    return CreateFileW(filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN | FILE_FLAG_BACKUP_SEMANTICS, NULL);
}

MOONBIT_EXPORT FILE moonbit_file_create(moonbit_bytes_t filename) {
    return CreateFileW(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);
}

MOONBIT_EXPORT Bool moonbit_remove_file(moonbit_bytes_t filename) {
    return DeleteFileW(filename);
}

MOONBIT_EXPORT Bool moonbit_create_dir(moonbit_bytes_t filename) {
    // CreateDirectoryW returns TRUE if the directory is created successfully, or FALSE if it already exists.
    // If the directory already exists, we return TRUE to indicate success.
    return CreateDirectoryW(filename, NULL);
}

MOONBIT_EXPORT Bool moonbit_remove_dir(moonbit_bytes_t filename) {
    return RemoveDirectoryW(filename);
}

typedef LPBY_HANDLE_FILE_INFORMATION FILE_STAT;

MOONBIT_EXPORT FILE_STAT moonbit_file_metadata_new() {
    return moonbit_make_external_object(&moonbit_release_common_object, sizeof(BY_HANDLE_FILE_INFORMATION));
}

MOONBIT_EXPORT Bool moonbit_file_metadata(FILE file, FILE_STAT stat) {
    return GetFileInformationByHandle(file, stat);
}

MOONBIT_EXPORT int32_t moonbit_file_read(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    DWORD bytes_read;
    BOOL ret = ReadFile(file, buf, capacity, &bytes_read, NULL);
    if (!ret) {
        return -1;
    }
    return bytes_read;
}

MOONBIT_EXPORT int32_t moonbit_file_write(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    DWORD bytes_written;
    BOOL ret = WriteFile(file, buf, capacity, &bytes_written, NULL);
    if (!ret) {
        return -1;
    }
    return bytes_written;
}


MOONBIT_EXPORT int32_t moonbit_file_read_all(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    // assert filesize == len(buf) == capacity
    int32_t have_read = 0;
    while (have_read < capacity) {
        DWORD bytes_read;
        BOOL ret = ReadFile(file, buf + have_read, capacity - have_read, &bytes_read, NULL);
        if (!ret) {
            return -1;
        }
        if (0 == bytes_read) {
            break; // EOF
        } else {
            have_read += bytes_read;
        }
    }
    return have_read;
}

MOONBIT_EXPORT int32_t moonbit_file_write_all(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    // assert len(buf) == capacity
    int32_t written = 0;
    while (written < capacity) {
        DWORD bytes_written;
        BOOL ret = WriteFile(file, buf + written, capacity - written, &bytes_written, NULL);
        if (!ret) {
            return -1;
        }
        written += bytes_written;
    }
    return written;
}

MOONBIT_EXPORT Bool moonbit_file_close(FILE file) {
    return CloseHandle(file);
}

MOONBIT_EXPORT int32_t moonbit_file_metadata_filesize(FILE_STAT stat) {
    // only works when filesize less than 2^31 - 1 bytes
    return stat->nFileSizeLow;
}

typedef DWORD FILE_TYPE;

MOONBIT_EXPORT FILE_TYPE moonbit_file_metadata_filetype(FILE_STAT stat) {
    return stat->dwFileAttributes;
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_dir(FILE_TYPE filetype) {
    return (filetype & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_file(FILE_TYPE filetype) {
    return !(moonbit_metadata_filetype_is_dir(filetype) || moonbit_metadata_filetype_is_symlink(filetype));
}

MOONBIT_EXPORT int32_t moonbit_metadata_filetype_is_symlink(FILE_TYPE filetype) {
    return (filetype & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
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
    return open(filename, O_CLOEXEC | O_WRONLY | O_CREAT, 0666);
}

MOONBIT_EXPORT Bool moonbit_remove_file(moonbit_bytes_t filename) {
    return unlink(filename) != -1;
}

MOONBIT_EXPORT Bool moonbit_create_dir(moonbit_bytes_t dirname) {
    // 0o755 = (7 × 8^2) + (5 × 8^1) + (5 × 8^0) = 448 + 40 + 5 = 493
    return mkdir(dirname, 0755) != -1;
}
MOONBIT_EXPORT Bool moonbit_remove_dir(moonbit_bytes_t dirname) {
    return rmdir(dirname) != -1;
}

MOONBIT_EXPORT int32_t moonbit_file_read(FILE file, uint8_t* buf, int32_t capacity) {
    // assert len(buf) == capacity
    int32_t bytes_read = read(file, buf, capacity);
    return bytes_read;
}

MOONBIT_EXPORT int32_t moonbit_file_write(FILE file, uint8_t* buf, int32_t capacity) {
    // assert len(buf) == capacity
    int32_t bytes_written = write(file, buf, capacity);
    return bytes_written;
}


MOONBIT_EXPORT int32_t moonbit_file_read_all(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    // asssert filesize == len(buf) == capacity
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


MOONBIT_EXPORT int32_t moonbit_file_write_all(FILE file, moonbit_bytes_t buf, int32_t capacity) {
    // asssert len(buf) == capacity
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
    return moonbit_make_external_object(&moonbit_release_common_object, sizeof(struct stat));
}

// TODO: use `statx` on Linux if
// defined (LINUX_VERSION_CODE) && defined (__GLIBC__) && LINUX_VERSION_CODE >= KERNEL_VERSION(4, 11, 0) && __GLIBC__ >= 2 && __GLIBC_MINOR__ >= 28
MOONBIT_EXPORT Bool moonbit_file_metadata(FILE file, FILE_STAT stat) {
    return fstat(file, stat) != -1;
}

// MOONBIT_EXPORT Bool moonbit_file_symlink_metadata(moonbit_bytes_t file, FILE_STAT stat) {
//     return lstat(file, stat) != -1;
// }

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
    return (perm & 0222) == 0;
}

#endif

// stdio related functions
#if defined (_WIN32) || defined (_WIN64)

MOONBIT_EXPORT FILE moonbit_stdin() {
    return GetStdHandle(STD_INPUT_HANDLE);
}

MOONBIT_EXPORT FILE moonbit_stdout() {
    return GetStdHandle(STD_OUTPUT_HANDLE);
}

MOONBIT_EXPORT FILE moonbit_stderr() {
    return GetStdHandle(STD_ERROR_HANDLE);
}
#else

MOONBIT_EXPORT FILE moonbit_stdin() {
    return STDIN_FILENO;
}
MOONBIT_EXPORT FILE moonbit_stdout() {
    return STDOUT_FILENO;
}
MOONBIT_EXPORT FILE moonbit_stderr() {
    return STDERR_FILENO;
}

#endif