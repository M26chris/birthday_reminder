import 'package:birthday_reminder/helpers/birthday.dart';
import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:birthday_reminder/layouts/birthday_form_view.dart';
import 'package:birthday_reminder/layouts/bottom_popup.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/widgets/confirm_dialog.dart';
import 'package:birthday_reminder/widgets/share_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BirthdayView extends StatefulWidget {
  const BirthdayView({
    super.key,
    required this.birthday,
  });

  final Birthday birthday;

  @override
  State<BirthdayView> createState() => _BirthdayViewState();
}

class _BirthdayViewState extends State<BirthdayView> {
  BirthdayFormData? data;
  int resetId = 0;

  void setInitialData() {
    data = BirthdayFormData(
      name: widget.birthday.personName,
      day: widget.birthday.birth.day,
      month: widget.birthday.birth.month,
      year: widget.birthday.noYear ? 0 : widget.birthday.birth.year,
      notes: widget.birthday.notes,
      notificationHour: widget.birthday.notificationHour,
      notificationMinute: widget.birthday.notificationMinute,
    );
  }

  @override
  void initState() {
    setInitialData();
    super.initState();
  }

  void resetData() {
    setState(() {
      resetId = resetId == 1 ? 0 : 1;
      setInitialData();
    });
  }

  bool get somethingChanged {
    final year = widget.birthday.noYear ? 0 : widget.birthday.birth.year;
    if (widget.birthday.personName != data?.name) return true;
    if (widget.birthday.birth.day != data?.day) return true;
    if (widget.birthday.birth.month != data?.month) return true;
    if (year != data?.year) return true;
    if (widget.birthday.notes != data?.notes) return true;
    if (widget.birthday.notificationHour != data?.notificationHour) return true;
    if (widget.birthday.notificationMinute != data?.notificationMinute) return true;
    return false;
  }

  Future<void> save() async {
    final data = this.data;
    if (data == null) return;

    final noYear = data.year == 0;
    final birthDate = DateTime(
        noYear ? 2000 : data.year, data.month, data.day);

    await FirebaseFirestore.instance
        .collection('birthdays')
        .doc(widget.birthday.id)
        .update({
      'birth': birthDate,
      'noYear': noYear,
      'notes': data.notes,
      'owner': FirebaseAuth.instance.currentUser!.uid,
      'personName': data.name,
      'notif_hour': data.notificationHour,
      'notif_minute': data.notificationMinute,
      'app_version': '2.0.0',
      'updated_at': DateTime.now(),
    });

    // Reschedule local notification with the updated time
    final updatedBirthday = widget.birthday.copyWith(
      personName: data.name,
      birth: birthDate,
      noYear: noYear,
      notes: data.notes,
      notificationHour: data.notificationHour,
      notificationMinute: data.notificationMinute,
    );

    await BirthdayNotificationManager()
        .cancelBirthdayNotification(widget.birthday.id);
    await BirthdayNotificationManager()
        .scheduleBirthdayNotification(updatedBirthday);
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return WillPopScope(
      onWillPop: () async {
        if (somethingChanged) return false;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(somethingChanged
              ? strings.editing
              : (data?.name ?? widget.birthday.personName)),
          actions: [
            IconButton(
              onPressed: () async {
                final name = data?.name ?? widget.birthday.personName;
                final result = await confirm(
                  context,
                  onInput: (result) {},
                  title: Text(strings.are_you_sure),
                  content: Text(
                      "This will permanently delete $name's birthday."),
                );

                if (result) {
                  await FirebaseFirestore.instance
                      .collection('birthdays')
                      .doc(widget.birthday.id)
                      .delete();
                  // Cancel the local notification too
                  await BirthdayNotificationManager()
                      .cancelBirthdayNotification(widget.birthday.id);
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_rounded),
            ),
          ],
          leading: somethingChanged ? const Icon(Icons.edit) : null,
        ),
        primary: true,
        body: data != null
            ? BirthdayFormView(
                key: Key('reset-$resetId'),
                data: data!,
                onDataChange: (data) {
                  setState(() {
                    this.data = data;
                  });
                },
              )
            : null,
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (i) {
            if (somethingChanged) {
              if (i == 0) {
                resetData();
              } else if (i == 1) {
                Navigator.of(context).pop();
                save().catchError((error) {
                  if (!mounted) return;
                  confirm(
                    context,
                    title: Text(strings.error_ocurred),
                    acceptOnly: true,
                    onInput: (result) {},
                    content: Text(
                        "Couldn't save this birthday. Please try again.${kDebugMode ? '\n\n$error' : ''}"),
                  );
                });
              }
            } else {
              if (i == 0) {
                showShareModal(context, widget.birthday);
              } else if (i == 1) {
                Navigator.of(context).pop();
              }
            }
          },
          selectedIndex: somethingChanged ? 1 : 0,
          destinations: [
            NavigationDestination(
              icon: Icon(somethingChanged ? Icons.cancel : Icons.share),
              label: somethingChanged ? strings.cancel : strings.share,
            ),
            NavigationDestination(
              icon: Icon(somethingChanged ? Icons.save : Icons.close),
              label: somethingChanged ? strings.save : strings.close,
            ),
          ],
        ),
      ),
    );
  }
}

void showBirthdayView(BuildContext context, {required Birthday birthday}) {
  Navigator.of(context).push(
    BottomPopupRoute(
      height: 600,
      builder: (context) => BirthdayView(birthday: birthday),
    ),
  );
}
