import 'dart:async';
import 'dart:io';

import 'package:Openbook/provider.dart';
import 'package:Openbook/pages/auth/create_account/blocs/create_account.dart';
import 'package:Openbook/services/localization.dart';
import 'package:Openbook/widgets/buttons/primary-button.dart';
import 'package:Openbook/widgets/buttons/secondary-button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AuthAvatarStepPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AuthAvatarStepPageState();
  }
}

class AuthAvatarStepPageState extends State<AuthAvatarStepPage> {
  File _avatarImage;

  bool isSubmitted;
  bool isBootstrapped;

  CreateAccountBloc createAccountBloc;
  LocalizationService localizationService;

  @override
  void initState() {
    isBootstrapped = false;
    isSubmitted = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var openbookProvider = OpenbookProvider.of(context);
    localizationService = openbookProvider.localizationService;
    createAccountBloc = openbookProvider.createAccountBloc;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: <Widget>[
                    _buildWhatYourAvatar(context: context),
                    SizedBox(
                      height: 20.0,
                    ),
                    _buildAvatarPicker(),
                    SizedBox(
                      height: 20.0,
                    ),
                    _buildAvatarError()
                  ],
                ))),
      ),
      backgroundColor: Color(0xFFFFBF39),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _buildPreviousButton(context: context),
              ),
              Expanded(child: _buildNextButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarError() {
    return StreamBuilder(
      stream: createAccountBloc.avatarFeedback,
      initialData: null,
      builder: (context, snapshot) {
        String feedback = snapshot.data;
        if (feedback == null || !isSubmitted) {
          return Container();
        }

        return Container(
          child: Text(
            feedback,
            style: TextStyle(color: Colors.white, fontSize: 18.0),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    String buttonText = localizationService.trans('AUTH.CREATE_ACC.NEXT');

    return StreamBuilder(
      stream: createAccountBloc.avatarIsValid,
      initialData: false,
      builder: (context, snapshot) {
        bool avatarIsValid = snapshot.data;

        Function onPressed;

        if (avatarIsValid) {
          onPressed = () {
            Navigator.pushNamed(context, '/auth/done_step');
          };
        } else {
          onPressed = () {
            setState(() {
              //createAccountBloc.avatar.add(null);
              isSubmitted = true;
            });
          };
        }

        return OBPrimaryButton(
          isFullWidth: true,
          isLarge: true,
          child: Text(buttonText, style: TextStyle(fontSize: 18.0)),
          onPressed: onPressed,
        );
      },
    );
  }

  Widget _buildPreviousButton({@required BuildContext context}) {
    String buttonText = localizationService.trans('AUTH.CREATE_ACC.PREVIOUS');

    return OBSecondaryButton(
      isFullWidth: true,
      isLarge: true,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          SizedBox(
            width: 10.0,
          ),
          Text(
            buttonText,
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          )
        ],
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildWhatYourAvatar({@required BuildContext context}) {
    String whatAvatarText =
        localizationService.trans('AUTH.CREATE_ACC.WHAT_AVATAR');

    return Column(
      children: <Widget>[
        Text(whatAvatarText,
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildAvatarPicker() {
    // If we use StreamBuilder to build the TexField it has a weird
    // bug which places the cursor at the beginning of the label everytime
    // the stream changes. Therefore a flag is used to bootstrap initial value

    if (!isBootstrapped && createAccountBloc.hasAvatar()) {
      //_avatarController.text = createAccountBloc.getAvatar();
      //isBootstrapped = true;
    }

    return GestureDetector(
      onTap: () async {
        File image = await _getUserImage();
        createAccountBloc.avatar.add(image);
      },
      child: Column(
        children: <Widget>[
          Container(
            height: 150.0,
            width: 150.0,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
            child: StreamBuilder(
                stream: createAccountBloc.validatedAvatar,
                initialData: null,
                builder: (context, snapshot) {
                  var data = snapshot.data;

                  if(data == null){
                    return Image.asset('assets/images/avatar.png');
                  }

                  return Image.file(snapshot.data);
                }),
          ),
          SizedBox(height: 20.0),
          Text(
            'Tap to change',
            style: TextStyle(color: Colors.white, fontSize: 18.0),
          )
        ],
      ),
    );
  }

  Future<File> _getUserImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    return image;
  }
}
