import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:memorylens/features/login/ui/screens/login_screen.dart';
import 'package:memorylens/features/profile/ui/screens/profile_screen.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/screens/register_screen.dart';
import 'package:memorylens/features/welcome/ui/screens/welcome_screen.dart';
import 'package:memorylens/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vhavapudcqyvwycqizun.supabase.co',
    publishableKey: 'sb_publishable_1frmhC5wlr2CPs3tWJhuXA_6Bruj-FY',
  );
  initDependencies();
  runApp(const App());
}

/// Root widget that declares the theme and the named routes.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Lens',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => BlocProvider(
          create: (_) => sl<RegisterBloc>(),
          child: const RegisterScreen(),
        ),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
