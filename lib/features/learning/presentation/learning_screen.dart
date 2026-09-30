import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';

/// Centre de formation — grille de catégories.
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  static const List<_LearningCategory> _categories = <_LearningCategory>[
    _LearningCategory('Cloud', Icons.cloud_outlined),
    _LearningCategory('Cyber Security', Icons.security_outlined),
    _LearningCategory('React', Icons.code_outlined),
    _LearningCategory('Docker', Icons.storage_outlined),
    _LearningCategory('Sécurité', Icons.shield_outlined),
    _LearningCategory('DevOps', Icons.settings_suggest_outlined),
    _LearningCategory('Leadership', Icons.groups_outlined),
    _LearningCategory('Compliance', Icons.gavel_outlined),
    _LearningCategory('Soft Skills', Icons.psychology_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToResults(String query) {
    if (query.trim().isEmpty) return;
    debugPrint('Navigating to learning results with query: $query');
    context.push('/learning/results?query=${Uri.encodeComponent(query.trim())}');
  }

  @override
  Widget build(BuildContext context) {
    final List<_LearningCategory> filtered = _categories
        .where(
          (_LearningCategory c) =>
              c.label.toLowerCase().contains(_filterQuery.toLowerCase()),
        )
        .toList();

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Learning',
                  style: TextStyle(
                    color: GlassTokens.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GlassBlur(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String v) => setState(() => _filterQuery = v),
                    onSubmitted: (String v) => _navigateToResults(v),
                    style: const TextStyle(color: GlassTokens.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une formation…',
                      hintStyle: const TextStyle(color: GlassTokens.textHint),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: GlassTokens.textSecondary),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.arrow_forward,
                                  color: GlassTokens.submitBlue),
                              onPressed: () => _navigateToResults(_filterQuery),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final _LearningCategory cat = filtered[index];
                return _CategoryTile(
                  label: cat.label,
                  icon: cat.icon,
                  onTap: () {
                    debugPrint('Category clicked: ${cat.label}, triggering search for query: ${cat.label}');
                    _navigateToResults(cat.label);
                  },
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: GlassBlur(
        active: _pressed,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(widget.icon, size: 36, color: GlassTokens.textPrimary),
            const SizedBox(height: 12),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GlassTokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningCategory {
  const _LearningCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
