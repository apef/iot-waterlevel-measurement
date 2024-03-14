// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the third_party/toitware/LICENSE file.

import host.pipe
import reader show BufferedReader

main:
  reader := BufferedReader pipe.stdin
  line_number := 1
  while line := reader.read_line:
    if line.size == 0:
      print line
      continue
    in_word := is_word_char line[0]
    out_line := ""
    fragment_start := 0

    for col := 0; col <= line.size; col++:
      edge := ?
      if col < line.size:
        edge = (is_word_char line[col]) != in_word
        if col >= 2 and line[col - 2] == '\\': edge = true
      else:
        edge = true
      if edge:
        out_line += transform line[fragment_start..col]
        fragment_start = col
        in_word = not in_word
    print out_line

transform in/string -> string:
  return case_transform (private_transform in)

// Change from _name to name_ formats.
private_transform in/string -> string:
  if in[0] != '_': return in
  return in[1..] + "_"

// Change from camelCase to underscore_case
case_transform in/string -> string:
  if not 'a' <= in[0] <= 'z': return in
  fragment_start := 0
  out := ""
  for i := 0; i <= in.size; i++:
    edge := false
    if 1 <= i < in.size:
      edge = (is_lower_case in[i - 1]) and (is_upper_case in[i])
    else if i == in.size:
      edge = true
    if edge:
      fragment := in[fragment_start..i]
      if is_upper_case fragment[0]:
        out += "_$(to_lower fragment)"
      else:
        out += fragment
      fragment_start = i
  return out

to_lower in/string -> string:
  out := ByteArray in.size:
    c := in[it]
    if is_upper_case c:
      c + 32
    else:
      c
  return out.to_string

is_lower_case c/int -> bool:
  return 'a' <= c <= 'z'

is_upper_case c/int -> bool:
  return 'A' <= c <= 'Z'

is_word_char c/int -> bool:
  if 'a' <= c <= 'z': return true
  if 'A' <= c <= 'Z': return true
  if '0' <= c <= '9': return true
  if c == '_': return true
  return false
