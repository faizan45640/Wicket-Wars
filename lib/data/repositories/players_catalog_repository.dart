import '../models/catalog_player.dart';

/// Global `players_catalog/*` — templates for licensed / premium cards.
abstract class PlayersCatalogRepository {
  Stream<List<CatalogPlayer>> watchCatalog();
}
