import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
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
  late String _selectedSvgName;
  Color _selectedColor = CategoryColors.coolGrey;

  // Available SVG icons based on category type - exact list as specified
  late final List<String> _availableSvgNames;

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
  void initState() {
    super.initState();
    _selectedSvgName = widget.isIncome ? 'salary' : 'shopping';

    // Exact list of categories as specified
    _availableSvgNames =
        widget.isIncome
            ? [
              'salary',
              'scholarship',
              'insurance',
              'family',
              'stock',
              'commission',
              'allowance',
            ]
            : [
              'bills',
              'debt',
              'dining',
              'donate',
              'edu',
              'education',
              'electricity',
              'entertainment',
              'gifts',
              'groceries',
              'group',
              'healthcare',
              'housing',
              'insurance',
              'investment',
              'job',
              'loans',
              'pets',
              'rent',
              'saving',
              'settlement',
              'shopping',
              'tax',
              'technology',
              'transport',
              'travel',
            ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Use the SVG name as the icon identifier
    final iconString = _selectedSvgName;

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
                  prefixIcon: Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CategoryUtils.getCategoryColor(
                          _selectedSvgName,
                        ).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset(
                        CategoryIcons.getIconPath(_selectedSvgName),
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
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
                  itemCount: _availableSvgNames.length,
                  itemBuilder: (context, index) {
                    final svgName = _availableSvgNames[index];
                    final isSelected = _selectedSvgName == svgName;
                    final iconPath = CategoryIcons.getIconPath(svgName);

                    // Get a default color for this icon type
                    final Color iconColor = CategoryUtils.getCategoryColor(
                      svgName,
                    );
                    final Color backgroundColor =
                        isSelected
                            ? _selectedColor.withOpacity(0.3)
                            : iconColor.withOpacity(0.2);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedSvgName = svgName),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(iconPath),
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
