import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/image_service.dart';

class IzinPage extends StatefulWidget {
  @override
  _IzinPageState createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _attachmentPath;
  bool _isLoading = false;

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (file != null) {
        setState(() {
          _attachmentPath = file.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  Future<void> _submitSickLeave() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harap pilih tanggal mulai dan selesai')),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tanggal selesai harus setelah tanggal mulai')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final supabaseService = Provider.of<SupabaseService>(context, listen: false);
        final imageService = Provider.of<ImageService>(context, listen: false);
        final user = supabaseService.client.auth.currentUser!;

        String? attachmentUrl;
        if (_attachmentPath != null) {
          final fileName = 'sick_leave_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
          final storageService = Provider.of<SupabaseService>(context, listen: false);
          attachmentUrl = await storageService.uploadAttendancePhoto(_attachmentPath!, fileName);
        }

        await supabaseService.submitSickLeave({
          'user_id': user.id,
          'reason': _reasonController.text.trim(),
          'start_date': _startDate!.toIso8601String().split('T')[0],
          'end_date': _endDate!.toIso8601String().split('T')[0],
          'attachment_url': attachmentUrl,
          'status': 'Menunggu',
          'submitted_at': DateTime.now().toIso8601String(),
        });

        _showSuccessDialog();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Izin Berhasil Diajukan'),
          ],
        ),
        content: Text('Pengajuan izin sakit Anda telah berhasil dikirim dan menunggu persetujuan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Izin Sakit'),
        backgroundColor: Color(0xFF2E4B9C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Izin Sakit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E4B9C),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Isi form berikut untuk mengajukan izin sakit',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Alasan Sakit
                Text(
                  'Alasan Sakit *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Jelaskan alasan sakit Anda...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harap isi alasan sakit';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Tanggal Mulai
                Text(
                  'Tanggal Mulai Sakit *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(
                    _startDate == null
                        ? 'Pilih tanggal mulai'
                        : DateFormat('dd/MM/yyyy').format(_startDate!),
                  ),
                  trailing: Icon(Icons.arrow_drop_down),
                  onTap: () => _pickDate(context, true),
                  tileColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                SizedBox(height: 16),

                // Tanggal Selesai
                Text(
                  'Tanggal Selesai Sakit *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(
                    _endDate == null
                        ? 'Pilih tanggal selesai'
                        : DateFormat('dd/MM/yyyy').format(_endDate!),
                  ),
                  trailing: Icon(Icons.arrow_drop_down),
                  onTap: () => _pickDate(context, false),
                  tileColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                SizedBox(height: 20),

                // Upload Surat Dokter
                Text(
                  'Surat Dokter (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.attach_file),
                  title: Text(
                    _attachmentPath == null
                        ? 'Upload surat dokter (jika ada)'
                        : 'File terpilih: ${_attachmentPath!.split('/').last}',
                  ),
                  trailing: Icon(Icons.upload),
                  onTap: _pickAttachment,
                  tileColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSickLeave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E4B9C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Ajukan Izin Sakit',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}