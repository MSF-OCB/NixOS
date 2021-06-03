
import json
import yaml

from base64      import b64decode
from textwrap    import wrap
from typing      import Any, Mapping

import nacl.utils # type: ignore
from nacl.encoding import RawEncoder, Base64Encoder # type: ignore
from nacl.public   import PrivateKey, PublicKey, SealedBox  # type: ignore
from nacl.secret   import SecretBox  # type: ignore
from nacl.signing  import VerifyKey, SigningKey  # type: ignore


UTF8: str = "utf-8"
CHUNK_WIDTH: int = 76

# Length of an OpenSHH ED25519 public key, without the clear-text header
OPENSSH_PUBLIC_KEY_STRING_LENGTH: int = 68
# Byte pattern anouncing the start of the actual public key bytes
OPENSSH_PUBLIC_KEY_SIGNATURE: bytes  = b'\x00\x00\x00\x20'
# Byte pattern anouncing the start of the actual private key bytes
OPENSSH_PRIVATE_KEY_SIGNATURE: bytes = b'\x00\x00\x00\x40'

PUBLIC_KEY_LENGTH:  int = nacl.bindings.crypto_box_PUBLICKEYBYTES
PRIVATE_KEY_LENGTH: int = nacl.bindings.crypto_box_PUBLICKEYBYTES


def chunk(b64bytes: bytes) -> str:
  wrapped = wrap(b64bytes.decode(UTF8), width=CHUNK_WIDTH)
  return '\n'.join(wrapped)


def generate_symmetric_key() -> bytes:
    return nacl.utils.random(SecretBox.KEY_SIZE) # type: ignore


def encrypt_symmetric_string(key: bytes,
                             string_to_encrypt: str) -> str:
  return encrypt_symmetric(key, string_to_encrypt.encode(UTF8))


def encrypt_symmetric(key: bytes,
                      bytes_to_encrypt: bytes) -> str:
  box = SecretBox(key)
  return chunk(box.encrypt(bytes_to_encrypt, encoder=Base64Encoder))


# Takes a b64-encoded string encrypted with the given shared key and decrypts it.
def decrypt_symmetric(key: bytes,
                      encrypted_secrets: str) -> str:
  box = SecretBox(key)
  return decrypt(box, encrypted_secrets).decode(UTF8)


# takes a string of bytes and returns an encrypted version.
def encrypt_asymmetric(pubkey: PublicKey,
                       bytes_to_encrypt: bytes) -> str:
  box = SealedBox(pubkey)
  return chunk(box.encrypt(bytes_to_encrypt, encoder=Base64Encoder))


# Takes a b64-encoded string encrypted with the server's private key
# and returns the decrypted bytes.
def decrypt_asymmetric(privkey: PrivateKey,
                       encrypted_key: str) -> bytes:
  box = SealedBox(privkey)
  return decrypt(box, encrypted_key)


def decrypt(box: Any,
            ciphertext: str) -> bytes:
  return box.decrypt(ciphertext, encoder=Base64Encoder); # type: ignore


# takes an ed25519 public key string (only the key itself, without headers or comments)
# returns an appropriately transformed PublicKey object, usable to create an NaCl SealedBox
def extract_curve_public_key(openssh_public_key: str) -> PublicKey:
  openssh_pub_bytes = b64decode(openssh_public_key)
  pub_bytes = bytes_after(OPENSSH_PUBLIC_KEY_SIGNATURE, PUBLIC_KEY_LENGTH, openssh_pub_bytes)
  nacl_pub_ed = VerifyKey(key=pub_bytes, encoder=RawEncoder)
  return nacl_pub_ed.to_curve25519_public_key()


# takes an OpenSSH Ed25519 private key string and transforms it into a Curve25519 private key
def extract_curve_private_key(priv_key: str) -> PrivateKey:
  # Strip off the first and last line
  openssh_priv_key = '\n'.join(priv_key.splitlines()[:-1][1:])
  openssh_priv_bytes = b64decode(openssh_priv_key)
  priv_bytes = bytes_after(OPENSSH_PRIVATE_KEY_SIGNATURE, PRIVATE_KEY_LENGTH, openssh_priv_bytes)
  nacl_priv_ed = SigningKey(seed=priv_bytes, encoder=RawEncoder)
  return nacl_priv_ed.to_curve25519_private_key()


# Extract the public key from the JSON data and cut away the header
def extract_public_key(tunnels_json: Mapping,
                       server: str,
                       public_keys_path: str) -> PublicKey:
  server_tunnel_data = tunnels_json['tunnels']['per-host'].get(server)
  if not server_tunnel_data:
    raise Exception(f'Server {server} not found in "{public_keys_path}".')
  # Find the public key, strip off the header,
  # and discard anything following the key
  pubkey_chars = server_tunnel_data['public_key'].split(' ', 2)[1]
  if not len(pubkey_chars) == OPENSSH_PUBLIC_KEY_STRING_LENGTH:
    raise Exception(f"Error parsing the public key for server {server}.")
  return extract_curve_public_key(pubkey_chars)


# Extract length bytes counting from the first occurence of the given signature.
def bytes_after(signature: bytes,
                length: int,
                bytestr: bytes) -> bytes:
  start = bytestr.find(signature) + len(signature)
  return bytestr[start:start+length]

