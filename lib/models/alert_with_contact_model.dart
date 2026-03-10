import 'alert_model.dart';

class AlertWithContact {
  final Alert alert;
  final String contactName;
  final String contactProfilePic;
  final String contactPhone;

  AlertWithContact({
    required this.alert,
    required this.contactName,
    required this.contactProfilePic,
    required this.contactPhone,
  });
}
