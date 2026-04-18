import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

// Auth State
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth Service
class AuthService extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  static const _storage = FlutterSecureStorage();

  AuthService(this._apiService, this._storageService)
      : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _storage.read(key: 'auth_token');
      final userData = await _storageService.getUser();

      if (token != null && userData != null) {
        _apiService.setAuthToken(token);
        state = state.copyWith(
          user: userData,
          token: token,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل بيانات المستخدم',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final token = response.data['data']['token'];

        final user = User.fromJson(userData);

        // Store token and user data
        await _storage.write(key: 'auth_token', value: token);
        await _storageService.saveUser(user);

        // Set token for future API calls
        _apiService.setAuthToken(token);

        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'فشل في تسجيل الدخول',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';

      if (e.response?.statusCode == 401) {
        errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.response?.statusCode == 422) {
        errorMessage = 'البيانات المدخلة غير صحيحة';
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? nationalId,
    String? qiraat,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'national_id': nationalId,
        'qiraat': qiraat,
        'gender': gender,
      });

      if (response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final token = response.data['data']['token'];

        final user = User.fromJson(userData);

        // Store token and user data
        await _storage.write(key: 'auth_token', value: token);
        await _storageService.saveUser(user);

        // Set token for future API calls
        _apiService.setAuthToken(token);

        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'فشل في إنشاء الحساب',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';

      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Don't modify auth state during password change
    final currentState = state;

    try {
      final response = await _apiService.put('/change-password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });

      if (response.data['success'] == true) {
        // Password changed successfully - keep user logged in
        // Just clear any error and keep everything else
        state = currentState.copyWith(error: null);
        return true;
      } else {
        state = currentState.copyWith(
          error: response.data['message'] ?? 'فشل في تغيير كلمة المرور',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';

      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        } else {
          errorMessage =
              e.response?.data['message'] ?? 'كلمة المرور الحالية غير صحيحة';
        }
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      state = currentState.copyWith(error: errorMessage);
      return false;
    } catch (e) {
      state = currentState.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Call logout API if token exists
      if (state.token != null) {
        await _apiService.post('/logout');
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear local storage
    await _storage.delete(key: 'auth_token');
    await _storageService.clearUser();

    // Clear API token
    _apiService.clearAuthToken();

    state = const AuthState();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? qiraat,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.put('/profile', data: {
        'name': name ?? state.user!.name,
        'phone': phone ?? state.user!.phone,
        'qiraat': qiraat ?? state.user!.qiraat,
      });

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final updatedUser = User.fromJson(userData);

        await _storageService.saveUser(updatedUser);

        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'فشل في تحديث الملف الشخصي',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';

      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authServiceProvider =
    StateNotifierProvider<AuthService, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(apiService, storageService);
});
