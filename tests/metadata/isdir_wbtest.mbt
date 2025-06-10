test {
  assert_false(test_isdir("metadata/foo.txt"))
  assert_true(test_isdir("metadata/"))
  assert_false(test_isdir("metadata/bar.txt"))
}