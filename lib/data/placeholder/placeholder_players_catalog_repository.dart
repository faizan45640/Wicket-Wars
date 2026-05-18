import '../models/catalog_player.dart';
import '../models/player_attributes.dart';
import '../models/player_tier.dart';
import '../repositories/players_catalog_repository.dart';

/// In-memory sample catalog for tests / Firebase-off builds.
class PlaceholderPlayersCatalogRepository implements PlayersCatalogRepository {
  static final List<CatalogPlayer> _demo = [
    CatalogPlayer(
      id: 'catalog_demo_pro',
      displayName: 'Catalog Pro (demo)',
      isRealPlayer: true,
      playerTier: PlayerTier.premium,
      attributes: const PlayerAttributes(
        batting: 84,
        bowling: 72,
        fielding: 80,
        stamina: 78,
        consistency: 82,
      ),
    ),
    CatalogPlayer(
      id: 'catalog_custom_starter',
      displayName: 'Custom Starter (trainable)',
      isRealPlayer: false,
      playerTier: PlayerTier.free,
      attributes: const PlayerAttributes(
        batting: 52,
        bowling: 48,
        fielding: 50,
        stamina: 55,
        consistency: 50,
      ),
    ),
  ];

  @override
  Stream<List<CatalogPlayer>> watchCatalog() async* {
    yield _demo;
  }
}
