import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_model.dart';
import '../utils/constants.dart';

class MediaCard extends StatelessWidget {
  final Media media;
  final VoidCallback onTap;

  const MediaCard({Key? key, required this.media, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl:
                      AppConstants.tmdbImageBaseUrl + (media.posterPath ?? ''),
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child:
                          const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(media.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(AppColors.textMain),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.star,
                      color: Color(AppColors.ratingStar), size: 10),
                  const SizedBox(width: 3),
                  Text((media.voteAverage ?? 0.0).toStringAsFixed(1),
                      style: const TextStyle(
                          color: Color(AppColors.ratingStar), fontSize: 10))
                ]),
                Text(
                    media.mediaType == 'movie'
                        ? (media.releaseDate?.split('-')[0] ?? '')
                        : (media.firstAirDate?.split('-')[0] ?? ''),
                    style: const TextStyle(
                        color: Color(AppColors.textSecondary), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
