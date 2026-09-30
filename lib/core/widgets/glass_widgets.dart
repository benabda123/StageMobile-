import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';
import 'waves_background.dart';

export 'waves_background.dart' show GlassBlur, WavesBackground;

/// Scaffold global avec fond WAVES + contenu.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = true,
    this.extendBodyBehindAppBar = false,
    this.contentPadding = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// Laisse le body passer sous la bottom bar (effet glass).
  final bool extendBody;

  /// `false` par défaut : le body démarre sous le header, sans chevauchement.
  final bool extendBodyBehindAppBar;

  /// Applique les marges haut/bas standard (gap header + réserve bottom nav).
  final bool contentPadding;

  @override
  Widget build(BuildContext context) {
    Widget paddedBody = body;
    if (contentPadding) {
      paddedBody = Padding(
        padding: EdgeInsets.only(
          top: appBar != null ? GlassLayout.contentTopGap : 0,
          bottom: bottomNavigationBar != null ? GlassLayout.bottomNavReserve : 0,
        ),
        child: body,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const WavesBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          appBar: appBar,
          body: paddedBody,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        ),
      ],
    );
  }
}

/// AppBar compacte glassmorphism (logo Keystone + actions).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions = const <Widget>[],
    this.leading,
    this.showLogo = true,
  });

  final Widget? title;
  final List<Widget> actions;
  final Widget? leading;
  final bool showLogo;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      // Affiche la flèche retour automatiquement quand un écran est poussé
      // (ex. formulaires, détails), sauf si un `leading` personnalisé est fourni.
      automaticallyImplyLeading: leading == null,
      leading: leading,
      title: title ??
          (showLogo
              ? const Text(
                  'Keystone',
                  style: TextStyle(
                    color: GlassTokens.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                )
              : null),
      actions: actions,
      flexibleSpace: GlassBlur(
        borderRadius: BorderRadius.zero,
        fillColor: GlassTokens.glassFill.withValues(alpha: 0.45),
        borderColor: GlassTokens.glassBorder,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Badge de statut translucide (vert pour accepté, etc.).
class GlassStatusBadge extends StatelessWidget {
  const GlassStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.95),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Carte verticale glass pour listes (congés, tickets…).
class GlassListCard extends StatelessWidget {
  const GlassListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.icon,
    this.footer,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final IconData? icon;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: GlassTokens.textPrimary, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: GlassTokens.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null) badge!,
                ],
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: GlassTokens.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              if (footer != null) ...<Widget>[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloc sélectionnable tactile (types congé, priorités…).
class GlassSelectableTile extends StatelessWidget {
  const GlassSelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassBlur(
        active: selected,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  color: GlassTokens.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GlassTokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: GlassTokens.textPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton principal bleu accentué.
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: GlassTokens.submitBlue,
          foregroundColor: GlassTokens.textPrimary,
          disabledBackgroundColor: GlassTokens.submitBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          ),
          elevation: 0,
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.send_rounded, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// Champ de formulaire glass.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return GlassBlur(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: GlassTokens.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: GlassTokens.textSecondary),
          hintStyle: const TextStyle(color: GlassTokens.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

/// État vide glass.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
  });

  final String message;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassBlur(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: GlassTokens.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GlassTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GlassTokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatar utilisateur pour le header.
class GlassUserAvatar extends StatelessWidget {
  const GlassUserAvatar({super.key, this.initial, this.onTap});

  final String? initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String letter =
        (initial != null && initial!.isNotEmpty) ? initial![0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassBlur(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: GlassTokens.activeFill,
            child: Text(
              letter,
              style: const TextStyle(
                color: GlassTokens.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation glass avec lueur sur l'onglet actif.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassBlur(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List<Widget>.generate(items.length, (int i) {
            final GlassNavItem item = items[i];
            final bool active = i == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: GlassBlur(
                  active: active,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  borderRadius: BorderRadius.circular(12),
                  fillColor: active
                      ? GlassTokens.activeFill
                      : Colors.transparent,
                  borderColor:
                      active ? GlassTokens.activeBorder : Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 22,
                        color: active
                            ? GlassTokens.textPrimary
                            : GlassTokens.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                          color: active
                              ? GlassTokens.textPrimary
                              : GlassTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
