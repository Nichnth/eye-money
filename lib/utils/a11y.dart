import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// The app's spoken language. Used to tag screen-reader text so TalkBack /
/// VoiceOver pronounce it with the Indonesian voice.
const Locale kIdLocale = Locale('id', 'ID');

/// Wraps [text] with an Indonesian locale hint.
///
/// On Android this becomes a `LocaleSpan`, so TalkBack reads the node with the
/// Indonesian voice (when an `id` voice is installed) instead of the user's
/// default engine language. Use with `Semantics.attributedLabel` /
/// `attributedHint` / `attributedValue`.
AttributedString idLabel(String text) {
  if (text.isEmpty) return AttributedString(text);
  return AttributedString(
    text,
    attributes: <StringAttribute>[
      LocaleStringAttribute(
        range: TextRange(start: 0, end: text.length),
        locale: kIdLocale,
      ),
    ],
  );
}
