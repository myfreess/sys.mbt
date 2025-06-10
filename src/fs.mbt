///|
#external
pub type File

///|
#external
pub type FileType

///|
pub type Metadata

///|
#external
pub type Permissions

///|
extern "c" fn moonbit_file_is_invalid(file : File) -> Bool = "moonbit_file_is_invalid"

///|
#borrow(filename)
extern "c" fn moonbit_file_open(filename : CStr) -> File = "moonbit_file_open"

///|
#borrow(filename)
extern "c" fn moonbit_remove_file(filename : CStr) -> Bool = "moonbit_remove_file"

///|
#borrow(dirname)
extern "c" fn moonbit_create_dir(dirname : CStr) -> Bool = "moonbit_create_dir"

///|
#borrow(dirname)
extern "c" fn moonbit_remove_dir(dirname : CStr) -> Bool = "moonbit_remove_dir"

///|
#borrow(filename)
extern "c" fn moonbit_file_create(filename : CStr) -> File = "moonbit_file_create"

///|
#borrow(buf)
extern "c" fn moonbit_file_read(
  file : File,
  buf : FixedArray[Byte],
  capacity : Int
) -> Int = "moonbit_file_read"

///|
#borrow(buf)
extern "c" fn moonbit_file_write(
  file : File,
  buf : FixedArray[Byte],
  capacity : Int
) -> Int = "moonbit_file_write"

///|
#borrow(bytes)
extern "c" fn moonbit_file_read_all(
  file : File,
  bytes : Bytes,
  capacity : Int
) -> Int = "moonbit_file_read_all"

///|
#borrow(bytes)
extern "c" fn moonbit_file_write_all(
  file : File,
  bytes : Bytes,
  capacity : Int
) -> Int = "moonbit_file_write_all"

///|
extern "c" fn moonbit_file_close(file : File) -> Bool = "moonbit_file_close"

///|
extern "c" fn moonbit_file_metadata_new() -> Metadata = "moonbit_file_metadata_new"

///|
#borrow(stat)
extern "c" fn moonbit_file_metadata(file : File, stat : Metadata) -> Bool = "moonbit_file_metadata"

///|
#borrow(stat)
extern "c" fn moonbit_file_metadata_filetype(stat : Metadata) -> FileType = "moonbit_file_metadata_filetype"

///|
extern "c" fn moonbit_metadata_filetype_is_dir(filetype : FileType) -> Bool = "moonbit_metadata_filetype_is_dir"

///|
extern "c" fn moonbit_metadata_filetype_is_file(filetype : FileType) -> Bool = "moonbit_metadata_filetype_is_file"

///|
extern "c" fn moonbit_metadata_filetype_is_symlink(filetype : FileType) -> Bool = "moonbit_metadata_filetype_is_symlink"

///|
#borrow(stat)
extern "c" fn moonbit_file_metadata_filesize(stat : Metadata) -> Int = "moonbit_file_metadata_filesize"

///|
#borrow(stat)
extern "c" fn moonbit_file_metadata_permissions(stat : Metadata) -> Permissions = "moonbit_file_metadata_permissions"

///|
extern "c" fn moonbit_metadata_permissions_readonly(perm : Permissions) -> Bool = "moonbit_metadata_permissions_readonly"

///|
/// Open a file for reading.
/// If the file does not exist, a `SysError` is raised.
pub fn[P : AsPath] open_file(filename : P) -> File raise SysError {
  let filename = filename.to_path().to_cstr()
  let file = moonbit_file_open(filename)
  if moonbit_file_is_invalid(file) {
    raise last_sys_error()
  } else {
    return file
  }
}

///|
/// Creates a new file with the given filename.
/// If the file already exists, it will be truncated to zero length.
/// If the file cannot be created, a `SysError` is raised.
pub fn[P : AsPath] create_file(filename : P) -> File raise SysError {
  let filename = filename.to_path().to_cstr()
  let file = moonbit_file_create(filename)
  if moonbit_file_is_invalid(file) {
    raise last_sys_error()
  } else {
    return file
  }
}

///|
pub fn[P : AsPath] remove_file(filename : P) -> Unit raise SysError {
  let filename = filename.to_path().to_cstr()
  if not(moonbit_remove_file(filename)) {
    raise last_sys_error()
  }
}

///|
pub fn[P : AsPath] create_dir(dirname : P) -> Unit raise SysError {
  let dirname = dirname.to_path().to_cstr()
  if not(moonbit_create_dir(dirname)) {
    raise last_sys_error()
  }
}

///|
pub fn[P : AsPath] remove_dir(dirname : P) -> Unit raise SysError {
  let filename = dirname.to_path().to_cstr()
  if not(moonbit_remove_dir(filename)) {
    raise last_sys_error()
  }
}

///|
pub fn File::close(self : File) -> Unit raise SysError {
  if not(moonbit_file_close(self)) {
    raise last_sys_error()
  }
}

///|
pub fn File::metadata(self : File) -> Metadata raise SysError {
  let stat = moonbit_file_metadata_new()
  let successfully_init_stat = moonbit_file_metadata(self, stat)
  if successfully_init_stat {
    return stat
  } else {
    raise last_sys_error()
  }
}

///|
// pub fn File::symlink_metadata(self : File) -> Metadata? {
//   let stat = moonbit_file_metadata_new()
//   let successfully_init_stat = moonbit_file_symlink_metadata(self, stat)
//   if successfully_init_stat {
//     return Some(stat)
//   } else {
//     return None
//   }
// }

///|
pub fn Metadata::filesize(self : Metadata) -> Int {
  return moonbit_file_metadata_filesize(self)
}

///|
pub fn Metadata::filetype(self : Metadata) -> FileType {
  return moonbit_file_metadata_filetype(self)
}

///|
pub fn Metadata::is_dir(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_dir(self.filetype())
}

///|
pub fn Metadata::is_file(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_file(self.filetype())
}

///|
pub fn Metadata::is_symlink(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_symlink(self.filetype())
}

///|
pub fn Metadata::permissions(self : Metadata) -> Permissions {
  return moonbit_file_metadata_permissions(self)
}

///|
pub fn Permissions::is_readonly(self : Permissions) -> Bool {
  return moonbit_metadata_permissions_readonly(self)
}

///|
pub fn File::read(self : File, buf : FixedArray[Byte]) -> Int raise SysError {
  let capacity = buf.length()
  let have_read = moonbit_file_read(self, buf, capacity)
  guard have_read >= 0 else { raise last_sys_error() }
  return have_read
}

///|
pub fn File::write(self : File, buf : FixedArray[Byte]) -> Int raise SysError {
  let capacity = buf.length()
  let written = moonbit_file_write(self, buf, capacity)
  guard written >= 0 else { raise last_sys_error() }
  return written
}

///|
pub fn File::read_all(self : File) -> Bytes raise SysError {
  let metadata = self.metadata()
  let size = metadata.filesize()
  let buf = Bytes::make(size, 0)
  let have_read = moonbit_file_read_all(self, buf, size)
  guard have_read == size else { raise last_sys_error() }
  return buf
}

///|
pub fn File::write_all(self : File, buf : Bytes) -> Unit raise SysError {
  let size = buf.length()
  let written = moonbit_file_write_all(self, buf, size)
  guard written == size else { raise last_sys_error() }
}
