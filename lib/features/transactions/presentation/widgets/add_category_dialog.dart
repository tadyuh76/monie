import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_event.dart';

class AddCategoryDialog extends StatefulWidget {
  final bool isIncome;

  const AddCategoryDialog({super.key, this.isIncome = false});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = CategoryColors.coolGrey;

  final List<IconData> _availableIcons = [
    Icons.shopping_basket,
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.movie,
    Icons.medical_services,
    Icons.school,
    Icons.home,
    Icons.work,
    Icons.computer,
    Icons.card_giftcard,
    Icons.trending_up,
    Icons.account_balance,
    Icons.flight,
    Icons.subscriptions,
    Icons.power,
    Icons.pets,
    Icons.fitness_center,
    Icons.more_horiz,
  ];

  final List<Color> _availableColors = [
    CategoryColors.red,
    CategoryColors.orange,
    CategoryColors.gold,
    CategoryColors.green,
    CategoryColors.teal,
    CategoryColors.blue,
    CategoryColors.darkBlue,
    CategoryColors.indigo,
    CategoryColors.plum,
    CategoryColors.purple,
    CategoryColors.coolGrey,
    CategoryColors.warmGrey,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Convert the icon to string representation
    final iconString = _selectedIcon.toString();

    // Convert the color to hex string
    final colorHex = CategoryColors.toHex(_selectedColor);

    // Create the category through the bloc
    context.read<CategoriesBloc>().add(
      CreateCategory(
        name: _nameController.text,
        icon: iconString,
        color: colorHex,
        isIncome: widget.isIncome,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Coffee, Groceries, etc.',
                  prefixIcon: Icon(_selectedIcon, color: _selectedColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Select Icon', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = _selectedIcon == icon;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _selectedColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? _selectedColor : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Text('Select Color', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = _selectedColor == color;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(onPressed: _save, child: Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
