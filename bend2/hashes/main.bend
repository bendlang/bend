import Base
import ./md5.bend as M5
import ./sha1.bend as S1
import ./sha2_32.bend as S32
import ./sha2_64.bend as S64
import ./sha3.bend as S3
import ./ripemd160.bend as R160
import ./sm3.bend as SM
import ./blake2s.bend as B2S
import ./blake2b.bend as B2B
import ./blake3.bend as B3

# Cryptographic hash functions for Bend
# =====================================

# Public facade for the entire library. Import this file once as `Hashes`.
#
# Preferred API:
#   Hashes.SHA256.hash(bytes)   -> raw digest bytes
#   Hashes.SHA256.hex(bytes)    -> lowercase hexadecimal
#   Hashes.SHA256.text("abc")   -> lowercase hexadecimal of UTF-8 text
#
# Raw byte inputs are List<&2,U32>; each item is interpreted modulo 256.
# SHAKE output lengths are measured in bytes.
# `bytes` and `hex_bytes` are explicit aliases retained for clarity.

# MD5 # legacy compatibility hash
def MD5.hash(xs: List<&2,U32>) -> List<&2,U32>:
  M5.MD5.bytes(xs)

def MD5.hex(xs: List<&2,U32>) -> String:
  M5.MD5.hex_bytes(xs)

def MD5.text(s: String) -> String:
  M5.MD5.text(s)

def MD5.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  M5.MD5.bytes(xs)

def MD5.hex_bytes(xs: List<&2,U32>) -> String:
  M5.MD5.hex_bytes(xs)

# SHA1 # legacy compatibility hash
def SHA1.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S1.SHA1.bytes(xs)

def SHA1.hex(xs: List<&2,U32>) -> String:
  S1.SHA1.hex_bytes(xs)

def SHA1.text(s: String) -> String:
  S1.SHA1.text(s)

def SHA1.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S1.SHA1.bytes(xs)

def SHA1.hex_bytes(xs: List<&2,U32>) -> String:
  S1.SHA1.hex_bytes(xs)

# SHA224
def SHA224.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S32.SHA224.bytes(xs)

def SHA224.hex(xs: List<&2,U32>) -> String:
  S32.SHA224.hex_bytes(xs)

def SHA224.text(s: String) -> String:
  S32.SHA224.text(s)

def SHA224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S32.SHA224.bytes(xs)

def SHA224.hex_bytes(xs: List<&2,U32>) -> String:
  S32.SHA224.hex_bytes(xs)

# SHA256
def SHA256.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S32.SHA256.bytes(xs)

def SHA256.hex(xs: List<&2,U32>) -> String:
  S32.SHA256.hex_bytes(xs)

def SHA256.text(s: String) -> String:
  S32.SHA256.text(s)

def SHA256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S32.SHA256.bytes(xs)

def SHA256.hex_bytes(xs: List<&2,U32>) -> String:
  S32.SHA256.hex_bytes(xs)

# SHA384
def SHA384.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA384.bytes(xs)

def SHA384.hex(xs: List<&2,U32>) -> String:
  S64.SHA384.hex_bytes(xs)

def SHA384.text(s: String) -> String:
  S64.SHA384.text(s)

def SHA384.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA384.bytes(xs)

def SHA384.hex_bytes(xs: List<&2,U32>) -> String:
  S64.SHA384.hex_bytes(xs)

# SHA512
def SHA512.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512.bytes(xs)

def SHA512.hex(xs: List<&2,U32>) -> String:
  S64.SHA512.hex_bytes(xs)

def SHA512.text(s: String) -> String:
  S64.SHA512.text(s)

def SHA512.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512.bytes(xs)

def SHA512.hex_bytes(xs: List<&2,U32>) -> String:
  S64.SHA512.hex_bytes(xs)

# SHA3_224
def SHA3_224.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_224.bytes(xs)

def SHA3_224.hex(xs: List<&2,U32>) -> String:
  S3.SHA3_224.hex_bytes(xs)

def SHA3_224.text(s: String) -> String:
  S3.SHA3_224.text(s)

def SHA3_224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_224.bytes(xs)

def SHA3_224.hex_bytes(xs: List<&2,U32>) -> String:
  S3.SHA3_224.hex_bytes(xs)

