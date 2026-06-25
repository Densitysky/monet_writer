// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outline_group.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const OutlineGroupSchema = Schema(
  name: r'OutlineGroup',
  id: -1817730672276821848,
  properties: {
    r'outlines': PropertySchema(
      id: 0,
      name: r'outlines',
      type: IsarType.objectList,
      target: r'CustomOutline',
    ),
    r'safeOutlines': PropertySchema(
      id: 1,
      name: r'safeOutlines',
      type: IsarType.objectList,
      target: r'CustomOutline',
    ),
    r'title': PropertySchema(
      id: 2,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _outlineGroupEstimateSize,
  serialize: _outlineGroupSerialize,
  deserialize: _outlineGroupDeserialize,
  deserializeProp: _outlineGroupDeserializeProp,
);

int _outlineGroupEstimateSize(
  OutlineGroup object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.outlines;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[CustomOutline]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              CustomOutlineSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.safeOutlines.length * 3;
  {
    final offsets = allOffsets[CustomOutline]!;
    for (var i = 0; i < object.safeOutlines.length; i++) {
      final value = object.safeOutlines[i];
      bytesCount +=
          CustomOutlineSchema.estimateSize(value, offsets, allOffsets);
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

void _outlineGroupSerialize(
  OutlineGroup object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<CustomOutline>(
    offsets[0],
    allOffsets,
    CustomOutlineSchema.serialize,
    object.outlines,
  );
  writer.writeObjectList<CustomOutline>(
    offsets[1],
    allOffsets,
    CustomOutlineSchema.serialize,
    object.safeOutlines,
  );
  writer.writeString(offsets[2], object.title);
}

OutlineGroup _outlineGroupDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutlineGroup();
  object.outlines = reader.readObjectList<CustomOutline>(
    offsets[0],
    CustomOutlineSchema.deserialize,
    allOffsets,
    CustomOutline(),
  );
  object.title = reader.readStringOrNull(offsets[2]);
  return object;
}

P _outlineGroupDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<CustomOutline>(
        offset,
        CustomOutlineSchema.deserialize,
        allOffsets,
        CustomOutline(),
      )) as P;
    case 1:
      return (reader.readObjectList<CustomOutline>(
            offset,
            CustomOutlineSchema.deserialize,
            allOffsets,
            CustomOutline(),
          ) ??
          []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OutlineGroupQueryFilter
    on QueryBuilder<OutlineGroup, OutlineGroup, QFilterCondition> {
  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outlines',
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outlines',
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outlines',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'safeOutlines',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension OutlineGroupQueryObject
    on QueryBuilder<OutlineGroup, OutlineGroup, QFilterCondition> {
  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      outlinesElement(FilterQuery<CustomOutline> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'outlines');
    });
  }

  QueryBuilder<OutlineGroup, OutlineGroup, QAfterFilterCondition>
      safeOutlinesElement(FilterQuery<CustomOutline> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'safeOutlines');
    });
  }
}
