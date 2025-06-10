fn test_write_all(filename: String, content: Bytes) -> Unit raise Error {
  let file = @sys.create_file(filename) catch {
    _ => fail("File::create(): \{filename} failed")
  }
  file.write_all(content) catch {
    _ => fail("File::write_all(): \{filename} failed")
  }
  file.close()
}