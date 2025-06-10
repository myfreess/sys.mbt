test {
  inspect(test_filesize("metadata/foo.txt"), content="6")
  inspect(test_filesize("metadata/bar.txt"), content="17")
}