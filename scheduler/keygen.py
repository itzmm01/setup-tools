# coding=utf-8
import base64
from Crypto.Cipher import AES
from Crypto import Random
import argparse
import binascii

ROOT_KEY = "tencentcloud GDC"
ROOT_IV = "tencentcloud  IV"


def generate_key():
    """
    生成秘钥，加密解密时需要传入
    :return:
    """
    random = Random.new().read(AES.block_size)
    return base64.encodestring(__encrypt(random))


def encrypt(plaintext, instance_key):
    """
    加密
    :param plaintext: 需要加密的内容
    :param instance_key: 秘钥键
    :return:
    """
    decrypt_key = __parse_key(instance_key)
    return AES.new(decrypt_key, AES.MODE_CFB, ROOT_IV).encrypt(plaintext)


def decrypt(ciphertext, instance_key):
    """
    解密
    :param ciphertext: 需要加密的内容
    :param instance_key: 秘钥键
    :return:
    """
    decrypt_key = __parse_key(instance_key)
    return AES.new(decrypt_key, AES.MODE_CFB, ROOT_IV).decrypt(ciphertext)


def __encrypt(plaintext):
    """
    根据私钥加密，内部方法，请勿调用
    :param plaintext: 需要加密的内容
    :return:
    """
    return AES.new(ROOT_KEY, AES.MODE_CFB, ROOT_IV).encrypt(plaintext)


def __decrypt(ciphertext):
    """
    根据私钥解密，内部方法，请勿调用
    :param ciphertext: 需要加密的内容
    :return:
    """
    return AES.new(ROOT_KEY, AES.MODE_CFB, ROOT_IV).decrypt(ciphertext)


def __parse_key(instance_key):
    decode_key = base64.decodestring(instance_key)
    return __decrypt(decode_key)


def parser_args():
    """
    Returns:
    args.input: string     return the path of your input file
    """
    parser = argparse.ArgumentParser()

    parser.add_argument("-m", dest="mode", help="")
    parser.add_argument("-k", dest="key", help="instance_key", default="xxx")
    parser.add_argument("-s", dest="str", help="string", default="xxx")

    return parser.parse_args()


if __name__ == '__main__':
    args = parser_args()
    if args.mode == "encrypt":
        print(encrypt(args.str, args.key))
    elif args.mode == "decrypt":
        print(decrypt(binascii.a2b_hex(args.str.strip()), args.key))
    else:
        print("python keygen.py -m encrypt/decrypt -s xxx -k xxx")
