///|
#external
pub type File

///|
#external
pub type OpenOptions

///|
#external
pub type Metadata

///|
#external
pub type Permissions

///|
extern "c" fn moonbit_file_is_invalid(file : File) -> Bool = "moonbit_file_is_invalid"

///|
extern "c" fn moonbit_file_open(filename : CStr) -> File = "moonbit_file_open"

///|
extern "c" fn moonbit_file_create(filename : CStr) -> File = "moonbit_file_create"

///|
extern "c" fn moonbit_file_read_all(file : File, bytes : Bytes, n : Int) -> Int = "moonbit_file_read_all"

///|
extern "c" fn moonbit_file_write_all(
  file : File,
  bytes : Bytes,
  n : Int
) -> Int = "moonbit_file_write_all"

///|
extern "c" fn moonbit_file_close(file : File) -> Bool = "moonbit_file_close"

///|
extern "c" fn moonbit_file_metadata_new() -> Metadata = "moonbit_file_metadata_new"

///|
extern "c" fn moonbit_file_metadata(file : File, stat : Metadata) -> Bool = "moonbit_file_metadata"

///|
extern "c" fn moonbit_file_symlink_metadata(
  file : File,
  stat : Metadata
) -> Bool = "moonbit_file_symlink_metadata"

///|
extern "c" fn moonbit_metadata_filetype_is_dir(stat : Metadata) -> Bool = "moonbit_metadata_filetype_is_dir"

///|
extern "c" fn moonbit_metadata_filetype_is_file(stat : Metadata) -> Bool = "moonbit_metadata_filetype_is_file"

///|
extern "c" fn moonbit_metadata_filetype_is_symlink(stat : Metadata) -> Bool = "moonbit_metadata_filetype_is_symlink"

///|
extern "c" fn moonbit_file_metadata_filesize(stat : Metadata) -> Int = "moonbit_file_metadata_filesize"

///|
extern "c" fn moonbit_file_metadata_permissions(stat : Metadata) -> Permissions = "moonbit_file_metadata_permissions"

///|
extern "c" fn moonbit_metadata_permissions_readonly(perm : Permissions) -> Bool = "moonbit_metadata_permissions_readonly"

///|
pub fn[P : AsPath] File::open(filename : P) -> File? {
  let filename = filename.to_path().to_cstr()
  let file = moonbit_file_open(filename)
  if moonbit_file_is_invalid(file) {
    None
  } else {
    Some(file)
  }
}

///|
pub fn[P : AsPath] File::create(filename : P) -> File? {
  let filename = filename.to_path().to_cstr()
  let file = moonbit_file_create(filename)
  if moonbit_file_is_invalid(file) {
    None
  } else {
    Some(file)
  }
}

///|
pub fn File::close(self : File) -> Bool {
  return moonbit_file_close(self)
}

///|
pub fn File::metadata(self : File) -> Metadata? {
  let stat = moonbit_file_metadata_new()
  let successfully_init_stat = moonbit_file_metadata(self, stat)
  if successfully_init_stat {
    return Some(stat)
  } else {
    return None
  }
}

///|
pub fn File::symlink_metadata(self : File) -> Metadata? {
  let stat = moonbit_file_metadata_new()
  let successfully_init_stat = moonbit_file_symlink_metadata(self, stat)
  if successfully_init_stat {
    return Some(stat)
  } else {
    return None
  }
}

///|
pub fn Metadata::filesize(self : Metadata) -> Int {
  return moonbit_file_metadata_filesize(self)
}

///|
pub fn Metadata::is_dir(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_dir(self)
}

///|
pub fn Metadata::is_file(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_file(self)
}

///|
pub fn Metadata::is_symlink(self : Metadata) -> Bool {
  return moonbit_metadata_filetype_is_symlink(self)
}

///|
pub fn File::read_all(self : File) -> Bytes? {
  guard self.metadata() is Some(metadata) else { return None }
  let size = metadata.filesize()
  let buf = Bytes::make(size, 0)
  let have_read = moonbit_file_read_all(self, buf, size)
  guard have_read == size else { return None }
  return Some(buf)
}

///|
pub fn File::write_all(self : File, buf : Bytes) -> Bool {
  let size = buf.length()
  let written = moonbit_file_write_all(self, buf, size)
  return written == size
}
