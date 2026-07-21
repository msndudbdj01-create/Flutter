import 'package:flutter/material.dart';
import '../models/subtitle_entry.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SubtitleSelector {
  static void show({
    required BuildContext context,
    required List<SubtitleSource> subUrls,
    required bool isLoadingSubdl,
    required bool hasActiveSubtitles,
    required int activeSubtitlesCount,
    required VoidCallback onRefreshSubdl,
    required void Function(String url) onSubtitleSelected,
    required VoidCallback onRemoveSubtitles,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: const Color(AppColors.primary).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primary)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.subtitles,
                              color: const Color(AppColors.primary),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('select_subtitle'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                if (hasActiveSubtitles)
                                  Text(
                                    "${context.tr('subtitles_active')} • $activeSubtitlesCount ${context.tr('lines')}",
                                    style: TextStyle(
                                      color: const Color(AppColors.primary),
                                      fontSize: 11,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (isLoadingSubdl)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(AppColors.primary),
                                    strokeWidth: 2,
                                  ),
                                ),
                              if (!isLoadingSubdl)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: onRefreshSubdl,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.refresh,
                                            color:
                                                const Color(AppColors.primary),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            context.tr('refresh'),
                                            style: TextStyle(
                                              color: const Color(
                                                  AppColors.primary),
                                              fontSize: 12,
                                              fontFamily: 'Tajawal',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              if (hasActiveSubtitles)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: onRemoveSubtitles,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.close,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            context.tr('remove_subtitle'),
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12,
                                              fontFamily: 'Tajawal',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Colors.white12, height: 1, thickness: 1),
                    Expanded(
                      child: subUrls.isEmpty
                          ? _buildEmptyState(
                              isLoadingSubdl, onRefreshSubdl, context)
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: subUrls.length,
                              itemBuilder: (context, index) {
                                final sub = subUrls[index];
                                final isLast = index == subUrls.length - 1;
                                return RepaintBoundary(
                                  child: _SubtitleTile(
                                    sub: sub,
                                    isLast: isLast,
                                    onTap: () {
                                      onSubtitleSelected(sub.url);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        context.tr('subtitles_info'),
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildEmptyState(
      bool isLoading, VoidCallback onRefresh, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoading ? Icons.search : Icons.subtitles_off,
              color:
                  isLoading ? const Color(AppColors.primary) : Colors.white38,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isLoading
                ? context.tr('searching_subtitles')
                : context.tr('no_subtitles_available'),
            style: TextStyle(
              color:
                  isLoading ? const Color(AppColors.primary) : Colors.white54,
              fontSize: 15,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (!isLoading)
            Text(
              context.tr('check_connection_or_refresh'),
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontFamily: 'Tajawal',
              ),
            ),
          const SizedBox(height: 24),
          if (!isLoading)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(AppColors.primary).withOpacity(0.2),
                        const Color(AppColors.primary).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(AppColors.primary).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: const Color(AppColors.primary),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('try_again'),
                        style: TextStyle(
                          color: const Color(AppColors.primary),
                          fontSize: 13,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubtitleTile extends StatelessWidget {
  final SubtitleSource sub;
  final bool isLast;
  final VoidCallback onTap;

  const _SubtitleTile({
    Key? key,
    required this.sub,
    required this.isLast,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFromSubdl = sub.name.contains('[Subdl]');
    final bool isHighQuality = sub.name.contains('⭐');
    final bool isSeasonPack = sub.name.contains('📦');

    Color? tileColor;
    if (isHighQuality) {
      tileColor = const Color(AppColors.primary).withOpacity(0.08);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: isLast ? 0 : 4,
          ),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFromSubdl
                      ? const Color(AppColors.primary).withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSeasonPack ? Icons.folder_zip : Icons.subtitles,
                  color: isFromSubdl
                      ? const Color(AppColors.primary)
                      : Colors.white54,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatSubtitleName(sub.name),
                      style: TextStyle(
                        color: isHighQuality ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                        fontWeight:
                            isHighQuality ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isFromSubdl)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primary)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Subdl",
                              style: TextStyle(
                                color: const Color(AppColors.primary),
                                fontSize: 9,
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (isFromSubdl && sub.lang != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sub.lang!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                        if (isSeasonPack) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.tr('full_season'),
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 9,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isFromSubdl
                    ? const Color(AppColors.primary).withOpacity(0.7)
                    : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSubtitleName(String name) {
    return name.replaceAll(RegExp(r'^\[Subdl\]\s*'), '');
  }
}
