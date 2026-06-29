import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/careers/screens/career_category_screen.dart';
import 'features/careers/screens/career_detail_screen.dart';
import 'features/careers/screens/careers_screen.dart';
import 'features/games/screens/games_screen.dart';
import 'features/games/screens/guess_number_screen.dart';
import 'features/games/screens/memory_match_screen.dart';
import 'features/games/screens/quick_math_screen.dart';
import 'features/games/screens/riddles_screen.dart';
import 'features/games/screens/tic_tac_toe_screen.dart';
import 'features/games/screens/word_scramble_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/previous_papers/models/previous_paper_model.dart';
import 'features/previous_papers/screens/previous_paper_detail_screen.dart';
import 'features/previous_papers/screens/previous_paper_levels_screen.dart';
import 'features/previous_papers/screens/previous_paper_list_screen.dart';
import 'features/previous_papers/screens/previous_paper_subjects_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/smart_gpt/screens/smart_gpt_screen.dart';
import 'features/spoken_english/screens/spoken_english_screen.dart';
import 'features/quizzes/models/quiz_model.dart';
import 'features/quizzes/models/quiz_result_model.dart';
import 'features/quizzes/screens/quiz_history_screen.dart';
import 'features/quizzes/screens/quiz_language_screen.dart';
import 'features/quizzes/screens/quiz_play_screen.dart';
import 'features/quizzes/screens/quiz_result_screen.dart';
import 'features/quizzes/screens/quiz_review_screen.dart';
import 'features/quizzes/screens/quiz_subjects_screen.dart';
import 'features/quizzes/screens/quizzes_screen.dart';
import 'features/stories/screens/stories_screen.dart';
import 'features/stories/screens/story_detail_screen.dart';
import 'features/study_materials/models/study_material_model.dart';
import 'features/study_materials/screens/language_select_screen.dart';
import 'features/study_materials/screens/study_levels_screen.dart';
import 'features/study_materials/screens/study_material_detail_screen.dart';
import 'features/study_materials/screens/study_material_list_screen.dart';
import 'features/study_materials/screens/subjects_screen.dart';
import 'injection.dart';
import 'shared/screens/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/study-materials',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LanguageSelectScreen(),
            ),
          ),
          GoRoute(
            path: '/quizzes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuizzesScreen(),
            ),
          ),
          GoRoute(
            path: '/careers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CareersScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/study-materials/detail/:id',
        builder: (context, state) {
          final material = state.extra as StudyMaterialModel;
          return StudyMaterialDetailScreen(material: material);
        },
      ),
      GoRoute(
        path: '/study-materials/:lang/levels',
        builder: (context, state) {
          final lang = state.pathParameters['lang']!;
          return StudyLevelsScreen(language: lang);
        },
      ),
      GoRoute(
        path: '/study-materials/:lang/:level/subjects',
        builder: (context, state) {
          final lang = state.pathParameters['lang']!;
          final level = state.pathParameters['level']!;
          return SubjectsScreen(academicLevel: level, language: lang);
        },
      ),
      GoRoute(
        path: '/study-materials/:lang/:level/:subject',
        builder: (context, state) {
          final lang = state.pathParameters['lang']!;
          final level = state.pathParameters['level']!;
          final subject = state.pathParameters['subject']!;
          return BlocProvider(
            create: (_) => createStudyMaterialCubit(
              academicLevel: level,
              subject: subject,
              language: lang,
            ),
            child: StudyMaterialListScreen(
              academicLevel: level,
              subject: subject,
              language: lang,
            ),
          );
        },
      ),
      GoRoute(
        path: '/previous-papers',
        builder: (context, state) => const PreviousPaperLevelsScreen(),
      ),
      GoRoute(
        path: '/previous-papers/:level/subjects',
        builder: (context, state) {
          final level = state.pathParameters['level']!;
          return PreviousPaperSubjectsScreen(academicLevel: level);
        },
      ),
      GoRoute(
        path: '/previous-papers/detail/:id',
        builder: (context, state) {
          final paper = state.extra as PreviousPaperModel;
          return PreviousPaperDetailScreen(paper: paper);
        },
      ),
      GoRoute(
        path: '/previous-papers/:level/:subject',
        builder: (context, state) {
          final level = state.pathParameters['level']!;
          final subject = state.pathParameters['subject']!;
          return BlocProvider(
            create: (_) => createPreviousPaperCubit(
              academicLevel: level,
              subject: subject,
            ),
            child: PreviousPaperListScreen(
              academicLevel: level,
              subject: subject,
            ),
          );
        },
      ),
      GoRoute(
        path: '/careers/category/:category',
        builder: (context, state) {
          final category =
              Uri.decodeComponent(state.pathParameters['category']!);
          return BlocProvider(
            create: (_) => createCareerCubit(),
            child: CareerCategoryScreen(category: category),
          );
        },
      ),
      GoRoute(
        path: '/careers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => createCareerCubit(),
            child: CareerDetailScreen(careerId: id),
          );
        },
      ),
      GoRoute(
        path: '/stories',
        builder: (context, state) => const StoriesScreen(),
      ),
      GoRoute(
        path: '/stories/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => createStoryCubit(),
            child: StoryDetailScreen(storyId: id),
          );
        },
      ),
      GoRoute(
        path: '/quizzes/play',
        builder: (context, state) {
          final quiz = state.extra as QuizModel;
          return BlocProvider(
            create: (_) => createQuizPlayCubit(quiz),
            child: const QuizPlayScreen(),
          );
        },
      ),
      GoRoute(
        path: '/quizzes/result',
        builder: (context, state) {
          final result = state.extra as QuizResultModel;
          return QuizResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/quizzes/review',
        builder: (context, state) {
          final result = state.extra as QuizResultModel;
          return QuizReviewScreen(result: result);
        },
      ),
      GoRoute(
        path: '/quizzes/history',
        builder: (context, state) => const QuizHistoryScreen(),
      ),
      GoRoute(
        path: '/quizzes/:level/language',
        builder: (context, state) {
          final level = state.pathParameters['level']!;
          return QuizLanguageScreen(classLevel: level);
        },
      ),
      GoRoute(
        path: '/quizzes/:lang/:level/subjects',
        builder: (context, state) {
          final lang = state.pathParameters['lang']!;
          final level = state.pathParameters['level']!;
          return BlocProvider(
            create: (_) => createQuizSubjectsCubit(
              classLevel: level,
              language: lang,
            )..load(),
            child: QuizSubjectsScreen(classLevel: level, language: lang),
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/games',
        builder: (context, state) => const GamesScreen(),
      ),
      GoRoute(
        path: '/games/memory',
        builder: (context, state) => const MemoryMatchScreen(),
      ),
      GoRoute(
        path: '/games/quick-math',
        builder: (context, state) => const QuickMathScreen(),
      ),
      GoRoute(
        path: '/games/tic-tac-toe',
        builder: (context, state) => const TicTacToeScreen(),
      ),
      GoRoute(
        path: '/games/word-scramble',
        builder: (context, state) => const WordScrambleScreen(),
      ),
      GoRoute(
        path: '/games/riddles',
        builder: (context, state) => const RiddlesScreen(),
      ),
      GoRoute(
        path: '/games/guess-number',
        builder: (context, state) => const GuessNumberScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/spoken-english',
        builder: (context, state) => const SpokenEnglishScreen(),
      ),
      GoRoute(
        path: '/smart-gpt',
        builder: (context, state) => BlocProvider(
          create: (_) => createSmartGptCubit(),
          child: const SmartGPTScreen(),
        ),
      ),
      GoRoute(
        path: '/coming-soon/:feature',
        builder: (context, state) {
          final feature = state.pathParameters['feature']!
              .split('-')
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');
          return ComingSoonScreen(feature: feature);
        },
      ),
    ],
  );
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
