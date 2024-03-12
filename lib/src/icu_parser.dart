// This file incorporates work covered by the following copyright and
// permission notice:
//
//     Copyright 2013, the Dart project authors. All rights reserved.
//     Redistribution and use in source and binary forms, with or without
//     modification, are permitted provided that the following conditions are
//     met:
//
//         * Redistributions of source code must retain the above copyright
//           notice, this list of conditions and the following disclaimer.
//         * Redistributions in binary form must reproduce the above
//           copyright notice, this list of conditions and the following
//           disclaimer in the documentation and/or other materials provided
//           with the distribution.
//         * Neither the name of Google Inc. nor the names of its
//           contributors may be used to endorse or promote products derived
//           from this software without specific prior written permission.
//
//     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//     A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//     OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//     SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//     LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//     DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//     THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//     (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//     OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:petitparser/petitparser.dart';

/// Some getters have been commented out as they weren't necessary for our
/// purposes.
class IcuParser {
  Parser<String> get openCurly => char('{');

  Parser<String> get closeCurly => char('}');

  Parser get twoSingleQuotes => string("''").map((x) => "'");

  Parser get quotedCurly => (string("'{'") | string("'}'")).map((x) => x[1]);

  Parser get icuEscapedText => quotedCurly | twoSingleQuotes;

  Parser get curly => openCurly | closeCurly;

  Parser get html => char('<');

  Parser get notAllowedInIcuText => curly | html;

  Parser get icuText => notAllowedInIcuText.neg();

  // Parser<String> get notAllowedInNormalText => char('{');

  // Parser<String> get normalText => notAllowedInNormalText.neg();

  Parser get messageText => (icuEscapedText | icuText).plus().flatten();

  Parser get justText => messageText.end();

  Parser get optionalMessageText => (icuEscapedText | icuText).star().flatten();

  Parser get placeholderText => (optionalMessageText &
          openCurly &
          messageText &
          closeCurly &
          optionalMessageText)
      .plus()
      .flatten();

  // Parser<String> get nonIcuMessageText => normalText.plus().flatten();

  // Parser<int> get number => digit().plus().flatten().trim().map<int>(int.parse);

  Parser<String> get id =>
      (letter() & (word() | char('_')).star()).flatten().trim();

  Parser<String> get comma => char(',').trim();

  /// Given a list of possible keywords, return a rule that accepts any of them.
  /// e.g., given ["male", "female", "other"], accept any of them.
  Parser<String> asKeywords(List<String> list) =>
      list.map(string).cast<Parser>().reduce((a, b) => a | b).flatten().trim();

  Parser<String> get pluralKeyword => asKeywords(
        ['=0', '=1', '=2', 'zero', 'one', 'two', 'few', 'many', 'other'],
      );

  Parser<String> get genderKeyword => asKeywords(['female', 'male', 'other']);

  var interiorText = undefined();

  Parser<String> get preface =>
      (openCurly & id & comma).map((values) => values[1]);

  Parser get pluralLiteral => string('plural');

  Parser get pluralClause =>
      (pluralKeyword & openCurly & interiorText & closeCurly).trim().pick(2);

  Parser get plural =>
      preface & pluralLiteral & comma & pluralClause.plus() & closeCurly;

  Parser<String> get selectLiteral => string('select');

  Parser get selectClause =>
      (id & openCurly & interiorText & closeCurly).trim().pick(2);

  Parser get generalSelect =>
      preface & selectLiteral & comma & selectClause.plus() & closeCurly;

  Parser get genderClause =>
      (genderKeyword & openCurly & interiorText & closeCurly).trim().pick(2);

  Parser get gender =>
      preface & selectLiteral & comma & genderClause.plus() & closeCurly;

  Parser get pluralOrGenderOrSelect => plural | gender | generalSelect;

  Parser get pluralOrGenderOrSelectContents =>
      pluralOrGenderOrSelect.map((result) => result[3]);

  Parser get contents => pluralOrGenderOrSelect | placeholderText | messageText;

  Parser get empty => epsilon();

  // Parser get parameter => openCurly & id & closeCurly;

  // TODO: Tokens can be nested deeper and we'll need to get those too using
  // fold or something
  List<Token> parse(String message) {
    final parsed = (placeholderText.token() |
            justText.token() |
            pluralOrGenderOrSelectContents)
        .parse(message);

    if (parsed.isFailure) {
      print('Failed to parse: $message');
      print(parsed.message);
      throw Exception('parsing failed');
    } else {
      final parsedValue = parsed.value;
      print('Parsed: $parsedValue');
      return parsedValue is List
          ? List<Token>.from(parsedValue)
          : [parsedValue as Token];
    }
  }

  IcuParser() {
    // There is a cycle here, so we need the explicit set to avoid infinite recursion.
    interiorText.set((contents | empty).token());
  }
}
