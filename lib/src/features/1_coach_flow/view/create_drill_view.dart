import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// Import the new ViewModel
import '../viewmodel/create_drill_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class CreateDrillView extends StatefulWidget {
  const CreateDrillView({super.key});

  @override
  State<CreateDrillView> createState() => _CreateDrillViewState();
}

class _CreateDrillViewState extends State<CreateDrillView> {
  // 1. The View owns its ViewModel
  final _viewModel = CreateDrillViewModel();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Listen for changes
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    // 3. Clean up
    _viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _goalController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // 4. Rebuild UI when ViewModel changes
  void _onViewModelChanged() {
    setState(() {});
  }

  // 5. "handle" function now calls the ViewModel
  void _saveDrill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool success = await _viewModel.saveDrill(
      name: _nameController.text.trim(),
      goal: _goalController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Drill created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop(); // Go back to the dashboard
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Error saving drill. Please check video and try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // 6. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create New Drill',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // DARK BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Video Preview Card ---
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_viewModel.videoController != null &&
                            _viewModel.videoController!.value.isInitialized)
                          AspectRatio(
                            aspectRatio:
                                _viewModel.videoController!.value.aspectRatio,
                            child: VideoPlayer(_viewModel.videoController!),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library,
                                  size: 48, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(height: 10),
                              Text(
                                "No Video Selected",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5)),
                              )
                            ],
                          ),
                        
                        // Pick Video Button (Overlay)
                        Positioned(
                          bottom: 16,
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.pickVideo,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: Text(_viewModel.videoController != null
                                ? 'Change Video'
                                : 'Select Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Form Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Drill Details",
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // --- Drill Name ---
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                              labelText: 'Drill Name', icon: Icons.title),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // --- Drill Goal/Description ---
                        TextFormField(
                          controller: _goalController,
                          decoration: _inputDecoration(
                              labelText: 'Goal / Description',
                              icon: Icons.description),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a description'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // --- Skill Focus ---
                        _buildDropdownTile(
                          'Skill Focus',
                          ['General', 'Agility', 'Strength', 'Cardio'],
                          _viewModel.skillFocus,
                          (newValue) {
                            _viewModel.setSkillFocus(newValue!);
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- XP Gained ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    Text('XP Awarded',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade300)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_viewModel.xpGained.round()} XP',
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.amber,
                                inactiveTrackColor: Colors.amber.shade100,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12, elevation: 4),
                                overlayColor: Colors.amber.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _viewModel.xpGained,
                                min: 10,
                                max: 200,
                                divisions: 19,
                                onChanged: (double value) {
                                  _viewModel.setXp(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Save Button ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _saveDrill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _viewModel.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Drill',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40), // Bottom spacing
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (UI Only) ---
  InputDecoration _inputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget _buildDropdownTile(String title, List<String> options,
      String currentValue, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Icon(Icons.category, color: Colors.deepPurple.shade300),
        const SizedBox(width: 15),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
              items: options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}