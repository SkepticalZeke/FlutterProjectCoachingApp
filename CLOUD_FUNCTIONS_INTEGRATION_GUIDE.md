# Cloud Functions Integration Guide

This guide shows you how to use all the Cloud Functions that are deployed but not yet integrated into your app.

## Overview

All 30 Cloud Functions are deployed at:
```
https://asia-southeast1-fitness-coaching-app-5633f.cloudfunctions.net/
```

## ✅ Already Integrated (9 functions)

These are actively used in your app through `database_repository.dart`:

| Function | Used In | Location |
|----------|---------|----------|
| `addAthlete` | Create new athlete | `database_repository.dart:44` |
| `addRestDay` | Set rest day | `database_repository.dart:152` |
| `assignDrill` | Assign drill to athlete | `database_repository.dart:213` |
| `completeDrill` | Complete a drill | `database_repository.dart:229` |
| `createCoachDrill` | Create drill template | `database_repository.dart:164` |
| `createCoachProfile` | Create coach account | `database_repository.dart:38` |
| `submitReview` | Review drill submission | `database_repository.dart:247` |
| `updateAthleteDetails` | Update athlete info | `database_repository.dart:142` |
| `updateAthleteProfile` | Update athlete name/PIN | `database_repository.dart:405` |

---

## 🆕 Newly Integrated ViewModels

I've created 4 new ViewModels that implement the remaining functions:

### 1. **CoachNotificationsViewModel** (Updated)

**File**: `lib/src/features/1_coach_flow/viewmodel/coach_notifications_viewmodel.dart`

**New Methods**:
```dart
// Fetch all notifications
await viewModel.fetchNotifications();

// Mark single notification as read
await viewModel.markNotificationRead(notificationId);

// Mark all as read
await viewModel.markAllNotificationsRead();

// Clear all notifications
await viewModel.clearAllNotifications();
```

**Functions Used**:
- ✅ `getNotifications`
- ✅ `markNotificationRead`
- ✅ `markAllNotificationsRead`
- ✅ `clearNotifications`

---

### 2. **AthleteManagementViewModel** (New)

**File**: `lib/src/features/1_coach_flow/viewmodel/athlete_management_viewmodel.dart`

**Usage Example**:
```dart
final viewModel = AthleteManagementViewModel();

// Fetch all athletes
await viewModel.fetchAthletes();

// Get single athlete
final athlete = await viewModel.getAthlete(athleteId);

// Create new athlete
final athleteId = await viewModel.createAthlete(
  name: 'John Doe',
  email: 'john@example.com',
  pin: '1234',
  coachId: currentCoachId,
);

// Update athlete
await viewModel.updateAthlete(
  athleteId: athleteId,
  updates: {
    'name': 'Jane Doe',
    'level': 2,
  },
);

// Delete athlete (admin only)
await viewModel.deleteAthlete(athleteId);
```

**Functions Used**:
- ✅ `getAthletes`
- ✅ `getAthlete`
- ✅ `createAthlete`
- ✅ `updateAthlete`
- ✅ `deleteAthlete`

---

### 3. **CoachManagementViewModel** (New)

**File**: `lib/src/features/1_coach_flow/viewmodel/coach_management_viewmodel.dart`

**Usage Example**:
```dart
final viewModel = CoachManagementViewModel();

// Get all coaches (admin only)
await viewModel.fetchCoaches();

// Get single coach
final coach = await viewModel.getCoach(coachId);

// Create new coach
final coachId = await viewModel.createCoach(
  uid: firebaseAuthUid,
  email: 'coach@example.com',
);
```

**Functions Used**:
- ✅ `getCoaches`
- ✅ `getCoach`
- ✅ `createCoach`

---

### 4. **DrillManagementViewModel** (New)

**File**: `lib/src/features/1_coach_flow/viewmodel/drill_management_viewmodel.dart`

**Usage Example**:
```dart
final viewModel = DrillManagementViewModel();

// Get all drills
await viewModel.fetchDrills();

// Get drills by status
await viewModel.fetchDrills(status: 'pending_review');

// Get single drill
final drill = await viewModel.getDrill(drillId);

// Create drill
final drillId = await viewModel.createDrill(
  title: 'Push-ups',
  athleteId: athleteId,
  description: 'Do 20 push-ups',
  xp: 100,
);

// Submit drill (athlete)
await viewModel.submitDrill(
  drillId: drillId,
  videoUrl: 'https://...',
  notes: 'Completed!',
);

// Review drill (coach)
await viewModel.reviewDrill(
  drillId: drillId,
  approved: true,
  feedback: 'Great job!',
  rating: 5,
);
```

