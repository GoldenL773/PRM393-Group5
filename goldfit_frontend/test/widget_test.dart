// This is a basic Flutter widgets test.
//
// To perform an interaction with a widgets in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widgets
// tree, read text, and verify that the values of widgets properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goldfit_frontend/main.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/auth_repository.dart';
import 'package:goldfit_frontend/features/auth/models/user_model.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_collection.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';

// Create minimal mock classes directly here
class MockAnalyticsRepository implements AnalyticsRepository {
  @override Future<WardrobeAnalytics> getAnalytics() async => WardrobeAnalytics(
    totalItems: 0,
    totalValue: 0,
    mostWorn: [],
    leastWorn: [],
  );
  @override Future<void> recordUsage(String outfitId, DateTime date) async {}
  @override Future<List<ClothingItem>> getMostWorn(int limit) async => [];
  @override Future<List<ClothingItem>> getLeastWorn(int limit) async => [];
  @override Future<Map<ClothingType, int>> getItemCountByType() async => {};
  @override Future<double> getTotalValue() async => 0;
  @override void invalidateCache() {}
}

class MockClothingRepository implements ClothingRepository {
  @override Future<ClothingItem> create(ClothingItem item) async => item;
  @override Future<ClothingItem?> getById(String id) async => null;
  @override Future<List<ClothingItem>> getAll() async => [];
  @override Future<List<ClothingItem>> getByType(ClothingType type) async => [];
  @override Future<List<ClothingItem>> getByFilters(FilterState filters) async => [];
  @override Future<ClothingItem> update(ClothingItem item) async => item;
  @override Future<void> delete(String id) async {}
  @override Future<List<ClothingItem>> batchCreate(List<ClothingItem> items) async => items;
  @override Stream<List<ClothingItem>> watchAll() => Stream.value([]);
}

class MockOutfitRepository implements OutfitRepository {
  @override Future<Outfit> create(Outfit outfit) async => outfit;
  @override Future<Outfit?> getById(String id) async => null;
  @override Future<List<Outfit>> getAll() async => [];
  @override Future<List<Outfit>> getByVibe(String vibe) async => [];
  @override Future<Outfit> update(Outfit outfit) async => outfit;
  @override Future<void> delete(String id) async {}
  @override Future<void> assignToDate(String outfitId, DateTime date, String timeSlot, {String? eventName, String? startTime}) async {}
  @override Future<void> unassignFromDate(DateTime date, String timeSlot) async {}
  @override Future<List<Outfit>> getByDate(DateTime date) async => [];
  @override Future<List<Outfit>> getByDateRange(DateTime start, DateTime end) async => [];
  @override Stream<List<Outfit>> watchAll() => Stream.value([]);
}

// Mock Auth Repository for testing
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  String? _error;

  MockAuthRepository({UserModel? currentUser}) : _currentUser = currentUser;

  @override
  Future<UserModel?> signInWithGoogle() async {
    if (_error != null) throw Exception(_error);
    return _currentUser;
  }

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    if (_error != null) throw Exception(_error);
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Invalid credentials');
    }
    return _currentUser;
  }

  @override
  Future<UserModel?> registerWithEmail(String email, String password, String name) async {
    if (_error != null) throw Exception(_error);
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Registration failed');
    }
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<String?> createSession(String userId) async {
    return 'mock_session_token_$userId';
  }

  @override
  Future<bool> validateSession(String sessionToken) async {
    return sessionToken.isNotEmpty;
  }

  @override
  Future<void> revokeSession(String sessionToken) async {}

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
  }

  void setMockUser(UserModel? user) {
    _currentUser = user;
  }

  void setError(String error) {
    _error = error;
  }

  @override
  Future<UserModel?> updateUser(UserModel user) {
    // TODO: implement updateUser
    throw UnimplementedError();
  }
}

class MockCollectionRepository implements CollectionRepository {
  @override
  Future<WardrobeCollection> create(WardrobeCollection collection) async =>
      collection;

  @override
  Future<WardrobeCollection?> getById(String id) async => null;

  @override
  Future<List<WardrobeCollection>> getAll() async => [];

  @override
  Future<WardrobeCollection> update(WardrobeCollection collection) async =>
      collection;

