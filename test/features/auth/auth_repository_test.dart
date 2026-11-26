import 'package:ecotrash/features/auth/data/repositories/local_auth_repository.dart';
import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalAuthRepository.resetInMemory();
  });

  test('register, restore session, sign in, and sign out', () async {
    final repository = LocalAuthRepository(inMemory: true);
    final registeredUser = await repository.register(
      name: 'Kesha Faryl',
      email: 'Kesha@example.com',
      password: 'sampah123',
    );

    expect(registeredUser.name, 'Kesha Faryl');
    expect(registeredUser.email, 'kesha@example.com');

    final restartedRepository = LocalAuthRepository(inMemory: true);
    final restoredUser = await restartedRepository.getCurrentUser();
    expect(restoredUser?.id, registeredUser.id);
    expect(restoredUser?.name, registeredUser.name);

    await restartedRepository.signOut();
    expect(await restartedRepository.getCurrentUser(), isNull);

    final signedInUser = await repository.signIn(
      email: 'KESHA@example.com',
      password: 'sampah123',
    );
    expect(signedInUser.id, registeredUser.id);
  });

  test('rejects duplicate email and invalid credentials', () async {
    final repository = LocalAuthRepository(inMemory: true);
    await repository.register(
      name: 'Dina',
      email: 'dina@example.com',
      password: 'pilahsampah1',
    );

    await expectLater(
      repository.register(
        name: 'Dina Baru',
        email: 'DINA@example.com',
        password: 'pilahsampah1',
      ),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      repository.signIn(email: 'dina@example.com', password: 'salah123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('updates the display name in the persisted session', () async {
    final repository = LocalAuthRepository(inMemory: true);
    await repository.register(
      name: 'Kesha',
      email: 'kesha@example.com',
      password: 'sampah123',
    );

    final updated = await repository.updateDisplayName('Kesha Faryl');

    expect(updated.name, 'Kesha Faryl');
    expect((await repository.getCurrentUser())?.name, 'Kesha Faryl');
  });

  test('normalizes phone numbers and signs in with a phone account', () async {
    final repository = LocalAuthRepository(inMemory: true);
    await repository.register(
      name: 'Dina Telepon',
      phone: '081234567890',
      password: 'sampah123',
    );
    final signedIn = await repository.signIn(
      phone: '62 81234567890',
      password: 'sampah123',
    );
    expect(signedIn.phone, '+6281234567890');
  });

  test('locks an account after five wrong passwords', () async {
    final repository = LocalAuthRepository(inMemory: true);
    await repository.register(
      name: 'Kunci Akun',
      email: 'kunci@example.com',
      password: 'sampah123',
    );
    for (var i = 0; i < 5; i++) {
      await expectLater(
        repository.signIn(
          email: 'kunci@example.com',
          password: 'passwordsalah1',
        ),
        throwsA(isA<AuthException>()),
      );
    }
    await expectLater(
      repository.signIn(email: 'kunci@example.com', password: 'sampah123'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('Terlalu banyak percobaan'),
        ),
      ),
    );
  });
}
