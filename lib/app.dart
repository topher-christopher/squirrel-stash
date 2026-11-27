import 'package:material_ui/material_ui.dart';

import 'theme/app_theme.dart';
import 'ui/home_study_screen.dart';

class SquirrelStashApp extends StatelessWidget {
  const SquirrelStashApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SquirrelStash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const HomeStudyScreen(),
      );
}
