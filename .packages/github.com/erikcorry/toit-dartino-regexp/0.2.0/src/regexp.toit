// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import bytes show Buffer
import case

class MiniExpLabel_:
  // Initially points to -1 to indicate the label is neither linked (used) nor
  // bound (fixed to a location). When the label is linked, but not bound, it
  // has a negative value, determined by fixup_location(l), that indicates the
  // location of a reference to it, that will be patched when its location has
  // been bound.  When the label is bound, the negative value is used to patch
  // the chained locations that need patching, and the location is set to the
  // correct location for future use.
  static NO_LOCATION ::= -1
  location_ := NO_LOCATION

  is_bound -> bool:
    return location_ >= 0

  is_linked -> bool:
    return location_ < NO_LOCATION

  bind codes/List/*<int>*/ -> none:
    assert: not is_bound
    l /int := codes.size
    for forward_reference := location_; forward_reference != NO_LOCATION; :
      patch_location /int := decode_fixup_ forward_reference
      forward_reference = codes[patch_location]
      codes[patch_location] = l
    location_ = l

  location -> int:
    assert: is_bound
    return location_

  // The negative value is -(location + 2) so as to avoid NO_LOCATION, which is
  // -1.
  encode_fixup_ location/int -> int:
    return -(location + 2)

  // It's perhaps not intuitive that the encoding and decoding functions are
  // identical, but they are both just mirroring around -1.
  decode_fixup_ encoded/int -> int:
    return -(encoded + 2)

  link codes/List/*<int>*/ -> none:
    value/int := location_
    if not is_bound: location_ = encode_fixup_ codes.size
    // If the label is bound, this writes the correct (positive) location.
    // Otherwise it writes the previous link in the chain of forward references
    // that need fixing when the label is bound.
    codes.add value

// Registers.
ZERO_REGISTER_        ::= 0
NO_POSITION_REGISTER_ ::= 1
CURRENT_POSITION_     ::= 2
STRING_LENGTH_        ::= 3
STACK_POINTER_        ::= 4
FIXED_REGISTERS_      ::= 5

REGISTER_NAMES_ ::= [
  "ZERO",
  "NO_POSITION_REGISTER",
  "CURRENT_POSITION",
  "STRING_LENGTH",
  "STACK_POINTER",
  "TEMP_0",
  "TEMP_1",
  "TEMP_2",
  "TEMP_3",
  "TEMP_4",
  "TEMP_5",
  "TEMP_6",
  "TEMP_7",
  "TEMP_8",
  "TEMP_9",
  "TEMP_10",
  "TEMP_11",
  "TEMP_12",
  "TEMP_13",
  "TEMP_14",
  "TEMP_15",
]

// Used for capture registers that have not captured any position in the
// string.
NO_POSITION_ ::= -1

// Byte codes.
BC_GOTO_                        ::= 0  // label
BC_PUSH_REGISTER_               ::= 1  // reg
BC_PUSH_BACKTRACK_              ::= 2  // const
BC_POP_REGISTER_                ::= 3  // reg
BC_BACKTRACK_EQ_                ::= 4  // reg reg
BC_BACKTRACK_NE_                ::= 5  // reg reg
BC_BACKTRACK_GT_                ::= 6  // reg reg
BC_BACKTRACK_IF_NO_MATCH_       ::= 7  // constant-pool-offset
BC_BACKTRACK_IF_IN_RANGE_       ::= 8  // from to
BC_GOTO_IF_MATCH_               ::= 9  // char_code label
BC_GOTO_IF_IN_RANGE_            ::= 10 // from to label
BC_GOTO_IF_UNICODE_IN_RANGE_    ::= 11 // from to label
BC_GOTO_EQ_                     ::= 12 // reg reg label
BC_GOTO_GE_                     ::= 13 // reg reg label
BC_GOTO_IF_WORD_CHARACTER_      ::= 14 // position-offset label
BC_ADD_TO_REGISTER_             ::= 15 // reg const
BC_ADVANCE_BY_RUNE_WIDTH_       ::= 16 // reg
BC_COPY_REGISTER_               ::= 17 // dest-reg source-reg
BC_BACKTRACK_ON_BACK_REFERENCE_ ::= 18 // capture-reg
BC_BACKTRACK_                   ::= 19
BC_SUCCEED_                     ::= 20
BC_FAIL_                        ::= 21

// Format is name, number of register arguments, number of other arguments.
BYTE_CODE_NAMES_ ::= [
  "GOTO", 0, 1,
  "PUSH_REGISTER", 1, 0,
  "PUSH_BACKTRACK", 0, 1,
  "POP_REGISTER", 1, 0,
  "BACKTRACK_EQ", 2, 0,
  "BACKTRACK_NE", 2, 0,
  "BACKTRACK_GT", 2, 0,
  "BACKTRACK_IF_NO_MATCH", 0, 1,
  "BACKTRACK_IF_IN_RANGE", 0, 2,
  "GOTO_IF_MATCH", 0, 2,
  "GOTO_IF_IN_RANGE", 0, 3,
  "GOTO_IF_UNICODE_IN_RANGE", 0, 3,
  "GOTO_EQ", 2, 1,
  "GOTO_GE", 2, 1,
  "GOTO_IF_WORD_CHARACTER", 0, 2,
  "ADD_TO_REGISTER", 1, 1,
  "ADVANCE_BY_RUNE_WIDTH", 1, 1,
  "COPY_REGISTER", 2, 0,
  "BACKTRACK_ON_BACK_REFERENCE", 1, 1,
  "BACKTRACK", 0, 0,
  "SUCCEED", 0, 0,
  "FAIL", 0, 0,
]

CHAR_CODE_NO_BREAK_SPACE_ ::= 0xa0
CHAR_CODE_OGHAM_SPACE_MARK_ ::= 0x1680
CHAR_CODE_EN_QUAD_ ::= 0x2000
CHAR_CODE_HAIR_SPACE_ ::= 0x200a
CHAR_CODE_LINE_SEPARATOR_ ::= 0x2028
CHAR_CODE_PARAGRAPH_SEPARATOR_ ::= 0x2029
CHAR_CODE_NARROW_NO_BREAK_SPACE_ ::= 0x202f
CHAR_CODE_MEDIUM_MATHEMATICAL_SPACE_ ::= 0x205f
CHAR_CODE_IDEOGRAPHIC_SPACE_ ::= 0x3000
CHAR_CODE_ZERO_WIDTH_NO_BREAK_SPACE_ ::= 0xfeff
CHAR_CODE_LAST_ ::= 0x10ffff

