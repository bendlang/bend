# Known-answer smoke tests for every public hash variant.
import Base
import ../../bend2/hashes/main.bend as Hashes

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Hashes.MD5.text("abc"))
    IO.print(Hashes.SHA1.text("abc"))
    IO.print(Hashes.SHA224.text("abc"))
    IO.print(Hashes.SHA256.text("abc"))
    IO.print(Hashes.SHA384.text("abc"))
    IO.print(Hashes.SHA512.text("abc"))
    IO.print(Hashes.SHA512_224.text("abc"))
    IO.print(Hashes.SHA512_256.text("abc"))
    IO.print(Hashes.SHA3_224.text("abc"))
    IO.print(Hashes.SHA3_256.text("abc"))
    IO.print(Hashes.SHA3_384.text("abc"))
    IO.print(Hashes.SHA3_512.text("abc"))
    IO.print(Hashes.KECCAK_224.text("abc"))
    IO.print(Hashes.KECCAK_256.text("abc"))
    IO.print(Hashes.KECCAK_384.text("abc"))
    IO.print(Hashes.KECCAK_512.text("abc"))
    IO.print(Hashes.SHAKE128.text("abc", 32))
    IO.print(Hashes.SHAKE256.text("abc", 64))
    IO.print(Hashes.BLAKE2s.text("abc"))
    IO.print(Hashes.BLAKE2b.text("abc"))
    IO.print(Hashes.BLAKE3.text("abc"))
    IO.print(Hashes.RIPEMD160.text("abc"))
    IO.print(Hashes.SM3.text("abc"))

#|900150983cd24fb0d6963f7d28e17f72
#|a9993e364706816aba3e25717850c26c9cd0d89d
#|23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7
#|ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
#|cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7
#|ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f
#|4634270f707b6a54daae7530460842e20e37ed265ceee9a43e8924aa
#|53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23
#|e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf
#|3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
#|ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25
#|b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0
#|c30411768506ebe1c2871b1ee2e87d38df342317300a9b97a95ec6a8
#|4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
#|f7df1165f033337be098e7d288ad6a2f74409d7a60b49c36642218de161b1f99f8c681e4afaf31a34db29fb763e3c28e
#|18587dc2ea106b9a1563e32b3312421ca164c7f1f07bc922a9c83d77cea3a1e5d0c69910739025372dc14ac9642629379540c17e2a65b19d77aa511a9d00bb96
#|5881092dd818bf5cf8a3ddb793fbcba74097d5c526a6d35f97b83351940f2cc8
#|483366601360a8771c6863080cc4114d8db44530f8f1e1ee4f94ea37e78b5739d5a15bef186a5386c75744c0527e1faa9f8726e462a12a4feb06bd8801e751e4
#|508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982
#|ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923
#|6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85
#|8eb208f7e05d987a9b044a8e98c6b087f15a0bfc
#|66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0
