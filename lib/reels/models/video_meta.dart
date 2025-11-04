class Comment {
  final String user;
  final String comment;

  Comment({required this.user, required this.comment});

  factory Comment.fromJson(Map<String, dynamic> json) =>
      Comment(user: json['user'], comment: json['comment']);
}

class VideoMeta {
  final String filename;
  final String creator;
  final bool liked;
  final bool follow;
  final List<Comment> comments;

  VideoMeta({
    required this.filename,
    required this.creator,
    required this.liked,
    required this.follow,
    required this.comments,
  });

  factory VideoMeta.fromJson(Map<String, dynamic> json) {
    final commentList =
        (json['comments'] as List<dynamic>?)
            ?.map((e) => Comment.fromJson(e))
            .toList() ??
        [];

    return VideoMeta(
      filename: json['filename'],
      creator: json['creator'],
      liked: json['liked'],
      follow: json['follow'],
      comments: commentList,
    );
  }
}
