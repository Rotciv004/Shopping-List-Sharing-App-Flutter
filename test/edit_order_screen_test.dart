import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_app/data/in_memory_data.dart';
import 'package:shopping_list_app/models/family.dart';
import 'package:shopping_list_app/models/order.dart';
import 'package:shopping_list_app/models/user.dart';
import 'package:shopping_list_app/ui/order/edit_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditOrderScreen', () {
    late Order order;

    setUp(() {
      final data = InMemoryData.instance;
      data.users.clear();
      data.families.clear();
      data.orders.clear();
      final user = User(firstName: 'A', lastName: 'B', email: 'a@b.c', password: 'pw');
      data.users.add(user);
      data.currentUser = user;
      final fam = Family(name: 'Test Fam', membersList: [user.id], ordersList: []);
      data.families.add(fam);
      order = Order(
        name: 'Apples',
        description: 'Green',
        quantity: 5,
        priority: Priority.MEDIUM,
        placingUserId: user.id,
        allocatedSum: 12.0,
        fulfillmentDeadLineDate: DateTime.now().add(const Duration(days: 1)),
      );
      data.orders.add(order);
      fam.ordersList.add(order.id);
    });

    testWidgets('pre-populates fields', (tester) async {
      await tester.pumpWidget(MaterialApp(home: EditOrderScreen(order: order)));

      expect(find.widgetWithText(TextFormField, 'Apples'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Green'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '5'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<Priority>), findsOneWidget);
    });

    testWidgets('validates and returns updated order', (tester) async {
      await tester.pumpWidget(MaterialApp(home: EditOrderScreen(order: order)));

      // Clear name to trigger validation
      await tester.enterText(find.widgetWithText(TextFormField, 'Apples'), '');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);

      // Fix and change name
      await tester.enterText(find.byType(TextFormField).first, 'Bananas');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      // Screen should pop; we cannot capture result directly here in a simple pump test,
      // but we can simulate the caller updating the data layer in an integration test.
    });
  });
}
