import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class RegistrationUsernameField extends StatelessWidget {
  const RegistrationUsernameField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(AppStrings.username, style: AppTextStyles.bodyMedium),
            SizedBox(height: 8.h),
            TextFormField(
              initialValue: state.data.username,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: AppStrings.usernameHint,
              ),
              onChanged: (String value) {
                context.read<RegistrationBloc>().add(
                  RegistrationUsernameChanged(username: value),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
