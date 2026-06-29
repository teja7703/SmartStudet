import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../injection.dart';
import '../../progress/repositories/progress_repository.dart';
import '../models/story_model.dart';
import '../cubit/story_cubit.dart';
import '../cubit/story_state.dart';

class StoryDetailScreen extends StatefulWidget {
  final String storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<StoryCubit>().loadStoryDetail(widget.storyId);
    _scrollController.addListener(_onScroll);
  }

  bool _visitRecorded = false;

  void _recordVisit(StoryModel story) {
    if (_visitRecorded) return;
    _visitRecorded = true;
    getIt<ProgressRepository>().recordActivity(
      type: 'story',
      id: story.id,
      title: story.title,
      subtitle: story.name,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    context.read<StoryCubit>().updateReadProgress(widget.storyId, progress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryCubit, StoryState>(
      builder: (context, state) {
        if (state is StoryDetailLoading ||
            state is StoryInitial ||
            state is StoryLoading) {
          return Scaffold(appBar: AppBar(), body: const LoadingWidget());
        }
        if (state is StoryDetailError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<StoryCubit>().loadStoryDetail(widget.storyId),
            ),
          );
        }
        if (state is StoryDetailLoaded) {
          _recordVisit(state.story);
          return _Detail(
            story: state.story,
            isBookmarked: state.isBookmarked,
            readProgress: state.readProgress,
            scrollController: _scrollController,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Detail extends StatelessWidget {
  final StoryModel story;
  final bool isBookmarked;
  final double readProgress;
  final ScrollController scrollController;

  const _Detail({
    required this.story,
    required this.isBookmarked,
    required this.readProgress,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          LinearProgressIndicator(
            value: readProgress,
            backgroundColor: AppColors.divider,
            color: AppColors.secondaryGreen,
            minHeight: 3,
          ),
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 240,
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.accentRed,
                  actions: [
                    IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          context.read<StoryCubit>().toggleBookmark(story.id),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetworkImageBox(
                          url: story.imageUrl,
                          alignment: Alignment.topCenter,
                          color: AppColors.accentRed,
                          fallbackIcon: Icons.auto_stories_rounded,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            story.category,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accentRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(story.title, style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.accentPurple
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: AppColors.accentPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.name.isNotEmpty
                                        ? story.name
                                        : 'Smart Student',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  Text(
                                    '${story.readTime} min read',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (story.quote.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _QuoteCard(quote: story.quote),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          story.summary,
                          style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
                        ),
                        if (story.successLesson.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _LessonCard(lesson: story.successLesson),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.secondaryGreen,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Lesson',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
