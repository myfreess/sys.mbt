///|
type OsStrBuilder @buffer.T

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
  let buf = OsStrBuilder(@buffer.new(size_hint=osstr.inner().length() * 4))
  buf.push_osstr(osstr.inner())
  return buf
}

///|
pub fn OsStrBuilder::push_char(self : OsStrBuilder, chr : Char) -> Unit {
  if moonbit_os_iswin32() {
    write_utf16le_char(self.inner(), chr)
  } else {
    write_utf8_char(self.inner(), chr)
  }
}

///|
pub fn OsStrBuilder::push(self : OsStrBuilder, str : @string.View) -> Unit {
  if moonbit_os_iswin32() {
    self.inner().write_stringview(str)
  } else {
    for chr in str {
      self.push_char(chr)
    }
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
  self.inner().write_bytes(osstr.inner())
}

///|
pub fn OsStrBuilder::to_osstr(self : OsStrBuilder) -> OsStr {
  return OsStr(self.inner().contents())
}

///|
type OsStr Bytes

///|
pub fn OsStr::from(str : @string.View) -> OsStr {
  OsStrBuilder::from(str).to_osstr()
}

///|
pub impl Add for OsStr with op_add(self : OsStr, other : OsStr) {
  self.inner() + other.inner()
}

///|
pub impl Show for OsStr with output(self, logger) {
  logger.write_string("OsStr(\"")
  if moonbit_os_iswin32() {
    logger.write_string(self.inner().to_unchecked_string())
  } else {
    let decoder = Decoder::new()
    logger.write_string(decoder.decode_lossy(self.inner()))
  }
  logger.write_string("\")")
}

///|
test {
  inspect(
    OsStr::from("/tmp"),
    content=
      #|OsStr("/tmp")
    ,
  )
  inspect(
    OsStr::from("/etc/passwd"),
    content=
      #|OsStr("/etc/passwd")
    ,
  )
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

///|
priv struct Decoder {
  // Input bytes
  // Stores the input bytes that need to be decoded.
  // The primary data source from which characters are read and decoded.
  mut i : FixedArray[Byte]
  // Input position
  // Keeps track of the current position within the input bytes `i`.
  // Indicates the next byte (starting point) to read from `i` during the decoding process
  mut i_pos : Int
  // Temporary bytes
  // Used to temporarily store bytes that are read in parts
  // (which might happen for multi-byte encoded characters).
  t : FixedArray[Byte]
  // Temporary Length
  // Tracks how many bytes currently reside in the temporary bytes `t`.
  mut t_len : Int
  // Temporary Need
  // The number of bytes still needed to complete the character code currently being processed.
  mut t_need : Int
  // Continuation
  // Called with a `Decoder` state.
  mut k : (Decoder) -> Decode
}

///|
priv enum Decode {
  End
  Refill(Bytes)
  Malformed(Bytes)
  Uchar(Char)
} derive(Show)

///|
const U_REP = '\u{FFFD}'

///|
fn decode_lossy(self : Decoder, input : @bytes.View) -> String {
  if input.length() > 0 {
    self.i_cont(input)
  }
  if self.i_rem() == 0 {
    return String::default()
  }
  // drive decoder to decode
  let chars = []
  loop self.decode_() {
    Uchar(u) => {
      chars.push(u)
      continue self.decode_()
    }
    Malformed(_) => {
      chars.push(U_REP)
      continue self.decode_()
    }
    End => String::from_array(chars)
    Refill(_) => continue self.decode_()
  }
}

///|
fn Decoder::new() -> Decoder {
  let i = FixedArray::default()
  let i_pos = 0
  let t = FixedArray::make(4, Byte::default())
  let t_len = 0
  let t_need = 0
  let k = Decoder::decode_utf_8
  { i, i_pos, t, t_len, t_need, k }
}

///|
let utf_8_len = [
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4,
  4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

///|
fn Decoder::decode_utf_8(self : Decoder) -> Decode {
  let rem = self.i_rem()
  if rem <= 0 {
    Decode::End
  } else {
    let idx = self.i[self.i_pos].to_int()
    let need = utf_8_len[idx]
    if rem < need {
      self.t_need(need)
      Decode::t_fill(Decoder::t_decode_utf_8, self)
    } else {
      let j = self.i_pos
      if need == 0 {
        self.i_pos += 1
        self.ret(Decoder::decode_utf_8, Decode::malformed(self.i, j, 1))
      } else {
        self.i_pos += need
        self.ret(Decoder::decode_utf_8, Decode::r_utf_8(self.i, j, need))
      }
    }
  }
}

///|
fn Decoder::i_cont(self : Decoder, input : @bytes.View) -> Unit {
  // concat `input` to `i`, drop decoded `i`
  let i_rem = @math.maximum(self.i_rem(), 0)
  let new_len = i_rem + input.length()
  // init a new `i`
  let new_i = FixedArray::make(new_len, Byte::default())
  if i_rem > 0 {
    // copy the remainder of the old `i` into the new `i`
    self.i.blit_to(new_i, len=i_rem, src_offset=self.i_pos)
  }
  // copy all `input` into new `i`, starting at the remainder of the old `i`
  new_i.blit_from_bytesview(i_rem, input)
  self.i = new_i
  // reset position to starting position
  self.i_pos = 0
}

///|
fn Decoder::ret(self : Decoder, k : (Decoder) -> Decode, v : Decode) -> Decode {
  self.k = k
  v
}

///|
fn decode_(self : Decoder) -> Decode {
  (self.k)(self)
}

///|
fn Decoder::i_rem(self : Decoder) -> Int {
  self.i.length() - self.i_pos
}

///|
fn Decoder::t_need(self : Decoder, need : Int) -> Unit {
  self.t_len = 0
  self.t_need = need
}

///|
fn Decoder::eoi(self : Decoder) -> Unit {
  self.i = FixedArray::default()
}

///|
fn Decoder::refill(self : Decoder, k : (Decoder) -> Decode) -> Decode {
  self.eoi()
  self.ret(k, Decode::Refill(Bytes::from_fixedarray(self.t)))
}

///|
fn Decode::t_fill(k : (Decoder) -> Decode, decoder : Decoder) -> Decode {
  fn blit(decoder : Decoder, l : Int) -> Unit {
    decoder.i.blit_to(
      decoder.t,
      len=l,
      dst_offset=decoder.t_len,
      src_offset=decoder.i_pos,
    )
    decoder.i_pos += l
    decoder.t_len += l
  }

  let rem = decoder.i_rem()
  if rem < 0 { // eoi
    k(decoder)
  } else {
    let need = decoder.t_need - decoder.t_len
    if rem < need {
      blit(decoder, rem)
      decoder.refill(Decode::curry(Decode::t_fill)(k))
    } else {
      blit(decoder, need)
      k(decoder)
    }
  }
}

///|
fn[T, U, V] Decode::curry(f : (T, U) -> V) -> (T) -> (U) -> V {
  fn(x : T) { fn(y : U) -> V { f(x, y) } }
}

///|
fn Decoder::t_decode_utf_8(self : Decoder) -> Decode {
  if self.t_len < self.t_need {
    self.ret(Decoder::decode_utf_8, Decode::malformed(self.t, 0, self.t_len))
  } else {
    self.ret(Decoder::decode_utf_8, Decode::r_utf_8(self.t, 0, self.t_len))
  }
}

///|
fn Decode::r_utf_8(
  bytes : FixedArray[Byte],
  offset : Int,
  length : Int
) -> Decode {
  fn uchar(c : Int) {
    Uchar(Int::unsafe_to_char(c))
  }

  match length {
    1 => uchar(bytes[offset].to_int())
    2 => {
      let b0 = bytes[offset].to_int()
      let b1 = bytes[offset + 1].to_int()
      if b1 >> 6 != 0b10 {
        Decode::malformed(bytes, offset, length)
      } else {
        uchar(((b0 & 0x1F) << 6) | (b1 & 0x3F))
      }
    }
    3 => {
      let b0 = bytes[offset].to_int()
      let b1 = bytes[offset + 1].to_int()
      let b2 = bytes[offset + 2].to_int()
      let c = ((b0 & 0x0F) << 12) | (((b1 & 0x3F) << 6) | (b2 & 0x3F))
      if b2 >> 6 != 0b10 {
        Decode::malformed(bytes, offset, length)
      } else {
        match b0 {
          0xE0 =>
            if b1 < 0xA0 || 0xBF < b1 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
          0xED =>
            if b1 < 0x80 || 0x9F < b1 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
          _ =>
            if b1 >> 6 != 0b10 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
        }
      }
    }
    4 => {
      let b0 = bytes[offset].to_int()
      let b1 = bytes[offset + 1].to_int()
      let b2 = bytes[offset + 2].to_int()
      let b3 = bytes[offset + 3].to_int()
      let c = ((b0 & 0x07) << 18) |
        ((b1 & 0x3F) << 12) |
        ((b2 & 0x3F) << 6) |
        (b3 & 0x3F)
      if b3 >> 6 != 0b10 || b2 >> 6 != 0b10 {
        Decode::malformed(bytes, offset, length)
      } else {
        match b0 {
          0xF0 =>
            if b1 < 0x90 || 0xBF < b1 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
          0xF4 =>
            if b1 < 0x80 || 0x8F < b1 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
          _ =>
            if b1 >> 6 != 0b10 {
              Decode::malformed(bytes, offset, length)
            } else {
              uchar(c)
            }
        }
      }
    }
    _ => panic()
  }
}

///|
fn Decode::malformed(
  bytes : FixedArray[Byte],
  offset : Int,
  length : Int
) -> Decode {
  Malformed(slice(bytes, offset, length))
}

///|
fn slice(bytes : FixedArray[Byte], offset : Int, length : Int) -> Bytes {
  let new_bytes = FixedArray::make(length, b'0')
  bytes.blit_to(new_bytes, len=length, src_offset=offset)
  Bytes::from_fixedarray(new_bytes)
}
