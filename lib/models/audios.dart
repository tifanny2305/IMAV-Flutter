class Audio {
  final String id;
  final String url;
  final String transcription;
  final String fecha_registro;

  Audio({
    required this.id,
    required this.url,
    required this.transcription,
    required this.fecha_registro,
  });

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      id: json['id'],
      url: json['url_audio'],
      transcription: json['transcripcion'],
      fecha_registro: json['fecha_registro'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url_audio': url,
      'transcripcion': transcription,
      'fecha_registro': fecha_registro,
    };
  }
}
