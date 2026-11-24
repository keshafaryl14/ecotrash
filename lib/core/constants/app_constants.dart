abstract final class AppConstants {
  static const appName = 'EcoTrash';
}

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const scan = '/scan';
  static const scanResult = '/scan/result';
  static const map = '/map';
  static const bankDetail = '/map/bank/:id';
  static const pickup = '/pickup';
  static const pickupNew = '/pickup/new';
  static const pickupDetail = '/pickup/:id';
  static const rewards = '/rewards';
  static const rewardVouchers = '/rewards/vouchers';
  static const education = '/education';
  static const profile = '/profile';
}

abstract final class AppStorageKeys {
  static const onboardingCompleted = 'onboarding_completed';
  static const authUserId = 'auth_user_id';
  static const authUserName = 'auth_user_name';
  static const authUserEmail = 'auth_user_email';
}
