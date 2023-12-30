import 'package:auto_route/auto_route.dart';
import 'package:what_to_click/src/pages/click_track/widget.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: ClickTrackRoute.page,
          initial: true,
        ),
      ];
}
