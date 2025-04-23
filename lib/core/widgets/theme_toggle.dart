import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/theme/cubit/theme_cubit.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDarkMode = state.themeMode == ThemeMode.dark;

        return IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode ? Colors.amber : Colors.blueGrey,
          ),
          tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () {
            context.read<ThemeCubit>().toggleTheme();
          },
        );
      },
    );
  }
}
