// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import expect show *
import regexp show RegExp
import regexp

main:
  foo_bar
  simple
  newline
  utf
  case
  char_class
  greedy
  look_around
  match

foo_bar -> none:
  re := RegExp "foo.*bar"
  expect (re.has_matching "foo bar")
  expect (re.has_matching "foobar")
  expect_not (re.has_matching "fooba")

simple -> none:
  TESTS := {
      "foo.*bar": [true,  // case sensitive.
                   false,  // multiline.
                   ["foo bar", "foobar", "foo.....bar", "foo æ bar", "xx foo xx bar xx"],
                   ["fooba", "fobar", "foo baR", "f oobar", "fæbar", "", "fbar", "f", "bar"]],
      "^foo.*bar": [true,  // case sensitive.
                    false,  // multiline.
                    ["foo bar", "foobar", "foo.....bar", "foo æ bar"],
                    ["xx foo xx bar", "fooba", "fobar", "foo baR", "f oobar", "fæbar", "", "fbar", "f", "bar"]],
      "foo.*bar\$": [true,  // case sensitive.
                     false,  // multiline.
                     ["foo bar", "foobar", "foo.....bar", "foo æ bar"],
                     ["foo xx bar xx", "fooba", "fobar", "foo baR", "f oobar", "fæbar", "", "fbar", "f", "bar"]],
      "^foo.*bar\$": [true,  // case sensitive.
                     false,  // multiline.
                     ["foo bar", "foobar", "foo.....bar", "foo æ bar"],
                     ["foo bar xx", "xx foo bar", "fooba", "fobar", "foo baR", "f oobar", "fæbar", "", "fbar", "f", "bar"]],
  }

  TESTS.do: | source vectors |
    re := RegExp source --case_sensitive=vectors[0] --multiline=vectors[1]
    vectors[2].do: | should_match |
      expect
          re.has_matching should_match
    vectors[3].do: | should_match |
      expect_not
          re.has_matching should_match

newline -> none:
  re := RegExp "foo.bar" --multiline=false
  expect (re.has_matching "foo bar")
  expect_not (re.has_matching "foo\nbar")
  expect_not (re.has_matching "foo\rbar")

  re = RegExp "foo.bar" --multiline=true
  expect (re.has_matching "foo bar")
  expect (re.has_matching "foo\nbar")
  expect (re.has_matching "foo\rbar")

utf -> none:
  re := RegExp "foo.+bar" --multiline=false
  expect (re.has_matching "foo bar")
  expect_not (re.has_matching "foobar")
  expect (re.has_matching "fooæbar")
  expect (re.has_matching "foo€bar")
  expect (re.has_matching "foo☃bar")
  expect (re.has_matching "foo..bar")

  re = RegExp "^sø(en)?\$"
  expect (re.has_matching "søen")
  expect_not (re.has_matching "søe")
  expect (re.has_matching "sø")

  re = RegExp "^sø*\$"
  expect_not (re.has_matching "")
  expect (re.has_matching "s")
  expect (re.has_matching "sø")
  expect (re.has_matching "søø")
  expect_not (re.has_matching "sæø")
  expect_not (re.has_matching "søø.")

  re = RegExp "^s€*\$"
  expect_not (re.has_matching "")
  expect (re.has_matching "s")
  expect (re.has_matching "s€")
  expect (re.has_matching "s€€")
  expect_not (re.has_matching "sæ€")
  expect_not (re.has_matching "s€€.")

  re = RegExp "^s☃*\$"
  expect_not (re.has_matching "")
  expect (re.has_matching "s")
  expect (re.has_matching "s☃")
  expect (re.has_matching "s☃☃")
  expect_not (re.has_matching "s€☃")
  expect_not (re.has_matching "s☃☃.")

  re = RegExp "foo.bar"
  expect (re.has_matching "foo bar")
  expect_not (re.has_matching "foobar")
  expect (re.has_matching "fooæbar")
  expect (re.has_matching "foo€bar")
  expect (re.has_matching "foo☃bar")
  expect_not (re.has_matching "foo..bar")