class MiniExpCompiler_:
  pattern /string ::= ?
  case_sensitive /bool ::= ?
  registers /List ::= []
  capture_register_count /int := 0
  first_capture_register /int := -1
  codes_ /List ::= []
  extra_constants_ /List ::= []
  back_references_ /List ::= []
  pending_goto_ /MiniExpLabel_? := null

  constructor .pattern .case_sensitive:
    for i := 0; i < FIXED_REGISTERS_; i++:
      registers.add (i == NO_POSITION_REGISTER_ ? NO_POSITION_ : 0)

  codes -> List:
    flush_pending_goto
    return codes_

  constant_pool -> ByteArray:
    if extra_constants_.is_empty:
      return pattern.to_byte_array
    else:
      byte_array := ByteArray extra_constants_.size: extra_constants_[it]
      return pattern.to_byte_array + byte_array

  // The rune for the constant pool object at the given index.
  constant_pool_entry index/int -> int:
    if index < pattern.size: return pattern[index]
    first_byte := extra_constants_[index - pattern.size]
    if first_byte < 0x80: return first_byte
    byte_count := UTF_FIRST_CHAR_TABLE_[first_byte >> 4]
    result := first_byte & 0x1f
    if byte_count == 4: result &= 7
    (byte_count - 1).repeat:
      result <<= 6
      result |= extra_constants_[index + it] & 0x3f
    return result

  constant_pool_byte index/int -> int:
    if index < pattern.size: return pattern.at --raw index
    return extra_constants_[index - pattern.size]

  // Indexed by the top nibble of a UTF-8 byte this tells you how many bytes
  // long the UTF-8 sequence is.
  static UTF_FIRST_CHAR_TABLE_ ::= [
    1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 2, 2, 3, 4,
  ]

  emit_ code/int arg1/int?=null arg2/int?=null -> none:
    flush_pending_goto
    codes_.add code
    if arg1 != null: codes_.add arg1
    if arg2 != null: codes_.add arg2

  generate ast/MiniExpAst_ on_success/MiniExpLabel_ -> none:
    bind ast.label
    ast.generate this on_success

  bind label/MiniExpLabel_ -> none:
    if label == pending_goto_:
      pending_goto_ = null  // Peephole optimization.
    flush_pending_goto
    label.bind codes_

  link label/MiniExpLabel_ -> none: label.link codes_

  succeed -> none: emit_ BC_SUCCEED_

  fail -> none: emit_ BC_FAIL_

  allocate_working_register -> int: return allocate_constant_register 0

  allocate_constant_register value/int -> int:
    register := registers.size
    registers.add value
    return register

  // Returns negative numbers, starting at -1. This is so that we can
  // interleave allocation of capture registers and regular registers, but
  // still end up with the capture registers being contiguous.
  allocate_capture_registers -> int:
    capture_register_count += 2
    return -capture_register_count + 1

  add_back_reference b/BackReference_ -> none:
    back_references_.add b

  add_capture_registers -> none:
    first_capture_register = registers.size
    for i := 0; i < capture_register_count; i++:
      registers.add NO_POSITION_
    process_back_refences

  process_back_refences -> none:
    back_references_.do: | b/BackReference_ |
      // 1-based index (you can't refer back to capture zero).
      numeric_index := int.parse b.index
      if b.index[0] == '0' or numeric_index * 2 >= capture_register_count:
        // Web compatible strangeness - if the index is more than the number of
        // captures it turns into an octal character code escape.
        code_unit := 0
        octals_found := 0
        replace /MiniExpAst_? := null
        non_octals_found := false
        // The first 0-3 octal digits form an octal character escape, the rest
        // are literals.
        b.index.do --runes: | octal_digit |
          if (not non_octals_found) and
              '0' <= octal_digit <= '7' and
              code_unit * 8 < 0x100 and octals_found < 3:
            code_unit *= 8
            code_unit += octal_digit - '0'
            octals_found++
          else:
            pool_index := add_to_constant_pool octal_digit
            atom /MiniExpAst_ := Atom_ pool_index
            replace = (replace == null) ? atom : Alternative_ replace atom
            non_octals_found = true
        if octals_found != 0:
          pool_index := add_to_constant_pool code_unit
          atom /MiniExpAst_ := Atom_ pool_index
          replace = (replace == null) ? atom : Alternative_ atom replace
        b.replace_with_ast replace
      else:
        b.register = first_capture_register + numeric_index * 2

  // Raw register numbers are negative for capture registers, positive for
  // constant and working registers.
  register_number raw_register_number/int -> int:
    if raw_register_number >= 0: return raw_register_number
    return -(raw_register_number + 1) + first_capture_register

  add_to_constant_pool rune/int -> int:
    result := pattern.size + extra_constants_.size
    if rune < 0x80:
      extra_constants_.add rune
      return result
    str := string.from_runes [rune]
    str.size.repeat:
      extra_constants_.add (str.at --raw it)
    return result

  push_backtrack label/MiniExpLabel_ -> none:
    emit_ BC_PUSH_BACKTRACK_
    link label

  backtrack -> none:
    emit_ BC_BACKTRACK_

  push reg/int -> none:
    emit_ BC_PUSH_REGISTER_
        register_number reg

  pop reg/int -> none:
    emit_ BC_POP_REGISTER_
        register_number reg

  goto label/MiniExpLabel_ -> none:
    if pending_goto_ != label: flush_pending_goto
    pending_goto_ = label

  flush_pending_goto -> none:
    if pending_goto_ != null:
      codes_.add BC_GOTO_
      link pending_goto_
      pending_goto_ = null

  backtrack_if_equal register1/int register2/int -> none:
    emit_ BC_BACKTRACK_EQ_
         register_number register1
         register_number register2

  backtrack_if_not_equal register1/int register2/int -> none:
    emit_ BC_BACKTRACK_NE_
        register_number register1
        register_number register2

  add_to_register reg/int offset/int -> none:
    emit_ BC_ADD_TO_REGISTER_
        register_number reg
        offset

  copy_register dest_register/int source_register/int -> none:
    emit_ BC_COPY_REGISTER_
        register_number dest_register
        register_number source_register

  backtrack_on_back_reference_fail register/int case_sensitive/bool -> none:
    emit_ BC_BACKTRACK_ON_BACK_REFERENCE_
        register_number register
        case_sensitive ? 1 : 0

  backtrack_if_greater register1/int register2/int -> none:
    emit_ BC_BACKTRACK_GT_
        register_number register1
        register_number register2

  goto_if_greater_equal register1/int register2/int label/MiniExpLabel_ -> none:
    emit_ BC_GOTO_GE_
        register_number register1
        register_number register2
    link label

  backtrack_if_no_match constant_pool_offset/int -> none:
    emit_ BC_BACKTRACK_IF_NO_MATCH_ constant_pool_offset

  backtrack_if_in_range from/int to/int -> none:
    emit_ BC_BACKTRACK_IF_IN_RANGE_ from to

  goto_if_matches char_code/int label/MiniExpLabel_ -> none:
    emit_ BC_GOTO_IF_MATCH_  char_code
    link label

  goto_if_in_range from/int to/int label/MiniExpLabel_ -> none:
    if from == to:
      goto_if_matches from label
    else:
      emit_ BC_GOTO_IF_IN_RANGE_ from to
      link label

  goto_if_unicode_in_range from/int to/int label/MiniExpLabel_ -> none:
    emit_ BC_GOTO_IF_UNICODE_IN_RANGE_ from to
    link label

  // Adds a number of UTF-8 encoded runes to the current position, and stores
  // the result in the given destination register.  Can also step backwards.
  advance_by_rune_width destination_register/int count/int -> none:
    emit_ BC_ADVANCE_BY_RUNE_WIDTH_ destination_register count

  backtrack_if_not_at_word_boundary -> none:
    non_word_on_left := MiniExpLabel_
    word_on_left := MiniExpLabel_
    at_word_boundary := MiniExpLabel_
    do_backtrack := MiniExpLabel_

    emit_ BC_GOTO_EQ_ CURRENT_POSITION_ ZERO_REGISTER_
    link non_word_on_left
    emit_ BC_GOTO_IF_WORD_CHARACTER_ -1
    link word_on_left

    bind non_word_on_left
    emit_ BC_BACKTRACK_EQ_ CURRENT_POSITION_ STRING_LENGTH_
    emit_ BC_GOTO_IF_WORD_CHARACTER_ 0
    link at_word_boundary
    bind do_backtrack
    backtrack

    bind word_on_left
    emit_ BC_GOTO_EQ_ CURRENT_POSITION_ STRING_LENGTH_
    link at_word_boundary
    emit_ BC_GOTO_IF_WORD_CHARACTER_ 0
    link do_backtrack

    bind at_word_boundary

// MiniExpAnalysis_ objects reflect properties of an AST subtree.  They are
// immutable and are reused to some extent.
class MiniExpAnalysis_:
  // Can this subtree match an empty string?  If we know that's not possible,
  // we can optimize away the test that ensures we are making progress when we
  // match repetitions.
  can_match_empty /bool ::= ?

  // Set to null if the AST does not match something with a fixed length.  That
  // fixed length thing has to be something that does not touch the stack.  This
  // is an important optimization that prevents .* from using huge amounts of
  // stack space when running.
  fixed_length /int? ::= ?

  // Can this subtree only match at the start of the regexp?  Can't pass all
  // tests without being able to spot this.
  anchored /bool ::= ?

  // Allows the AST to notify a surrounding loop (a quantifier higher up the
  // tree) that it has registers it expects to be saved on the back edge.
  registers_to_save/List?/*<int>*/ ::= ?

  static combine_registers left/List?/*<int>*/ right/List?/*<int>*/ -> List?/*<int>*/:
    if right == null or right.is_empty:
      return left
    else if left == null or left.is_empty:
      return right
    else:
      return left + right  // List concatenation.

  static combine_fixed_lengths left/MiniExpAnalysis_ right/MiniExpAnalysis_ -> int?:
    if left.fixed_length == null or right.fixed_length == null:
      return null
    else:
      return left.fixed_length + right.fixed_length

  constructor.orr left/MiniExpAnalysis_ right/MiniExpAnalysis_:
    can_match_empty = left.can_match_empty or right.can_match_empty
    // Even if both alternatives are the same length we can't handle a
    // disjunction without pushing backtracking information on the stack.
    fixed_length = null
    anchored = left.anchored and right.anchored
    registers_to_save = combine_registers left.registers_to_save right.registers_to_save

  constructor.andd left/MiniExpAnalysis_ right/MiniExpAnalysis_:
    can_match_empty = left.can_match_empty and right.can_match_empty
    fixed_length = combine_fixed_lengths left right
    anchored = left.anchored
    registers_to_save = combine_registers left.registers_to_save right.registers_to_save

  constructor.empty:
    can_match_empty = true
    fixed_length = 0
    anchored = false
    registers_to_save = null

  constructor.at_start:
    can_match_empty = true
    fixed_length = 0
    anchored = true
    registers_to_save = null

  constructor.lookahead body_analysis/MiniExpAnalysis_ positive/bool:
    can_match_empty = true
    fixed_length = 0
    anchored = positive and body_analysis.anchored
    registers_to_save = body_analysis.registers_to_save

  constructor.quantifier body_analysis/MiniExpAnalysis_ min/int max/int? regs/List/*<int>*/:
    can_match_empty = min == 0 or body_analysis.can_match_empty
    fixed_length = (min == 1 and max == 1) ? body_analysis.fixed_length : null
    anchored = min > 0 and body_analysis.anchored
    registers_to_save = combine_registers body_analysis.registers_to_save regs

  constructor.atom:
    can_match_empty = false
    fixed_length = 1
    anchored = false
    registers_to_save = null

  constructor.know_nothing:
    can_match_empty = true
    fixed_length = null
    anchored = false
    registers_to_save = null

  constructor.capture body_analysis/MiniExpAnalysis_ start/int end/int:
    can_match_empty = body_analysis.can_match_empty
    // We can't generate a capture without pushing backtracking information
    // on the stack.
    fixed_length = null
    anchored = body_analysis.anchored
    registers_to_save = combine_registers body_analysis.registers_to_save [start, end]

abstract class MiniExpAst_:
  // When generating code for an AST, note that:
  // * The previous code may fall through to this AST, but it might also
  //   branch to it.  The label has always been bound just before generate
  //   is called.
  // * It's not permitted to fall through to the bottom of the generated
  //   code. Always end with backtrack or a goto on_success.
  // * You can push any number of backtrack pairs (PC, position), but if you
  //   push anything else, then you have to push a backtrack location that will
  //   clean it up.  On entry you can assume there is a backtrack pair on the
  //   top of the stack.
  abstract generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none

  abstract analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_

  // Label is bound at the entry point for the AST tree.
  label ::= MiniExpLabel_

  abstract case_expand compiler/MiniExpCompiler_ -> MiniExpAst_

class Disjunction_ extends MiniExpAst_:
  left_/MiniExpAst_ ::= ?
  right_/MiniExpAst_ ::= ?

  constructor .left_ .right_:

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    try_right := MiniExpLabel_
    compiler.push_backtrack try_right
    compiler.generate left_ on_success
    compiler.bind try_right
    compiler.generate right_ on_success

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.orr
        left_.analyze compiler
        right_.analyze compiler

  case_expand compiler/MiniExpCompiler_ -> Disjunction_:
    l := left_.case_expand compiler
    r := right_.case_expand compiler
    if l == left_ and r == right_: return this
    return Disjunction_ l r

