import 'package:flutter_test/flutter_test.dart';
import 'package:keystone_mobile/core/auth/route_guard.dart';
import 'package:keystone_mobile/core/auth/user_role.dart';

void main() {
  group('route_guard', () {
    test('employee peut accéder à son espace uniquement', () {
      expect(roleCanAccess(UserRole.employee, '/home'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/tasks'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/tasks/5/status'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/tickets/mine'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/tickets/new'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/tickets/12'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/module/learning'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/leaves/mine'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/leaves/new'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/meetings/new'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/meetings/12'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/notifications'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/profile/settings'), isTrue);
      expect(roleCanAccess(UserRole.employee, '/admin/tasks'), isFalse);
      expect(roleCanAccess(UserRole.employee, '/itsupport/tickets'), isFalse);
      expect(roleCanAccess(UserRole.employee, '/hr/leaves'), isFalse);
      expect(roleCanAccess(UserRole.employee, '/admin/meetings'), isFalse);
      expect(roleCanAccess(UserRole.employee, '/admin/rooms'), isFalse);
    });

    test('admin peut accéder au back-office et aux tickets', () {
      expect(roleCanAccess(UserRole.admin, '/home'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/admin/tasks'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/admin/tasks/8/status'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/itsupport/tickets'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/tickets/8'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/module/employees'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/hr/leaves'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/hr/employees'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/notifications'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/profile/settings'), isTrue);
      expect(roleCanAccess(UserRole.admin, '/tasks'), isFalse);
    });

    test('manager accède aux tâches admin mais pas aux tickets', () {
      expect(roleCanAccess(UserRole.manager, '/admin/tasks'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/module/meetings'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/admin/meetings'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/admin/rooms'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/notifications'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/profile/settings'), isTrue);
      expect(roleCanAccess(UserRole.manager, '/tickets/mine'), isFalse);
      expect(roleCanAccess(UserRole.manager, '/itsupport/tickets'), isFalse);
      expect(roleCanAccess(UserRole.manager, '/tasks'), isFalse);
    });

    test('hr accède aux placeholders mais pas aux modules métiers', () {
      expect(roleCanAccess(UserRole.hr, '/home'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/module/employees'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/module/leaves'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/hr/leaves'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/hr/employees'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/notifications'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/profile/settings'), isTrue);
      expect(roleCanAccess(UserRole.hr, '/tasks'), isFalse);
      expect(roleCanAccess(UserRole.hr, '/admin/tasks'), isFalse);
      expect(roleCanAccess(UserRole.hr, '/itsupport/tickets'), isFalse);
    });

    test('itsupport accède aux tickets et aux placeholders', () {
      expect(roleCanAccess(UserRole.itsupport, '/home'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/itsupport/tickets'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/tickets/8'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/module/tickets'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/notifications'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/profile/settings'), isTrue);
      expect(roleCanAccess(UserRole.itsupport, '/tasks'), isFalse);
      expect(roleCanAccess(UserRole.itsupport, '/admin/tasks'), isFalse);
    });
  });

  group('highestPriorityRole', () {
    test('priorité admin > manager > hr > itsupport > employee', () {
      expect(
        highestPriorityRole(const <String>['employee', 'itsupport']),
        UserRole.itsupport,
      );
      expect(
        highestPriorityRole(const <String>['employee', 'itsupport', 'admin']),
        UserRole.admin,
      );
      expect(highestPriorityRole(const <String>['employee']), UserRole.employee);
      expect(highestPriorityRole(const <String>['manager', 'hr']), UserRole.manager);
      expect(highestPriorityRole(const <String>[]), UserRole.employee);
    });
  });
}
