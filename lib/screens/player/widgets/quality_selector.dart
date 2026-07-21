import 'package:flutter/material.dart';
import '../models/subtitle_entry.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class QualitySelector {
  static void show({
    required BuildContext context,
    required List<VideoQuality> qualities,
    required String? selectedQuality,
    required void Function(String url, String quality) onQualitySelected,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('select_quality'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const Divider(color: Colors.white24),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: qualities.length,
                    itemBuilder: (context, i) {
                      final q = qualities[i];
                      final isSelected = selectedQuality == q.quality;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.hd,
                          color: isSelected
                              ? const Color(AppColors.primary)
                              : Colors.white54,
                          size: 20,
                        ),
                        title: Text(
                          q.quality,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: const Color(AppColors.primary),
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          onQualitySelected(q.url, q.quality);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
