part of 'qui_tiktok_feed.dart';

@immutable
class _PreviewOpportunity {
  const _PreviewOpportunity({
    required this.title,
    required this.place,
    required this.pay,
    required this.time,
    required this.color,
  });

  final String title;
  final String place;
  final String pay;
  final String time;
  final Color color;
}

class _PreviewOpportunityCard extends StatelessWidget {
  const _PreviewOpportunityCard({required this.opportunity});

  final _PreviewOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: opportunity.color, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            ),
            const Spacer(),
            Text(
              opportunity.pay,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: opportunity.color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              opportunity.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 18),
                const SizedBox(width: 6),
                Text(opportunity.place),
                const SizedBox(width: 16),
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 6),
                Text(opportunity.time),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
