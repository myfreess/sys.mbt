///|
pub type OsStrBuilder @buffer.T

///|
extern "c" fn moonbit_os_iswin32() -> Bool = "moonbit_os_iswin32"

///|
pub fn OsStrBuilder::new(size_hint~ : Int = 20) -> OsStrBuilder {
  return OsStrBuilder(@buffer.new(size_hint~))
}

///|
pub fn OsStrBuilder::from(view : @string.View) -> OsStrBuilder {
  let buf = OsStrBuilder(@buffer.new(size_hint=view.length() * 4))
  buf.push(view)
  return buf
}

///|
pub fn OsStrBuilder::from_osstr(osstr : OsStr) -> OsStrBuilder {
  let buf = OsStrBuilder(@buffer.new(size_hint=osstr._.length() * 4))
  buf.push_osstr(osstr._)
  return buf
}

///|
pub fn OsStrBuilder::push_char(self : OsStrBuilder, chr : Char) -> Unit {
  if moonbit_os_iswin32() {
    write_utf16le_char(self._, chr)
  } else {
    write_utf8_char(self._, chr)
  }
}

///|
pub fn OsStrBuilder::push(self : OsStrBuilder, str : @string.View) -> Unit {
  for chr in str {
    self.push_char(chr)
  }
}

///|
pub fn OsStrBuilder::checked_push(
  self : OsStrBuilder,
  str : @string.View
) -> Unit {
  for chr in str {
    if chr != '\u0000' {
      self.push_char(chr)
    }
  }
}

///|
pub fn OsStrBuilder::push_osstr(self : OsStrBuilder, osstr : OsStr) -> Unit {
  self._.write_bytes(osstr._)
}

///|
pub fn OsStrBuilder::to_osstr(self : OsStrBuilder) -> OsStr {
  return OsStr(self._.contents())
}

///|
pub type OsStr Bytes

///|
pub fn OsStr::from(str : @string.View) -> OsStr {
  OsStrBuilder::from(str).to_osstr()
}

///|
pub impl Add for OsStr with op_add(self : OsStr, other : OsStr) {
  self._ + other._
}

///|
fn write_utf8_char(buf : @buffer.T, value : Char) -> Unit {
  let code = value.to_uint()
  match code {
    _..<0x80 => {
      let b0 = ((code & 0x7F) | 0x00).to_byte()
      buf.write_byte(b0)
    }
    _..<0x0800 => {
      let b0 = (((code >> 6) & 0x1F) | 0xC0).to_byte()
      let b1 = ((code & 0x3F) | 0x80).to_byte()
      buf.write_byte(b0)
      buf.write_byte(b1)
    }
    _..<0x010000 => {
      let b0 = (((code >> 12) & 0x0F) | 0xE0).to_byte()
      let b1 = (((code >> 6) & 0x3F) | 0x80).to_byte()
      let b2 = ((code & 0x3F) | 0x80).to_byte()
      buf.write_byte(b0)
      buf.write_byte(b1)
      buf.write_byte(b2)
    }
    _..<0x110000 => {
      let b0 = (((code >> 18) & 0x07) | 0xF0).to_byte()
      let b1 = (((code >> 12) & 0x3F) | 0x80).to_byte()
      let b2 = (((code >> 6) & 0x3F) | 0x80).to_byte()
      let b3 = ((code & 0x3F) | 0x80).to_byte()
      buf.write_byte(b0)
      buf.write_byte(b1)
      buf.write_byte(b2)
      buf.write_byte(b3)
    }
    _ => abort("Char out of range")
  }
}

///|
fn write_utf16le_char(buf : @buffer.T, value : Char) -> Unit {
  let code = value.to_uint()
  if code < 0x10000 {
    let b0 = (code & 0xFF).to_byte()
    let b1 = (code >> 8).to_byte()
    buf.write_byte(b0)
    buf.write_byte(b1)
  } else if code < 0x110000 {
    let hi = code - 0x10000
    let lo = (hi >> 10) | 0xD800
    let hi = (hi & 0x3FF) | 0xDC00
    let b0 = (lo & 0xFF).to_byte()
    let b1 = (lo >> 8).to_byte()
    let b2 = (hi & 0xFF).to_byte()
    let b3 = (hi >> 8).to_byte()
    buf.write_byte(b0)
    buf.write_byte(b1)
    buf.write_byte(b2)
    buf.write_byte(b3)
  } else {
    abort("Char out of range")
  }
}
