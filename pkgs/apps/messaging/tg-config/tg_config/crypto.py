"""
Crypto — AES-IGE encrypt/decrypt used by Telegram Desktop local storage.
"""

import hashlib
import secrets
import struct

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
except ImportError:
    print("pip install cryptography")
    raise


def derive_key(salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac("sha1", b"", salt, 4, dklen=256)


def _prepare_aes(msg_key: bytes, auth_key: bytes):
    x = 8
    sha1_a = hashlib.sha1(msg_key + auth_key[x : x + 32]).digest()
    sha1_b = hashlib.sha1(
        auth_key[32 + x : 48 + x] + msg_key + auth_key[48 + x : 64 + x]
    ).digest()
    sha1_c = hashlib.sha1(auth_key[64 + x : 96 + x] + msg_key).digest()
    sha1_d = hashlib.sha1(msg_key + auth_key[96 + x : 128 + x]).digest()
    aes_key = sha1_a[0:8] + sha1_b[8:20] + sha1_c[4:16]
    aes_iv = sha1_a[8:20] + sha1_b[0:8] + sha1_c[16:20] + sha1_d[0:8]
    return aes_key, aes_iv


def _aes_ige(data: bytes, key: bytes, iv: bytes, encrypt: bool) -> bytes:
    cipher = Cipher(algorithms.AES(key), modes.ECB(), backend=default_backend())
    worker = cipher.encryptor() if encrypt else cipher.decryptor()
    prev_ct, prev_pt = iv[:16], iv[16:]
    out = bytearray()
    for i in range(0, len(data), 16):
        blk = data[i : i + 16]
        if encrypt:
            ct = bytes(
                a ^ b
                for a, b in zip(
                    worker.update(bytes(a ^ b for a, b in zip(blk, prev_ct))), prev_pt
                )
            )
            out += ct
            prev_ct, prev_pt = ct, blk
        else:
            pt = bytes(
                a ^ b
                for a, b in zip(
                    worker.update(bytes(a ^ b for a, b in zip(blk, prev_pt))), prev_ct
                )
            )
            out += pt
            prev_ct, prev_pt = blk, pt
    return bytes(out)


def encrypt_local(data: bytes, auth_key: bytes) -> bytes:
    size = 4 + len(data)
    full_size = size + (16 - size % 16) % 16
    full = struct.pack("<I", size) + data + secrets.token_bytes(full_size - size)
    msg_key = hashlib.sha1(full).digest()[:16]
    aes_key, aes_iv = _prepare_aes(msg_key, auth_key)
    return msg_key + _aes_ige(full, aes_key, aes_iv, encrypt=True)


def decrypt_local(enc: bytes, auth_key: bytes) -> bytes:
    msg_key, enc_data = enc[:16], enc[16:]
    aes_key, aes_iv = _prepare_aes(msg_key, auth_key)
    dec = _aes_ige(enc_data, aes_key, aes_iv, encrypt=False)
    if hashlib.sha1(dec).digest()[:16] != msg_key:
        raise ValueError("SHA1 mismatch — invalid key or corrupted data")
    return dec[4 : struct.unpack_from("<I", dec)[0]]
