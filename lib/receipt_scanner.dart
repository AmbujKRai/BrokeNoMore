import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptScanner extends StatefulWidget {
  final Function(double amount, String category) onExpenseExtracted;

  const ReceiptScanner({
    Key? key,
    required this.onExpenseExtracted,
  }) : super(key: key);

  @override
  State<ReceiptScanner> createState() => _ReceiptScannerState();
}

class _ReceiptScannerState extends State<ReceiptScanner> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _extractedText = '';
  double? _extractedAmount;
  String _selectedCategory = 'Food';

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isProcessing = true;
        });
        await _processImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    try {
      final inputImage = InputImage.fromFile(_image!);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      setState(() {
        _extractedText = recognizedText.text;
      });

      // Try to extract amount from the text
      final amountRegex = RegExp(r'(?:Rs\.?|₹)\s*(\d+(?:\.\d{2})?)');
      final matches = amountRegex.allMatches(_extractedText);
      
      if (matches.isNotEmpty) {
        // Get the last match (usually the total amount)
        final lastMatch = matches.last;
        final amountStr = lastMatch.group(1);
        if (amountStr != null) {
          setState(() {
            _extractedAmount = double.parse(amountStr);
          });
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null) ...[
              ElevatedButton.icon(
                onPressed: () => _getImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _getImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ] else ...[
              Image.file(_image!),
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_extractedAmount != null) ...[
                  Text(
                    'Extracted Amount: ₹${_extractedAmount!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Movies', child: Text('Movies')),
                      DropdownMenuItem(value: 'Party', child: Text('Party')),
                      DropdownMenuItem(value: 'Stationery', child: Text('Stationery')),
                      DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_extractedAmount != null) {
                        widget.onExpenseExtracted(_extractedAmount!, _selectedCategory);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Extracted Text:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_extractedText),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
} 