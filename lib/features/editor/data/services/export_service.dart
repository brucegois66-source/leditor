import 'dart:io';

class ExportResult {
  final File file;
  final Duration trimStart;
  final Duration trimEnd;

  const ExportResult({
    required this.file,
    required this.trimStart,
    required this.trimEnd,
  });

  Duration get duration => trimEnd - trimStart;
}

class ExportService {
  const ExportService();

  Future<ExportResult> exportTrim({
    required String inputPath,
    required Duration trimStart,
    required Duration trimEnd,
  }) async {
    if (inputPath.trim().isEmpty) {
      throw ArgumentError.value(
        inputPath,
        'inputPath',
        'O caminho do vídeo não pode estar vazio.',
      );
    }

    if (trimStart < Duration.zero) {
      throw ArgumentError.value(
        trimStart,
        'trimStart',
        'O início do trim não pode ser negativo.',
      );
    }

    if (trimEnd <= trimStart) {
      throw ArgumentError(
        'O fim do trim deve ser maior que o início do trim.',
      );
    }

    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw FileSystemException(
        'O vídeo de origem não foi encontrado.',
        inputPath,
      );
    }

    // Próxima etapa:
    // Aqui entraremos com o processador nativo para gerar um novo MP4,
    // mantendo somente o intervalo entre trimStart e trimEnd.
    //
    // Não retorne inputFile como resultado final: isso apenas compartilharia
    // o vídeo original, sem aplicar o corte.
    throw UnimplementedError(
      'Exportação real ainda não foi conectada ao processador de vídeo.',
    );
  }
}