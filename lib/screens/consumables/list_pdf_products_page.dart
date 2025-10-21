import 'dart:io';
import 'package:cleaning_schedule/controllers/pdf_controller.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ListPdfProductsPage extends StatefulWidget {
  const ListPdfProductsPage({super.key});

  @override
  State<ListPdfProductsPage> createState() => _ListPdfProductsPageState();
}

class _ListPdfProductsPageState extends State<ListPdfProductsPage> {
  List<File> _pdfFiles = [];
  PdfController pdfController = PdfController();

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  /// Charge les fichiers PDF depuis le dossier productsCategory
  Future<void> _loadPdfFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory('${dir.path}/productsCategory');

      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      final files = <File>[];
      await for (var entity in categoryDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          files.add(entity);
        }
      }

      // Tri par date de modification décroissante (du plus récent au plus ancien)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

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
        title: const Text('Liste des PDF Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfFiles,
          )
        ],
      ),
      body: _pdfFiles.isEmpty?
      const Center(child: Text('Aucun PDF trouvé')): 
      ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _pdfFiles.length,
        itemBuilder: (context, index) {
          final file = _pdfFiles[index];
          final fileName = file.path.split('/').last;

          return InkWell(
            onLongPress: () {
              pdfController.deletePdfFromProductsCategory(context, fileName);
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(fileName),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    await OpenFilex.open(file.path);
                  },
                ),
                onTap: () async {
                  await OpenFilex.open(file.path);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