class EmptyAlternative_ extends MiniExpAst_:
  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.goto on_success

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.empty

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    return this

class Alternative_ extends MiniExpAst_:
  left_/MiniExpAst_ ::= ?
  right_/MiniExpAst_ ::= ?

  constructor .left_ .right_:

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.generate left_ right_.label
    compiler.generate right_ on_success

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.andd
        left_.analyze compiler
        right_.analyze compiler

  case_expand compiler/MiniExpCompiler_ -> Alternative_:
    l := left_.case_expand compiler
    r := right_.case_expand compiler
    if l == left_ and r == right_: return this
    return Alternative_ l r

abstract class Assertion extends MiniExpAst_:
  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.empty

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    return this

class AtStart_ extends Assertion:
  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.backtrack_if_not_equal CURRENT_POSITION_ ZERO_REGISTER_
    compiler.goto on_success

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.at_start

class AtEnd_ extends Assertion:
  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.backtrack_if_not_equal CURRENT_POSITION_ STRING_LENGTH_
    compiler.goto on_success

abstract class MultiLineAssertion_ extends Assertion:
  backtrack_if_not_newline compiler/MiniExpCompiler_ -> none:
    compiler.backtrack_if_in_range
        '\r' + 1
        CHAR_CODE_LINE_SEPARATOR_ - 1
    compiler.backtrack_if_in_range
        0
        '\n' - 1
    compiler.backtrack_if_in_range 
        '\n' + 1
        '\r' - 1
    compiler.backtrack_if_in_range
        CHAR_CODE_PARAGRAPH_SEPARATOR_ + 1
        CHAR_CODE_LAST_

class AtBeginningOfLine_ extends MultiLineAssertion_:
  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.goto_if_greater_equal ZERO_REGISTER_ CURRENT_POSITION_ on_success
    // We need to look one back to see if there was a newline there.  If we
    // backtrack, then that also restores the current position, but if we don't
    // backtrack, we have to fix it again.
    compiler.add_to_register CURRENT_POSITION_ -1
    backtrack_if_not_newline compiler
    compiler.add_to_register CURRENT_POSITION_ 1
    compiler.goto on_success

class AtEndOfLine_ extends MultiLineAssertion_:
  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.goto_if_greater_equal CURRENT_POSITION_ STRING_LENGTH_ on_success
    backtrack_if_not_newline compiler
    compiler.goto on_success

class WordBoundary_ extends Assertion:
  positive_ /bool ::= ?

  constructor .positive_:

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    // Positive word boundaries are much more common that negative ones, so we
    // will allow ourselves to generate some pretty horrible code for the
    // negative ones.
    if not positive_:
      compiler.push_backtrack on_success
    compiler.backtrack_if_not_at_word_boundary
    if positive_:
      compiler.goto on_success
    else:
      // Pop the two stack position of the unneeded backtrack.
      compiler.pop CURRENT_POSITION_
      compiler.pop CURRENT_POSITION_
      // This overwrites the current position with the correct value.
      compiler.backtrack

class LookAhead_ extends Assertion:
  positive_ /bool ::= ?
  body_/MiniExpAst_ ::= ?
  subtree_registers_/List?/*<int>*/ := null

  saved_stack_pointer_register_/int
  saved_position_/int

  constructor .positive_ .body_ compiler/MiniExpCompiler_:
    saved_stack_pointer_register_ = compiler.allocate_working_register
    saved_position_ = compiler.allocate_working_register

  constructor.private_ .positive_ .body_ .saved_stack_pointer_register_ .saved_position_:

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    // Lookahead.  Even if the subexpression succeeds, the current position is
    // reset, and the backtracking stack is unwound so that we can never
    // backtrack into the lookahead.  On a failure of the subexpression, the
    // stack will be naturally unwound.
    body_succeeded := MiniExpLabel_
    succeed_on_failure := MiniExpLabel_
    undo_captures/MiniExpLabel_? := null
    compiler.copy_register saved_stack_pointer_register_ STACK_POINTER_
    compiler.copy_register saved_position_ CURRENT_POSITION_
    if not positive_:
      compiler.push_backtrack succeed_on_failure
    compiler.generate body_ body_succeeded

    compiler.bind body_succeeded
    compiler.copy_register STACK_POINTER_ saved_stack_pointer_register_
    compiler.copy_register CURRENT_POSITION_ saved_position_
    if not positive_:
      // For negative lookahead always zap the captures when the body succeeds
      // and the lookahead thus fails.  The captures are only needed for any
      // backrefs inside the negative lookahead.
      if subtree_registers_ != null:
        subtree_registers_.do: | register |
          compiler.copy_register register NO_POSITION_REGISTER_
      compiler.backtrack
      compiler.bind succeed_on_failure
    else:
      // For positive lookahead, the backtrack stack has been unwound, because
      // we don't ever backtrack into a lookahead, but if we backtrack past
      // this point we have to undo any captures that happened in there.
      // Register a backtrack to do that before continuing.
      if subtree_registers_ != null and not subtree_registers_.is_empty:
        undo_captures = MiniExpLabel_
        compiler.push_backtrack undo_captures

    compiler.goto on_success

    if undo_captures != null:
      compiler.bind undo_captures
      subtree_registers_.do: | register |
        compiler.copy_register register NO_POSITION_REGISTER_
      compiler.backtrack

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    body_analysis/MiniExpAnalysis_ := body_.analyze compiler
    subtree_registers_ = body_analysis.registers_to_save
    return MiniExpAnalysis_.lookahead body_analysis positive_

  case_expand compiler/MiniExpCompiler_ -> LookAhead_:
    b := body_.case_expand compiler
    if b == body_: return this
    return LookAhead_.private_ positive_ b saved_stack_pointer_register_ saved_position_

