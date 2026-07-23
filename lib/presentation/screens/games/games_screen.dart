import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/games_provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gamesProvider = context.watch<GamesProvider>();
    final uid = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: SafeArea(
        child: gamesProvider.isLoading
            ? const LoadingIndicator()
            : gamesProvider.games.isEmpty
                ? const EmptyState(
                    icon: Icons.sports_esports_rounded,
                    title: 'No games available',
                    subtitle: 'Check back soon — new games are added regularly.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: gamesProvider.games.length,
                    itemBuilder: (context, index) {
                      final game = gamesProvider.games[index];
                      final completed = gamesProvider.isCompleted(game.id);
                      final isClaiming = gamesProvider.claimingGameId == game.id;
                      return _GameCard(
                        game: game,
                        completed: completed,
                        isClaiming: isClaiming,
                        onPlay: uid == null
                            ? null
                            : () async {
                                final success = await gamesProvider.playGame(uid, game);
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('+${game.rewardCoins} coins earned!')),
                                  );
                                } else if (gamesProvider.actionError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(gamesProvider.actionError!)),
                                  );
                                  gamesProvider.clearError();
                                }
                              },
                      );
                    },
                  ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameModel game;
  final bool completed;
  final bool isClaiming;
  final VoidCallback? onPlay;

  const _GameCard({
    required this.game,
    required this.completed,
    required this.isClaiming,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: game.iconUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: game.iconUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 64, height: 64, color: AppColors.surfaceElevated),
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.sports_esports_rounded, color: AppColors.textSecondary),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: const Icon(Icons.sports_esports_rounded, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(game.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.accentGold, size: 16),
                        const SizedBox(width: 4),
                        Text('+${game.rewardCoins}',
                            style: const TextStyle(
                                color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: completed ? null : onPlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: completed ? AppColors.divider : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          minimumSize: const Size(0, 36),
                        ),
                        child: isClaiming
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(completed ? 'Claimed' : 'Play',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