# SHA3_256
def SHA3_256.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_256.bytes(xs)

def SHA3_256.hex(xs: List<&2,U32>) -> String:
  S3.SHA3_256.hex_bytes(xs)

def SHA3_256.text(s: String) -> String:
  S3.SHA3_256.text(s)

def SHA3_256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_256.bytes(xs)

def SHA3_256.hex_bytes(xs: List<&2,U32>) -> String:
  S3.SHA3_256.hex_bytes(xs)

# SHA3_384
def SHA3_384.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_384.bytes(xs)

def SHA3_384.hex(xs: List<&2,U32>) -> String:
  S3.SHA3_384.hex_bytes(xs)

def SHA3_384.text(s: String) -> String:
  S3.SHA3_384.text(s)

def SHA3_384.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_384.bytes(xs)

def SHA3_384.hex_bytes(xs: List<&2,U32>) -> String:
  S3.SHA3_384.hex_bytes(xs)

# SHA3_512
def SHA3_512.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_512.bytes(xs)

def SHA3_512.hex(xs: List<&2,U32>) -> String:
  S3.SHA3_512.hex_bytes(xs)

def SHA3_512.text(s: String) -> String:
  S3.SHA3_512.text(s)

def SHA3_512.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.SHA3_512.bytes(xs)

def SHA3_512.hex_bytes(xs: List<&2,U32>) -> String:
  S3.SHA3_512.hex_bytes(xs)

