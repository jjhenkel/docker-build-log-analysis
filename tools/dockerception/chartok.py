import sys


def encode(c):
  if c == '\n':
    return '\ n'
  elif c == '\t':
    return '\ t'
  elif c == '\r':
    return '\ r'
  return c.lower()


if __name__ == '__main__':
  MAX_CHARS = 10000 if len(sys.argv) <= 1 else int(sys.argv[1])
  
  result = ''
  length = 0
  for line in sys.stdin:
    for i, c in enumerate(line):
      result += encode(c) + ' '
      length += 1
      if length > MAX_CHARS:
        break
    if length > MAX_CHARS:
      break
  print(result.rstrip())

