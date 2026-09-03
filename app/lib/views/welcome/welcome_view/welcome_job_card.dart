part of 'welcome_view.dart';

class _WelcomeJobCard extends StatelessWidget {
  const _WelcomeJobCard({required this.job, super.key});

  static const width = 334.0;

  final _WelcomeJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: context.mateo.colorScheme.background,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: context.mateo.colorScheme.colors.neutral.solid.withValues(alpha: 0.07), blurRadius: 42),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.postedTime,
            key: const ValueKey('welcome_job_posted_time'),
            style: TextStyle(color: context.mateo.colorScheme.text.tertiary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            job.title,
            key: const ValueKey('welcome_job_title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.mateo.colorScheme.text.primary,
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
              color: context.mateo.colorScheme.text.profit,
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
              color: context.mateo.colorScheme.text.secondary,
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
