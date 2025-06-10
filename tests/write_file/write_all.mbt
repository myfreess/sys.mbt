fn test_write_all(filename: String, content: Bytes) -> Bool raise Error {
  guard @sys.File::create(filename) is Some(file) else {
    fail("File::create(): {filename} failed")
  }
  guard file.write_all(content) else {
    fail("File::write_all(): {filename} failed")
  }
  ignore(file.close())
  return true
}