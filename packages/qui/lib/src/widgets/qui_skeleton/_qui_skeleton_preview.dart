part of 'qui_skeleton.dart';

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Garçom para Fim de Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(r'Pinheiros - R$ 180 - 18h-23h'),
          SizedBox(height: 12),
          Row(children: [Icon(Icons.star, size: 16), SizedBox(width: 4), Text('4.8 (32 avaliações)')]),
        ],
      ),
    );
  }
}
