import 'package:isar/isar.dart';
import 'package:monet_writer/models/inspiration_fragment.dart';

/// ── 灵感碎片 ──────────────────────────────────────────

mixin InspirationMixin {
  Isar get isar;

  Future<List<InspirationFragment>> getAllInspirationFragments() async =>
      await isar.inspirationFragments.where().findAll();
}
