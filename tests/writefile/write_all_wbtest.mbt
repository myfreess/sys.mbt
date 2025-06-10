test {
  test_write_all("writefile/foo.txt", b"\x41\x42\x43\x44\x45\x46")
  test_write_all("writefile/bar.txt", b"\x31\x30\x0a\x31\x31\x0a\x31\x32\x0a\x31\x33\x0a\x31\x34\x0a\x31\x35")
  let bar2 = @sys.create_file("writefile/bar2.txt")
  bar2.write_all(b"\x31\x30\x0a")
  bar2.write_all(b"\x31\x31\x0a")
  bar2.write_all(b"\x31\x32\x0a")
  bar2.write_all(b"\x31\x33\x0a")
  bar2.write_all(b"\x31\x34\x0a")
  bar2.write_all(b"\x31\x35")
  bar2.close()
}