fn test_create_when_exist(filename: String) -> Unit raise @sys.SysError {
  // will clear file contents
  let file = @sys.create_file(filename);
  file.close()
}


test {
  test_create_when_exist("create_when_exist/foo.txt")
}