class Quantifier_ extends MiniExpAst_:
  min_ /int? ::= ?
  max_ /int? ::= ?
  greedy_ /bool ::= ?
  body_/MiniExpAst_ ::= ?
  counter_register_/int? := null
  start_of_match_register_/int? := null  // Implements 21.2.2.5.1 note 4.
  min_register_/int? := null
  max_register_/int? := null
  subtree_registers_that_need_saving_/List?/*<int>*/ := null
  optimized_greedy_register_/int? := null
  save_position_register_/int? := null
  body_length_/int? := null

  is_optimized_greedy_ -> bool: return optimized_greedy_register_ != null

  constructor
      --min /int?
      --max /int?
      --greedy /bool
      --body /MiniExpAst_
      --compiler /MiniExpCompiler_:
    min_ = min
    max_ = max
    greedy_ = greedy
    body_ = body
    if counter_check_:
      counter_register_ = compiler.allocate_working_register
      min_register_ = (min_check_ min_) ? (compiler.allocate_constant_register min_) : null
      max_register_ = (max_check_ max_) ? (compiler.allocate_constant_register max_) : null

  constructor.private_
      --min /int?
      --max /int?
      --greedy /bool
      --body /MiniExpAst_
      --counter_register /int?
      --start_of_match_register /int?
      --min_register /int?
      --max_register /int?
      --subtree_registers_that_need_saving /List?
      --optimized_greedy_register /int?
      --save_position_register /int?
      --body_length /int?:
    min_ = min
    max_ = max
    greedy_ = greedy
    body_ = body
    counter_register_ = counter_register
    start_of_match_register_ = start_of_match_register
    min_register_ = min_register
    max_register_ = max_register
    subtree_registers_that_need_saving_ = subtree_registers_that_need_saving
    optimized_greedy_register_ = optimized_greedy_register
    save_position_register_ = save_position_register
    body_length_ = body_length

  // We fall through to the top of this, when it is time to match the body of
  // the quantifier.  If the body matches successfully, we should go to
  // on_body_success, otherwise clean up and backtrack.
  generate_common compiler/MiniExpCompiler_ on_body_success/MiniExpLabel_ -> none:
    need_to_catch_didnt_match/bool := greedy_ or body_can_match_empty_ or
        counter_check_ or save_and_restore_registers_
    didnt_match := MiniExpLabel_

    if save_and_restore_registers_:
      subtree_registers_that_need_saving_.do: | reg |
        compiler.push reg
        compiler.copy_register reg NO_POSITION_REGISTER_

    if body_can_match_empty_:
      compiler.push start_of_match_register_
      compiler.copy_register start_of_match_register_ CURRENT_POSITION_

    if need_to_catch_didnt_match:
      compiler.push_backtrack didnt_match

    if counter_check_:
      compiler.add_to_register counter_register_ 1
      if max_check_ max_:
        compiler.backtrack_if_greater counter_register_ max_register_

    compiler.generate body_ on_body_success

    if need_to_catch_didnt_match:
      compiler.bind didnt_match
      if body_can_match_empty_:
        compiler.pop start_of_match_register_
      if counter_check_:
        compiler.add_to_register counter_register_ -1
      if save_and_restore_registers_:
        for i := subtree_registers_that_need_saving_.size - 1; i >= 0; i--:
          compiler.pop subtree_registers_that_need_saving_[i]
      if not greedy_: compiler.backtrack

  generate_fixed_length_greedy compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    new_iteration := MiniExpLabel_
    cant_advance_more := MiniExpLabel_
    continuation_failed := MiniExpLabel_
    after_cant_advance_more := MiniExpLabel_

    // Save the current position, so we know when the quantifier has been
    // unwound enough.
    compiler.copy_register optimized_greedy_register_ CURRENT_POSITION_
    if min_ != 0:
      assert: min_ < 3 and body_length_ < 3
      // Move the unwound-enough register forward by enough characters to cover
      // the minimum repetitions.  This doesn't actually check the characters.
      // It can advance beyond the end of the subject!
      compiler.advance_by_rune_width optimized_greedy_register_ (min_ * body_length_)

    // This backtrack doesn't trigger until the quantifier has eaten as much as
    // possible.  Unfortunately, whenever we backtrack in this simple system,
    // the old current position in the subject string is also rewound.  That's
    // not so convenient here, so we will have to save the current position in
    // a special register.  It would be faster to generate the body in a
    // special mode where we use a different backtrack instruction that just
    // rewinds the current position a certain number of characters instead of
    // popping it.
    compiler.push_backtrack cant_advance_more  // Also pushes the current position, which we don't need.

    // The loop.
    compiler.bind new_iteration
    compiler.copy_register save_position_register_ CURRENT_POSITION_
    compiler.generate body_ new_iteration

    // The greedy quantifier has eaten as much as it can.  Time to try the
    // continuation of the regexp after the quantifier.
    compiler.bind cant_advance_more  // Also restores the original position, which is wrong.
    compiler.copy_register CURRENT_POSITION_ save_position_register_  // Fix the position.

    if min_ != 0:
      // We may have to backtrack because we didn't get the minimum number of
      // matches.
      compiler.backtrack_if_greater optimized_greedy_register_ CURRENT_POSITION_

    compiler.goto after_cant_advance_more

    // The continuation of the regexp failed.  We backtrack the greedy
    // quantifier by one step and retry.
    compiler.bind continuation_failed
    compiler.advance_by_rune_width CURRENT_POSITION_ -body_length_
    // If we got back to where the quantifier started matching, then jump
    // to the continuation (we haven't pushed a backtrack, so if that fails, it
    // will backtrack further).
    // We don't have goto_if_equal, so use goto_if_greater_equal.
    compiler.bind after_cant_advance_more
    compiler.goto_if_greater_equal optimized_greedy_register_ CURRENT_POSITION_ on_success
    compiler.push_backtrack continuation_failed
    compiler.goto on_success

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    // We optimize loops of the form .* to avoid big backtrack stacks.
    if is_optimized_greedy_:
      generate_fixed_length_greedy compiler on_success
      return
    if min_ == 1 and max_ == 1:
      compiler.generate body_ on_success
      return
    // The above means if max_ is 1 then min_ must be 0, which simplifies
    // things.
    body_matched/MiniExpLabel_ := max_ == 1 ? on_success : MiniExpLabel_
    check_empty_match_label/MiniExpLabel_? := null
    on_body_success/MiniExpLabel_ := body_matched
    if body_can_match_empty_:
      check_empty_match_label = MiniExpLabel_
      on_body_success = check_empty_match_label
    if counter_check_:
      compiler.copy_register counter_register_ ZERO_REGISTER_

    if body_matched != on_success:
      compiler.bind body_matched

    if greedy_:
      generate_common compiler on_body_success

      if min_check_ min_:
        compiler.goto_if_greater_equal counter_register_ min_register_ on_success
        compiler.backtrack
      else:
        compiler.goto on_success
    else:
      // Non-greedy.
      try_body := MiniExpLabel_

      if min_check_ min_:
        // If there's a minimum and we haven't reached it we should not try to
        // run the continuation, but go straight to the body_.
        // TODO(erikcorry): if we had a goto_if_less we could save instructions
        // here.
        jump_to_continuation := MiniExpLabel_
        compiler.goto_if_greater_equal counter_register_ min_register_ jump_to_continuation
        compiler.goto try_body
        compiler.bind jump_to_continuation
      // If the continuation fails, we can try the body_ once more.
      compiler.push_backtrack try_body
      compiler.goto on_success

      // We failed to match the continuation, so lets match the body_ once more
      // and then try again.
      compiler.bind try_body
      generate_common compiler on_body_success

    if body_can_match_empty_:
      compiler.bind check_empty_match_label
      if min_check_ min_:
        compiler.goto_if_greater_equal min_register_ counter_register_ body_matched
      compiler.backtrack_if_equal start_of_match_register_ CURRENT_POSITION_
      compiler.goto body_matched

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    body_analysis/MiniExpAnalysis_ := body_.analyze compiler
    subtree_registers_that_need_saving_ = body_analysis.registers_to_save
    body_length_ = body_analysis.fixed_length
    if body_analysis.can_match_empty:
      start_of_match_register_ = compiler.allocate_working_register
    // Some limitations to prevent min * body_length being too high.
    else if max_ == null and greedy_ and body_length_ != null and (min_ == null or min_ < 3) and (body_length_ < 3 or min_ == null or min_ == 0):
      // This also put us in a mode where code is generated differently for
      // this AST.
      optimized_greedy_register_ = compiler.allocate_working_register
      save_position_register_ = compiler.allocate_working_register
    my_regs/List/*<int>*/ := [counter_register_, optimized_greedy_register_, save_position_register_].filter: it != null
    return MiniExpAnalysis_.quantifier body_analysis min_ max_ my_regs

  static max_check_ max -> bool: return max != 1 and max != null

  static min_check_ min -> bool: return min != 0

  counter_check_ -> bool: return (max_check_ max_) or (min_check_ min_)

  body_can_match_empty_ -> bool: return start_of_match_register_ != null

  save_and_restore_registers_ -> bool:
    return subtree_registers_that_need_saving_ != null and
           not subtree_registers_that_need_saving_.is_empty

  case_expand compiler/MiniExpCompiler_ -> Quantifier_:
    b := body_.case_expand compiler
    if b == body_: return this
    return Quantifier_.private_
        --min=min_
        --max=max_
        --greedy=greedy_
        --body=b
        --counter_register=counter_register_
        --start_of_match_register=start_of_match_register_
        --min_register=min_register_
        --max_register=max_register_
        --subtree_registers_that_need_saving=subtree_registers_that_need_saving_
        --optimized_greedy_register=optimized_greedy_register_
        --save_position_register=save_position_register_
        --body_length=body_length_

class Atom_ extends MiniExpAst_:
  constant_index_ /int ::= ?

  constructor .constant_index_:

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    code_unit/int := compiler.constant_pool_byte constant_index_
    compiler.backtrack_if_equal CURRENT_POSITION_ STRING_LENGTH_
    compiler.backtrack_if_no_match constant_index_
    compiler.add_to_register CURRENT_POSITION_ 1
    compiler.goto on_success

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    if compiler.case_sensitive:
      return utf_expand compiler
    char_code/int := compiler.constant_pool_entry constant_index_
    equivalence := case.reg_exp_equivalence_class char_code
    if not equivalence or equivalence.size == 1:
      return utf_expand compiler
    // Need to expand to multiple characters.
    result := Disjunction_
        (Atom_ (compiler.add_to_constant_pool equivalence[0])).utf_expand compiler
        (Atom_ (compiler.add_to_constant_pool equivalence[1])).utf_expand compiler
    if equivalence.size > 2:
      result = Disjunction_
          result
          (Atom_ (compiler.add_to_constant_pool equivalence[2])).utf_expand compiler
    assert: equivalence <= 3
    return result

  utf_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    first_byte := compiler.constant_pool_byte constant_index_
    byte_count := MiniExpCompiler_.UTF_FIRST_CHAR_TABLE_[first_byte >> 4]
    if byte_count == 1: return this
    result := Alternative_
        Atom_ constant_index_
        Atom_ constant_index_ + 1
    if byte_count >= 3:
      result = Alternative_
          result
          Atom_ constant_index_ + 2
    if byte_count == 4:
      result = Alternative_
          result
          Atom_ constant_index_ + 3
    return result

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.atom

class Range_:
  from /int := 0
  to   /int := 0

  constructor .from .to:

  stringify -> string:
    return "$from-$to"

