fn test_filesize(filename : String) -> Int raise Error {
  guard @sys.File::open(filename) is Some(file) else {
    fail("Failed to open file: \{filename}")
  }
  guard file.metadata() is Some(metadata) else {
    fail("Failed to retrieve metadata for file: \{filename}")
  }
  metadata.filesize()
}