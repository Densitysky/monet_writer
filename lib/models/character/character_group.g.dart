// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_group.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const CharacterGroupSchema = Schema(
  name: r'CharacterGroup',
  id: -2203397536893773923,
  properties: {
    r'characters': PropertySchema(
      id: 0,
      name: r'characters',
      type: IsarType.objectList,
      target: r'Character',
    ),
    r'safeCharacters': PropertySchema(
      id: 1,
      name: r'safeCharacters',
      type: IsarType.objectList,
      target: r'Character',
    ),
    r'title': PropertySchema(
      id: 2,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _characterGroupEstimateSize,
  serialize: _characterGroupSerialize,
  deserialize: _characterGroupDeserialize,
  deserializeProp: _characterGroupDeserializeProp,
);

int _characterGroupEstimateSize(
  CharacterGroup object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.characters;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Character]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              CharacterSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.safeCharacters.length * 3;
  {
    final offsets = allOffsets[Character]!;
    for (var i = 0; i < object.safeCharacters.length; i++) {
      final value = object.safeCharacters[i];
      bytesCount += CharacterSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _characterGroupSerialize(
  CharacterGroup object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<Character>(
    offsets[0],
    allOffsets,
    CharacterSchema.serialize,
    object.characters,
  );
  writer.writeObjectList<Character>(
    offsets[1],
    allOffsets,
    CharacterSchema.serialize,
    object.safeCharacters,
  );
  writer.writeString(offsets[2], object.title);
}

CharacterGroup _characterGroupDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CharacterGroup();
  object.characters = reader.readObjectList<Character>(
    offsets[0],
    CharacterSchema.deserialize,
    allOffsets,
    Character(),
  );
  object.title = reader.readStringOrNull(offsets[2]);
  return object;
}

P _characterGroupDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<Character>(
        offset,
        CharacterSchema.deserialize,
        allOffsets,
        Character(),
      )) as P;
    case 1:
      return (reader.readObjectList<Character>(
            offset,
            CharacterSchema.deserialize,
            allOffsets,
            Character(),
          ) ??
          []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension CharacterGroupQueryFilter
    on QueryBuilder<CharacterGroup, CharacterGroup, QFilterCondition> {
  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'characters',
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'characters',
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'characters',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeCharacters',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension CharacterGroupQueryObject
    on QueryBuilder<CharacterGroup, CharacterGroup, QFilterCondition> {
  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      charactersElement(FilterQuery<Character> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'characters');
    });
  }

  QueryBuilder<CharacterGroup, CharacterGroup, QAfterFilterCondition>
      safeCharactersElement(FilterQuery<Character> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'safeCharacters');
    });
  }
}