class CharClass_ extends MiniExpAst_:
  ranges_ /List ::= []
  positive_ /bool ::= ?

  constructor .positive_:

  constructor.private_ .ranges_ .positive_:

  // Here and elsewhere, "to" is inclusive.
  add from/int to/int -> none:
    ranges_.add
        Range_ from to

  static space_codes_/List/*<int>*/ := [
    -1,
    '\t', '\r',
    ' ', ' ',
    CHAR_CODE_NO_BREAK_SPACE_, CHAR_CODE_NO_BREAK_SPACE_,
    CHAR_CODE_OGHAM_SPACE_MARK_, CHAR_CODE_OGHAM_SPACE_MARK_,
    CHAR_CODE_EN_QUAD_, CHAR_CODE_HAIR_SPACE_,
    CHAR_CODE_LINE_SEPARATOR_, CHAR_CODE_PARAGRAPH_SEPARATOR_,
    CHAR_CODE_NARROW_NO_BREAK_SPACE_, CHAR_CODE_NARROW_NO_BREAK_SPACE_,
    CHAR_CODE_MEDIUM_MATHEMATICAL_SPACE_, CHAR_CODE_MEDIUM_MATHEMATICAL_SPACE_,
    CHAR_CODE_IDEOGRAPHIC_SPACE_, CHAR_CODE_IDEOGRAPHIC_SPACE_,
    CHAR_CODE_ZERO_WIDTH_NO_BREAK_SPACE_, CHAR_CODE_ZERO_WIDTH_NO_BREAK_SPACE_,
    CHAR_CODE_LAST_]

  add_spaces -> none:
    for i := 1; i < space_codes_.size - 1; i += 2:
      add space_codes_[i] space_codes_[i + 1]

  add_not_spaces -> none:
    for i := 0; i < space_codes_.size; i += 2:
      add space_codes_[i] + 1
          space_codes_[i + 1] - 1

  add_special char_code/int -> none:
    if char_code == 'd':
      add '0' '9'
    else if char_code == 'D':
      add 0
          '0' - 1
      add '9' + 1
          CHAR_CODE_LAST_
    else if char_code == 's':
      add_spaces
    else if char_code == 'S':
      add_not_spaces
    else if char_code == 'w':
      add '0' '9'
      add 'A' 'Z'
      add '_' '_'
      add 'a' 'z'
    else if char_code == 'W':
      add 0
          '0' - 1 
      add '9' + 1
          'A' - 1
      add 'Z' + 1
          '_' - 1
      add '_' + 1
          'a' - 1
      add 'z' + 1
          CHAR_CODE_LAST_

  fix_ranges ranges/List/*<Range_>*/ case_sensitive/bool -> List/*<Range_>*/:
    // There's a lot of punctuation and no case-sensitive characters before the
    // Unicode 'A' code point.
    ranges = ranges.copy
    if not case_sensitive and (ranges.any: it.to >= 'A'):
      old_size := ranges.size
      range_start := -1
      range_end := -1
      for i := 0; i < old_size; i++:
        range := ranges[i]
        // For each character, eg. in the range a-f, we need to find the
        // equivalent characters, eg. A-F, and add them to the character class.
        for j := range.from; j <= range.to; j++:
          // Get the characters that are equivalent to the current one.
          // For example, if j == 'A' we would expect to get ['a', 'A'] or
          // ['A', 'a'].  A reply of null means there the character is only
          // case-equivalent to itself.  There are never more than three
          // case equivalents.
          equivalents := case.reg_exp_equivalence_class j
          if equivalents and equivalents.size != 1:
            assert: equivalents.contains j
            if range_start >= 0 and equivalents.size == 2 and equivalents.contains range_end + 1 and j != range_end + 1:
              // There's just one case-equivalent character (other than j) and
              // it's the one we were expecting, so we merely need to extend
              // the range by one to cover the new character.
              // (We exclude the theoretical case where j is identical to the
              // range extension, because in that case we would not record the
              // other equivalent character.)
              range_end++
            else:
              // Flush the existing range of equivalents that we were
              // constructing.
              if range_start >= 0:
                ranges.add (Range_ range_start range_end)
                range_start = -1
              if equivalents.size > 2:
                // If there are > 2 equivalents, just add them all to the list
                // of ranges.
                equivalents.do: | equivalent |
                  ranges.add (Range_ equivalent equivalent)
              else:
                // Since there are two equivalents, and one of them is the
                // character we already have in a range, start constructing a
                // new range of equivalents.
                equivalents.do: | equivalent |
                  if equivalent != j:
                    range_start = range_end = equivalent
        // At the end, flush the equivalent range we were constructing.
        if range_start >= 0:
          ranges.add (Range_ range_start range_end)
          range_start = -1

    // Even if there is no case-independence work to do we still want to
    // consolidate ranges.
    ranges.sort --in_place: | a b | a.from - b.from

    // Now that they are sorted, check if it's worth merging
    // adjacent/overlapping ranges.
    for i := 1; i < ranges.size; i++:
      if ranges[i - 1].to + 1 >= ranges[i].from:
        ranges = merge_adjacent_ranges_ ranges
        break

    return ranges

  // Merge adjacent/overlapping ranges.
  merge_adjacent_ranges_ ranges/List -> List:
    last := ranges[0]
    new_ranges := [last]
    ranges.do: | range |
      if last.to + 1 >= range.from:
        last.to = max last.to range.to
      else:
        last = range
        new_ranges.add last
    return new_ranges

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    ranges := fix_ranges ranges_ compiler.case_sensitive
    return CharClass_.private_ ranges positive_

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    compiler.backtrack_if_equal CURRENT_POSITION_ STRING_LENGTH_
    match := MiniExpLabel_
    match_unicode := MiniExpLabel_
    backtrack_on_in_range := MiniExpLabel_
    ranges_.do: | range |
      bytes := utf_8_bytes range.to
      if positive_:
        if bytes == 1:
          compiler.goto_if_in_range range.from range.to match
        else:
          compiler.goto_if_unicode_in_range range.from range.to match_unicode
      else:
        if bytes == 1:
          compiler.backtrack_if_in_range range.from range.to
        else:
          compiler.goto_if_unicode_in_range range.from range.to backtrack_on_in_range
    if positive_:
      compiler.backtrack
      if match_unicode.is_linked:
        compiler.bind match_unicode
        compiler.advance_by_rune_width CURRENT_POSITION_ 1
        compiler.goto on_success
      compiler.bind match
      compiler.add_to_register CURRENT_POSITION_ 1
      compiler.goto on_success
    else:
      compiler.advance_by_rune_width CURRENT_POSITION_ 1
      compiler.goto on_success
      if backtrack_on_in_range.is_linked:
        compiler.bind backtrack_on_in_range
        compiler.backtrack

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    return MiniExpAnalysis_.atom

// This class is used for all backslashes followed by numbers.  For web
// compatibility, if the number (interpreted as decimal) is smaller than the
// number of captures, then it will be interpreted as a back reference.
// Otherwise the number will be interpreted as an octal character code escape.
class BackReference_ extends MiniExpAst_:
  back_reference_index_/string
  register_/int? := null
  ast_that_replaces_us_/MiniExpAst_? := null

  constructor .back_reference_index_:

  index -> string: return back_reference_index_

  register= r/int -> none:
    register_ = r

  replace_with_ast ast/MiniExpAst_ -> none:
    ast_that_replaces_us_ = ast

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    if register_ == null:
      compiler.generate ast_that_replaces_us_ on_success
    else:
      compiler.backtrack_on_back_reference_fail register_ compiler.case_sensitive
      compiler.goto on_success

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    compiler.add_back_reference this
    return MiniExpAnalysis_.know_nothing

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    return this

class Capture_ extends MiniExpAst_:
  capture_count_ /int ::= ?
  body_/MiniExpAst_ ::= ?
  start_register_/int? := null
  end_register_/int? := null

  constructor .capture_count_ .body_:

  constructor.private_ .capture_count_ .body_ .start_register_ .end_register_:

  allocate_registers compiler/MiniExpCompiler_ -> none:
    if start_register_ == null:
      start_register_ = compiler.allocate_capture_registers
      end_register_ = start_register_ - 1

  generate compiler/MiniExpCompiler_ on_success/MiniExpLabel_ -> none:
    undo_start := MiniExpLabel_
    write_end := MiniExpLabel_
    undo_end := MiniExpLabel_
    compiler.copy_register start_register_ CURRENT_POSITION_
    compiler.push_backtrack undo_start

    compiler.generate body_ write_end

    compiler.bind write_end
    compiler.copy_register end_register_ CURRENT_POSITION_
    compiler.push_backtrack undo_end
    compiler.goto on_success

    compiler.bind undo_start
    compiler.copy_register start_register_ NO_POSITION_REGISTER_
    compiler.backtrack

    compiler.bind undo_end
    compiler.copy_register end_register_ NO_POSITION_REGISTER_
    compiler.backtrack

  analyze compiler/MiniExpCompiler_ -> MiniExpAnalysis_:
    allocate_registers compiler
    body_analysis := body_.analyze compiler
    return MiniExpAnalysis_.capture body_analysis start_register_ end_register_

  case_expand compiler/MiniExpCompiler_ -> MiniExpAst_:
    b := body_.case_expand compiler
    if b == body_: return this
    return Capture_.private_ capture_count_ b start_register_ end_register_

interface Match:
  /// The regular expression that created this match.
  pattern -> RegExp

  /// The input string in which a match was found.
  input -> string

  /// The substring of the input that matched the regexp.
  matched -> string

  /// The start index of the match in the string.
  index -> int

  /// The end index of the match in the string.
  end_index -> int

  /**
  The start index of the nth capture in the string.
  The 0th capture is the index of the match of the whole regexp.
  */
  index index/int -> int?

  /**
  The end index of the nth capture in the string.
  The 0th capture is the index of the match of the whole regexp.
  */
  end_index index/int -> int?

  /**
  The string captured by the nth capture.
  The 0th capture is the entire substring that matched the regexp.
  */
  operator [] index/int -> string

  /**
  The number of captures in the regexp.
  */
  capture_count -> int

class MiniExpMatch_ implements Match:
  pattern /RegExp ::= ?
  input /string ::= ?
  registers_ /List/*<int>*/ ::= ?
  first_capture_reg_ /int ::= ?

  constructor .pattern .input .registers_ .first_capture_reg_:

  capture_count -> int: return (registers_.size - 2 - first_capture_reg_) >> 1

  matched -> string: return this[0]

  index -> int: return registers_[first_capture_reg_]

  end_index -> int: return registers_[first_capture_reg_ + 1]

  index index/int -> int?:
    if not 0 <= index <= capture_count: throw "OUT_OF_RANGE"
    result := registers_[first_capture_reg_ + index * 2]
    return result == NO_POSITION_ ? null : result

  end_index index/int -> int?:
    if not 0 <= index <= capture_count: throw "OUT_OF_RANGE"
    result := registers_[first_capture_reg_ + 1 + index * 2]
    return result == NO_POSITION_ ? null : result

  operator[] index/int -> string?:
    if not 0 <= index <= capture_count: throw "OUT_OF_RANGE"
    index *= 2
    index += first_capture_reg_
    if registers_[index] == NO_POSITION_: return null
    return input.copy registers_[index] registers_[index + 1]

interface RegExp:
  pattern -> string
  multiline -> bool
  case_sensitive -> bool
  match_as_prefix a/string a1/int -> Match
  first_matching a/string -> Match
  has_matching a/string -> bool
  string_matching a/string -> string?
  all_matches subject/string start/int [block] -> bool
  trace -> none

  constructor pattern/string --multiline/bool=true --case_sensitive/bool=true:
    return MiniExp_ pattern multiline case_sensitive

