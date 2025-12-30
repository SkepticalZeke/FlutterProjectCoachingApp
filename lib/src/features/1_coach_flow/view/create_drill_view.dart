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
        const SnackBar(
            content: Text('Drill created successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Go back to the dashboard
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error saving drill. Please check video and try again.'),
            backgroundColor: Colors.red),
      );
    }
  }

  // 6. Build method is "dumb"
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ),
                child: _viewModel.videoController != null &&
                        _viewModel.videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _viewModel.videoController!.value.aspectRatio,
                        child: VideoPlayer(_viewModel.videoController!),
                      )
                    : Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.video_call,
                              color: theme.colorScheme.primary),
                          label: Text(
                            'Select Example Video',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onPressed: _viewModel.pickVideo, // Call ViewModel
                        ),
                      ),
              ),
              if (_viewModel.videoController != null)
                TextButton(
                  onPressed: _viewModel.pickVideo, // Call ViewModel
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
                _viewModel.skillFocus, // Read from ViewModel
                (newValue) {
                  _viewModel.setSkillFocus(newValue!); // Write to ViewModel
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
                      value: _viewModel.xpGained, // Read from ViewModel
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: _viewModel.xpGained.round().toString(),
                      onChanged: (double value) {
                        _viewModel.setXp(value); // Write to ViewModel
                      },
                    ),
                  ),
                  Text(_viewModel.xpGained.round().toString(),
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 30),

              // --- Save Button ---
              ElevatedButton(
                onPressed: _viewModel.isLoading ? null : _saveDrill, // Read state
                child: _viewModel.isLoading
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

  // --- Helper Widgets (UI Only) ---
  InputDecoration _buildInputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    );
  }

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