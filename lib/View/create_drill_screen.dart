import 'dart:io'; // Used for the video file
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // To pick a video
import 'package:video_player/video_player.dart'; // To preview the video
import 'package:firebase_storage/firebase_storage.dart'; // To upload the video
import 'package:cloud_firestore/cloud_firestore.dart'; // To save the drill data
import 'package:firebase_auth/firebase_auth.dart'; // To get the coach's ID

class CreateDrillScreen extends StatefulWidget {
  const CreateDrillScreen({super.key});

  @override
  State<CreateDrillScreen> createState() => _CreateDrillScreenState();
}

class _CreateDrillScreenState extends State<CreateDrillScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  String _skillFocus = 'General';
  double _xpGained = 50;
  bool _isLoading = false;

  // Video Picking
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoController;

  // Firebase
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to pick a video from the gallery
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoFile = pickedFile;
        });
        _initializeVideoPlayer();
      }
    } catch (e) {
      _showErrorSnackBar("Error picking video: $e");
    }
  }

  // Initialize the video player for preview
  void _initializeVideoPlayer() {
    if (_videoFile == null) return;

    _videoController?.dispose(); // Dispose old controller if exists
    _videoController = VideoPlayerController.file(File(_videoFile!.path))
      ..initialize().then((_) {
        setState(() {}); // Update UI when video is initialized
        _videoController?.play();
      });
  }

  // Function to save the drill (upload video + save data)
  Future<void> _saveDrill() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (_videoFile == null) {
      _showErrorSnackBar("Please select an example video.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? coachUid = _auth.currentUser?.uid;
      if (coachUid == null) {
        throw Exception("No coach is logged in.");
      }

      // 1. Upload Video to Firebase Storage
      final String videoFileName =
          '${coachUid}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final File fileToUpload = File(_videoFile!.path);

      UploadTask uploadTask = _storage
          .ref('coach_drills/$coachUid/$videoFileName')
          .putFile(fileToUpload);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Save Drill Data to Firestore
      // We'll create a new 'drills' collection for the coach
      await _firestore
          .collection('coaches')
          .doc(coachUid)
          .collection('drills')
          .add({
        'name': _nameController.text.trim(),
        'goal': _goalController.text.trim(),
        'skillFocus': _skillFocus,
        'xp': _xpGained,
        'videoUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Drill created successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Go back to the dashboard
      }
    } catch (e) {
      _showErrorSnackBar("Error saving drill: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Drill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Video Preview ---
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.2)),
                ),
                child: _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.video_call,
                              color: theme.colorScheme.primary),
                          label: Text(
                            'Select Example Video',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onPressed: _pickVideo,
                        ),
                      ),
              ),
              if (_videoFile != null)
                TextButton(
                  onPressed: _pickVideo,
                  child: const Text('Change Video'),
                ),
              const SizedBox(height: 20),

              // --- Drill Name ---
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                    labelText: 'Drill Name', icon: Icons.title),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),

              // --- Drill Goal/Description ---
              TextFormField(
                controller: _goalController,
                decoration: _buildInputDecoration(
                    labelText: 'Goal / Description', icon: Icons.description),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 20),

              // --- Skill Focus ---
              _buildDropdownTile(
                'Skill Focus',
                ['General', 'Agility', 'Strength', 'Cardio'],
                _skillFocus,
                (newValue) {
                  setState(() {
                    _skillFocus = newValue!;
                  });
                },
              ),

              // --- XP Gained ---
              Row(
                children: [
                  Icon(Icons.star, color: theme.colorScheme.primary),
                  const SizedBox(width: 15),
                  Text('XP Awarded:', style: theme.textTheme.titleMedium),
                  Expanded(
                    child: Slider(
                      value: _xpGained,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: _xpGained.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _xpGained = value;
                        });
                      },
                    ),
                  ),
                  Text(_xpGained.round().toString(),
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 30),

              // --- Save Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDrill,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 3),
                      )
                    : const Text('Save Drill'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for consistent text field styling
  InputDecoration _buildInputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    );
  }

  // Helper for consistent dropdown styling
  Widget _buildDropdownTile(String title, List<String> options,
      String currentValue, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.category, color: theme.colorScheme.primary),
        const SizedBox(width: 15),
        Text('$title:', style: theme.textTheme.titleMedium),
        const Spacer(),
        DropdownButton<String>(
          value: currentValue,
          dropdownColor: theme.colorScheme.surface,
          style: theme.textTheme.bodyLarge,
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}