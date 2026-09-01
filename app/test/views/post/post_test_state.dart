import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';

class PostTestState extends PostState {
  PostTestState({required this.initialData});

  final PostData initialData;

  @override
  PostData build() => initialData;
}
