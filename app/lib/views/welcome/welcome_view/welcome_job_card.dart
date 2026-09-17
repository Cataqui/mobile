part of 'welcome_view.dart';

class _WelcomeJobCard extends StatelessWidget {
  const _WelcomeJobCard({required this.job, super.key});

  static const width = 334.0;

  final _WelcomeJob job;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              key: const ValueKey('welcome_card_surface'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MateoTheme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: switch (Theme.of(context).brightness) {
                        Brightness.light => MateoTheme.of(context).palette.neutral[12].withValues(alpha: 0.07),
                        Brightness.dark => throw UnsupportedError('Job cards do not support dark mode.'),
                      },
                      blurRadius: 42,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.postedTime,
                  key: const ValueKey('welcome_job_posted_time'),
                  style: TextStyle(
                    color: MateoTheme.of(context).colorScheme.text.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.title,
                  key: const ValueKey('welcome_job_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MateoTheme.of(context).colorScheme.text.primary,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.amount,
                  key: const ValueKey('welcome_job_amount'),
                  style: TextStyle(
                    color: MateoTheme.of(context).colorScheme.text.profit,
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.description,
                  key: const ValueKey('welcome_job_description'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MateoTheme.of(context).colorScheme.text.secondary,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
