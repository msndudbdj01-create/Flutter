import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GasraShimmer extends StatelessWidget {
  final Widget child;

  const GasraShimmer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class ShimmerHorizontalList extends StatelessWidget {
  final double height;
  final double cardWidth;

  const ShimmerHorizontalList({
    Key? key,
    this.height = 180,
    this.cardWidth = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 5,
        separatorBuilder: (context, index) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          return GasraShimmer(
            child: Container(
              width: cardWidth.w,
              height: height.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShimmerHeroBanner extends StatelessWidget {
  const ShimmerHeroBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GasraShimmer(
      child: Container(
        width: double.infinity,
        height: 550.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.r),
            bottomRight: Radius.circular(30.r),
          ),
        ),
      ),
    );
  }
}