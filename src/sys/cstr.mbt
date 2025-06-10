pub type CStr Bytes

trait AsCStr {
  to_cstr(Self) -> CStr
}

pub impl AsCStr for OsStr with to_cstr(self) {
  if moonbit_os_iswin32() {
    // UTF-16 NULL terminator
    self._ + "\x00\x00"
  } else {
    self._ + "\x00"
  }
}

pub impl AsCStr for OsStrBuilder with to_cstr(self) {
  if moonbit_os_iswin32() {
    // UTF-16 NULL terminator
    self._..write_byte(0x00)..write_byte(0x00)
  } else {
    self._.write_byte(0x00)
  }
  return CStr(self._.contents())
}

pub impl AsCStr for String with to_cstr(self) {
  return OsStr::from(self[:]).to_cstr()
}

pub impl AsCStr for @string.View with to_cstr(self) {
  return OsStr::from(self).to_cstr()
}

pub impl AsCStr for Path with to_cstr(self) {
  return self._.to_cstr()
}