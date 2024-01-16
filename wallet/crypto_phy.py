## This file is meant to work with the wallet.jl file.
## Because Cryptography isin't at a stable enough state for Julia yet.
## Here we use the cryptography.py package. TODO: transfer to Julia.

import json

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import (
    encode_dss_signature,
    decode_dss_signature
)
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.exceptions import InvalidSignature


# Generates private key for wallet.
def gen_private_key():
    return ec.generate_private_key(
        ec.SECP256K1(),
        backend=default_backend()
    )


# Generate public key for wallet.
def gen_public_key(private_key):
    return private_key.public_key()


def serialive_public_key(public_key) -> str:
    """
    Return the serialized version of the public key for readibility.
        - :param <public_key> the public key object.
    
    :return <str> serialized public key.
    """
    return public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode("utf-8")


def sign(private_key, data) -> str:
    """
    Generate the signature based on the data using the local private key.
        - :param <private_key> the private key object.
        - :param <data> the data.

    :return <str> the signature.
    """
    return decode_dss_signature(private_key.sign(
        json.dumps(data).encode("utf-8"),
        ec.ECDSA(hashes.SHA256())
    ))


def verify_singature(public_key, data, signature) -> bool:
    """
    Verify a signature based on the ORIGINAL public key AND data.
        - :param <public_key> The original public key object.
        - :param <data> The original data.
        - :param <signature> The signature? TODO: write this.

    :return <bool> True on valid, False on invalid.
    """

    # Convert back to unserialized public key
    deserialized_public_key = serialization.load_pem_public_key(
        public_key.encode("utf-8"),
        backend=default_backend()
    )

    # Get that signature shit. TODO: change comment in final release
    (r, s) = signature

    # Try to verify because it throws exception.
    try:
        deserialized_public_key.verify(
            encode_dss_signature(r, s),
            json.dumps(data).encode("utf-8"),
            ec.ECDSA(hashes.SHA256())
        )

        # If successful 
        return True
    except InvalidSignature:
        return False