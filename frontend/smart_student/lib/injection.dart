import 'package:get_it/get_it.dart';
import 'core/network/api_client.dart';
import 'core/services/storage_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/careers/cubit/career_cubit.dart';
import 'features/careers/repositories/career_repository.dart';
import 'features/home/cubit/dashboard_cubit.dart';
import 'features/home/repositories/dashboard_repository.dart';
import 'features/previous_papers/cubit/previous_paper_cubit.dart';
import 'features/previous_papers/repositories/previous_paper_repository.dart';
import 'features/progress/cubit/progress_cubit.dart';
import 'features/progress/repositories/progress_repository.dart';
import 'features/quizzes/cubit/quiz_cubit.dart';
import 'features/quizzes/cubit/quiz_play_cubit.dart';
import 'features/quizzes/cubit/quiz_subjects_cubit.dart';
import 'features/quizzes/models/quiz_model.dart';
import 'features/quizzes/repositories/quiz_repository.dart';
import 'features/smart_gpt/cubit/smart_gpt_cubit.dart';
import 'features/smart_gpt/repositories/smart_gpt_repository.dart';
import 'features/stories/cubit/story_cubit.dart';
import 'features/stories/repositories/story_repository.dart';
import 'features/study_materials/cubit/study_material_cubit.dart';
import 'features/study_materials/repositories/study_material_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<StudyMaterialRepository>(
    () => StudyMaterialRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PreviousPaperRepository>(
    () => PreviousPaperRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<CareerRepository>(
    () => CareerRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<StoryRepository>(
    () => StoryRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<QuizRepository>(
    () => QuizRepository(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<SmartGptRepository>(
    () => SmartGptRepository(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );

  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(getIt<DashboardRepository>()),
  );
  getIt.registerFactory<CareerCubit>(
    () => CareerCubit(getIt<CareerRepository>()),
  );
  getIt.registerFactory<StoryCubit>(
    () => StoryCubit(getIt<StoryRepository>(), getIt<StorageService>()),
  );
  getIt.registerFactory<QuizCubit>(() => QuizCubit(getIt<QuizRepository>()));
  getIt.registerFactory<SmartGptCubit>(
    () => SmartGptCubit(getIt<SmartGptRepository>()),
  );
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepository(
      apiClient: getIt<ApiClient>(),
      storage: getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<ProgressCubit>(
    () => ProgressCubit(getIt<ProgressRepository>()),
  );
}

StudyMaterialCubit createStudyMaterialCubit({
  required String academicLevel,
  required String subject,
  String language = 'English',
}) {
  return StudyMaterialCubit(
    repository: getIt<StudyMaterialRepository>(),
    academicLevel: academicLevel,
    subject: subject,
    language: language,
  );
}

CareerCubit createCareerCubit() {
  return CareerCubit(getIt<CareerRepository>());
}

StoryCubit createStoryCubit() {
  return StoryCubit(getIt<StoryRepository>(), getIt<StorageService>());
}

SmartGptCubit createSmartGptCubit() {
  return SmartGptCubit(getIt<SmartGptRepository>());
}

QuizPlayCubit createQuizPlayCubit(QuizModel quiz) {
  return QuizPlayCubit(quiz: quiz, repository: getIt<QuizRepository>());
}

QuizSubjectsCubit createQuizSubjectsCubit({required String classLevel}) {
  return QuizSubjectsCubit(
    repository: getIt<QuizRepository>(),
    classLevel: classLevel,
  );
}

PreviousPaperCubit createPreviousPaperCubit({
  required String academicLevel,
  required String subject,
}) {
  return PreviousPaperCubit(
    repository: getIt<PreviousPaperRepository>(),
    academicLevel: academicLevel,
    subject: subject,
  );
}
