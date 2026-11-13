import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_bloc.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_event.dart';
import 'package:memorylens/features/connectivity/ui/widgets/connectivity_shell.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/global_error_handlers.dart';
import 'package:memorylens/features/error_handling/ui/observers/error_bloc_observer.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';
import 'package:memorylens/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/login/ui/bloc/login_bloc.dart';
import 'package:memorylens/features/login/ui/screens/login_screen.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/screens/memories_screen.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_bloc.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_event.dart';
import 'package:memorylens/features/profile/ui/screens/profile_screen.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/screens/confirm_email_screen.dart';
import 'package:memorylens/features/register/ui/screens/register_screen.dart';
import 'package:memorylens/features/welcome/ui/screens/welcome_screen.dart';
import 'package:memorylens/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  installGlobalErrorHandlers(
    tracker: sl<ScreenTracker>(),
    report: sl<ReportErrorUseCase>(),
  );
  Bloc.observer = sl<ErrorBlocObserver>();
  try {
    await Supabase.initialize(
      url: 'https://vhavapudcqyvwycqizun.supabase.co',
      publishableKey: 'sb_publishable_1frmhC5wlr2CPs3tWJhuXA_6Bruj-FY',
    );
  } catch (error, stack) {
    // The app still opens: each screen shows its own friendly message when it
    // needs the backend.
    unawaited(
      sl<ReportErrorUseCase>()(
        screen: ScreenTracker.unknownScreen,
        action: 'Supabase.initialize',
        error: error,
        stackTrace: stack,
      ),
    );
  }
  runApp(const App());
}

/// Root widget that declares the theme and the named routes.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConnectivityBloc>()..add(ConnectivityStarted()),
      child: MaterialApp(
        title: 'Memory Lens',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorObservers: [sl<ScreenTracker>()],
        builder: (context, child) => ColoredBox(
          color: AppColors.canvas,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ConnectivityShell(child: child!),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const WelcomeScreen(),
          '/login': (_) => BlocProvider(
            create: (_) => sl<LoginBloc>(),
            child: const LoginScreen(),
          ),
          '/register': (_) => BlocProvider(
            create: (_) => sl<RegisterBloc>(),
            child: const RegisterScreen(),
          ),
          '/confirm-email': (_) => const ConfirmEmailScreen(),
          '/recuerdos': (_) => BlocProvider(
            create: (_) => sl<MemoriesBloc>()..add(MemoriesStarted()),
            child: const MemoriesScreen(),
          ),
          '/analizando': (_) => const AnalyzingScreen(),
          '/profile': (_) => BlocProvider(
            create: (_) => sl<ProfileBloc>()..add(ProfileRequested()),
            child: const ProfileScreen(),
          ),
        },
      ),
    );
  }
}
