fn test_filesize(filename : String) -> Int raise Error {
  let file = @sys.open_file(filename) catch {
    _ => fail("Failed to open file: \{filename}")
  }
  let metadata = file.metadata() catch {
    _ => fail("Failed to retrieve metadata for file: \{filename}")
  }
  metadata.filesize()
}

fn test_isdir(filename : String) -> Bool raise Error {
  let file = @sys.open_file(filename) catch {
    _ => fail("Failed to open file: \{filename}")
  }
  let metadata = file.metadata() catch {
    _ => fail("Failed to retrieve metadata for file: \{filename}")
  }
  metadata.is_dir()
}