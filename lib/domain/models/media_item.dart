import 'package:equatable/equatable.dart';

class MediaItem extends Equatable {
  final String id;
  final String name;
  final String? originalTitle;
  final String? overview;
  final String type;
  final int? productionYear;
  final double? communityRating;
  final double? criticRating;
  final int? runTimeTicks;
  final String? officialRating;
  final List<String> genres;
  final String? seriesId;
  final String? seriesName;
  final String? seasonId;
  final int? indexNumber;
  final int? parentIndexNumber;
  final int? playedPercentage;
  final int? userDataPlaybackPositionTicks;
  final bool isPlayed;
  final bool isFavorite;
  final String? premiereDate;
  final String? status;
  final int? episodeCount;

  const MediaItem({
    required this.id,
    required this.name,
    this.originalTitle,
    this.overview,
    required this.type,
    this.productionYear,
    this.communityRating,
    this.criticRating,
    this.runTimeTicks,
    this.officialRating,
    this.genres = const [],
    this.seriesId,
    this.seriesName,
    this.seasonId,
    this.indexNumber,
    this.parentIndexNumber,
    this.playedPercentage,
    this.userDataPlaybackPositionTicks,
    this.isPlayed = false,
    this.isFavorite = false,
    this.premiereDate,
    this.status,
    this.episodeCount,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final userData = json['UserData'] as Map<String, dynamic>?;

    return MediaItem(
      id: json['Id'] ?? '',
      name: json['Name'] ?? '',
      originalTitle: json['OriginalTitle'],
      overview: json['Overview'],
      type: json['Type'] ?? '',
      productionYear: json['ProductionYear'],
      communityRating: (json['CommunityRating'] as num?)?.toDouble(),
      criticRating: (json['CriticRating'] as num?)?.toDouble(),
      runTimeTicks: json['RunTimeTicks'],
      officialRating: json['OfficialRating'],
      genres: (json['Genres'] as List?)?.cast<String>() ?? [],
      seriesId: json['SeriesId'],
      seriesName: json['SeriesName'],
      seasonId: json['SeasonId'],
      indexNumber: json['IndexNumber'],
      parentIndexNumber: json['ParentIndexNumber'],
      playedPercentage: userData?['PlayedPercentage']?.round(),
      userDataPlaybackPositionTicks: userData?['PlaybackPositionTicks'],
      isPlayed: userData?['Played'] ?? false,
      isFavorite: userData?['IsFavorite'] ?? false,
      premiereDate: json['PremiereDate'],
      status: json['Status'],
      episodeCount: json['RecursiveItemCount'] ?? json['ChildCount'],
    );
  }

  bool get isMovie => type == 'Movie';
  bool get isSeries => type == 'Series';
  bool get isEpisode => type == 'Episode';
  bool get isSeason => type == 'Season';

  String get formattedRating {
    if (communityRating == null) return '';
    return communityRating!.toStringAsFixed(1);
  }

  String get formattedDuration {
    if (runTimeTicks == null) return '';
    final minutes = (runTimeTicks! / 600000000).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String get episodeTitle {
    if (!isEpisode) return name;
    final ep = indexNumber?.toString().padLeft(2, '0') ?? '??';
    final season = parentIndexNumber?.toString() ?? '?';
    return 'S$season E$ep - $name';
  }

  @override
  List<Object?> get props => [id, name, type];
}
