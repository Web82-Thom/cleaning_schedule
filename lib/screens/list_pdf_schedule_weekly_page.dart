import 'dart:io';
import 'package:cleaning_schedule/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ListPdfScheduleWeeklyPage extends StatefulWidget {
  const ListPdfScheduleWeeklyPage({super.key});

  @override
  State<ListPdfScheduleWeeklyPage> createState() => _ListPdfScheduleWeeklyPageState();
}

class _ListPdfScheduleWeeklyPageState extends State<ListPdfScheduleWeeklyPage> {
  List<FileSystemEntity> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory('${dir.path}/scheduleWeeklyCategory');

      // Crée le dossier s'il n'existe pas
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      // Liste les fichiers PDF
      final files = categoryDir
          .listSync()
          .where((f) => f is File && f.path.endsWith('.pdf'))
          .map((f) => f as File)
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (!mounted) return;

      setState(() {
        _pdfFiles = files;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 PDF enregistrés'),
      ),
      body: _pdfFiles.isEmpty
          ? const Center(child: Text('Aucun PDF enregistré pour le moment'))
          : ListView.builder(
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                final file = _pdfFiles[index];
                final fileName = file.path.split('/').last;
                final lastModif = file.statSync().modified.toLocal().toString().split('.')[0];

                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(fileName, style: TextStyle(fontSize: 14),),
                  subtitle: Text('Modifié le : $lastModif', style: TextStyle(fontSize: 12),),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final fileToDelete = file;
                      final nameToShow = fileName;

                      try {
                        await File(fileToDelete.path).delete();

                        _loadPdfFiles(); // safe, pas de context ici

                        // Utilise le ScaffoldMessenger global pour éviter tout warning
                        if (mounted) {
                          ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)?.showSnackBar(
                            SnackBar(content: Text('Supprimé : $nameToShow')),
                          );
                        }
                      } catch (e) {
                        debugPrint('Erreur lors de la suppression: $e');
                      }
                    },
                  ),


                  onTap: () async {
                    await OpenFilex.open(file.path);
                  },
                );
              },
            ),
    );
  }
}
