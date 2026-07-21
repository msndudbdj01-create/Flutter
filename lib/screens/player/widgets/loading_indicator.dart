import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

/// مؤشر التحميل المركزي
class PlayerLoadingIndicator extends StatelessWidget {
  const PlayerLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Color(AppColors.primary)),
      ),
    );
  }
}