class MiniExp_ implements RegExp:
  byte_codes_/List?/*<int>*/ := null
  initial_register_values_/List?/*<int>*/ := null
  first_capture_register_/int? := null
  sticky_entry_point_/int? := null
  constant_pool_/ByteArray? := null
  pattern /string ::= ?
  multiline /bool ::= ?
  case_sensitive /bool ::= ?
  trace_ /bool := false

  trace -> none:
    trace_ = true

  constructor .pattern .multiline .case_sensitive:
    compiler := MiniExpCompiler_ pattern case_sensitive
    parser := MiniExpParser_ compiler pattern multiline
    ast/MiniExpAst_ := parser.parse
    generate_code_ compiler ast pattern

  match_as_prefix a/string a1/int=0 -> Match?:
    return match_ a a1 sticky_entry_point_

  first_matching a/string -> Match?:
    return match_ a 0 0

  has_matching a/string -> bool:
    return (match_ a 0 0) != null

  string_matching a/string -> string?:
    m/Match := match_ a 0 0
    if m == null: return null
    return m[0]

  /**
  Calls the block once for each match with the match as argument.
  Returns true iff there was at least one match.
  */
  all_matches subject/string start/int=0 [block] -> bool:
    at_least_once := false
    position := start
    if not 0 <= position <= subject.size: throw "OUT_OF_RANGE"
    while position <= subject.size:
      current := (match_ subject position 0) as MiniExpMatch_
      if current == null: return at_least_once
      if current.index == current.end_index:
        position = current.end_index + 1
      else:
        position = current.end_index
      block.call current
      at_least_once = true
    return at_least_once

  match_ a/string start_position/int start_program_counter/int -> Match?:
    registers/List/*<int>*/ := initial_register_values_.copy
    interpreter := MiniExpInterpreter_ byte_codes_ constant_pool_ registers trace_
    if not interpreter.interpret a start_position start_program_counter:
      return null
    return MiniExpMatch_ this a registers first_capture_register_

  generate_code_ compiler/MiniExpCompiler_ ast/MiniExpAst_ source/string -> none:
    // Top level capture regs.
    top_level_capture_reg/int := compiler.allocate_capture_registers

    top_analysis/MiniExpAnalysis_ := ast.analyze compiler

    ast = ast.case_expand compiler

    compiler.add_capture_registers

    sticky_entry_point := MiniExpLabel_
    sticky_start := MiniExpLabel_
    fail_sticky := MiniExpLabel_

    start := MiniExpLabel_
    compiler.bind start

    fail := MiniExpLabel_
    compiler.push_backtrack fail

    compiler.bind sticky_start
    compiler.copy_register top_level_capture_reg CURRENT_POSITION_

    succeed := MiniExpLabel_
    compiler.generate ast succeed

    compiler.bind fail
    if not top_analysis.anchored:
      end := MiniExpLabel_
      compiler.goto_if_greater_equal CURRENT_POSITION_ STRING_LENGTH_ end
      compiler.advance_by_rune_width CURRENT_POSITION_ 1
      compiler.goto start
      compiler.bind end
    compiler.bind fail_sticky
    compiler.fail

    compiler.bind succeed
    compiler.copy_register top_level_capture_reg - 1 CURRENT_POSITION_
    compiler.succeed

    compiler.bind sticky_entry_point
    compiler.push_backtrack fail_sticky
    compiler.goto sticky_start

    byte_codes_ = compiler.codes
    constant_pool_ = compiler.constant_pool
    initial_register_values_ = compiler.registers
    first_capture_register_ = compiler.first_capture_register
    sticky_entry_point_ = sticky_entry_point.location

  disassemble_ -> none:
    print "\nDisassembly\n"
    labels /List/*<bool>*/ := List byte_codes_.size
    for i := 0; i < byte_codes_.size; :
      code /int := byte_codes_[i]
      if code == BC_PUSH_BACKTRACK_ or code == BC_GOTO_:
        pushed /int := byte_codes_[i + 1]
        if pushed >= 0 and pushed < byte_codes_.size: labels[pushed] = true
      i += BYTE_CODE_NAMES_[code * 3 + 1] + BYTE_CODE_NAMES_[code * 3 + 2] + 1
    for i := 0; i < byte_codes_.size; :
      if labels[i]: print "$i:"
      i += disassemble_single_instruction_ byte_codes_ first_capture_register_ i: print it
    print "\nEnd Disassembly\n"

  static disassemble_single_instruction_ byte_codes/List first_capture_register/int? i/int [block] -> int:
      code /int := byte_codes[i]
      regs /int := BYTE_CODE_NAMES_[code * 3 + 1]
      other_args /int := BYTE_CODE_NAMES_[code * 3 + 2]
      line /string := "$(%3d i):"
      joiner /string := " "
      arg_joiner /string := " "
      if code == BC_COPY_REGISTER_:
        joiner = " = "
      else if code == BC_ADD_TO_REGISTER_:
        arg_joiner = " += "
      else:
        line = "$(%3d i): $BYTE_CODE_NAMES_[code * 3]"
      for j := 0; j < regs; j++:
        reg/int := byte_codes[i + 1 + j]
        line = "$line$(j == 0 ? " " : joiner)$(register_name_ reg first_capture_register)"
      for j := 0; j < other_args; j++:
        line = "$line$arg_joiner$byte_codes[i + 1 + regs + j]"
      block.call line
      return regs + other_args + 1

  static register_name_ i/int first_capture_register/int? -> string:
    if first_capture_register and first_capture_register <= i:
      capture := i - first_capture_register
      if capture & 1 == 0:
        return "start$(capture / 2)"
      else:
        return "end$(capture / 2)"
    if i < REGISTER_NAMES_.size:
      return REGISTER_NAMES_[i]
    return "reg$i"

// Lexer tokens.
NONE ::= 0
QUANT ::= 1
BACKSLASH ::= 2
DOT ::= 3
L_PAREN ::= 4
R_PAREN ::= 5
L_SQUARE ::= 6
HAT ::= 7
DOLLAR ::= 8
PIPE ::= 9
BACK_REFERENCE ::= 10
WORD_BOUNDARY ::= 11
NOT_WORD_BOUNDARY ::= 12
WORD_CHARACTER ::= 13
NOT_WORD_CHARACTER ::= 14
DIGIT ::= 15
NOT_DIGIT ::= 16
WHITESPACE ::= 17
NOT_WHITESPACE ::= 18
NON_CAPTURING ::= 19
LOOK_AHEAD ::= 20
NEGATIVE_LOOK_AHEAD ::= 21
OTHER ::= 22

