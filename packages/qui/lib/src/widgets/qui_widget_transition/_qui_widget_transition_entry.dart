part of 'qui_widget_transition.dart';

class _QuiWidgetTransitionEntry {
  _QuiWidgetTransitionEntry(this.widget, this.key) : globalKey = GlobalKey(debugLabel: 'qui_wt_entry');

  Widget widget;
  final _QuiWidgetTransitionKey key;
  final GlobalKey globalKey;
}
