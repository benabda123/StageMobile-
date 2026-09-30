import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/learning_item.dart';
import 'learning_provider.dart';

/// Écran des résultats de recherche Learning.
class LearningResultsScreen extends ConsumerWidget {
  const LearningResultsScreen({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LearningItem>> searchState =
        ref.watch(learningSearchProvider(query));

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'Formations : $query',
          style: const TextStyle(
            color: GlassTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        showLogo: false,
      ),
      body: RefreshIndicator(
        color: GlassTokens.accentBorder,
        onRefresh: () => ref.refresh(learningSearchProvider(query).future),
        child: searchState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GlassTokens.accentBorder),
          ),
          error: (Object error, StackTrace _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              GlassEmptyState(
                message: 'Erreur de chargement',
                subtitle: '$error',
                icon: Icons.error_outline,
              ),
            ],
          ),
          data: (List<LearningItem> items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const <Widget>[
                  SizedBox(height: 48),
                  GlassEmptyState(
                    message: 'Aucun résultat trouvé',
                    subtitle: 'Essayez un autre mot-clé ou catégorie',
                    icon: Icons.school_outlined,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final LearningItem item = items[index];
                return GlassBlur(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (item.thumbnail.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.thumbnail,
                            width: 100,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) {
                              return Container(
                                width: 100,
                                height: 65,
                                color: GlassTokens.glassFill,
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: GlassTokens.textSecondary,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 65,
                          decoration: BoxDecoration(
                            color: GlassTokens.glassFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.video_library,
                            color: GlassTokens.textSecondary,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GlassTokens.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.channelTitle,
                              style: const TextStyle(
                                color: GlassTokens.submitBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GlassTokens.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