# SHAKE128
def SHAKE128.hash(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  S3.SHAKE128.bytes(xs,out_len)

def SHAKE128.hex(xs: List<&2,U32>, out_len: U32) -> String:
  S3.SHAKE128.hex_bytes(xs,out_len)

def SHAKE128.text(s: String, out_len: U32) -> String:
  S3.SHAKE128.text(s,out_len)

def SHAKE128.bytes(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  S3.SHAKE128.bytes(xs,out_len)

def SHAKE128.hex_bytes(xs: List<&2,U32>, out_len: U32) -> String:
  S3.SHAKE128.hex_bytes(xs,out_len)

# SHAKE256
def SHAKE256.hash(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  S3.SHAKE256.bytes(xs,out_len)

def SHAKE256.hex(xs: List<&2,U32>, out_len: U32) -> String:
  S3.SHAKE256.hex_bytes(xs,out_len)

def SHAKE256.text(s: String, out_len: U32) -> String:
  S3.SHAKE256.text(s,out_len)

def SHAKE256.bytes(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  S3.SHAKE256.bytes(xs,out_len)

def SHAKE256.hex_bytes(xs: List<&2,U32>, out_len: U32) -> String:
  S3.SHAKE256.hex_bytes(xs,out_len)

# BLAKE2s
def BLAKE2s.hash(xs: List<&2,U32>) -> List<&2,U32>:
  B2S.BLAKE2s.bytes(xs)

def BLAKE2s.hex(xs: List<&2,U32>) -> String:
  B2S.BLAKE2s.hex_bytes(xs)

def BLAKE2s.text(s: String) -> String:
  B2S.BLAKE2s.text(s)

def BLAKE2s.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  B2S.BLAKE2s.bytes(xs)

def BLAKE2s.hex_bytes(xs: List<&2,U32>) -> String:
  B2S.BLAKE2s.hex_bytes(xs)

# BLAKE2b
def BLAKE2b.hash(xs: List<&2,U32>) -> List<&2,U32>:
  B2B.BLAKE2b.bytes(xs)

def BLAKE2b.hex(xs: List<&2,U32>) -> String:
  B2B.BLAKE2b.hex_bytes(xs)

def BLAKE2b.text(s: String) -> String:
  B2B.BLAKE2b.text(s)

def BLAKE2b.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  B2B.BLAKE2b.bytes(xs)

def BLAKE2b.hex_bytes(xs: List<&2,U32>) -> String:
  B2B.BLAKE2b.hex_bytes(xs)

# BLAKE3
def BLAKE3.hash(xs: List<&2,U32>) -> List<&2,U32>:
  B3.BLAKE3.bytes(xs)

def BLAKE3.hex(xs: List<&2,U32>) -> String:
  B3.BLAKE3.hex_bytes(xs)

def BLAKE3.text(s: String) -> String:
  B3.BLAKE3.text(s)

def BLAKE3.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  B3.BLAKE3.bytes(xs)

def BLAKE3.hex_bytes(xs: List<&2,U32>) -> String:
  B3.BLAKE3.hex_bytes(xs)


# SHA512_224
def SHA512_224.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512_224.bytes(xs)

def SHA512_224.hex(xs: List<&2,U32>) -> String:
  S64.SHA512_224.hex_bytes(xs)

def SHA512_224.text(s: String) -> String:
  S64.SHA512_224.text(s)

def SHA512_224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512_224.bytes(xs)

def SHA512_224.hex_bytes(xs: List<&2,U32>) -> String:
  S64.SHA512_224.hex_bytes(xs)

# SHA512_256
def SHA512_256.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512_256.bytes(xs)

def SHA512_256.hex(xs: List<&2,U32>) -> String:
  S64.SHA512_256.hex_bytes(xs)

def SHA512_256.text(s: String) -> String:
  S64.SHA512_256.text(s)

def SHA512_256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S64.SHA512_256.bytes(xs)

def SHA512_256.hex_bytes(xs: List<&2,U32>) -> String:
  S64.SHA512_256.hex_bytes(xs)

# Original Keccak (pre-SHA-3 domain separation)
def KECCAK_224.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_224.bytes(xs)

def KECCAK_224.hex(xs: List<&2,U32>) -> String:
  S3.KECCAK_224.hex_bytes(xs)

def KECCAK_224.text(s: String) -> String:
  S3.KECCAK_224.text(s)

def KECCAK_224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_224.bytes(xs)

def KECCAK_224.hex_bytes(xs: List<&2,U32>) -> String:
  S3.KECCAK_224.hex_bytes(xs)

def KECCAK_256.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_256.bytes(xs)

def KECCAK_256.hex(xs: List<&2,U32>) -> String:
  S3.KECCAK_256.hex_bytes(xs)

def KECCAK_256.text(s: String) -> String:
  S3.KECCAK_256.text(s)

def KECCAK_256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_256.bytes(xs)

def KECCAK_256.hex_bytes(xs: List<&2,U32>) -> String:
  S3.KECCAK_256.hex_bytes(xs)

def KECCAK_384.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_384.bytes(xs)

def KECCAK_384.hex(xs: List<&2,U32>) -> String:
  S3.KECCAK_384.hex_bytes(xs)

def KECCAK_384.text(s: String) -> String:
  S3.KECCAK_384.text(s)

def KECCAK_384.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_384.bytes(xs)

def KECCAK_384.hex_bytes(xs: List<&2,U32>) -> String:
  S3.KECCAK_384.hex_bytes(xs)

def KECCAK_512.hash(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_512.bytes(xs)

def KECCAK_512.hex(xs: List<&2,U32>) -> String:
  S3.KECCAK_512.hex_bytes(xs)

def KECCAK_512.text(s: String) -> String:
  S3.KECCAK_512.text(s)

def KECCAK_512.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  S3.KECCAK_512.bytes(xs)

def KECCAK_512.hex_bytes(xs: List<&2,U32>) -> String:
  S3.KECCAK_512.hex_bytes(xs)

# RIPEMD-160 (legacy compatibility)
def RIPEMD160.hash(xs: List<&2,U32>) -> List<&2,U32>:
  R160.RIPEMD160.bytes(xs)

def RIPEMD160.hex(xs: List<&2,U32>) -> String:
  R160.RIPEMD160.hex_bytes(xs)

def RIPEMD160.text(s: String) -> String:
  R160.RIPEMD160.text(s)

def RIPEMD160.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  R160.RIPEMD160.bytes(xs)

def RIPEMD160.hex_bytes(xs: List<&2,U32>) -> String:
  R160.RIPEMD160.hex_bytes(xs)

# SM3
def SM3.hash(xs: List<&2,U32>) -> List<&2,U32>:
  SM.SM3.bytes(xs)

def SM3.hex(xs: List<&2,U32>) -> String:
  SM.SM3.hex_bytes(xs)

def SM3.text(s: String) -> String:
  SM.SM3.text(s)

def SM3.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  SM.SM3.bytes(xs)

def SM3.hex_bytes(xs: List<&2,U32>) -> String:
  SM.SM3.hex_bytes(xs)
