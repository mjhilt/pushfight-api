import base64
import bcrypt

# We use bcrypt to do the actual hashing and comparisons
def hash_pw(plaintext):
    return bcrypt.hashpw(plaintext.encode(), bcrypt.gensalt())

def check_pw(pw, hashed):
    return bcrypt.checkpw(pw, hashed)

def b64encode(in_string):
    encoded_bytes = base64.b64encode(bytes(in_string, "utf8"))
    return encoded_bytes.decode('utf8')