class MiniExpParser_:
  compiler_ /MiniExpCompiler_ ::= ?
  source_ /string ::= ?
  multiline_ /bool ::= ?

  capture_count_ /int := 0

  // State of the parser and lexer.
  position_/int := 0  // Location in source.
  last_token_/int := -1
  // This is the offset in the constant pool of the character data associated
  // with the token.
  last_token_index_/int := -1
  // Greedyness of the last single-character quantifier.
  last_was_greedy_/bool := false
  last_back_reference_index_/string? := null
  minimum_repeats_/int? := null
  maximum_repeats_/int? := null

  constructor .compiler_ .source_ .multiline_:

  parse -> MiniExpAst_:
    get_token
    ast/MiniExpAst_ := parse_disjunction
    expect_token NONE
    return ast

  at_ position/int -> int: return source_[position]

  has_ position/int -> bool: return source_.size > position

  error message/string -> none:
    throw
      FormatException "Error while parsing regexp: $message" source_ position_

  parse_disjunction -> MiniExpAst_:
    ast/MiniExpAst_ := parse_alternative
    while accept_token PIPE:
      ast = Disjunction_ ast parse_alternative
    return ast

  end_of_alternative -> bool:
    return last_token_ == PIPE or last_token_ == R_PAREN or
        last_token_ == NONE

  parse_alternative -> MiniExpAst_:
    if end_of_alternative:
      return EmptyAlternative_
    ast/MiniExpAst_ := parse_term
    while not end_of_alternative:
      ast = Alternative_ ast parse_term
    return ast

  try_parse_assertion -> MiniExpAst_?:
    if accept_token HAT:
      return multiline_ ? AtBeginningOfLine_ : AtStart_
    if accept_token DOLLAR:
      return multiline_ ? AtEndOfLine_ : AtEnd_
    if accept_token WORD_BOUNDARY: return WordBoundary_ true
    if accept_token NOT_WORD_BOUNDARY: return WordBoundary_ false
    lookahead_ast/MiniExpAst_? := null
    if accept_token LOOK_AHEAD:
      lookahead_ast = LookAhead_ true parse_disjunction compiler_
    else if accept_token NEGATIVE_LOOK_AHEAD:
      lookahead_ast = LookAhead_ false parse_disjunction compiler_
    if lookahead_ast != null:
      expect_token R_PAREN
      // The normal syntax does not allow a quantifier here, but the web
      // compatible one does.  Slightly nasty hack for compatibility:
      if peek_token QUANT:
        quant/MiniExpAst_ := Quantifier_ --min=minimum_repeats_ --max=maximum_repeats_ --greedy=last_was_greedy_ --body=lookahead_ast --compiler=compiler_
        expect_token QUANT
        return quant
      return lookahead_ast
    return null

  parse_term -> MiniExpAst_:
    ast/MiniExpAst_? := try_parse_assertion
    if ast == null:
      ast = parse_atom
      if peek_token QUANT:
        quant/MiniExpAst_ := Quantifier_ --min=minimum_repeats_ --max=maximum_repeats_ --greedy=last_was_greedy_ --body=ast --compiler=compiler_
        expect_token QUANT
        return quant
    return ast

  parse_atom -> MiniExpAst_?:
    if peek_token OTHER:
      result := Atom_ last_token_index_
      expect_token OTHER
      return result
    if accept_token DOT:
      ast := CharClass_ false  // Negative char class.
      if not multiline_:
        ast.add '\n' '\n'
        ast.add '\r' '\r'
        ast.add CHAR_CODE_LINE_SEPARATOR_ CHAR_CODE_PARAGRAPH_SEPARATOR_
      return ast

    if peek_token BACK_REFERENCE:
      back_ref := BackReference_ last_back_reference_index_
      expect_token BACK_REFERENCE
      return back_ref

    if accept_token L_PAREN:
      ast/MiniExpAst_ := parse_disjunction
      ast = Capture_ capture_count_++ ast
      expect_token R_PAREN
      return ast
    if accept_token NON_CAPTURING:
      ast := parse_disjunction
      expect_token R_PAREN
      return ast

    char_class/CharClass_? := null
    digit_char_class := false
    if accept_token WORD_CHARACTER:
      char_class = CharClass_ true
    else if accept_token NOT_WORD_CHARACTER:
      char_class = CharClass_ false
    else if accept_token DIGIT:
      char_class = CharClass_ true
      digit_char_class = true
    else if accept_token NOT_DIGIT:
      char_class = CharClass_ false
      digit_char_class = true
    if char_class != null:
      char_class.add '0' '9'
      if not digit_char_class:
        char_class.add 'A' 'Z'
        char_class.add '_' '_'
        char_class.add 'a' 'z'
      return char_class

    if accept_token WHITESPACE:
      char_class = CharClass_ true
    else if accept_token NOT_WHITESPACE:
      char_class = CharClass_ false
    if char_class != null:
      char_class.add_spaces
      return char_class
    if peek_token L_SQUARE:
      return parse_character_class
    if peek_token NONE: error "Unexpected end of regexp"
    error "Unexpected token $last_token_"
    return null

  parse_character_class -> MiniExpAst_:
    char_class/CharClass_ := ?

    if has_ position_ and (at_ position_) == '^':
      position_++
      char_class = CharClass_ false
    else:
      char_class = CharClass_ true

    add_char_code := : | code |
      if code < 0:
        char_class.add_special (at_ -code + 1)
      else:
        char_class.add code code

    while has_ position_:
      code/int := at_ position_

      degenerate_range := false
      if code == ']':
        // End of character class.  This reads the terminating square bracket.
        get_token
        break
      // Single character or escape code representing a single character.
      // This also advanced position_.
      code = read_character_class_code_

      // Check if there are at least 2 more characters and the next is a dash.
      if (not has_ position_ + 1) or
         (at_ position_) != '-' or
         (at_ position_ + 1) == ']':
        // No dash-something here, so it's not part of a range.  Add the code
        // and move on.
        add_char_code.call code
        continue
      // Found a dash, try to parse a range.
      position_++;  // Skip the dash.
      code2/int := read_character_class_code_
      if code < 0 or code2 < 0:
        // One end of the range is not a single character, so the range is
        // degenerate.  We add either and and the dash, instead of a range.
        add_char_code.call code
        char_class.add '-' '-'
        add_char_code.call code2
      else:
        // Found a range.
        if code > code2: error "Character range out of order"
        char_class.add code code2
    expect_token OTHER;  // The terminating right square bracket.
    return char_class

  // Returns a character (possibly from a parsed escape) or a negative number
  // indicating the position of a character class special \s \d or \w.
  read_character_class_code_ -> int:
    code/int := at_ position_
    if code != '\\':
      position_ += utf_8_bytes code
      return code
    if not has_ position_ + 1: error "Unexpected end of regexp"
    code2/int := at_ position_ + 1
    lower/int := code2 | 0x20
    if (lower == 'd' or lower == 's' or lower == 'w'):
      answer := -position_
      position_ += 2
      return answer
    if code2 == 'c':
      // For web compatibility, the set of characters that can follow \c inside
      // a character class is different from the a-z_a-Z that are allowed outside
      // a character class.
      if has_ position_ + 2 and is_backslash_c_character (at_ position_ + 2):
        position_ += 3
        return at_ (position_ - 1) % 32
      // This makes little sense, but for web compatibility, \c followed by an
      // invalid character is interpreted as a literal backslash, followed by
      // the "c", etc.
      position_++
      return '\\'
    if '0' <= code2 and code2 <= '9':
      position_++
      return lex_integer 8 0x100
    position_ += 1 + (utf_8_bytes code2)
    if code2 == 'u':
      code = lex_hex 4
    else if code2 == 'x':
      code = lex_hex 2
    else if CONTROL_CHARACTERS.contains code2:
      code = CONTROL_CHARACTERS[code2]
    else:
      code = code2
    // In the case of a malformed escape we just interpret as if the backslash
    // was not there.
    if code == -1: code = code2
    return code

  expect_token token/int -> none:
    if token != last_token_:
      error "At position_ $(position_ - 1) expected $token, found $last_token_"
    get_token

  accept_token token/int -> bool:
    if token == last_token_:
      get_token
      return true
    return false

  peek_token token/int -> bool: return token == last_token_

  static CHARCODE_TO_TOKEN ::= [
    OTHER, OTHER, OTHER, OTHER,      // 0-3
    OTHER, OTHER, OTHER, OTHER,      // 4-7
    OTHER, OTHER, OTHER, OTHER,      // 8-11
    OTHER, OTHER, OTHER, OTHER,      // 12-15
    OTHER, OTHER, OTHER, OTHER,      // 16-19
    OTHER, OTHER, OTHER, OTHER,      // 20-23
    OTHER, OTHER, OTHER, OTHER,      // 24-27
    OTHER, OTHER, OTHER, OTHER,      // 28-31
    OTHER, OTHER, OTHER, OTHER,      //  !"#
    DOLLAR, OTHER, OTHER, OTHER,     // $%&'
    L_PAREN, R_PAREN, QUANT, QUANT,  // ()*+,
    OTHER, OTHER, DOT, OTHER,        // ,-./
    OTHER, OTHER, OTHER, OTHER,      // 0123
    OTHER, OTHER, OTHER, OTHER,      // 4567
    OTHER, OTHER, OTHER, OTHER,      // 89:
    OTHER, OTHER, OTHER, QUANT,      // <=>?
    OTHER, OTHER, OTHER, OTHER,      // @ABC
    OTHER, OTHER, OTHER, OTHER,      // DEFG
    OTHER, OTHER, OTHER, OTHER,      // HIJK
    OTHER, OTHER, OTHER, OTHER,      // LMNO
    OTHER, OTHER, OTHER, OTHER,      // PQRS
    OTHER, OTHER, OTHER, OTHER,      // TUVW
    OTHER, OTHER, OTHER, L_SQUARE,   // XYZ[
    BACKSLASH, OTHER, HAT, OTHER,    // \]^_
    OTHER, OTHER, OTHER, OTHER,      // `abc
    OTHER, OTHER, OTHER, OTHER,      // defg
    OTHER, OTHER, OTHER, OTHER,      // hijk
    OTHER, OTHER, OTHER, OTHER,      // lmno
    OTHER, OTHER, OTHER, OTHER,      // pqrs
    OTHER, OTHER, OTHER, OTHER,      // tuvw
    OTHER, OTHER, OTHER, QUANT,      // xyz{
    PIPE, OTHER]                     // |}

  static ESCAPES ::= {
    'b': WORD_BOUNDARY,
    'B': NOT_WORD_BOUNDARY,
    'w': WORD_CHARACTER,
    'W': NOT_WORD_CHARACTER,
    'd': DIGIT,
    'D': NOT_DIGIT,
    's': WHITESPACE,
    'S': NOT_WHITESPACE,
  }

  static CONTROL_CHARACTERS ::= {
    'b': '\b',
    'f': '\f',
    'n': '\n',
    'r': '\r',
    't': '\t',
    'v': '\v',
  }

  static token_from_charcode code/int -> int:
    if code >= CHARCODE_TO_TOKEN.size: return OTHER
    return CHARCODE_TO_TOKEN[code]

  on_digit position_/int -> bool:
    if not has_ position_: return false
    if (at_ position_) < '0': return false
    return (at_ position_) <= '9'

  get_token -> none:
    if not has_ position_:
      last_token_ = NONE
      return
    last_token_index_ = position_
    code/int := at_ position_
    last_token_ = token_from_charcode code
    token := last_token_
    if token == BACKSLASH:
      lex_backslash
      return
    if token == L_PAREN:
      lex_left_parenthesis
    else if token == QUANT:
      lex_quantifier
    position_ += utf_8_bytes code

  // This may be a bug in Irregexp, but there are tests for it: \c _and \c0
  // work like \cc which means Control-C.  But only in character classes.
  static is_backslash_c_character code/int -> bool:
    if is_ascii_letter code: return true
    if '0' <= code <= '9': return true
    return code == '_'

  static is_ascii_letter code/int -> bool:
    if 'A' <= code <= 'Z': return true
    return 'a' <= code <= 'z'

  lex_backslash -> none:
    if not has_ (position_ + 1): error "\\ at end of pattern"
    next_code/int := at_ position_ + 1
    if ESCAPES.contains next_code:
      position_ += 2
      last_token_ = ESCAPES[next_code]
    else if CONTROL_CHARACTERS.contains next_code:
      position_ += 2
      last_token_ = OTHER
      last_token_index_ =
          compiler_.add_to_constant_pool CONTROL_CHARACTERS[next_code]
    else if next_code == 'c':
       if (has_ position_ + 2) and (is_ascii_letter (at_ position_ + 2)):
         last_token_ = OTHER
         last_token_index_ = compiler_.add_to_constant_pool (at_ position_ + 2) % 32
         position_ += 3
       else:
         // \c _is interpreted as a literal backslash and literal "c_".
         last_token_ = OTHER
         last_token_index_ = position_
         position_++
    else if on_digit position_ + 1:
      position_++
      last_back_reference_index_ = lex_integer_as_string
      last_token_ = BACK_REFERENCE
    else if next_code == 'x' or next_code == 'u':
      position_ += 2
      last_token_ = OTHER
      code_unit := lex_hex (next_code == 'x' ? 2 : 4)
      if code_unit == -1:
        last_token_index_ = position_ - 1
      else:
        last_token_index_ = compiler_.add_to_constant_pool code_unit
    else:
      last_token_ = OTHER
      last_token_index_ = position_ + 1
      position_ += 1 + (utf_8_bytes next_code)

  lex_hex chars/int -> int:
    if not has_ position_ + chars - 1: return -1
    total/int := 0
    for i := 0; i < chars; i++:
      total *= 16
      char_code := at_ position_ + i
      if char_code >= '0' and char_code <= '9':
        total += char_code - '0'
      else if (char_code >= 'A' and
                 char_code <= 'F'):
        total += 10 + char_code - 'A'
      else if (char_code >= 'a' and
                 char_code <= 'f'):
        total += 10 + char_code - 'a'
      else:
        return -1
    position_ += chars
    return total

  lex_integer_as_string -> string:
    b := Buffer
    while true:
      if not has_ position_: return b.to_string
      code := at_ position_
      if code >= '0' and code <= '9':
        b.write_byte code
        position_++
      else:
        return b.to_string

  lex_integer base/int max/int? -> int:
    total/int := 0
    while true:
      if not has_ position_: return total
      code := at_ position_
      if code >= '0' and code < '0' + base and (max == null or total * base < max):
        position_++
        total *= base
        total += code - '0'
      else:
        return total

  lex_left_parenthesis -> none:
    if not has_ position_ + 1: error "unterminated group"
    if (at_ position_ + 1) == '?':
      if not has_ position_ + 2: error "unterminated group"
      parenthesis_modifier/int := at_ position_ + 2
      if parenthesis_modifier == '=':
        last_token_ = LOOK_AHEAD
      else if parenthesis_modifier == ':':
        last_token_ = NON_CAPTURING
      else if parenthesis_modifier == '!':
        last_token_ = NEGATIVE_LOOK_AHEAD
      else:
        error "invalid group"
      position_ += 2
      return

  lex_quantifier -> none:
    quantifier_code/int := at_ position_
    if quantifier_code == '{':
      parsed_repeats := false
      saved_position := position_
      if on_digit (position_ + 1):
        position_++
        // We parse the repeats in the lexer.  Forms allowed are {n}, {n,}
        // and {n,m}.
        minimum_repeats_ = lex_integer 10 null
        if has_ position_:
          if (at_ position_) == '}':
            maximum_repeats_ = minimum_repeats_
            parsed_repeats = true
          else if (at_ position_) == ',':
            position_++
            if has_ position_:
              if (at_ position_) == '}':
                maximum_repeats_ = null;  // No maximum.
                parsed_repeats = true
              else if on_digit position_:
                maximum_repeats_ = lex_integer 10 null
                if (has_ position_) and (at_ position_) == '}':
                  parsed_repeats = true
      if parsed_repeats:
        if maximum_repeats_ != null and minimum_repeats_ > maximum_repeats_:
          error "numbers out of order in {} quantifier"
      else:
        // If parsing of the repeats fails then we follow JS in interpreting
        // the left brace as a literal.
        position_ = saved_position
        last_token_ = OTHER
        return
    else if quantifier_code == '*':
      minimum_repeats_ = 0
      maximum_repeats_ = null;  // No maximum.
    else if quantifier_code == '+':
      minimum_repeats_ = 1
      maximum_repeats_ = null;  // No maximum.
    else:
      minimum_repeats_ = 0
      maximum_repeats_ = 1
    if (has_ position_ + 1) and (at_ position_ + 1) == '?':
      position_++
      last_was_greedy_ = false
    else:
      last_was_greedy_ = true

