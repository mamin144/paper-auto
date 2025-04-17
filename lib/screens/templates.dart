import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class PdfViewerPage extends StatefulWidget {
  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? pdfFilePath;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    final ByteData data = await rootBundle.load("lib/assets/الشهادات.pdf");
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File("${tempDir.path}/الشهادات.pdf");
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);

    setState(() {
      pdfFilePath = tempFile.path;
    });
  }

  void openPdf() async {
    if (pdfFilePath != null) {
      final Uri fileUri = Uri.file(
        pdfFilePath!,
      ); // Correctly formatted file path URI

      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      } else {
        print("Could not open PDF");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Viewer")),
      body: Center(
        child:
            pdfFilePath == null
                ? CircularProgressIndicator()
                : GestureDetector(
                  onTap: openPdf,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Tap to open PDF in Google",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