**Functions Used**:
- ✅ `getDrills`
- ✅ `getDrill`
- ✅ `createDrill`
- ✅ `submitDrill`
- ✅ `reviewDrill`

---

## 🔄 Background Functions (Automatic)

These functions run automatically - you don't need to call them:

| Function | Type | Trigger |
|----------|------|---------|
| `onAthleteUpdate` | Firestore Trigger | When athlete document changes |
| `onDrillUpdate` | Firestore Trigger | When drill document changes |
| `checkAthleteProgress` | Scheduled | Every 30 minutes (6am-11:30pm) |

---

## How to Use in Your UI

### Example 1: Notification Bell Icon

```dart
// In your widget
class NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CoachNotificationsViewModel>(context);

    return IconButton(
      icon: Badge(
        label: Text('${viewModel.notifications.length}'),
        child: Icon(Icons.notifications),
      ),
      onPressed: () async {
        await viewModel.fetchNotifications();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationsScreen(),
          ),
        );
      },
    );
  }
}
```

### Example 2: Admin Athlete List

```dart
class AthleteListScreen extends StatefulWidget {
  @override
  _AthleteListScreenState createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  final viewModel = AthleteManagementViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.fetchAthletes();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return CircularProgressIndicator();
        }

        return ListView.builder(
          itemCount: viewModel.athletes.length,
          itemBuilder: (context, index) {
            final athlete = viewModel.athletes[index];
            return ListTile(
              title: Text(athlete['name']),
              subtitle: Text('Level ${athlete['level']}'),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await viewModel.deleteAthlete(athlete['id']);
                },
              ),
            );
          },
        );
      },
    );
  }
}
```

### Example 3: Drill Review Screen

```dart
class DrillReviewButton extends StatelessWidget {
  final String drillId;

  @override
  Widget build(BuildContext context) {
    final viewModel = DrillManagementViewModel();

    return Row(
      children: [
        ElevatedButton(
          onPressed: () async {
            final success = await viewModel.reviewDrill(
              drillId: drillId,
              approved: true,
              feedback: 'Excellent work!',
              rating: 5,
            );

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Drill approved!')),
              );
            }
          },
          child: Text('Approve'),
        ),
        ElevatedButton(
          onPressed: () async {
            await viewModel.reviewDrill(
              drillId: drillId,
              approved: false,
              feedback: 'Needs improvement',
              rating: 2,
            );
          },
          child: Text('Reject'),
        ),
      ],
    );
  }
}
```

---

## Integration Checklist

### Immediate Use (High Priority)

- [ ] **Notifications**: Add notification bell to coach dashboard
- [ ] **Drill Review**: Use `reviewDrill` instead of direct Firestore writes
- [ ] **Athlete CRUD**: Replace any direct Firestore athlete operations

### Optional (Nice to Have)

- [ ] **Admin Panel**: Create admin screen using `getCoaches` and `getAthletes`
- [ ] **Drill Analytics**: Use `getDrills` with status filters for reports
- [ ] **Bulk Operations**: Use Cloud Functions for mass updates

---

## Benefits of Using These Functions

### Security
✅ Server-side validation
✅ Authentication checks
✅ Role-based access control

### Maintainability
✅ Update logic without app updates
✅ Centralized business rules
✅ Easier debugging with Cloud Logs

### Performance
✅ Reduced client-side code
✅ Server-side data processing
✅ Better error handling

---

## Testing Your Integration

### 1. Test Notifications
```dart
final viewModel = CoachNotificationsViewModel();
await viewModel.fetchNotifications();
print('Notifications: ${viewModel.notifications.length}');
```

### 2. Test Athlete Management
```dart
final viewModel = AthleteManagementViewModel();
await viewModel.fetchAthletes();
print('Athletes: ${viewModel.athletes.length}');
```

### 3. Monitor Cloud Functions
View logs at:
https://console.firebase.google.com/project/fitness-coaching-app-5633f/functions/logs

---

## Next Steps

1. **Add Provider**: Register new ViewModels in your Provider setup
2. **Update UI**: Replace direct Firestore calls with ViewModel methods
3. **Test**: Run the app and test each function
4. **Monitor**: Check Cloud Functions logs for any errors

## Questions?

All functions are documented in:
- `lib/src/core/services/cloud_functions_service.dart`
- `functions/src/functions/app-specific.ts`
