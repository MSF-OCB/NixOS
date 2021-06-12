from setuptools import setup, find_packages # type: ignore

setup (
  name = "nixostools",
  packages = find_packages(),
  entry_points = {
    "console_scripts": [
      "build_nixos_configs    = nixostools.build:main",
      "encrypt_server_secrets = nixostools.encrypt_server_secrets:main",
      "decrypt_server_secrets = nixostools.decrypt_server_secrets:main",
      "add_encryption_key     = nixostools.add_encryption_key:main",
      "update_nixos_keys      = nixostools.update_nixos_keys:main"
    ]
  },
)

