fn test_read_all(filename: String) -> Bytes raise @sys.SysError {
  let file = @sys.open_file(filename)
  let bytes = file.read_all()
  file.close()
  return bytes
}