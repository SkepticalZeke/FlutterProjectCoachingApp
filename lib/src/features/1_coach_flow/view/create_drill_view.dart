import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// Import the new ViewModel
import '../viewmodel/create_drill_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  Refactored CreateDrillView with:
  - Gradient Background
  - Modern Input Styling
  - Enhanced Video Preview Container
  - Polished Layout
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
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Drill created successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop(); // Go back to the dashboard
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Error saving drill. Check video & try again.')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // 6. Build method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create New Drill',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.95),
                colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity, // Ensure gradient covers full screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.05) ?? Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Video Preview ---
                  _buildVideoPreview(context),
                  const SizedBox(height: 24),

                  // --- Drill Name ---
                  TextFormField(
                    controller: _nameController,
                    style: theme.textTheme.bodyLarge,
                    decoration: _buildInputDecoration(
                      context,
                      labelText: 'Drill Name',
                      icon: Icons.title,
                      hintText: 'e.g., "High Knees"',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- Drill Goal/Description ---
                  TextFormField(
                    controller: _goalController,
                    style: theme.textTheme.bodyLarge,
                    decoration: _buildInputDecoration(
                      context,
                      labelText: 'Goal / Description',
                      icon: Icons.description,
                      hintText: 'Describe correct form...',
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // --- Skill Focus ---
                  _buildModernDropdown(
                    context,
                    'Skill Focus',
                    ['General', 'Agility', 'Strength', 'Cardio'],
                    _viewModel.skillFocus,
                    (newValue) => _viewModel.setSkillFocus(newValue!),
                    Icons.category_rounded,
                  ),
                  const SizedBox(height: 24),

                  // --- XP Gained ---
                  _buildXpSlider(context),
                  const SizedBox(height: 32),

                  // --- Save Button ---
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _saveDrill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                      ),
                      child: _viewModel.isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary, strokeWidth: 3),
                            )
                          : const Text(
                              'Save Drill',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasVideo = _viewModel.videoController != null &&
        _viewModel.videoController!.value.isInitialized;

    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasVideo)
                  AspectRatio(
                    aspectRatio: _viewModel.videoController!.value.aspectRatio,
                    child: VideoPlayer(_viewModel.videoController!),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_rounded,
                          size: 48, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No Video Selected',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                
                // Overlay button if no video or just to prompt
                if (!hasVideo)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _viewModel.pickVideo,
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasVideo || !hasVideo) // Always show the button below for clarity or change
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextButton.icon(
              onPressed: _viewModel.pickVideo,
              icon: Icon(hasVideo ? Icons.change_circle_outlined : Icons.add_circle_outline),
              label: Text(hasVideo ? 'Change Video' : 'Select Video from Gallery'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context,
      {required String labelText, required IconData icon, String? hintText}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      prefixIcon: Icon(icon, color: colorScheme.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildModernDropdown(BuildContext context, String title,
      List<String> options, String currentValue, ValueChanged<String?> onChanged, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: title,
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        prefixIcon: Icon(icon, color: colorScheme.secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: colorScheme.surface,
      style: theme.textTheme.bodyLarge,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildXpSlider(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                'XP Reward',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_viewModel.xpGained.round()} XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber[700],
              inactiveTrackColor: Colors.amber[100],
              thumbColor: Colors.amber[900],
              overlayColor: Colors.amber.withOpacity(0.2),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            ),
            child: Slider(
              value: _viewModel.xpGained,
              min: 10,
              max: 200,
              divisions: 19,
              label: _viewModel.xpGained.round().toString(),
              onChanged: (double value) {
                _viewModel.setXp(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}