import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../models/party_model.dart';
import 'my_room_card.dart';

class MyRoomsSection extends StatelessWidget {
  const MyRoomsSection({
    required this.title,
    required this.parties,
    required this.isCreatedSection,
    super.key,
  });

  final String title;
  final List<PartyModel> parties;
  final bool isCreatedSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 21.sp)),
        SizedBox(height: 10.h),
        ...parties.map(
          (PartyModel party) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: MyRoomCard(
              party: party,
              isCreatedRoom: isCreatedSection,
              onOpen: () {
                context.push(AppRoutes.partyDetailsPath(party.id));
              },
            ),
          ),
        ),
      ],
    );
  }
}
