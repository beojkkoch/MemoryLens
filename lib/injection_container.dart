import 'package:get_it/get_it.dart';
import 'package:memorylens/features/photo_detail/data/repository/photo_detail_repository_impl.dart';
import 'package:memorylens/features/photo_detail/data/source/supabase_photo_detail_data_source.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_categories_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_photo_detail_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/save_photo_edit_usecase.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_bloc.dart';
import 'package:memorylens/features/chat/data/repository/chat_repository_impl.dart';
import 'package:memorylens/features/chat/data/repository/photo_search_repository_impl.dart';
import 'package:memorylens/features/chat/data/source/supabase_chat_data_source.dart';
import 'package:memorylens/features/chat/data/source/supabase_photo_search_data_source.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/features/chat/domain/repository/photo_search_repository.dart';
import 'package:memorylens/features/chat/domain/usecases/answer_question_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/delete_conversation_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/save_chat_message_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/start_conversation_usecase.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_bloc.dart';
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
import 'package:memorylens/features/gallery_import/data/repository/device_gallery_repository_impl.dart';
import 'package:memorylens/features/gallery_import/data/repository/import_scan_repository_impl.dart';
import 'package:memorylens/features/gallery_import/data/repository/photo_import_repository_impl.dart';
import 'package:memorylens/features/gallery_import/data/source/device_gallery_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_import_scan_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_imported_photo_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_photo_storage_data_source.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/count_new_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/has_pending_import_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_new_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_bloc.dart';
import 'package:memorylens/features/memories/data/repository/photo_repository_impl.dart';
import 'package:memorylens/features/photo_analysis/data/repository/photo_analysis_repository_impl.dart';
import 'package:memorylens/features/photo_analysis/data/source/supabase_photo_analysis_data_source.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/has_pending_analysis_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/retry_failed_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_bloc.dart';
import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_analyzed_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/get_memories_usecase.dart';
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
  sl.registerLazySingleton(() => DeviceGalleryDataSource());
  sl.registerLazySingleton(() => SupabasePhotoStorageDataSource());
  sl.registerLazySingleton(() => SupabaseImportedPhotoDataSource());
  sl.registerLazySingleton(() => SupabaseImportScanDataSource());
  sl.registerLazySingleton(() => SupabasePhotoAnalysisDataSource());
  sl.registerLazySingleton(() => SupabasePhotoDetailDataSource());
  sl.registerLazySingleton(() => SupabaseChatDataSource());
  sl.registerLazySingleton(() => SupabasePhotoSearchDataSource());

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
  sl.registerLazySingleton<DeviceGalleryRepository>(
    () => DeviceGalleryRepositoryImpl(),
  );
  sl.registerLazySingleton<PhotoImportRepository>(
    () => PhotoImportRepositoryImpl(),
  );
  sl.registerLazySingleton<ImportScanRepository>(
    () => ImportScanRepositoryImpl(),
  );
  sl.registerLazySingleton<PhotoAnalysisRepository>(
    () => PhotoAnalysisRepositoryImpl(),
  );
  sl.registerLazySingleton<PhotoDetailRepository>(
    () => PhotoDetailRepositoryImpl(),
  );
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  sl.registerLazySingleton<PhotoSearchRepository>(
    () => PhotoSearchRepositoryImpl(),
  );

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
  sl.registerLazySingleton(() => GetMemoriesUseCase());
  sl.registerLazySingleton(() => CountAnalyzedPhotosUseCase());
  sl.registerLazySingleton(() => ImportGalleryPhotosUseCase());
  sl.registerLazySingleton(() => HasPendingImportUseCase());
  sl.registerLazySingleton(() => AnalyzePendingPhotosUseCase());
  sl.registerLazySingleton(() => HasPendingAnalysisUseCase());
  sl.registerLazySingleton(() => RetryFailedPhotosUseCase());
  sl.registerLazySingleton(() => CountNewPhotosUseCase());
  sl.registerLazySingleton(() => ImportNewPhotosUseCase());
  sl.registerLazySingleton(() => GetPhotoDetailUseCase());
  sl.registerLazySingleton(() => GetCategoriesUseCase());
  sl.registerLazySingleton(() => SavePhotoEditUseCase());
  sl.registerLazySingleton(() => GetConversationsUseCase());
  sl.registerLazySingleton(() => GetChatMessagesUseCase());
  sl.registerLazySingleton(() => StartConversationUseCase());
  sl.registerLazySingleton(() => SaveChatMessageUseCase());
  sl.registerLazySingleton(() => AnswerQuestionUseCase());
  sl.registerLazySingleton(() => DeleteConversationUseCase());

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
  sl.registerFactory(() => GalleryImportBloc());
  sl.registerFactory(() => PhotoAnalysisBloc());
  sl.registerFactory(() => PhotoDetailBloc());
  sl.registerFactory(() => ChatBloc());
}
