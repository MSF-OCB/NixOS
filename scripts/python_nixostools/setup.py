from setuptools import setup, find_packages # type: ignore

setup (
  name = "nixostools",
  packages = find_packages(),
  entry_points = {
    "console_scripts": [
      "encrypt_server_secrets = nixostools.encrypt_server_secrets:main",
      "decrypt_server_secrets = nixostools.decrypt_server_secrets:main",
    ]
  },
)

