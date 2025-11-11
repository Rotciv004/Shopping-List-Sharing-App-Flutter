import 'package:flutter/material.dart';
import '../../models/family.dart';
import '../family/family_details_screen.dart';

class OptimizedFamiliesList extends StatelessWidget {
  final List<Family> families;
  final VoidCallback onAdd;

  const OptimizedFamiliesList({
    super.key,
    required this.families,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (families.isEmpty) {
      return const Center(child: Text('No families yet'));
    }

    return ListView.builder(
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return FamilyListItem(
          key: ValueKey(family.id),
          family: family,
        );
      },
    );
  }
}

class FamilyListItem extends StatelessWidget {
  final Family family;

  const FamilyListItem({
    super.key,
    required this.family,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(family.name),
        subtitle: Text('${family.numberOfMembers} members • ${family.numberOfOrders} orders'),
        leading: const Icon(Icons.group_outlined),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyDetailsScreen(familyId: family.id),
          ),
        ),
      ),
    );
  }
}