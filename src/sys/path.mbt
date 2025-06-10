

let path_separator : Char =
  if moonbit_os_iswin32() {
    '\\'
  } else {
    '/'
  }

pub type Path OsStr

pub fn Path::op_add(self : Path, other : Path) -> Path {
  self._ + other._
}

pub fn Path::from(view : @string.View) -> Path {
  Path(OsStrBuilder::from(view).to_osstr())
}

pub fn Path::join(self : Path, other : ArrayView[@string.View]) -> Path {
  let buf = OsStrBuilder::from_osstr(self._)
  for str in other {
    buf.push_char(path_separator)
    buf.push(str)
  }
  buf.to_osstr()
}

pub fn Path::as_view(self : Path) -> @bytes.View {
  self._._[:]
}

trait AsPath : AsCStr {
  to_path(Self) -> Path
}

pub impl AsPath for Path with to_path(self) {
  return self
}

pub impl AsPath for @string.View with to_path(self) {
  return Path::from(self)
}

pub impl AsPath for String with to_path(self) {
  return Path::from(self[:])
}

pub impl AsPath for OsStr with to_path(self) {
  return Path(self)
}

