from setuptools import setup # type: ignore

setup (
  name = "ocb_nixos_python_scripts",
  packages = [ "secret_lib",
               "ansible_vault_lib",
               "." ],
  entry_points = {
    "console_scripts": [
      "encrypt_server_secrets = encrypt_server_secrets:main",
      "decrypt_server_secrets = decrypt_server_secrets:main",
    ]
  },
)

