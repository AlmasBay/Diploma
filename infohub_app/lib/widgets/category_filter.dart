import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryFilter extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final Function(Category?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
      Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('Все'),
        selected: selectedCategory == null,
        onSelected: (_) => onCategorySelected(null),
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: selectedCategory == null ? Colors.white : Colors.black87,
        ),
      ),
    ),
    ...categories.map((category) {
    final isSelected = selectedCategory?.id == category.id;
    return Padding
      (
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category.name),
        selected: isSelected,
        onSelected: (_) => onCategorySelected(category),
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
    }).toList(),
          ],
      ),
    );
  }
}