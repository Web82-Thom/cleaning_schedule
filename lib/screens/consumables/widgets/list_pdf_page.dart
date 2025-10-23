import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cleaning_schedule/controllers/pdf_controller.dart';

class ListPdfPage extends StatefulWidget {
  const ListPdfPage({super.key});

  @override
  State<ListPdfPage> createState() => _ListPdfPageState();
}

class _ListPdfPageState extends State<ListPdfPage> {
  final PdfController pdfController = PdfController();
  List<FileSystemEntity> _files = [];
  bool _loading = true;
  String _title = 'PDFs';
  String _fileNamePrefix = '';
  String _elementName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _title = args['title'] ?? _title;
      _fileNamePrefix = args['fileNamePrefix'] ?? '';
      _elementName = args['elementName'] ?? '';
    }

    _loadFiles();
  }

  /// 🔹 CHARGER LES FICHIERS PDF LOCAUX
  Future<void> _loadFiles() async {
    setState(() => _loading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final allFiles = dir.listSync().where((f) => f.path.endsWith('.pdf'));

      final safePrefix = _fileNamePrefix.toLowerCase().replaceAll(' ', '_');
      final safeElement = _elementName.toLowerCase().replaceAll(' ', '_');

      _files = allFiles.where((f) {
        final name = f.path.split('/').last.toLowerCase();
        return name.startsWith('conso_${safePrefix}_$safeElement');
      }).toList();

      _files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    } catch (e) {
      debugPrint('Erreur lors du chargement des PDFs : $e');
      _files = [];
    }

    setState(() => _loading = false);
  }

  /// 🔹 SUPPRESSION D’UN FICHIER
  Future<void> _deleteFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le PDF'),
        content: Text('Voulez-vous vraiment supprimer "${file.path.split('/').last}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await pdfController.deletePdfFromCategory(context: context, file: file);
        await _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF supprimé avec succès ✅')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression : $e')),
          );
        }
      }
    }
  }

  /// 🔹 OUVRIR UN PDF
  Future<void> _openFile(File file) async {
    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’ouverture : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF : $_title - $_elementName'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun PDF disponible pour le moment',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    // 🔹 Liste déroulante des PDFs
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _files.length,
                        itemBuilder: (context, i) {
                          final f = _files[i];
                          final fileName = f.path.split('/').last;
                          final file = File(f.path);
                          final modifiedDate =
                              file.statSync().modified.toLocal();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.indigo, size: 30),
                              title: Text(
                                fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Modifié le : '
                                '${modifiedDate.day.toString().padLeft(2, '0')}/'
                                '${modifiedDate.month.toString().padLeft(2, '0')}/'
                                '${modifiedDate.year}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteFile(file),
                              ),
                              onTap: () => _openFile(file),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
