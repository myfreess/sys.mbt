test "open file" {
  assert_true(@sys.File::open("open_file/foo.txt") is Some(_))
  assert_true(@sys.File::open("bar.txt") is None)
}