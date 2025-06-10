///|
test {
  let filename = "read_file/foo.txt"
  guard @sys.File::open(filename) is Some(file) else {
    fail("File::open(): \{filename} not exists")
  }
  guard @sys.File::read_all(file) is Some(bytes) else {
    fail("File::read_all(): \{filename} failed")
  }
  inspect(
    bytes,
    content=#|b"\x41\x42\x43\x44\x45\x46"
  )
  ignore(file.close())
}

test {
  let filename = "read_file/bar.txt"
  guard @sys.File::open(filename) is Some(file) else {
    fail("File::open(): \{filename} not exists")
  }
  guard @sys.File::read_all(file) is Some(bytes) else {
    fail("File::read_all(): \{filename} failed")
  }
  inspect(
    bytes
  , content=#|b"\x31\x30\x0a\x31\x31\x0a\x31\x32\x0a\x31\x33\x0a\x31\x34\x0a\x31\x35"
  )
  ignore(file.close())
}
