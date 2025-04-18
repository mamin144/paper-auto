import 'package:flutter/material.dart';
import 'package:paperauto/services/report_service.dart';

class GenerateReport extends StatefulWidget {
  final Map<String, dynamic> project;

  const GenerateReport({
    super.key,
    required this.project,
  });

  @override
  State<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends State<GenerateReport> {
  final ReportService _reportService = ReportService();
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateReport(String type) async {
    try {
      setState(() {
        _isGenerating = true;
        _error = null;
      });

      String filePath;
      if (type == 'MIR') {
        filePath = await _reportService.generateMIR(widget.project);
      } else {
        filePath = await _reportService.generateIR(widget.project);
      }

      await _reportService.openPDF(filePath);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Generate Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Report Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : () => _generateReport('MIR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate Monthly Inspection Report (MIR)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : () => _generateReport('IR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate Inspection Report (IR)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 