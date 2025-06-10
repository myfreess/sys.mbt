fn test_read_all(filename: String) -> Bytes raise Error {
  guard @sys.File::open(filename) is Some(file) else {
    fail("File::open(): {filename} not exists")
  }
  guard file.read_all() is Some(bytes) else {
    fail("File::read_all(): {filename} failed")
  }
  ignore(file.close())
  return bytes
}