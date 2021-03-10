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

import 'models/base_element.dart';
import 'models/option.dart';
import 'models/option_element.dart';
import 'models/sentence.dart';

class IcuParser {
  Parser<String> get openCurly => char('{');

  Parser<String> get closeCurly => char('}');

  Parser get quotedCurly => (string("'{'") | string("'}'")).map((x) => x[1]);

  Parser get icuEscapedText => quotedCurly | twoSingleQuotes;

  Parser get curly => (openCurly | closeCurly);

  Parser get notAllowedInIcuText => curly | char('<');

  Parser get icuText => notAllowedInIcuText.neg();

  Parser<String> get notAllowedInNormalText => char('{');

  Parser<String> get normalText => notAllowedInNormalText.neg();

  Parser get messageText => (icuEscapedText | icuText)
      .plus()
      .flatten()
      .map((result) => LiteralElement(result));

  Parser<LiteralElement> get nonIcuMessageText =>
      normalText.plus().flatten().map((result) => LiteralElement(result));

  Parser get twoSingleQuotes => string("''").map((x) => "'");

  Parser<int> get number => digit().plus().flatten().trim().map<int>(int.parse);

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

  Parser get pluralClause => (pluralKeyword &
          openCurly &
          interiorText &
          closeCurly)
      .trim()
      .map((result) => Option(result[0],
          List<BaseElement>.from(result[2] is List ? result[2] : [result[2]])));

  Parser get plural =>
      preface & pluralLiteral & comma & pluralClause.plus() & closeCurly;

  Parser get intlPlural => plural
      .map((result) => PluralElement(result[0], List<Option>.from(result[3])));

  Parser<String> get selectLiteral => string('select');

  Parser get genderClause => (genderKeyword &
          openCurly &
          interiorText &
          closeCurly)
      .trim()
      .map((result) => Option(result[0],
          List<BaseElement>.from(result[2] is List ? result[2] : [result[2]])));

  Parser get gender =>
      preface & selectLiteral & comma & genderClause.plus() & closeCurly;

  Parser get intlGender => gender
      .map((result) => GenderElement(result[0], List<Option>.from(result[3])));

  Parser get selectClause => (id & openCurly & interiorText & closeCurly)
      .trim()
      .map((result) => Option(result[0],
          List<BaseElement>.from(result[2] is List ? result[2] : [result[2]])));

  Parser get generalSelect =>
      preface & selectLiteral & comma & selectClause.plus() & closeCurly;

  Parser<SelectElement> get intlSelect => generalSelect
      .map((result) => SelectElement(result[0], List<Option>.from(result[3])));

  Parser get pluralOrGenderOrSelect => (intlPlural | intlGender | intlSelect);

  Parser get contents => pluralOrGenderOrSelect | parameter | messageText;

  Parser get simpleText => (nonIcuMessageText | parameter | openCurly)
          .plus()
          .callCC((continuation, context) {
        print('hello');
        final result = continuation(context);
        return result;
      });

  Parser<LiteralElement> get empty => epsilon().map((_) => LiteralElement(''));

  Parser<ArgumentElement> get parameter =>
      (openCurly & id & closeCurly).map((result) => ArgumentElement(result[1]));

  Result<BaseElement> parse(String message) {
    final parsed =
        (pluralOrGenderOrSelect | simpleText | empty).map<BaseElement>(
      (dynamic result) {
        if (result is List) {
          return Sentence(List<SentenceElement>.from(result));
        } else {
          return result as OptionElement;
        }
      },
    ).parse(message);

    return parsed;
  }

  IcuParser() {
    // There is a cycle here, so we need the explicit set to avoid infinite recursion.
    interiorText.set(contents.plus() | empty);
  }
}