case -> none:
  re := RegExp "foo.+bar" --case_sensitive=false
  expect (re.has_matching "foo bar")
  expect_not (re.has_matching "foobar")
  expect (re.has_matching "Foo BaR")
  expect_not (re.has_matching "Foo Bax")
  expect_not (re.has_matching "FOOBAR")

  re = RegExp "Søen" --case_sensitive=false
  expect (re.has_matching "Søen")
  expect (re.has_matching "søen")
  expect (re.has_matching "SøEN")
  expect (re.has_matching "SØEN")
  expect (re.has_matching "sØen")
  expect (re.has_matching "..sØen")
  expect_not (re.has_matching "soen")
  expect_not (re.has_matching "söen")

  re = RegExp "Sø*en" --case_sensitive=false
  expect (re.has_matching "Søen")
  expect (re.has_matching "Søøøen")
  expect (re.has_matching "søen")
  expect (re.has_matching "SøEN")
  expect (re.has_matching "SEN")
  expect (re.has_matching "SøØøØøØøøØØEN")
  expect (re.has_matching "sØen")
  expect (re.has_matching "..sØen")
  expect_not (re.has_matching "soen")
  expect_not (re.has_matching "söen")

  re = RegExp "Sø*en" --case_sensitive=false
  expect (re.has_matching "Søen")
  expect (re.has_matching "Søøøen")
  expect (re.has_matching "søen")
  expect (re.has_matching "SøEN")
  expect (re.has_matching "SEN")
  expect (re.has_matching "SøØøØøØøøØØEN")
  expect (re.has_matching "sØen")
  expect (re.has_matching "..sØen")
  expect_not (re.has_matching "soen")
  expect_not (re.has_matching "söen")

  // Sigma test. 'Σ', 'ς', 'σ'
  re = RegExp "Six Σ event" --case_sensitive=false
  expect_not (re.has_matching "Søen")
  expect_not (re.has_matching "Six . event")
  expect_not (re.has_matching "Six .. event")
  expect_not (re.has_matching "Six ... event")
  expect (re.has_matching "six Σ event")
  expect (re.has_matching "six ς event")
  expect (re.has_matching "six σ event")

  re = RegExp "Six Σ event" --case_sensitive=true
  expect_not (re.has_matching "Søen")
  expect_not (re.has_matching "Six . event")
  expect_not (re.has_matching "Six .. event")
  expect_not (re.has_matching "Six ... event")
  expect (re.has_matching "Six Σ event")
  expect_not (re.has_matching "Six ς event")
  expect_not (re.has_matching "Six σ event")

  re = RegExp "foo[a-z]bar" --case_sensitive=false
  expect_not (re.has_matching "foo bar")
  expect_not (re.has_matching "FOO BAR")
  expect (re.has_matching "fooabar")
  expect (re.has_matching "fooAbar")
  expect (re.has_matching "foogbar")
  expect (re.has_matching "fooGbar")
  expect (re.has_matching "foozbar")
  expect (re.has_matching "fooZbar")
  expect_not (re.has_matching "foo@bar")
  expect_not (re.has_matching "foo{bar")
  expect_not (re.has_matching "foo[bar")
  expect_not (re.has_matching "foo`bar")

  re = RegExp "foo[M-d]bar" --case_sensitive=false
  expect_not (re.has_matching "foolbar")
  expect_not (re.has_matching "fooebar")
  expect_not (re.has_matching "fooLbar")
  expect_not (re.has_matching "fooEbar")
  expect (re.has_matching "foombar")
  expect (re.has_matching "fooMbar")
  expect (re.has_matching "foodbar")
  expect (re.has_matching "fooDbar")
  expect (re.has_matching "foo`bar")

char_class:
  re := RegExp "foo[z-ø]bar" --case_sensitive=false
  expect (re.has_matching "foozbar")
  expect (re.has_matching "fooZbar")
  expect_not (re.has_matching "fooxbar")
  expect_not (re.has_matching "fooXbar")
  expect (re.has_matching "fooøbar")
  expect (re.has_matching "fooØbar")
  expect (re.has_matching "fooµbar")      // 0xb5, mu in the Latin1 plane.
  expect (re.has_matching "fooμbar")      // 0x3bc, mu in the greek lower case area.
  expect (re.has_matching "fooΜbar")      // 0x39c, mu in the greek upper case area.
  expect_not (re.has_matching "fooMbar")  // Just a regular M.
  expect_not (re.has_matching "foo€bar")  // 3-byte Unicode char.
  expect_not (re.has_matching "foo☃bar")  // 4-byte Unicode char.

  re = RegExp "foo[^z-ø]bar" --case_sensitive=false
  expect_not (re.has_matching "foozbar")
  expect_not (re.has_matching "fooZbar")
  expect (re.has_matching "fooxbar")
  expect (re.has_matching "fooXbar")
  expect_not (re.has_matching "fooøbar")
  expect_not (re.has_matching "fooØbar")
  expect_not (re.has_matching "fooµbar")   // 0xb5, mu in the Latin1 plane.
  expect_not (re.has_matching "fooμbar")   // 0x3bc, mu in the greek lower case area.
  expect_not (re.has_matching "fooΜbar")   // 0x39c, mu in the greek upper case area.
  expect (re.has_matching "foo€bar")       // 3-byte Unicode char.
  expect (re.has_matching "foo☃bar")       // 4-byte Unicode char.
  expect (re.has_matching "fooMbar")       // Just a regular M.

