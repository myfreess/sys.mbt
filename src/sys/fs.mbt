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
extern "c" fn moonbit_file_is_invalid(file : File) -> Bool = "moonbit_file_is_invalid"

///|
extern "c" fn moonbit_file_open(filename : CStr) -> File = "moonbit_file_open"

///|
extern "c" fn moonbit_file_read_all(
  file : File,
  bytes : Bytes,
  n : Int
) -> Int = "moonbit_file_read_all"

///|
extern "c" fn moonbit_file_close(file : File) -> Bool = "moonbit_file_close"

///|
extern "c" fn moonbit_file_metadata_new() -> Metadata = "moonbit_file_metadata_new"

///|
extern "c" fn moonbit_file_metadata(file : File, stat : Metadata) -> Bool = "moonbit_file_metadata"

///|
extern "c" fn moonbit_file_metadata_filesize(stat : Metadata) -> Int = "moonbit_file_metadata_filesize"


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

pub fn File::close(self : File) -> Bool {
  return moonbit_file_close(self)
}

pub fn File::metadata(self : File) -> Metadata? {
  let stat = moonbit_file_metadata_new()
  let successfully_init_stat = moonbit_file_metadata(self, stat)
  if successfully_init_stat {
    return Some(stat)
  } else {
    // assert rescode == -1
    return None
  }
}

pub fn Metadata::filesize(self : Metadata) -> Int {
  return moonbit_file_metadata_filesize(self)
}

pub fn File::read_all(self : File) -> Bytes? {
  guard self.metadata() is Some(metadata) else {
    return None
  }
  let size = metadata.filesize()
  let buf = Bytes::make(size, 0)
  let have_read = moonbit_file_read_all(self, buf, size)
  // guard have_read == size else {
  //   return None
  // }
  return Some(buf)
}