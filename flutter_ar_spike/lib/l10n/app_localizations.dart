import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appDel_game0.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get appDel_game0;

  /// No description provided for @appDel_game1.
  ///
  /// In en, this message translates to:
  /// **'Beginner Level'**
  String get appDel_game1;

  /// No description provided for @appDel_game2.
  ///
  /// In en, this message translates to:
  /// **'Normal Level'**
  String get appDel_game2;

  /// No description provided for @appDel_game3.
  ///
  /// In en, this message translates to:
  /// **'Senior Level'**
  String get appDel_game3;

  /// No description provided for @appDel_mandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory'**
  String get appDel_mandatory;

  /// No description provided for @appDel_option.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get appDel_option;

  /// No description provided for @ar_clear1.
  ///
  /// In en, this message translates to:
  /// **'Stealth discovery!'**
  String get ar_clear1;

  /// No description provided for @ar_clear2.
  ///
  /// In en, this message translates to:
  /// **'Stealth Radar needed!'**
  String get ar_clear2;

  /// No description provided for @ar_stealth_action.
  ///
  /// In en, this message translates to:
  /// **'Aim & approach to grab it'**
  String get ar_stealth_action;

  /// No description provided for @ar_stealth_attr.
  ///
  /// In en, this message translates to:
  /// **'Stealth'**
  String get ar_stealth_attr;

  /// No description provided for @ar_stealth_radar.
  ///
  /// In en, this message translates to:
  /// **'Stealth Radar'**
  String get ar_stealth_radar;

  /// No description provided for @ar_stealth_reveal.
  ///
  /// In en, this message translates to:
  /// **'shows range/bearing when acquired'**
  String get ar_stealth_reveal;

  /// No description provided for @ar_tip1.
  ///
  /// In en, this message translates to:
  /// **'The distance of closest item is displayed. In case of the item that has Stealth attribute, its distance will not be shown'**
  String get ar_tip1;

  /// No description provided for @ar_tip2.
  ///
  /// In en, this message translates to:
  /// **'It is the visibility range in which the item can be seen in AR screen. Only the item that is in the visibility range can be seen and won'**
  String get ar_tip2;

  /// No description provided for @ar_tip3.
  ///
  /// In en, this message translates to:
  /// **'Fit the hour hand(item direction) into the fan shape(phone direction). Item will be shown in AR screen once item comes into the visibility range. Shake to win!!!'**
  String get ar_tip3;

  /// No description provided for @builder_item_hint.
  ///
  /// In en, this message translates to:
  /// **' Item Touch:Setting, Item Drag:Move'**
  String get builder_item_hint;

  /// No description provided for @builer_list_pop1.
  ///
  /// In en, this message translates to:
  /// **'Modify or Test?'**
  String get builer_list_pop1;

  /// No description provided for @builer_list_pop2.
  ///
  /// In en, this message translates to:
  /// **'You can upload on the server if you can finish designed mission testing'**
  String get builer_list_pop2;

  /// No description provided for @builer_list_pop3.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get builer_list_pop3;

  /// No description provided for @builer_list_pop4.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get builer_list_pop4;

  /// No description provided for @builer_list_pop11.
  ///
  /// In en, this message translates to:
  /// **'Modify or Test?'**
  String get builer_list_pop11;

  /// No description provided for @builer_list_pop12.
  ///
  /// In en, this message translates to:
  /// **'You can upload on the server if you finished designed mission testing'**
  String get builer_list_pop12;

  /// No description provided for @builer_list_pop13.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get builer_list_pop13;

  /// No description provided for @builer_list_pop14.
  ///
  /// In en, this message translates to:
  /// **'Server upload'**
  String get builer_list_pop14;

  /// No description provided for @builer_list_title.
  ///
  /// In en, this message translates to:
  /// **'Mission Design'**
  String get builer_list_title;

  /// No description provided for @builer_word_0.
  ///
  /// In en, this message translates to:
  /// **'Basic Item Info'**
  String get builer_word_0;

  /// No description provided for @builer_word_1.
  ///
  /// In en, this message translates to:
  /// **'Item Type'**
  String get builer_word_1;

  /// No description provided for @builer_word_2.
  ///
  /// In en, this message translates to:
  /// **'Display Type?'**
  String get builer_word_2;

  /// No description provided for @builer_word_3.
  ///
  /// In en, this message translates to:
  /// **'Explosion Range'**
  String get builer_word_3;

  /// No description provided for @builer_word_4.
  ///
  /// In en, this message translates to:
  /// **'Hidden Item Range'**
  String get builer_word_4;

  /// No description provided for @builer_word_5.
  ///
  /// In en, this message translates to:
  /// **'Mandatory?'**
  String get builer_word_5;

  /// No description provided for @builer_word_6.
  ///
  /// In en, this message translates to:
  /// **'Display Type?'**
  String get builer_word_6;

  /// No description provided for @builer_word_7.
  ///
  /// In en, this message translates to:
  /// **'Visible Range'**
  String get builer_word_7;

  /// No description provided for @builer_word_8.
  ///
  /// In en, this message translates to:
  /// **'Additional Item Info'**
  String get builer_word_8;

  /// No description provided for @builer_word_9.
  ///
  /// In en, this message translates to:
  /// **'Charging Time'**
  String get builer_word_9;

  /// No description provided for @builer_word_10.
  ///
  /// In en, this message translates to:
  /// **'Initial Power'**
  String get builer_word_10;

  /// No description provided for @builer_word_11.
  ///
  /// In en, this message translates to:
  /// **'Run Start Number'**
  String get builer_word_11;

  /// No description provided for @builer_word_12.
  ///
  /// In en, this message translates to:
  /// **'Straight Distance'**
  String get builer_word_12;

  /// No description provided for @builer_word_13.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get builer_word_13;

  /// No description provided for @builer_word_14.
  ///
  /// In en, this message translates to:
  /// **'Enter instructions or a message.'**
  String get builer_word_14;

  /// No description provided for @builer_word_15.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get builer_word_15;

  /// No description provided for @builer_word_16.
  ///
  /// In en, this message translates to:
  /// **'Item Quiz'**
  String get builer_word_16;

  /// No description provided for @builer_word_17.
  ///
  /// In en, this message translates to:
  /// **'Enter a quiz question'**
  String get builer_word_17;

  /// No description provided for @builer_word_18.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get builer_word_18;

  /// No description provided for @builer_word_19.
  ///
  /// In en, this message translates to:
  /// **'Enter a quiz answer'**
  String get builer_word_19;

  /// No description provided for @builer_word_20.
  ///
  /// In en, this message translates to:
  /// **'The probability of (1 / additional times) will be applied during the mission play.'**
  String get builer_word_20;

  /// No description provided for @builer_word_21.
  ///
  /// In en, this message translates to:
  /// **'Add Quiz'**
  String get builer_word_21;

  /// No description provided for @builer_word_22.
  ///
  /// In en, this message translates to:
  /// **'Run Start Num'**
  String get builer_word_22;

  /// No description provided for @builer_word_23.
  ///
  /// In en, this message translates to:
  /// **'Enter a hint about Mission Quiz'**
  String get builer_word_23;

  /// No description provided for @builer_word_24.
  ///
  /// In en, this message translates to:
  /// **'Enter a message when Item acquired(option)'**
  String get builer_word_24;

  /// No description provided for @bulletin_title.
  ///
  /// In en, this message translates to:
  /// **'Badge List'**
  String get bulletin_title;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @data_check_message_0.
  ///
  /// In en, this message translates to:
  /// **'Enter a Mission title'**
  String get data_check_message_0;

  /// No description provided for @data_check_message_1.
  ///
  /// In en, this message translates to:
  /// **'Enter a mission description.'**
  String get data_check_message_1;

  /// No description provided for @data_check_message_2.
  ///
  /// In en, this message translates to:
  /// **'Enter a mission location that will be easily recognized by users. E.g. Disneyland, Lake Park, etc.'**
  String get data_check_message_2;

  /// No description provided for @data_check_message_2_0.
  ///
  /// In en, this message translates to:
  /// **'Set to the badge of Mission Symbol'**
  String get data_check_message_2_0;

  /// No description provided for @data_check_message_3.
  ///
  /// In en, this message translates to:
  /// **'Please set items on the map by tapping.\n Mission requires at least Start Item and End Item.'**
  String get data_check_message_3;

  /// No description provided for @data_check_message_4.
  ///
  /// In en, this message translates to:
  /// **'Mission must have exactly one Start item.'**
  String get data_check_message_4;

  /// No description provided for @data_check_message_5.
  ///
  /// In en, this message translates to:
  /// **'Touch the Run End item and \n Set Time Limit in the detail setup \n Please refer to the distance and set time limit.'**
  String get data_check_message_5;

  /// No description provided for @data_check_message_6.
  ///
  /// In en, this message translates to:
  /// **'Run Start and Run End items must be paired.'**
  String get data_check_message_6;

  /// No description provided for @data_check_message_7.
  ///
  /// In en, this message translates to:
  /// **'At least one Mandatory item is required.'**
  String get data_check_message_7;

  /// No description provided for @data_check_message_8.
  ///
  /// In en, this message translates to:
  /// **'Please set 1 End Item on the map by tapping'**
  String get data_check_message_8;

  /// No description provided for @data_check_message_9.
  ///
  /// In en, this message translates to:
  /// **'Mission requires a only one End Item \n Touch the End item and \n delete End Item in the detail setup'**
  String get data_check_message_9;

  /// No description provided for @data_check_message_10.
  ///
  /// In en, this message translates to:
  /// **'Touch the map and set Start Item \n Mission requires a one Start Item'**
  String get data_check_message_10;

  /// No description provided for @data_check_message_11.
  ///
  /// In en, this message translates to:
  /// **'Only one start item is needed that indicates the beginning of a mission. \n Delete the item after you choose it in the detail setup.'**
  String get data_check_message_11;

  /// No description provided for @data_check_message_12.
  ///
  /// In en, this message translates to:
  /// **'Touch the Quiz item and \n Enter detail setup and add your quiz questions'**
  String get data_check_message_12;

  /// No description provided for @data_check_message_13.
  ///
  /// In en, this message translates to:
  /// **'Touch the Quiz item and \n Add your quiz answer in the detail setup'**
  String get data_check_message_13;

  /// No description provided for @data_check_message_14.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got to add Stealth radar \n in case you\'ve added the item that has Stealth display attribute'**
  String get data_check_message_14;

  /// No description provided for @data_check_message_15.
  ///
  /// In en, this message translates to:
  /// **'configure suitable time to make the mission more interesting \n set up the time to more than 5 minutes'**
  String get data_check_message_15;

  /// No description provided for @data_check_message_16.
  ///
  /// In en, this message translates to:
  /// **'Mission time limit should be set to 5 minutes.'**
  String get data_check_message_16;

  /// No description provided for @data_check_title_0.
  ///
  /// In en, this message translates to:
  /// **'No Mission Title'**
  String get data_check_title_0;

  /// No description provided for @data_check_title_1.
  ///
  /// In en, this message translates to:
  /// **'No Mission Description'**
  String get data_check_title_1;

  /// No description provided for @data_check_title_2.
  ///
  /// In en, this message translates to:
  /// **'No Mission Place'**
  String get data_check_title_2;

  /// No description provided for @data_check_title_2_0.
  ///
  /// In en, this message translates to:
  /// **'No Badge'**
  String get data_check_title_2_0;

  /// No description provided for @data_check_title_3.
  ///
  /// In en, this message translates to:
  /// **'Set up more than 3 Items'**
  String get data_check_title_3;

  /// No description provided for @data_check_title_5.
  ///
  /// In en, this message translates to:
  /// **'No Run End time limit'**
  String get data_check_title_5;

  /// No description provided for @data_check_title_8.
  ///
  /// In en, this message translates to:
  /// **'No Set End item'**
  String get data_check_title_8;

  /// No description provided for @data_check_title_9_0.
  ///
  /// In en, this message translates to:
  /// **'End Item Number : {arg1}'**
  String data_check_title_9_0(int arg1);

  /// No description provided for @data_check_title_10.
  ///
  /// In en, this message translates to:
  /// **'No set Start Item'**
  String get data_check_title_10;

  /// No description provided for @data_check_title_11_0.
  ///
  /// In en, this message translates to:
  /// **'Start Item Number : {arg1}'**
  String data_check_title_11_0(int arg1);

  /// No description provided for @data_check_title_12.
  ///
  /// In en, this message translates to:
  /// **'No Quiz Item Questions'**
  String get data_check_title_12;

  /// No description provided for @data_check_title_13.
  ///
  /// In en, this message translates to:
  /// **'No Quiz Item Answer'**
  String get data_check_title_13;

  /// No description provided for @data_check_title_14.
  ///
  /// In en, this message translates to:
  /// **'No set Stealth Radar'**
  String get data_check_title_14;

  /// No description provided for @data_check_title_15.
  ///
  /// In en, this message translates to:
  /// **'No Mission Time Limit'**
  String get data_check_title_15;

  /// No description provided for @data_check_title_16.
  ///
  /// In en, this message translates to:
  /// **'Error Mission Time Limit'**
  String get data_check_title_16;

  /// No description provided for @data_message.
  ///
  /// In en, this message translates to:
  /// **'A quiz item requires at least one question.\n Enter a quiz question.'**
  String get data_message;

  /// No description provided for @data_title.
  ///
  /// In en, this message translates to:
  /// **'No Quiz Questions'**
  String get data_title;

  /// No description provided for @desig_badge.
  ///
  /// In en, this message translates to:
  /// **'Design Badge'**
  String get desig_badge;

  /// No description provided for @design_mission.
  ///
  /// In en, this message translates to:
  /// **'Designed Mission'**
  String get design_mission;

  /// No description provided for @detail_0.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get detail_0;

  /// No description provided for @detail_1.
  ///
  /// In en, this message translates to:
  /// **'An item has been added. Start again.'**
  String get detail_1;

  /// No description provided for @detail_2.
  ///
  /// In en, this message translates to:
  /// **'Mission not open'**
  String get detail_2;

  /// No description provided for @detail_3.
  ///
  /// In en, this message translates to:
  /// **'Mission has not been opened yet.'**
  String get detail_3;

  /// No description provided for @detail_5.
  ///
  /// In en, this message translates to:
  /// **'Virtual mode to be run from mission creation place. Real mode to be run from based on current location of the user. If you in virtual mode, depending on the terrain may be difficult to play.'**
  String get detail_5;

  /// No description provided for @detail_7.
  ///
  /// In en, this message translates to:
  /// **'continue'**
  String get detail_7;

  /// No description provided for @detail_8.
  ///
  /// In en, this message translates to:
  /// **'New start'**
  String get detail_8;

  /// No description provided for @detail_9.
  ///
  /// In en, this message translates to:
  /// **'Virtual Mode'**
  String get detail_9;

  /// No description provided for @detail_10.
  ///
  /// In en, this message translates to:
  /// **'Real Mode'**
  String get detail_10;

  /// No description provided for @detail_11.
  ///
  /// In en, this message translates to:
  /// **'More Information'**
  String get detail_11;

  /// No description provided for @detail_info_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Title'**
  String get detail_info_0;

  /// No description provided for @detail_info_1.
  ///
  /// In en, this message translates to:
  /// **'Mission Description'**
  String get detail_info_1;

  /// No description provided for @detail_info_2.
  ///
  /// In en, this message translates to:
  /// **'Mission Place'**
  String get detail_info_2;

  /// No description provided for @detail_info_3.
  ///
  /// In en, this message translates to:
  /// **'Best Record'**
  String get detail_info_3;

  /// No description provided for @detail_info_4.
  ///
  /// In en, this message translates to:
  /// **'Mission Play Record'**
  String get detail_info_4;

  /// No description provided for @detail_info_5.
  ///
  /// In en, this message translates to:
  /// **'Mission Create Date : {arg1}'**
  String detail_info_5(String arg1);

  /// No description provided for @detail_info_6.
  ///
  /// In en, this message translates to:
  /// **'My Play Time'**
  String get detail_info_6;

  /// No description provided for @detail_info_7.
  ///
  /// In en, this message translates to:
  /// **'Number of item in mission'**
  String get detail_info_7;

  /// No description provided for @detail_info_8.
  ///
  /// In en, this message translates to:
  /// **'Total : ({arg1}) Mandatory : ({arg2})'**
  String detail_info_8(int arg1, int arg2);

  /// No description provided for @detail_start.
  ///
  /// In en, this message translates to:
  /// **'Mission Start'**
  String get detail_start;

  /// No description provided for @fail_login.
  ///
  /// In en, this message translates to:
  /// **'Login Fail!'**
  String get fail_login;

  /// No description provided for @fail_login_message.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get fail_login_message;

  /// No description provided for @finish_time.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get finish_time;

  /// No description provided for @info_check_message_3.
  ///
  /// In en, this message translates to:
  /// **'Enter the correct mission answer'**
  String get info_check_message_3;

  /// No description provided for @info_check_title_3.
  ///
  /// In en, this message translates to:
  /// **'No Mission Quiz answers'**
  String get info_check_title_3;

  /// No description provided for @info_section_3.
  ///
  /// In en, this message translates to:
  /// **' You can play only where you \n created the mission if you are Virtual Mode off'**
  String get info_section_3;

  /// No description provided for @info_word_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Setup'**
  String get info_word_0;

  /// No description provided for @info_word_1.
  ///
  /// In en, this message translates to:
  /// **'Virtual Mode?'**
  String get info_word_1;

  /// No description provided for @info_word_2.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get info_word_2;

  /// No description provided for @info_word_3.
  ///
  /// In en, this message translates to:
  /// **'Mission Badge Setup'**
  String get info_word_3;

  /// No description provided for @info_word_4.
  ///
  /// In en, this message translates to:
  /// **'Set to the badge of Mission Symbol'**
  String get info_word_4;

  /// No description provided for @info_word_message_0.
  ///
  /// In en, this message translates to:
  /// **'Enter a mission Title.'**
  String get info_word_message_0;

  /// No description provided for @info_word_message_1.
  ///
  /// In en, this message translates to:
  /// **'Enter a detailed mission description.'**
  String get info_word_message_1;

  /// No description provided for @info_word_message_2.
  ///
  /// In en, this message translates to:
  /// **'Enter a place that can be easily recognized'**
  String get info_word_message_2;

  /// No description provided for @info_word_message_3.
  ///
  /// In en, this message translates to:
  /// **'Enter a mission quiz'**
  String get info_word_message_3;

  /// No description provided for @info_word_message_4.
  ///
  /// In en, this message translates to:
  /// **'Enter the correct mission answer'**
  String get info_word_message_4;

  /// No description provided for @info_word_title_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Title'**
  String get info_word_title_0;

  /// No description provided for @info_word_title_1.
  ///
  /// In en, this message translates to:
  /// **'Mission Description'**
  String get info_word_title_1;

  /// No description provided for @info_word_title_2.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get info_word_title_2;

  /// No description provided for @info_word_title_3.
  ///
  /// In en, this message translates to:
  /// **'Mission Quiz'**
  String get info_word_title_3;

  /// No description provided for @info_word_title_4.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get info_word_title_4;

  /// No description provided for @item_message.
  ///
  /// In en, this message translates to:
  /// **' Item  DisPlay  Visible Range'**
  String get item_message;

  /// No description provided for @locationDenied_msg.
  ///
  /// In en, this message translates to:
  /// **'Not available location services'**
  String get locationDenied_msg;

  /// No description provided for @locationDenied_title.
  ///
  /// In en, this message translates to:
  /// **'It cannot be used in case LBS is turned off.\n Turn on the Location Services in Iphone Setting.'**
  String get locationDenied_title;

  /// No description provided for @m_info_alert_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Title'**
  String get m_info_alert_0;

  /// No description provided for @m_info_alert_1.
  ///
  /// In en, this message translates to:
  /// **'Mission Description'**
  String get m_info_alert_1;

  /// No description provided for @m_info_alert_2.
  ///
  /// In en, this message translates to:
  /// **'Top time record'**
  String get m_info_alert_2;

  /// No description provided for @m_info_alert_3.
  ///
  /// In en, this message translates to:
  /// **'Mission Quiz'**
  String get m_info_alert_3;

  /// No description provided for @m_info_alert_4.
  ///
  /// In en, this message translates to:
  /// **'Quiz Hint'**
  String get m_info_alert_4;

  /// No description provided for @m_info_alert_5.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get m_info_alert_5;

  /// No description provided for @m_list_0.
  ///
  /// In en, this message translates to:
  /// **'Popular Mission'**
  String get m_list_0;

  /// No description provided for @m_list_1.
  ///
  /// In en, this message translates to:
  /// **'New Mission'**
  String get m_list_1;

  /// No description provided for @m_list_2.
  ///
  /// In en, this message translates to:
  /// **'Near Mission'**
  String get m_list_2;

  /// No description provided for @m_list_3.
  ///
  /// In en, this message translates to:
  /// **'Playing Mission List'**
  String get m_list_3;

  /// No description provided for @m_list_4.
  ///
  /// In en, this message translates to:
  /// **'Popular Mission List'**
  String get m_list_4;

  /// No description provided for @m_list_5.
  ///
  /// In en, this message translates to:
  /// **'New Mission List'**
  String get m_list_5;

  /// No description provided for @m_list_6.
  ///
  /// In en, this message translates to:
  /// **'Near Mission List'**
  String get m_list_6;

  /// No description provided for @mission_badge.
  ///
  /// In en, this message translates to:
  /// **'Mission Badge'**
  String get mission_badge;

  /// No description provided for @mission_complete.
  ///
  /// In en, this message translates to:
  /// **'[Mission Complete]'**
  String get mission_complete;

  /// No description provided for @mission_completed.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete!'**
  String get mission_completed;

  /// No description provided for @mission_info_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Title'**
  String get mission_info_0;

  /// No description provided for @mission_info_1.
  ///
  /// In en, this message translates to:
  /// **'Mission Description'**
  String get mission_info_1;

  /// No description provided for @mission_info_2.
  ///
  /// In en, this message translates to:
  /// **'Mission Information'**
  String get mission_info_2;

  /// No description provided for @mission_info_3.
  ///
  /// In en, this message translates to:
  /// **'Mission Quiz'**
  String get mission_info_3;

  /// No description provided for @mission_info_4.
  ///
  /// In en, this message translates to:
  /// **'Mission time limit'**
  String get mission_info_4;

  /// No description provided for @mission_info_5.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get mission_info_5;

  /// No description provided for @mission_info_6.
  ///
  /// In en, this message translates to:
  /// **'Inventory Items'**
  String get mission_info_6;

  /// No description provided for @mission_info_7.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get mission_info_7;

  /// No description provided for @mission_info_8.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get mission_info_8;

  /// No description provided for @mission_info_9.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get mission_info_9;

  /// No description provided for @mission_info_10.
  ///
  /// In en, this message translates to:
  /// **'Player Ranking'**
  String get mission_info_10;

  /// No description provided for @mission_play_0.
  ///
  /// In en, this message translates to:
  /// **'  Mine    Mandatory                  Hidden     Stealth'**
  String get mission_play_0;

  /// No description provided for @mission_play_1.
  ///
  /// In en, this message translates to:
  /// **' Run Time Limit:'**
  String get mission_play_1;

  /// No description provided for @mission_play_2.
  ///
  /// In en, this message translates to:
  /// **' Elapsed time:'**
  String get mission_play_2;

  /// No description provided for @mission_play_3.
  ///
  /// In en, this message translates to:
  /// **'Mission Failed!'**
  String get mission_play_3;

  /// No description provided for @mission_play_4.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get mission_play_4;

  /// No description provided for @mission_play_6.
  ///
  /// In en, this message translates to:
  /// **'Mine did not damage using Defense item'**
  String get mission_play_6;

  /// No description provided for @mission_play_7.
  ///
  /// In en, this message translates to:
  /// **'The most recently acquired {arg1} item has been lost.'**
  String mission_play_7(String arg1);

  /// No description provided for @mission_play_8.
  ///
  /// In en, this message translates to:
  /// **'A mine has exploded!'**
  String get mission_play_8;

  /// No description provided for @mission_play_9.
  ///
  /// In en, this message translates to:
  /// **'Run End Item Not Acquired!!'**
  String get mission_play_9;

  /// No description provided for @mission_play_10.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get mission_play_10;

  /// No description provided for @mission_play_button_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Exit'**
  String get mission_play_button_0;

  /// No description provided for @mission_play_button_1.
  ///
  /// In en, this message translates to:
  /// **'Buy Time Item'**
  String get mission_play_button_1;

  /// No description provided for @mission_play_button_2.
  ///
  /// In en, this message translates to:
  /// **'Time Increase'**
  String get mission_play_button_2;

  /// No description provided for @mission_play_exit_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the mission?'**
  String get mission_play_exit_message;

  /// No description provided for @mission_play_exit_title.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete'**
  String get mission_play_exit_title;

  /// No description provided for @mission_play_finish1.
  ///
  /// In en, this message translates to:
  /// **'Time Record: {arg1}'**
  String mission_play_finish1(String arg1);

  /// No description provided for @mission_play_finish2.
  ///
  /// In en, this message translates to:
  /// **'Congratulation!\n Please Rate the Mission.'**
  String get mission_play_finish2;

  /// No description provided for @mission_play_test1.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete!'**
  String get mission_play_test1;

  /// No description provided for @mission_play_test2.
  ///
  /// In en, this message translates to:
  /// **'Congratulation!\n Mission can be uploaded!'**
  String get mission_play_test2;

  /// No description provided for @mission_play_time_0.
  ///
  /// In en, this message translates to:
  /// **'Use time increase item'**
  String get mission_play_time_0;

  /// No description provided for @mission_play_time_1.
  ///
  /// In en, this message translates to:
  /// **'Do you want to use the time increase item? \n (you have {arg1} item)'**
  String mission_play_time_1(int arg1);

  /// No description provided for @mission_play_tip_1.
  ///
  /// In en, this message translates to:
  /// **'It displays the number of mines left.\n Mine item is not shown in map and AR screen'**
  String get mission_play_tip_1;

  /// No description provided for @mission_play_tip_2.
  ///
  /// In en, this message translates to:
  /// **'It displays the number of mandatory items left to complete the mission.'**
  String get mission_play_tip_2;

  /// No description provided for @mission_play_tip_3.
  ///
  /// In en, this message translates to:
  /// **'It displays the number of Transparent items which are not shown in map screen'**
  String get mission_play_tip_3;

  /// No description provided for @mission_play_tip_4.
  ///
  /// In en, this message translates to:
  /// **'It displays the number of Stealth items which are not shown in the Radar information in AR screen.'**
  String get mission_play_tip_4;

  /// No description provided for @mission_quiz.
  ///
  /// In en, this message translates to:
  /// **'Mission Quiz Open!'**
  String get mission_quiz;

  /// No description provided for @my_info_0.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get my_info_0;

  /// No description provided for @my_info_1.
  ///
  /// In en, this message translates to:
  /// **'Time increase'**
  String get my_info_1;

  /// No description provided for @my_info_2.
  ///
  /// In en, this message translates to:
  /// **'Quiz Solution'**
  String get my_info_2;

  /// No description provided for @my_info_3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}'**
  String my_info_3(int arg1);

  /// No description provided for @my_info_4.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get my_info_4;

  /// No description provided for @my_title.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get my_title;

  /// No description provided for @obtain_badge.
  ///
  /// In en, this message translates to:
  /// **'Badge acquired!'**
  String get obtain_badge;

  /// No description provided for @obtain_badge_fail.
  ///
  /// In en, this message translates to:
  /// **'Item acquisition conditions'**
  String get obtain_badge_fail;

  /// No description provided for @obtain_badge_fail_message_0.
  ///
  /// In en, this message translates to:
  /// **'You can collect Badge if you complete Mission'**
  String get obtain_badge_fail_message_0;

  /// No description provided for @obtain_badge_fail_message_2.
  ///
  /// In en, this message translates to:
  /// **'You can acquire Badge if you complete {arg1} Missions'**
  String obtain_badge_fail_message_2(int arg1);

  /// No description provided for @obtain_badge_fail_message_3.
  ///
  /// In en, this message translates to:
  /// **'You can acquire Badge if you design {arg1} Missions'**
  String obtain_badge_fail_message_3(int arg1);

  /// No description provided for @obtain_badge_success_message_0.
  ///
  /// In en, this message translates to:
  /// **'Mission Badge acquired.'**
  String get obtain_badge_success_message_0;

  /// No description provided for @obtain_badge_success_message_1.
  ///
  /// In en, this message translates to:
  /// **'Mission Play Badge acquired.'**
  String get obtain_badge_success_message_1;

  /// No description provided for @obtain_badge_success_message_2.
  ///
  /// In en, this message translates to:
  /// **'Mission Design Badge acquired..'**
  String get obtain_badge_success_message_2;

  /// No description provided for @obtain_correct.
  ///
  /// In en, this message translates to:
  /// **'Solution Item acquired!'**
  String get obtain_correct;

  /// No description provided for @obtain_correct_message.
  ///
  /// In en, this message translates to:
  /// **'You can get an answer \n if you win mission quiz or quiz item.'**
  String get obtain_correct_message;

  /// No description provided for @obtain_fail.
  ///
  /// In en, this message translates to:
  /// **'Item Not Acquired!'**
  String get obtain_fail;

  /// No description provided for @obtain_fail_message_0.
  ///
  /// In en, this message translates to:
  /// **'Run Start item has not been acquired.'**
  String get obtain_fail_message_0;

  /// No description provided for @obtain_fail_message_1.
  ///
  /// In en, this message translates to:
  /// **'This Run End is not available.\n Acquire other Run End items'**
  String get obtain_fail_message_1;

  /// No description provided for @obtain_fail_message_2.
  ///
  /// In en, this message translates to:
  /// **'obtain_fail_message_2'**
  String get obtain_fail_message_2;

  /// No description provided for @obtain_fail_message_3.
  ///
  /// In en, this message translates to:
  /// **'sec has passed'**
  String get obtain_fail_message_3;

  /// No description provided for @obtain_hint.
  ///
  /// In en, this message translates to:
  /// **'Hint Item acquired!'**
  String get obtain_hint;

  /// No description provided for @obtain_mine_nobomb.
  ///
  /// In en, this message translates to:
  /// **'the damage of Mine can be avoided if you win Defense item.'**
  String get obtain_mine_nobomb;

  /// No description provided for @obtain_no_hint.
  ///
  /// In en, this message translates to:
  /// **'Lose the draw!! No hint.'**
  String get obtain_no_hint;

  /// No description provided for @obtain_radar_ar.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see the distance and direction of the item that has Stealth attribute in Augmented Reality screen.'**
  String get obtain_radar_ar;

  /// No description provided for @obtain_radar_map.
  ///
  /// In en, this message translates to:
  /// **'It shows the item that has Hidden attribute in the map.'**
  String get obtain_radar_map;

  /// No description provided for @obtain_radar_mine.
  ///
  /// In en, this message translates to:
  /// **'It shows the exploding radius of Mine item in the map.'**
  String get obtain_radar_mine;

  /// No description provided for @obtain_random_fail.
  ///
  /// In en, this message translates to:
  /// **'Gambling Fail!'**
  String get obtain_random_fail;

  /// No description provided for @obtain_random_fail_message.
  ///
  /// In en, this message translates to:
  /// **'There are no item that can get by Gambling item. \n End item is not allowed to get by random winning'**
  String get obtain_random_fail_message;

  /// No description provided for @obtain_random_success.
  ///
  /// In en, this message translates to:
  /// **'Gambling acquired!'**
  String get obtain_random_success;

  /// No description provided for @obtain_random_success_message.
  ///
  /// In en, this message translates to:
  /// **'You can get one of the items \n that are not yet won at random'**
  String get obtain_random_success_message;

  /// No description provided for @obtain_run_record.
  ///
  /// In en, this message translates to:
  /// **'Time Record {arg1}'**
  String obtain_run_record(String arg1);

  /// No description provided for @obtain_run_start.
  ///
  /// In en, this message translates to:
  /// **'Run Start Item acquired!'**
  String get obtain_run_start;

  /// No description provided for @obtain_run_start_info.
  ///
  /// In en, this message translates to:
  /// **'Acquire Run End Item in time limit'**
  String get obtain_run_start_info;

  /// No description provided for @obtain_start_message.
  ///
  /// In en, this message translates to:
  /// **'If you touch OK, \n the item will be released Mission.'**
  String get obtain_start_message;

  /// No description provided for @obtain_success.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Item acquired!'**
  String obtain_success(String arg1);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get phone;

  /// No description provided for @play_badge.
  ///
  /// In en, this message translates to:
  /// **'Play Badge'**
  String get play_badge;

  /// No description provided for @play_mission.
  ///
  /// In en, this message translates to:
  /// **'Played Mission'**
  String get play_mission;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Preparing purchase..'**
  String get purchase;

  /// No description provided for @purchase_0.
  ///
  /// In en, this message translates to:
  /// **'Completing your purchase'**
  String get purchase_0;

  /// No description provided for @purchase_1.
  ///
  /// In en, this message translates to:
  /// **'Purchase has been completed.'**
  String get purchase_1;

  /// No description provided for @purchase_2.
  ///
  /// In en, this message translates to:
  /// **'Failure purchase'**
  String get purchase_2;

  /// No description provided for @purchase_3.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed.'**
  String get purchase_3;

  /// No description provided for @pwd_0.
  ///
  /// In en, this message translates to:
  /// **'Error mandatory field!'**
  String get pwd_0;

  /// No description provided for @pwd_1.
  ///
  /// In en, this message translates to:
  /// **'enter current password.'**
  String get pwd_1;

  /// No description provided for @pwd_2.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get pwd_2;

  /// No description provided for @pwd_3.
  ///
  /// In en, this message translates to:
  /// **'password mismatch!'**
  String get pwd_3;

  /// No description provided for @pwd_4.
  ///
  /// In en, this message translates to:
  /// **'password mismatch.'**
  String get pwd_4;

  /// No description provided for @pwd_5.
  ///
  /// In en, this message translates to:
  /// **'Error change password!'**
  String get pwd_5;

  /// No description provided for @pwd_6.
  ///
  /// In en, this message translates to:
  /// **'Try again later.'**
  String get pwd_6;

  /// No description provided for @pwd_7.
  ///
  /// In en, this message translates to:
  /// **'Change Success!'**
  String get pwd_7;

  /// No description provided for @pwd_8.
  ///
  /// In en, this message translates to:
  /// **'Use login.'**
  String get pwd_8;

  /// No description provided for @quiz_0.
  ///
  /// In en, this message translates to:
  /// **'Hint : [The number of letters:{arg1}]'**
  String quiz_0(int arg1);

  /// No description provided for @quiz_1.
  ///
  /// In en, this message translates to:
  /// **'Hint : [The number of letters:{arg1}][first letter:{arg2}]'**
  String quiz_1(int arg1, String arg2);

  /// No description provided for @quiz_2.
  ///
  /// In en, this message translates to:
  /// **'Use Solution!'**
  String get quiz_2;

  /// No description provided for @quiz_4.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get quiz_4;

  /// No description provided for @quiz_5.
  ///
  /// In en, this message translates to:
  /// **'That\'s Great!'**
  String get quiz_5;

  /// No description provided for @quiz_6.
  ///
  /// In en, this message translates to:
  /// **'Wrong Answer!'**
  String get quiz_6;

  /// No description provided for @quiz_7.
  ///
  /// In en, this message translates to:
  /// **'Would you like to challenge again? \n If you acquire an solution item you can know the answer!'**
  String get quiz_7;

  /// No description provided for @quiz_8.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get quiz_8;

  /// No description provided for @quiz_9.
  ///
  /// In en, this message translates to:
  /// **'Quiz : {arg1}'**
  String quiz_9(String arg1);

  /// No description provided for @quiz_10.
  ///
  /// In en, this message translates to:
  /// **'Try later.'**
  String get quiz_10;

  /// No description provided for @quiz_button_0.
  ///
  /// In en, this message translates to:
  /// **'Solution Item'**
  String get quiz_button_0;

  /// No description provided for @quiz_button_1.
  ///
  /// In en, this message translates to:
  /// **'Use Solution'**
  String get quiz_button_1;

  /// No description provided for @quiz_button_2.
  ///
  /// In en, this message translates to:
  /// **'Buy Solution'**
  String get quiz_button_2;

  /// No description provided for @quiz_message_0.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use Solution Item?'**
  String get quiz_message_0;

  /// No description provided for @quiz_message_1.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use a pay item? ({arg1} Items left)'**
  String quiz_message_1(int arg1);

  /// No description provided for @radius_of_visibility.
  ///
  /// In en, this message translates to:
  /// **'Visible range'**
  String get radius_of_visibility;

  /// No description provided for @save_fail.
  ///
  /// In en, this message translates to:
  /// **'Server Not Connected!'**
  String get save_fail;

  /// No description provided for @save_fail_message.
  ///
  /// In en, this message translates to:
  /// **'Try again this Mission!'**
  String get save_fail_message;

  /// No description provided for @setting_title0.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get setting_title0;

  /// No description provided for @setting_title1.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get setting_title1;

  /// No description provided for @setting_title2.
  ///
  /// In en, this message translates to:
  /// **'Send mail'**
  String get setting_title2;

  /// No description provided for @setting_title3.
  ///
  /// In en, this message translates to:
  /// **'Would you like to send mail \n for errors or Suggestions?'**
  String get setting_title3;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Congratulation!'**
  String get success;

  /// No description provided for @success_login.
  ///
  /// In en, this message translates to:
  /// **'Login Success!'**
  String get success_login;

  /// No description provided for @success_login_message.
  ///
  /// In en, this message translates to:
  /// **'You can use this service.'**
  String get success_login_message;

  /// No description provided for @success_message.
  ///
  /// In en, this message translates to:
  /// **'Game Passed!'**
  String get success_message;

  /// No description provided for @text_alert_0.
  ///
  /// In en, this message translates to:
  /// **'Please reply to Mission'**
  String get text_alert_0;

  /// No description provided for @user_id.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get user_id;

  /// No description provided for @user_reg_0.
  ///
  /// In en, this message translates to:
  /// **'Password Error!'**
  String get user_reg_0;

  /// No description provided for @user_reg_1.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mail address.'**
  String get user_reg_1;

  /// No description provided for @user_reg_2.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password at least 4 characters.'**
  String get user_reg_2;

  /// No description provided for @user_reg_3.
  ///
  /// In en, this message translates to:
  /// **'Password Error!'**
  String get user_reg_3;

  /// No description provided for @user_reg_4.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get user_reg_4;

  /// No description provided for @user_reg_5.
  ///
  /// In en, this message translates to:
  /// **'Registration Error!'**
  String get user_reg_5;

  /// No description provided for @user_reg_6.
  ///
  /// In en, this message translates to:
  /// **'Registration Complete!'**
  String get user_reg_6;

  /// No description provided for @user_reg_7.
  ///
  /// In en, this message translates to:
  /// **'Auto Login...'**
  String get user_reg_7;

  /// No description provided for @user_reg_8.
  ///
  /// In en, this message translates to:
  /// **'Mail Error!'**
  String get user_reg_8;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