class MiniExpInterpreter_:
  byte_codes_/List/*<int>*/ ::= ?
  constant_pool_ /ByteArray ::= ?
  registers_/List/*<int>*/ ::= ?
  trace_/bool

  constructor .byte_codes_ .constant_pool_ .registers_ .trace_:

  stack/List/*<int>*/ := []
  stack_pointer/int := -1

  interpret subject/string start_position/int program_counter/int -> bool:
    registers_[STRING_LENGTH_] = subject.size
    registers_[CURRENT_POSITION_] = start_position

    while true:
      byte_code := byte_codes_[program_counter]
      if trace_:
        pos := registers_[CURRENT_POSITION_]
        i := pos
        while i < subject.size and subject[i] == null: i--
        line := "\"$subject[0..i]^$subject[i..]\"  @$(%-3d pos) $(%50s registers_)  "
        MiniExp_.disassemble_single_instruction_ byte_codes_ null program_counter: line += it
        print line
      program_counter++
      // TODO: Faster implementation.
      if byte_code == BC_GOTO_:
        program_counter = byte_codes_[program_counter]
      else if byte_code == BC_PUSH_REGISTER_:
        reg/int := registers_[byte_codes_[program_counter++]]
        stack_pointer++
        if stack_pointer == stack.size:
          stack.add reg
        else:
          stack[stack_pointer] = reg
      else if byte_code == BC_PUSH_BACKTRACK_:
        value/int := byte_codes_[program_counter++]
        stack_pointer++
        if stack_pointer == stack.size:
          stack.add value
        else:
          stack[stack_pointer] = value
        position/int := registers_[CURRENT_POSITION_]
        stack_pointer++
        if stack_pointer == stack.size:
          stack.add position
        else:
          stack[stack_pointer] = position
      else if byte_code == BC_POP_REGISTER_:
        registers_[byte_codes_[program_counter++]] = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_EQ_:
        reg1/int := registers_[byte_codes_[program_counter++]]
        reg2/int := registers_[byte_codes_[program_counter++]]
        if reg1 == reg2:
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_NE_:
        reg1/int := registers_[byte_codes_[program_counter++]]
        reg2/int := registers_[byte_codes_[program_counter++]]
        if reg1 != reg2:
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_GT_:
        reg1/int := registers_[byte_codes_[program_counter++]]
        reg2/int := registers_[byte_codes_[program_counter++]]
        if reg1 > reg2:
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_IF_NO_MATCH_:
        if (subject.at --raw registers_[CURRENT_POSITION_]) !=
            (constant_pool_[byte_codes_[program_counter++]]):
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_IF_IN_RANGE_:
        code/int := subject.at --raw registers_[CURRENT_POSITION_]
        from/int := byte_codes_[program_counter++]
        to/int := byte_codes_[program_counter++]
        if from <= code and code <= to:
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_GOTO_IF_MATCH_:
        code/int := subject.at --raw registers_[CURRENT_POSITION_]
        expected/int := byte_codes_[program_counter++]
        dest/int := byte_codes_[program_counter++]
        if code == expected: program_counter = dest
      else if byte_code == BC_GOTO_IF_IN_RANGE_:
        code/int := subject.at --raw registers_[CURRENT_POSITION_]
        from/int := byte_codes_[program_counter++]
        to/int := byte_codes_[program_counter++]
        dest/int := byte_codes_[program_counter++]
        if from <= code and code <= to: program_counter = dest
      else if byte_code == BC_GOTO_IF_UNICODE_IN_RANGE_:
        code/int := subject[registers_[CURRENT_POSITION_]]
        from/int := byte_codes_[program_counter++]
        to/int := byte_codes_[program_counter++]
        dest/int := byte_codes_[program_counter++]
        if from <= code and code <= to: program_counter = dest
      else if byte_code == BC_GOTO_EQ_:
        reg1/int := registers_[byte_codes_[program_counter++]]
        reg2/int := registers_[byte_codes_[program_counter++]]
        dest/int := byte_codes_[program_counter++]
        if reg1 == reg2: program_counter = dest
      else if byte_code == BC_GOTO_GE_:
        reg1/int := registers_[byte_codes_[program_counter++]]
        reg2/int := registers_[byte_codes_[program_counter++]]
        dest/int := byte_codes_[program_counter++]
        if reg1 >= reg2: program_counter = dest
      else if byte_code == BC_GOTO_IF_WORD_CHARACTER_:
        offset/int := byte_codes_[program_counter++]
        char_code/int :=
            subject.at --raw registers_[CURRENT_POSITION_] + offset
        dest/int := byte_codes_[program_counter++]
        if char_code >= '0':
          if char_code <= '9':
            program_counter = dest
          else if char_code >= 'A':
            if char_code <= 'Z':
              program_counter = dest
            else if char_code == '_':
              program_counter = dest
            else if (char_code >= 'a' and
                       char_code <= 'z'):
              program_counter = dest
      else if byte_code == BC_ADD_TO_REGISTER_:
        register_index/int := byte_codes_[program_counter++]
        registers_[register_index] += byte_codes_[program_counter++]
      else if byte_code == BC_ADVANCE_BY_RUNE_WIDTH_:
        register_index/int := byte_codes_[program_counter++]
        characters/int := byte_codes_[program_counter++]
        position := registers_[CURRENT_POSITION_]
        if characters > 0:
          characters.repeat:
            if position >= subject.size:
              position++
            else:
              code/int := subject.at --raw position
              position += MiniExpCompiler_.UTF_FIRST_CHAR_TABLE_[code >> 4]
        else if characters < 0:
          (-characters).repeat:
            position--
            if position < subject.size:
              code/int? := subject[position]
              while code == null:
                position--
                code = subject[position]
        registers_[register_index] = position
      else if byte_code == BC_COPY_REGISTER_:
        // We don't normally keep the stack pointer in sync with its slot in
        // the registers_, but we have to have it in sync here.
        registers_[STACK_POINTER_] = stack_pointer
        register_index/int := byte_codes_[program_counter++]
        value/int := registers_[byte_codes_[program_counter++]]
        registers_[register_index] = value
        stack_pointer = registers_[STACK_POINTER_]
      else if byte_code == BC_BACKTRACK_ON_BACK_REFERENCE_:
        register_index/int := byte_codes_[program_counter++]
        case_sensitive := byte_codes_[program_counter++] != 0
        if not check_back_reference subject case_sensitive register_index:
          // Backtrack.
          registers_[CURRENT_POSITION_] = stack[stack_pointer--]
          program_counter = stack[stack_pointer--]
      else if byte_code == BC_BACKTRACK_:
        registers_[CURRENT_POSITION_] = stack[stack_pointer--]
        program_counter = stack[stack_pointer--]
      else if byte_code == BC_FAIL_:
        return false
      else if byte_code == BC_SUCCEED_:
        return true
      else:
        assert: false

  check_back_reference subject/string case_sensitive/bool register_index/int -> bool:
    start/int := registers_[register_index]
    end/int := registers_[register_index + 1]
    if end == NO_POSITION_: return true
    length/int := end - start
    current_position/int := registers_[CURRENT_POSITION_]
    if current_position + end - start > subject.size: return false
    for i := 0; i < length; i++:
      x := subject.at --raw start + i
      y := subject.at --raw current_position + i
      if not case_sensitive:
        x = case.reg_exp_canonicalize x
        y = case.reg_exp_canonicalize y
      if x != y: return false
    registers_[CURRENT_POSITION_] += length
    return true

class FormatException:
  text /string ::= ?
  source /string ::= ?
  position /int ::= ?

  constructor .text .source .position:

  stringify -> string:
    return "$text\n$source\n$("-" * position)^"
