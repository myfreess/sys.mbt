set shell := ["bash", "-c"]

info:
  moon fmt
  moon info --target native
  rm src/errno/linux/linux.mbti
  rm src/errno/win32/win32.mbti

test:
  moon clean
  cd tests && moon clean
  cd tests && moon test --target native -v

test_with_sanitize:
  moon clean
  cd tests && moon clean
  cd tests && MOON_CC='clang -fsanitize=address -fsanitize=undefined -g -fno-omit-frame-pointer' moon test --target native -v