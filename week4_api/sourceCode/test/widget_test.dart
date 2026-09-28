import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/main.dart';

void main() {
  testWidgets('App renders PagedPostPage title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pagedPostsProvider.overrideWith(() => DummyPagedPostsNotifier()),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.text('Posts Paged'), findsOneWidget);
  });
}

class DummyPagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() {
    return const PagedPostsState(items: []);
  }
}
