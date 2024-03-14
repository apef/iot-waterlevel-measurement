// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import expect show *
import case

FIXES_ ::= ["", "a", "A", ".", "\u{10400}"]

item from/string upper/string lower/string -> none:
  expect_equals
      case.to_upper from
      upper
  expect_equals
      case.to_lower from
      lower

  FIXES_.do: | prefix |
    FIXES_.do: | affix |
      expect_equals
          case.to_upper "$prefix$from$affix"
          "$(case.to_upper prefix)$upper$(case.to_upper affix)"
      expect_equals
          case.to_lower "$prefix$from$affix"
          "$(case.to_lower prefix)$lower$(case.to_lower affix)"

item_unchanged from/string -> none:
  item from from from

main:
  upper_lower_test
  equivalence_test
  equivalence_class_test

upper_lower_test:
  item "foo" "FOO" "foo"
  item "Foo" "FOO" "foo"
  item "Schloß" "SCHLOSS" "schloß"
  item "Søen så sær ud" "SØEN SÅ SÆR UD" "søen så sær ud"
  item "Σαν σήμερα 15 Αυγούστου" "ΣΑΝ ΣΉΜΕΡΑ 15 ΑΥΓΟΎΣΤΟΥ" "σαν σήμερα 15 αυγούστου"  // Today is August 15.
  item "Доверяй, но проверяй." "ДОВЕРЯЙ, НО ПРОВЕРЯЙ." "доверяй, но проверяй."  // Trust, but verify.
  item_unchanged ""
  item_unchanged "."
  item_unchanged "\u2603"
  item_unchanged "\u{1f639}"
  item "\u{10400}" "\u{10400}" "\u{10428}"
  item "\u{10428}" "\u{10400}" "\u{10428}"
  // Small letter n preceeded by apostrophe.
  item "\u0149" "\u02bcN" "\u0149"
  // That's Alpha-Iota in the upper case position, not AI.
  // See https://en.wikipedia.org/wiki/Iota_subscript.
  item "ᾳ" "ΑΙ" "ᾳ"
  // The various forms of 'C' and the Lunate form of Sigma have case
  // equivalents, but the double struck C, and the Celsius sign have no lower
  // case equivalents.
  item "ḈÇCϹℂ℃" "ḈÇCϹℂ℃" "ḉçcϲℂ℃"
  item "ḉçcϲℂ℃" "ḈÇCϹℂ℃" "ḉçcϲℂ℃"

equivalence_test:
  expect_equals '!'
      case.reg_exp_canonicalize '!'
  expect_equals 'S'
      case.reg_exp_canonicalize 's'
  expect_equals 'S'
      case.reg_exp_canonicalize 'S'
  expect_equals 'Æ'
      case.reg_exp_canonicalize 'æ'
  expect_equals 'Æ'
      case.reg_exp_canonicalize 'Æ'
  expect_equals 'Σ'
      case.reg_exp_canonicalize 'ς'
  expect_equals 'Σ'
      case.reg_exp_canonicalize 'σ'

equivalence_class_test:
  expect_equals null
      case.reg_exp_equivalence_class '!'
  expect_equals ['S', 's']
      case.reg_exp_equivalence_class 's'
  expect_equals ['S', 's']
      case.reg_exp_equivalence_class 'S'
  expect_equals ['Σ', 'ς', 'σ']
      case.reg_exp_equivalence_class 'ς'
  expect_equals ['Σ', 'ς', 'σ']
      case.reg_exp_equivalence_class 'σ'
  expect_equals ['Σ', 'ς', 'σ']
      case.reg_exp_equivalence_class 'Σ'