  @override
  Future<void> delete(String id) async {}
}
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: '''
GEMINI_API_KEY=
GEMINI_API_KEY_TEXT=
OPENWEATHER_API_KEY=
REMOVE_BG_API_KEY=
''');
  });

  testWidgets('GoldFit app smoke test', (WidgetTester tester) async {
    // Create a mock auth repository with no user (not authenticated)
    final mockAuthRepo = MockAuthRepository(currentUser: null);

    // Build our app and trigger a frame with all required parameters
    await tester.pumpWidget(GoldFitApp(
      authRepository: mockAuthRepo,
      analyticsRepository: MockAnalyticsRepository(),
      clothingRepository: MockClothingRepository(),
      collectionRepository: MockCollectionRepository(),
      outfitRepository: MockOutfitRepository(),
    ));

    // Wait for any async operations
    await tester.pumpAndSettle();

    // Since no user is logged in, we should see the auth screen
    // Verify that the app displays the welcome message
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue your journey'), findsOneWidget);
    // Optionally, you may also check that the main app shell is not displayed
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('GoldFit app shows main screen when authenticated',
          (WidgetTester tester) async {
        // Create a mock user
        final mockUser = UserModel(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          provider: AuthProvider.email,
          emailVerified: true,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        // Create a mock auth repository with an authenticated user
        final mockAuthRepo = MockAuthRepository(currentUser: mockUser);

        // Build our app with authenticated user
        await tester.pumpWidget(GoldFitApp(
          authRepository: mockAuthRepo,
          analyticsRepository: MockAnalyticsRepository(),
          clothingRepository: MockClothingRepository(),
          outfitRepository: MockOutfitRepository(),
        ));

        // Wait for any async operations
        await tester.pumpAndSettle();

        // With authenticated user, we should see the main app shell
        // Note: This depends on what AppShell displays. You may need to adjust the expectation.
        // For now, we check that we don't see the auth screen
        expect(find.text('Welcome Back'), findsNothing);
        expect(find.text('Sign in to continue your journey'), findsNothing);
      });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository(currentUser: null);

    await tester.pumpWidget(GoldFitApp(
      authRepository: mockAuthRepo,
      analyticsRepository: MockAnalyticsRepository(),
      clothingRepository: MockClothingRepository(),
      outfitRepository: MockOutfitRepository(),
    ));

    await tester.pumpAndSettle();

    // Find the sign in button
    final signInButton = find.text('Sign In');
    expect(signInButton, findsOneWidget);

    // Try to submit without entering email
    await tester.tap(signInButton);
    await tester.pump();

    // Should show email validation error
    expect(find.text('Please enter your email'), findsOneWidget);

    // Enter invalid email
    final emailField = find.byType(TextField).first;
    await tester.enterText(emailField, 'invalid-email');
    await tester.tap(signInButton);
    await tester.pump();

    // Should show invalid email error
    expect(find.text('Enter a valid email'), findsOneWidget);

    // Enter valid email but empty password
    await tester.enterText(emailField, 'test@example.com');
    await tester.tap(signInButton);
    await tester.pump();

    // Should show password validation error
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Google Sign In button exists', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository(currentUser: null);

    await tester.pumpWidget(GoldFitApp(
      authRepository: mockAuthRepo,
      analyticsRepository: MockAnalyticsRepository(),
      clothingRepository: MockClothingRepository(),
      outfitRepository: MockOutfitRepository(),
    ));

    await tester.pumpAndSettle();

    // Check that Google Sign In button exists
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Toggle between login and register', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository(currentUser: null);

    await tester.pumpWidget(GoldFitApp(
      authRepository: mockAuthRepo,
      analyticsRepository: MockAnalyticsRepository(),
      clothingRepository: MockClothingRepository(),
      outfitRepository: MockOutfitRepository(),
    ));

    await tester.pumpAndSettle();

    // Initially shows login form
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsNothing);

    // Tap on "Sign Up" link
    final signUpLink = find.text('Sign Up');
    expect(signUpLink, findsOneWidget);
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    // Now shows register form
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);

    // Tap on "Sign In" link to go back
    final signInLink = find.text('Sign In');
    expect(signInLink, findsOneWidget);
    await tester.tap(signInLink);
    await tester.pumpAndSettle();

    // Back to login form
    expect(find.text('Sign In'), findsOneWidget);
  });
}