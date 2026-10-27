import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/login/ui/screens/login_screen.dart';
import 'package:memorylens/features/profile/ui/screens/profile_screen.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/screens/register_screen.dart';
import 'package:memorylens/features/welcome/ui/screens/welcome_screen.dart';
import 'package:memorylens/injection_container.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Records the sign up call instead of talking to Supabase Auth.
class FakeAuthRepository implements AuthRepository {
  String? email;
  String? password;
  Exception? error;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    this.email = email;
    this.password = password;
    return AppUser(id: 'user-1', email: email);
  }

  @override
  AppUser? currentUser() => null;
}

/// Keeps the saved profile and interests in memory.
class FakeProfileRepository implements ProfileRepository {
  Profile? profile;
  List<int>? interestIds;

  @override
  Future<void> createProfile(Profile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> saveInterests(String userId, List<int> interestIds) async {
    this.interestIds = interestIds;
  }
}

/// Serves part of the seeded catalog and gives new names ids from 100.
class FakeInterestRepository implements InterestRepository {
  List<String>? createdNames;

  @override
  Future<List<Interest>> getInterests() async {
    return const [
      Interest(id: 1, name: 'Tecnología'),
      Interest(id: 2, name: 'Moda'),
      Interest(id: 6, name: 'Viajes'),
    ];
  }

  @override
  Future<List<Interest>> createInterests(List<String> names) async {
    createdNames = names;
    return [
      for (var i = 0; i < names.length; i++)
        Interest(id: 100 + i, name: names[i]),
    ];
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeInterestRepository interests;

  setUp(() async {
    await sl.reset();
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    interests = FakeInterestRepository();
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<ProfileRepository>(profiles);
    sl.registerSingleton<InterestRepository>(interests);
    sl.registerLazySingleton(() => SignUpUseCase());
    sl.registerLazySingleton(() => GetInterestsUseCase());
    sl.registerFactory(() => RegisterBloc());
  });

  Future<void> pumpApp(WidgetTester tester, {String route = '/'}) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: route,
        routes: {
          '/': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => BlocProvider(
            create: (_) => sl<RegisterBloc>(),
            child: const RegisterScreen(),
          ),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Color barColor(WidgetTester tester, int index) {
    final bar = tester.widget<AnimatedContainer>(
      find.byKey(Key('step-bar-$index')),
    );
    return (bar.decoration! as BoxDecoration).color!;
  }

  Future<void> fillAccount(
    WidgetTester tester, {
    String confirmPassword = 'secreto123',
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Gómez');
    await tester.enterText(fields.at(1), 'ana@memorylens.ai');
    await tester.enterText(fields.at(2), 'secreto123');
    await tester.enterText(fields.at(3), confirmPassword);
    await tester.enterText(fields.at(4), 'Bogotá');
  }

  Future<void> goToCharacterization(WidgetTester tester) async {
    await pumpApp(tester, route: '/register');
    await fillAccount(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Diseñadora');
  }

  testWidgets('welcome opens the login screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continuar con correo electrónico'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('welcome opens the register screen on step one', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(barColor(tester, 0), AppColors.primary);
    expect(barColor(tester, 1), AppColors.border);
  });

  testWidgets('step one does not continue with empty fields', (tester) async {
    await pumpApp(tester, route: '/register');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa todos los campos'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(find.text('CARACTERIZACIÓN'), findsNothing);
  });

  testWidgets('step one does not continue with mismatched passwords', (
    tester,
  ) async {
    await pumpApp(tester, route: '/register');
    await fillAccount(tester, confirmPassword: 'otra-clave');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(find.text('CARACTERIZACIÓN'), findsNothing);
  });

  testWidgets('eye button shows and hides the password', (tester) async {
    await pumpApp(tester, route: '/register');
    bool passwordHidden() =>
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText;
    expect(passwordHidden(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();
    expect(passwordHidden(), isFalse);
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(passwordHidden(), isTrue);
  });

  testWidgets('complete step one opens step two and fills both bars', (
    tester,
  ) async {
    await goToCharacterization(tester);
    expect(find.text('CARACTERIZACIÓN'), findsOneWidget);
    expect(find.text('Paso 2 de 2'), findsOneWidget);
    expect(barColor(tester, 1), AppColors.primary);
    expect(find.text('Viajes'), findsOneWidget);
  });

  testWidgets('back arrow on step two returns to step one with the data', (
    tester,
  ) async {
    await goToCharacterization(tester);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(find.text('ana@memorylens.ai'), findsOneWidget);
  });

  testWidgets('step two without interests shows an error', (tester) async {
    await goToCharacterization(tester);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un interés'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('typing an existing interest selects it instead of duplicating', (
    tester,
  ) async {
    await goToCharacterization(tester);
    await tester.enterText(find.byType(TextField).at(1), '  viajes ');
    await tester.tap(find.byTooltip('Agregar interés'));
    await tester.pumpAndSettle();
    expect(find.text('Viajes'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(profiles.interestIds, [6]);
    expect(interests.createdNames, isNull);
  });

  testWidgets('valid form signs up with a new interest and opens profile', (
    tester,
  ) async {
    await goToCharacterization(tester);
    await tester.tap(find.text('Tecnología'));
    await tester.enterText(find.byType(TextField).at(1), 'fotografía');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Fotografía'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(auth.email, 'ana@memorylens.ai');
    expect(auth.password, 'secreto123');
    expect(profiles.profile?.fullName, 'Ana Gómez');
    expect(profiles.profile?.city, 'Bogotá');
    expect(profiles.profile?.profession, 'Diseñadora');
    expect(interests.createdNames, ['Fotografía']);
    expect(profiles.interestIds, unorderedEquals([1, 100]));
    expect(find.text('Mi perfil'), findsOneWidget);
  });

  testWidgets('sign up failure shows the message from the backend', (
    tester,
  ) async {
    auth.error = Exception('Ya existe una cuenta con ese correo');
    await goToCharacterization(tester);
    await tester.tap(find.text('Moda'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
  });
}
