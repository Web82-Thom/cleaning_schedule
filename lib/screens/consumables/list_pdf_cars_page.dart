import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cleaning_schedule/controllers/pdf_controller.dart';

class ListPdfCarsPage extends StatefulWidget {
  const ListPdfCarsPage({super.key});

  @override
  State<ListPdfCarsPage> createState() => _ListPdfCarsPageState();
}

class _ListPdfCarsPageState extends State<ListPdfCarsPage> {
  final PdfController pdfController = PdfController();
  List<FileSystemEntity> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  /// Charge les fichiers PDF du dossier carsCategory
  Future<void> _loadPdfFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final categoryDir = Directory('${dir.path}/carsCategory');

    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final files = categoryDir
        .listSync()
        .where((f) => f.path.endsWith('.pdf'))
        .toList()
      ..sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified));

    if (!mounted) return;
    setState(() {
      _pdfFiles = files;
    });
  }

  /// Supprimer un fichier PDF avec confirmation
  Future<void> _deletePdf(String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le PDF'),
        content: Text('Voulez-vous supprimer "$fileName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await pdfController.deletePdfFromCarsCategory(context, fileName);
      _loadPdfFiles(); // rechargement de la liste
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des PDF - Véhicules'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfFiles,
          ),
        ],
      ),
      body: _pdfFiles.isEmpty ?
      const Center(child: Text('Aucun PDF trouvé 🚗')) : 
      ListView.builder(
        itemCount: _pdfFiles.length,
        itemBuilder: (context, index) {
          final file = _pdfFiles[index];
          final fileName = file.path.split('/').last;
          return Card(
            elevation: 2,
            margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf,
                  color: Colors.redAccent),
              title: Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Modifié le : ${file.statSync().modified}',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                await OpenFilex.open(file.path);
              },
              onLongPress: () => _deletePdf(fileName),
            ),
          );
        },
      ),
    );
  }
}