greedy:
  re := RegExp "foo.{3,}bar"
  expect_not (re.has_matching "foobar")
  expect_not (re.has_matching "foo.bar")
  expect_not (re.has_matching "foo..bar")
  expect     (re.has_matching "foo...bar")
  expect     (re.has_matching "foo....bar")
  expect     (re.has_matching "foo.....bar")
  expect     (re.has_matching "foo......bar")

  // With Unicode characters we mustn't think we are 3 characters in when we
  // are actually only 3 bytes in.
  expect_not (re.has_matching "foo±bar")
  expect_not (re.has_matching "foo±±bar")
  expect     (re.has_matching "foo±±±bar")
  expect     (re.has_matching "foo±±±±bar")
  expect     (re.has_matching "foo±±±±±bar")
  expect     (re.has_matching "foo±±±±±±bar")

  // Try again with a . that can't match newlines
  re = RegExp "foo.{3,}bar"
  expect_not (re.has_matching "foo±bar")
  expect_not (re.has_matching "foo±±bar")
  expect     (re.has_matching "foo±±±bar")
  expect     (re.has_matching "foo±±±±bar")
  expect     (re.has_matching "foo±±±±±bar")
  expect     (re.has_matching "foo±±±±±±bar")

  // Don't let a negative character class match a part of a UTF-8 sequence.
  re = RegExp "foo.*[^f][^f]bar"
  expect_not (re.has_matching "foo€bar")

look_around -> none:
  // Positive look-ahead.
  re := RegExp "foo(?=[a-z]{5})bar"
  expect     (re.has_matching "foobarxx")
  expect     (re.has_matching "..foobarxx..")
  expect     (re.has_matching "..foobarrr..")
  expect     (re.has_matching "..foobarrrrr")
  expect_not (re.has_matching "..foobar....")
  expect_not (re.has_matching "..foobarx...")
  expect     (re.has_matching "..foofoobarxx..")

  // Negative look-ahead.
  re = RegExp "foo(?![a-z]{5})bar"
  expect_not (re.has_matching "foobarxx")
  expect_not (re.has_matching "..foobarxx..")
  expect_not (re.has_matching "..foobarrr..")
  expect_not (re.has_matching "..foobarrrrr")
  expect     (re.has_matching "..foobar....")
  expect     (re.has_matching "..foobarx...")
  expect_not (re.has_matching "..foofoobarxx..")

match -> none:
  // No ().
  re := RegExp ".x.y."
  m := re.first_matching ".x.y."
  expect_equals 0 m.index
  expect_equals 5 m.matched.size

  // Capturing ().
  re = RegExp ".(x.y)."
  m = re.first_matching ".x.y."
  expect_equals 0 m.index
  expect_equals 5 m.matched.size
  expect_equals ".x.y." m[0]
  expect_equals "x.y" m[1]
  expect_equals 1 (m.index 1)
  expect_equals 3 m[1].size

  m = re.first_matching ".x*y."
  expect_equals 0 m.index
  expect_equals 5 m.matched.size
  expect_equals ".x*y." m[0]
  expect_equals "x*y" m[1]
  expect_equals 1 (m.index 1)
  expect_equals 3 m[1].size

  // Capturing and non-capturing ().
  re = RegExp "(.)(?:x.y)(.)"
  m = re.first_matching ".0x1y2."
  expect_equals 1 m.index
  expect_equals 5 m.matched.size
  expect_equals "0x1y2" m[0]
  expect_equals "0" m[1]
  expect_equals "2" m[2]

  // Capturing () in a look-ahead.
  re = RegExp "foo(?=...(..))bar"
  m = re.first_matching "   foobar42  "
  expect_equals "foobar" m[0]  // Capture 0 is the whole match.
  expect_equals "42" m[1]      // Capture 1 is outside of capture 0!

  // Optional () in loop depends on last iteration.
  re = RegExp "(?:(foo)?(bar)?/)*"
  m = re.first_matching "foobar/foobar/foo/"
  expect_equals "foobar/foobar/foo/" m[0]
  expect_equals "foo" m[1]
  expect_equals null m[2]
  m = re.first_matching "foobar/foo/foobar/"
  expect_equals "foobar/foo/foobar/" m[0]
  expect_equals "foo" m[1]
  expect_equals "bar" m[2]
