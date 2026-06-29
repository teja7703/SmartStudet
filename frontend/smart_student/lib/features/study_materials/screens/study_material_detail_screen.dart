import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../injection.dart';
import '../../progress/repositories/progress_repository.dart';
import '../models/study_material_model.dart';
import '../services/study_material_pdf.dart';
import '../widgets/study_content_view.dart';

class StudyMaterialDetailScreen extends StatefulWidget {
  final StudyMaterialModel material;

  const StudyMaterialDetailScreen({super.key, required this.material});

  @override
  State<StudyMaterialDetailScreen> createState() =>
      _StudyMaterialDetailScreenState();
}

class _StudyMaterialDetailScreenState extends State<StudyMaterialDetailScreen> {
  bool _generatingPdf = false;

  StudyMaterialModel get material => widget.material;

  @override
  void initState() {
    super.initState();
    final subtitleParts = [
      if (material.subject.isNotEmpty) material.subject,
      if (material.academicLevel.isNotEmpty) material.academicLevel,
    ];
    getIt<ProgressRepository>().recordActivity(
      type: 'material',
      id: material.id,
      title: material.chapter.isNotEmpty ? material.chapter : material.title,
      subtitle: subtitleParts.join(' • '),
    );
  }

  Future<void> _downloadPdf() async {
    if (_generatingPdf) return;
    setState(() => _generatingPdf = true);
    try {
      final path = await StudyMaterialPdf.downloadForMaterial(material);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AcademicConstants.pdfDownloaded(material.language)),
          action: SnackBarAction(
            label: AcademicConstants.openLabel(material.language),
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  String _youtubeUrl() {
    if (material.videoUrl.trim().isNotEmpty) return material.videoUrl.trim();
    final isTelugu = material.language == 'Telugu';
    final parts = <String>[
      if (material.academicLevel.isNotEmpty)
        AcademicConstants.formatLevel(
          material.academicLevel,
          material.language,
        ),
      if (material.subject.isNotEmpty)
        AcademicConstants.formatSubject(material.subject, material.language),
      material.chapter,
      if (isTelugu) 'తెలుగులో',
    ];
    final query = Uri.encodeComponent(parts.join(' '));
    return 'https://www.youtube.com/results?search_query=$query';
  }

  Future<void> _watchOnYoutube() async {
    final uri = Uri.parse(_youtubeUrl());
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open YouTube')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(material.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(material: material),
            const SizedBox(height: 16),
            _ActionButtons(
              language: material.language,
              generatingPdf: _generatingPdf,
              onDownloadPdf: _downloadPdf,
              onWatchYoutube: _watchOnYoutube,
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: StudyContentView(content: material.content),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String language;
  final bool generatingPdf;
  final VoidCallback onDownloadPdf;
  final VoidCallback onWatchYoutube;

  const _ActionButtons({
    required this.language,
    required this.generatingPdf,
    required this.onDownloadPdf,
    required this.onWatchYoutube,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: generatingPdf ? null : onDownloadPdf,
            icon: generatingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              generatingPdf
                  ? AcademicConstants.preparing(language)
                  : AcademicConstants.downloadPdf(language),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWatchYoutube,
            icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
            label: Text(AcademicConstants.watchVideo(language)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final StudyMaterialModel material;

  const _HeaderCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AcademicConstants.chapterLabel(material.language)}: ${material.chapter}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            material.title,
            style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
