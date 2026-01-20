import 'package:flutter/material.dart';
import '../viewmodel/drill_library_viewmodel.dart';

/*
  VIEW (V)
  This is the UI for the Drill Library. It is "dumb" and only talks to the ViewModel.
  Coaches can see, edit, and delete their custom drills here.
*/
class DrillLibraryView extends StatefulWidget {
  const DrillLibraryView({super.key});

  @override
  State<DrillLibraryView> createState() => _DrillLibraryViewState();
}

class _DrillLibraryViewState extends State<DrillLibraryView> {
  // 1. The View owns its ViewModel
  final _viewModel = DrillLibraryViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    await _viewModel.loadDrills();
  }

  void _showDrillActions(Map<String, dynamic> drill) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Drill Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Edit Option
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Drill'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDrillDialog(drill);
                },
              ),
              // Delete Option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Drill'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(drill);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEditDrillDialog(Map<String, dynamic> drill) {
    final nameController = TextEditingController(text: drill['name'] ?? '');
    final goalController = TextEditingController(text: drill['goal'] ?? '');
    String selectedSkill = drill['skillFocus'] ?? 'General';
    double xpValue = (drill['xp'] ?? 50).toDouble();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Edit Drill'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Drill Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      decoration: const InputDecoration(
                        labelText: 'Drill Goal/Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: selectedSkill,
                      isExpanded: true,
                      items: ['General', 'Strength', 'Speed', 'Agility', 'Cardio', 'Flexibility']
                          .map((skill) {
                        return DropdownMenuItem(
                          value: skill,
                          child: Text(skill),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSkill = value ?? 'General';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('XP Reward: '),
                        Slider(
                          value: xpValue,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          label: xpValue.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              xpValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await _viewModel.updateDrill(
                      drillId: drill['id'],
                      name: nameController.text.trim(),
                      goal: goalController.text.trim(),
                      skillFocus: selectedSkill,
                      xp: xpValue,
                    );

                    if (mounted && success) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Drill updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> drill) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Drill?'),
          content: Text(
            'Are you sure you want to delete "${drill['name']}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _viewModel.deleteDrill(drill['id']);
                if (mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Drill deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Drill Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_viewModel.drills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Drills Yet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first drill to get started',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _viewModel.drills.length,
                  itemBuilder: (context, index) {
                    final drill = _viewModel.drills[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade700,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.video_library,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                        title: Text(
                          drill['name'] ?? 'Unnamed Drill',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Skill: ${drill['skillFocus'] ?? 'General'} | XP: ${drill['xp'] ?? 0}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              drill['goal'] ?? 'No description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF00BCD4),
                          ),
                          onPressed: () => _showDrillActions(drill),
                        ),
                        onTap: () => _showDrillActions(drill),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
