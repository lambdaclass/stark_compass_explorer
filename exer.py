from hashlib import md5
import secrets
import random


def md125(s: str) -> str:  # this is the hash function you'll use
  return md5(s.encode()).hexdigest()[:8]


# Function to generate a random string of a given length
def generate_random_string():
  characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  random_string = "nakamoto" + ''.join(
      secrets.choice(characters) for _ in range(random.randint(1, 1000)))
  return random_string


# Generate a random string of length 10
def generate_md125_collisions() -> (str, str):
  word_hash = {}
  hash_set = set()

  while True:
    word = generate_random_string()
    hash = md125(word)
    if hash in hash_set:
      for (k, v) in word_hash.items():
        if v == hash and k != word:
          print(k, v)
          print(word, hash)
          return (k, word)
    else:
      hash_set.add(hash)
      # print(hash_set)
      word_hash[word] = hash


if __name__ == "__main__":
    # This code will only run if the script is executed directly, not when imported as a module
    print("Running as a standalone script.")
    generate_md125_collisions()