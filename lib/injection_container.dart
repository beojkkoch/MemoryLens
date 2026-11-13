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
import 'package:memorylens/features/gallery_access/data/repository/gallery_permission_repository_impl.dart';
import 'package:memorylens/features/gallery_access/data/source/gallery_permission_data_source.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/memories/data/repository/photo_repository_impl.dart';
import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
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
  sl.registerLazySingleton(() => GalleryPermissionDataSource());
  sl.registerLazySingleton(() => SupabasePhotoDataSource());

  //Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  sl.registerLazySingleton<InterestRepository>(() => InterestRepositoryImpl());
  sl.registerLazySingleton<ErrorLogRepository>(() => ErrorLogRepositoryImpl());
  sl.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(),
  );
  sl.registerLazySingleton<GalleryPermissionRepository>(
    () => GalleryPermissionRepositoryImpl(),
  );
  sl.registerLazySingleton<PhotoRepository>(() => PhotoRepositoryImpl());

  //Use cases
  sl.registerLazySingleton(() => GetInterestsUseCase());
  sl.registerLazySingleton(() => SignUpUseCase());
  sl.registerLazySingleton(() => SignInUsecase());
  sl.registerLazySingleton(() => SignOutUsecase());
  sl.registerLazySingleton(() => GetProfileUseCase());
  sl.registerLazySingleton(() => ReportErrorUseCase());
  sl.registerLazySingleton(() => WatchConnectivityUseCase());
  sl.registerLazySingleton(() => RequestGalleryAccessUseCase());
  sl.registerLazySingleton(() => CheckGalleryAccessUseCase());
  sl.registerLazySingleton(() => OpenGallerySettingsUseCase());
  sl.registerLazySingleton(() => CountPhotosUseCase());

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
  sl.registerFactory(() => MemoriesBloc());
}
