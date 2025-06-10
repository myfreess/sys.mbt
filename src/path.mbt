///|
let path_separator : Char = if moonbit_os_iswin32() { '\\' } else { '/' }

///|
type Path OsStr

///|
pub fn Path::op_add(self : Path, other : Path) -> Path {
  self.inner() + other.inner()
}

///|
pub fn Path::from(view : @string.View) -> Path {
  Path(OsStrBuilder::from(view).to_osstr())
}

///|
pub fn Path::join(self : Path, other : ArrayView[@string.View]) -> Path {
  let buf = OsStrBuilder::from_osstr(self.inner())
  for str in other {
    buf.push_char(path_separator)
    buf.push(str)
  }
  buf.to_osstr()
}

///|
pub fn Path::as_view(self : Path) -> @bytes.View {
  self.inner().inner()[:]
}

///|
trait AsPath: AsCStr {
  to_path(Self) -> Path
}

///|
pub impl AsPath for Path with to_path(self) {
  return self
}

///|
pub impl AsPath for @string.View with to_path(self) {
  return Path::from(self)
}

///|
pub impl AsPath for String with to_path(self) {
  return Path::from(self[:])
}

///|
pub impl AsPath for OsStr with to_path(self) {
  return Path(self)
}

// \\?\

///|
let verbatim_prefix : String = "\\\\?\\"

// \??\

///|
let nt_prefix : String = "\\??\\"

// \\?\UNC\

///|
let unc_prefix : String = "\\\\?\\UNC\\"

///|
fn maybe_verbatim(path : Path) -> OsStr {
  // assume path utf16 encoded and non-empty
  if path.inner().inner().to_unchecked_string().has_prefix(verbatim_prefix) ||
    path.inner().inner().to_unchecked_string().has_prefix(nt_prefix) {
    // Early return for paths that are already verbatim
    return path.inner()
  }
  ...
}
