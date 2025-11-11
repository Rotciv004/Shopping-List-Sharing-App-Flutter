import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_app/data/in_memory_data.dart';
import 'package:shopping_list_app/models/family.dart';
import 'package:shopping_list_app/models/order.dart';
import 'package:shopping_list_app/models/user.dart';
import 'package:shopping_list_app/ui/family/family_details_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Delete order confirmation', () {
    late User user;
    late Family fam;
    late Order order;
    final data = InMemoryData.instance;

    setUp(() {
      data.users.clear();
      data.families.clear();
      data.orders.clear();
      data.notifications.clear();
      user = User(firstName: 'A', lastName: 'B', email: 'a@b.c', password: 'pw');
      data.users.add(user);
      data.currentUser = user;
      fam = Family(name: 'Test Fam', membersList: [user.id], ordersList: []);
      data.families.add(fam);
      order = Order(
        name: 'Test Item',
        description: 'Desc',
        quantity: 1,
        priority: Priority.LOW,
        placingUserId: user.id,
        fulfillmentDeadLineDate: DateTime.now().add(const Duration(days: 1)),
      );
      data.orders.add(order);
      fam.ordersList.add(order.id);
      fam.numberOfOrders = 1;
    });

    testWidgets('shows confirmation and deletes on confirm', (tester) async {
      await tester.pumpWidget(_wrap(FamilyDetailsScreen(familyId: fam.id)));
      await tester.pumpAndSettle();

      // Tap delete icon
      final deleteIconFinder = find.byIcon(Icons.delete_outline).first;
      expect(deleteIconFinder, findsOneWidget);
      await tester.tap(deleteIconFinder);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete order'), findsOneWidget);
      expect(find.text("Are you sure you want to delete 'Test Item'?") , findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(data.orders.any((o) => o.id == order.id), isFalse);
    });

    testWidgets('cancel does not delete', (tester) async {
      await tester.pumpWidget(_wrap(FamilyDetailsScreen(familyId: fam.id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('Delete order'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(data.orders.any((o) => o.id == order.id), isTrue);
    });
  });
}
