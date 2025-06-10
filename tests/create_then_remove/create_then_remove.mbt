fn test_create_then_remove_file(filename : String) -> Unit raise @sys.SysError {
  let file = @sys.create_file(filename)
  file.close()
  return @sys.remove_file(filename)
}

fn test_create_then_remove_dir(dirname : String) -> Unit raise @sys.SysError {
  @sys.create_dir(dirname)
  return @sys.remove_dir(dirname)
}