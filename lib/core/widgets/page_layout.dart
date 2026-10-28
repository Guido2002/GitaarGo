import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  final String eyebrow, title;
  final List<Widget> children;
  const PageLayout({
    required this.eyebrow,
    required this.title,
    required this.children,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    ),
  );
}

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({required this.child, super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}
