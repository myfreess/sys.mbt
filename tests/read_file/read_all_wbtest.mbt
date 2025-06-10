///|
test {
  inspect(
    test_read_all("read_file/foo.txt"), 
    content=#|b"\x41\x42\x43\x44\x45\x46"
  )
  inspect(
    test_read_all("read_file/bar.txt"),
    content=#|b"\x31\x30\x0a\x31\x31\x0a\x31\x32\x0a\x31\x33\x0a\x31\x34\x0a\x31\x35"
  )
}
