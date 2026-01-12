import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodel/drill_management_viewmodel.dart';

/*
  VIEW for Drill Management
  Coach interface for managing drill assignments and reviews
*/
class DrillManagementView extends StatefulWidget {
  const DrillManagementView({super.key});

  @override
  State<DrillManagementView> createState() => _DrillManagementViewState();
}

class _DrillManagementViewState extends State<DrillManagementView>
    with SingleTickerProviderStateMixin {
  final _viewModel = DrillManagementViewModel();
  late TabController _tabController;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDrills();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });
  }

  void _onTabChanged() {
    switch (_tabController.index) {
      case 0:
        _viewModel.fetchDrills(); // All
        break;
      case 1:
        _viewModel.filterByStatus('assigned'); // Assigned
        break;
      case 2:
        _viewModel.filterByStatus('pending_review'); // Pending
        break;
      case 3:
        _viewModel.filterByStatus('completed'); // Completed
        break;
    }
  }

  Future<void> _loadDrills() async {
    await _viewModel.fetchDrills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drill Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrills,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Assigned', icon: Icon(Icons.assignment)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Done', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null) {
            return _buildErrorView();
          }

          if (_viewModel.drills.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: _loadDrills,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.drills.length,
              itemBuilder: (context, index) {
                final drill = _viewModel.drills[index];
                return _DrillCard(
                  drill: drill,
                  currentUserId: _currentUserId,
                  onReview: () => _showReviewDialog(drill),
                  onViewDetails: () => _viewDrillDetails(drill),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDrillDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Drill'),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: ${_viewModel.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDrills,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No drills found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to assign a new drill',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showCreateDrillDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoUrlController = TextEditingController();
    final xpController = TextEditingController(text: '100');
    final athleteIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Drill'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Drill Name',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: athleteIdController,
                  decoration: const InputDecoration(
                    labelText: 'Athlete ID',
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Enter athlete ID',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Video URL (optional)',
                    prefixIcon: Icon(Icons.video_library),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: xpController,
                  decoration: const InputDecoration(
                    labelText: 'XP Reward',
                    prefixIcon: Icon(Icons.stars),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final drillId = await _viewModel.createDrill(
                  title: titleController.text,
                  athleteId: athleteIdController.text,
                  description: descriptionController.text,
                  videoUrl: videoUrlController.text.isEmpty
                      ? null
                      : videoUrlController.text,
                  xp: int.tryParse(xpController.text),
                  skillFocus: 'General',
                );

                if (mounted) {
                  if (drillId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drill assigned successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_viewModel.errorMessage ?? 'Failed to assign drill'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> drill) {
    final feedbackController = TextEditingController();
    int rating = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Review: ${drill['title']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    border: OutlineInputBorder(),
                    hintText: 'Provide feedback to the athlete',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _viewModel.reviewDrill(
                  drillId: drill['id'],
                  approved: false,
                  feedback: feedbackController.text,
                  rating: rating,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Drill sent back for revision'
                          : _viewModel.errorMessage ?? 'Review failed'),
                      backgroundColor: success ? Colors.orange : Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Needs Work'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _viewModel.reviewDrill(
                  drillId: drill['id'],
                  approved: true,
                  feedback: feedbackController.text,
                  rating: rating,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Drill approved!'
                          : _viewModel.errorMessage ?? 'Review failed'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDrillDetails(Map<String, dynamic> drill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(drill['title'] ?? 'Drill Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Status', value: drill['status'] ?? 'Unknown'),
              _DetailRow(label: 'Athlete ID', value: drill['athleteId'] ?? 'N/A'),
              _DetailRow(label: 'XP Reward', value: '${drill['xp'] ?? 0}'),
              if (drill['description'] != null) ...[
                const SizedBox(height: 8),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(drill['description']),
              ],
              if (drill['videoUrl'] != null) ...[
                const SizedBox(height: 8),
                const Text('Video:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(drill['videoUrl'], style: const TextStyle(color: Colors.blue)),
              ],
              if (drill['notes'] != null) ...[
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(drill['notes']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}

class _DrillCard extends StatelessWidget {
  final Map<String, dynamic> drill;
  final String? currentUserId;
  final VoidCallback onReview;
  final VoidCallback onViewDetails;

  const _DrillCard({
    required this.drill,
    required this.currentUserId,
    required this.onReview,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final title = drill['title'] ?? 'Unnamed Drill';
    final status = drill['status'] ?? 'assigned';
    final xp = drill['xp'] ?? 0;
    final athleteId = drill['athleteId'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Athlete: $athleteId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$xp XP',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (status == 'pending_review') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
        return Icons.play_circle;
      case 'pending_review':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'pending_review':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'pending_review':
        return 'Pending Review';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Needs Work';
      default:
        return status.toUpperCase();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
