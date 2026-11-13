import 'package:get_it/get_it.dart';
import 'package:memorylens/features/auth/data/repository/auth_repository_impl.dart';
import 'package:memorylens/features/auth/data/repository/interest_repository_impl.dart';
import 'package:memorylens/features/auth/data/repository/profile_repository_impl.dart';
import 'package:memorylens/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:memorylens/features/auth/data/source/supabase_interest_data_source.dart';
import 'package:memorylens/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:memorylens/features/connectivity/data/repository/connectivity_repository_impl.dart';
import 'package:memorylens/features/connectivity/data/source/connectivity_data_source.dart';
import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_bloc.dart';
import 'package:memorylens/features/error_handling/data/repository/error_log_repository_impl.dart';
import 'package:memorylens/features/error_handling/data/source/supabase_error_log_data_source.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/observers/error_bloc_observer.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_bloc.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:memorylens/features/login/ui/bloc/login_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  //Data sources
  sl.registerLazySingleton(() => SupabaseAuthDataSource());
  sl.registerLazySingleton(() => SupabaseProfileDataSource());
  sl.registerLazySingleton(() => SupabaseInterestDataSource());
  sl.registerLazySingleton(() => SupabaseErrorLogDataSource());
  sl.registerLazySingleton(() => ConnectivityDataSource());

  //Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  sl.registerLazySingleton<InterestRepository>(() => InterestRepositoryImpl());
  sl.registerLazySingleton<ErrorLogRepository>(() => ErrorLogRepositoryImpl());
  sl.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(),
  );

  //Use cases
  sl.registerLazySingleton(() => GetInterestsUseCase());
  sl.registerLazySingleton(() => SignUpUseCase());
  sl.registerLazySingleton(() => SignInUsecase());
  sl.registerLazySingleton(() => SignOutUsecase());
  sl.registerLazySingleton(() => GetProfileUseCase());
  sl.registerLazySingleton(() => ReportErrorUseCase());
  sl.registerLazySingleton(() => WatchConnectivityUseCase());

  //Observers
  sl.registerLazySingleton(() => ScreenTracker());
  sl.registerLazySingleton(
    () => ErrorBlocObserver(tracker: sl(), report: sl()),
  );

  //Blocs
  sl.registerFactory(() => RegisterBloc());
  sl.registerFactory(() => LoginBloc());
  sl.registerFactory(() => ProfileBloc());
  sl.registerFactory(() => ConnectivityBloc());
}
