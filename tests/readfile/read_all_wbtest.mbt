///|
test {
  inspect(
    test_read_all("readfile/foo.txt"), 
    content=#|b"\x41\x42\x43\x44\x45\x46"
  )
  inspect(
    test_read_all("readfile/bar.txt"),
    content=#|b"\x31\x30\x0a\x31\x31\x0a\x31\x32\x0a\x31\x33\x0a\x31\x34\x0a\x31\x35"
  )
  inspect(
    (try? test_read_all("no_exist.txt")).map_err(_.kind()),
    content="Err(NotFound)"
  )
}
