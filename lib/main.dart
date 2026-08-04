import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env ဖိုင်ကို ဖတ်ရန်
  await dotenv.load(fileName: ".env");

  // .env ထဲမှ URL နှင့် Key ကို ဆွဲယူခြင်း
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const TeacherMatchApp());
}

final supabase = Supabase.instance.client;

// Base64 Code များကို ပုံအဖြစ် ပြန်ပြောင်းပေးမည့် Helper Function
ImageProvider? getImgProv(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  if (url.startsWith('http')) return NetworkImage(url);
  if (url.startsWith('data:image')) {
    try {
      return MemoryImage(base64Decode(url.split(',').last));
    } catch (e) {
      return null;
    }
  }
  return null;
}

class TeacherMatchApp extends StatelessWidget {
  const TeacherMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A4B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// =========================================================================
// 1. HOME SCREEN (ပင်မစာမျက်နှာ)
// =========================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    checkForUpdate();
  }

  // ၁။ Update စစ်မယ့် Function
  Future<void> checkForUpdate({bool isManualCheck = false}) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await Supabase.instance.client
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      String latestVersion = response['version_number'];
      String downloadUrl = response['download_url'];

      if (currentVersion != latestVersion) {
        if (mounted) {
          // Version အဟောင်းနဲ့ အသစ်ပါ Dialog ထံ ပို့ပေးပါမည်
          showUpdateDialog(downloadUrl, currentVersion, latestVersion);
        }
      } else {
        if (isManualCheck && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("နောက်ဆုံး Version ဖြစ်နေပါပြီဗျ")),
          );
        }
      }
    } catch (e) {
      debugPrint("Update စစ်တဲ့အခါ Error တက်နေပါတယ်: $e");
    }
  }

  // ၂။ Noti Box ပြမယ့် Function (Size ကို ကျစ်ကျစ်လစ်လစ်ဖြစ်အောင် ပြင်ထားပါသည်)
  // ၂။ Noti Box ပြမယ့် Function (Dynamic Version ပါဝင်အောင် ပြင်ဆင်ထားပါသည်)
  void showUpdateDialog(String url, String currentVer, String latestVer) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.system_update,
                          color: Color(0xFF00796B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Update App",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A4B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ဒီနေရာမှာ Version စာသားများ အလိုအလျောက် လိုက်ပြောင်းသွားပါမည်
                  Text(
                    "ယခုအသုံးပြုနေသော ဗားရှင်းမှာ V $currentVer ဖြစ်ပါသည်။\n\nဗားရှင်းအသစ် (V $latestVer) ထွက်ရှိနေပါပြီ။ ပိုကောင်းမွန်သော စနစ်များကို အသုံးပြုနိုင်ရန် အောက်ပါခလုတ်ကို နှိပ်၍ ဆက်လက် ဒေါင်းလုဒ်ရယူနိုင်ပါသည်။",
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "ပိတ်မည်",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final Uri downloadUri = Uri.parse(url);
                          if (await canLaunchUrl(downloadUri)) {
                            await launchUrl(
                              downloadUri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text(
                          "ဒေါင်းလုဒ်ဆွဲမည်",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Teacher Match',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'ပင်မစာမျက်နှာ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A4B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Teacher Match ဆရာရှာဖွေရေး\nAgency မှ ကြိုဆိုပါတယ်',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Top Buttons
                Row(
                  children: [
                    Expanded(
                      child: _btn(
                        context,
                        Icons.school,
                        "Teacher",
                        const Color(0xFFC5E1A5),
                        () => _nav(context, const TeacherScreen()),
                        height: 90,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn(
                        context,
                        Icons.person,
                        "Student",
                        const Color(0xFFEF9A9A),
                        () => _nav(context, const StudentScreen()),
                        height: 90,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn(
                        context,
                        Icons.settings,
                        "Admin",
                        const Color(0xFFCE93D8),
                        () => _nav(context, const AdminScreen()),
                        height: 90,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mid Buttons
                Row(
                  children: [
                    Expanded(
                      child: _btn(
                        context,
                        Icons.shield,
                        "Black List",
                        const Color(0xFF9FA8DA),
                        () => _nav(context, const BlacklistScreen()),
                        height: 75,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn(
                        context,
                        Icons.help_outline,
                        "Help\nSupport & FAQ",
                        const Color(0xFF90CAF9),
                        () => _nav(context, const HelpSupportScreen()),
                        height: 75,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Term & Condition
                _btn(
                  context,
                  Icons.assignment,
                  "Term & Condition",
                  const Color(0xFFA5D6A7),
                  () => _nav(context, const TermsScreen()),
                  width: double.infinity,
                  height: 60,
                ),
                const SizedBox(height: 6),
                const Text(
                  'အသုံးမပြုမီ Term & Condition ကို အရင်ဖတ်ပေးပါ',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // User Guides
                Row(
                  children: [
                    Expanded(
                      child: _btn(
                        context,
                        Icons.menu_book,
                        "Teacher\nUserGuide",
                        const Color(0xFF90CAF9),
                        () => _nav(context, const TeacherGuideScreen()),
                        height: 75,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn(
                        context,
                        Icons.menu_book,
                        "Student\nUserGuide",
                        const Color(0xFFFFCCBC),
                        () => _nav(context, const StudentGuideScreen()),
                        height: 75,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Update APP Button
                _btn(
                  context,
                  Icons.download,
                  "Update APP",
                  const Color(0xFF00796B),
                  () => checkForUpdate(isManualCheck: true),
                  width: double.infinity,
                  height: 50,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),

                const Text(
                  "V 1.0.0",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Powered by Saw Yan Aung",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    String text,
    Color bgColor,
    VoidCallback onTap, {
    double height = 80,
    double? width,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 2. TEACHER SCREEN
// =========================================================================
class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int? loggedInTutorId;
  bool isRegisterView = false;
  bool isEditMode = false;
  int activeTab = 0;
  // ၁။ လျှောက်ထားပြီးပြီလား Supabase မှာ စစ်ပေးမည့် Function
  Future<bool> checkIfAlreadyApplied(int jobId, int? tutorId) async {
    if (tutorId == null) return false;
    try {
      final response = await Supabase.instance.client
          .from('job_applications')
          .select()
          .eq('job_id', jobId)
          .eq('tutor_id', tutorId);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking application: $e");
      return false;
    }
  }

  // ၂။ "လျှောက်ထားမည်" နှိပ်ရင် Supabase ထဲ သွားထည့်မည့် Function
  Future<void> applyJob(int jobId, int? tutorId) async {
    if (tutorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ကျေးဇူးပြု၍ အရင်ဆုံး Login ဝင်ပေးပါဗျ'),
          ),
        );
      }
      return;
    }
    try {
      await Supabase.instance.client.from('job_applications').insert({
        'job_id': jobId,
        'tutor_id': tutorId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {}); // UI ကို အလိုအလျောက် ပြောင်းလဲပေးရန်

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('လျှောက်ထားမှု အဆင်ပြေပါသည်')),
        );
      }
    } catch (e) {
      debugPrint("Error applying job: $e");
    }
  }

  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final regUserCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final townCtrl = TextEditingController();
  final feeCtrl = TextEditingController();
  final remCtrl = TextEditingController();

  final s1Ctrl = TextEditingController();
  final s2Ctrl = TextEditingController();
  final s3Ctrl = TextEditingController();
  final s4Ctrl = TextEditingController();

  String gender = 'Male';
  String stateVal = 'ရန်ကုန်တိုင်းဒေသကြီး';
  String currVal = 'Government';
  String modeVal = 'Online';
  String daysVal = 'နေ့တိုင်း';
  String timeVal = 'မနက်';

  String? g1Val, g2Val, g3Val, g4Val;
  String? photoUrl;
  String authMsg = '';
  String statusMsg = '';
  final chatMsgCtrl = TextEditingController();

  final List<String> grades = [
    "မူလတန်း / Primary",
    "အလယ်တန်း / Middle",
    "အထက်တန်း/ Hight",
    "IGCSE",
    "GED",
    "အခြား",
  ];
  final List<String> states = [
    "ရန်ကုန်တိုင်းဒေသကြီး",
    "မန္တလေးတိုင်းဒေသကြီး",
    "ပဲခူးတိုင်းဒေသကြီး",
    "နေပြည်တော်",
  ];

  Future<void> pickAndUploadPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      // ပုံအရွယ်အစားကို ချုံ့ရန် imageQuality: 25 ကို သုံးထားပါသည်
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
      );

      if (image != null) {
        final fileBytes = await image.readAsBytes();
        final base64Image = base64Encode(fileBytes);
        final ext = image.name.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
        final dataUri = 'data:image/$ext;base64,$base64Image';

        setState(() => photoUrl = dataUri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ဓာတ်ပုံရွေးချယ်ပြီးပါပြီ (သိမ်းမည်ကို နှိပ်ပါ)'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ဓာတ်ပုံရွေးရာတွင် အမှားရှိပါသည်: $e')),
        );
      }
    }
  }

  Future<void> tLogin() async {
    final res = await supabase
        .from('tutors')
        .select('*')
        .eq('username', userCtrl.text.trim())
        .eq('password', passCtrl.text.trim());
    if (res.isNotEmpty) {
      if (res.first['status'] == 'blacklisted') {
        setState(() => authMsg = "သင့်အကောင့်အား Blacklist သွင်းထားပါသည်");
        return;
      }
      setState(() {
        loggedInTutorId = res.first['id'];
        authMsg = '';
      });
      loadProfileData();
    } else {
      setState(() => authMsg = "Username သို့မဟုတ် Password မှားယွင်းနေပါသည်");
    }
  }

  Future<void> tRegister() async {
    final u = regUserCtrl.text.trim();
    final p = regPassCtrl.text.trim();
    if (!RegExp(r"^([A-Z][a-z]+)+$").hasMatch(u)) {
      setState(
        () => authMsg = "Username စာလုံးကြီးဖြင့် စရပါမည် (ဥပမာ- KyawKyaw)",
      );
      return;
    }
    if (p.length < 8) {
      setState(() => authMsg = "Password အနည်းဆုံး ၈ လုံး ရှိရပါမည်");
      return;
    }
    try {
      await supabase.from('tutors').insert({
        'username': u,
        'password': p,
        'status': 'pending',
      });
      setState(() {
        authMsg = "အကောင့်ဆောက်အောင်မြင်ပါသည်။ Login ဝင်ပါ";
        isRegisterView = false;
      });
    } catch (e) {
      setState(() => authMsg = "Username ရှိပြီးသားဖြစ်ပါသည်");
    }
  }

  Future<void> loadProfileData() async {
    if (loggedInTutorId == null) return;
    final res = await supabase
        .from('tutors')
        .select('*')
        .eq('id', loggedInTutorId!)
        .single();
    setState(() {
      nameCtrl.text = res['name'] ?? '';
      phoneCtrl.text = res['phone'] ?? '';
      bioCtrl.text = res['bio'] ?? '';
      townCtrl.text = res['township'] ?? '';
      feeCtrl.text = res['fee'] ?? '';
      remCtrl.text = res['current_time_remark'] ?? '';
      gender = res['gender'] ?? 'Male';
      stateVal = res['state'] ?? 'ရန်ကုန်တိုင်းဒေသကြီး';
      currVal = res['curriculum'] ?? 'Government';
      modeVal = res['teaching_mode'] ?? 'Online';
      daysVal = res['days'] ?? 'နေ့တိုင်း';
      timeVal = res['time'] ?? 'မနက်';

      g1Val = res['grade1'];
      s1Ctrl.text = res['subject1'] ?? '';
      g2Val = res['grade2'];
      s2Ctrl.text = res['subject2'] ?? '';
      g3Val = res['grade3'];
      s3Ctrl.text = res['subject3'] ?? '';
      g4Val = res['grade4'];
      s4Ctrl.text = res['subject4'] ?? '';
      photoUrl = res['photo'];

      String st = res['status'] ?? 'pending';
      if (st == 'pending') {
        statusMsg = "အတည်ပြုချက် စောင့်ဆိုင်းဆဲဖြစ်သည်";
      } else if (st == 'approved') {
        statusMsg = "အတည်ပြုပြီး ဖြစ်သည်";
      } else {
        statusMsg =
            "Profile ကို Reject လုပ်ထားပါသည် (${res['reject_reason'] ?? ''})";
      }
    });
  }

  Future<void> saveProfile() async {
    if (nameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        g1Val == null ||
        s1Ctrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အမည်၊ ဖုန်း နှင့် အတန်း(၁)/ဘာသာရပ်(၁) ဖြည့်ပါ'),
        ),
      );
      return;
    }
    await supabase
        .from('tutors')
        .update({
          'name': nameCtrl.text,
          'gender': gender,
          'phone': phoneCtrl.text,
          'bio': bioCtrl.text,
          'state': stateVal,
          'township': townCtrl.text,
          'curriculum': currVal,
          'teaching_mode': modeVal,
          'grade1': g1Val,
          'subject1': s1Ctrl.text,
          'grade2': g2Val,
          'subject2': s2Ctrl.text,
          'grade3': g3Val,
          'subject3': s3Ctrl.text,
          'grade4': g4Val,
          'subject4': s4Ctrl.text,
          'days': daysVal,
          'time': timeVal,
          'current_time_remark': remCtrl.text,
          'fee': feeCtrl.text,
          'photo': photoUrl,
          'status': 'pending',
        })
        .eq('id', loggedInTutorId!);

    setState(() => isEditMode = false);
    loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Teacher Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 14),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: loggedInTutorId == null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: isRegisterView ? _buildRegisterUI() : _buildLoginUI(),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabBtn(0, 'My Profile'),
                          _buildTabBtn(1, 'Post များ'),
                          _buildTabBtn(2, 'Admin Chat'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: activeTab == 0
                            ? _buildProfileUI()
                            : (activeTab == 1
                                  ? _buildPostsUI()
                                  : _buildChatUI()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabBtn(int index, String title) {
    final isActive = activeTab == index;
    return InkWell(
      onTap: () => setState(() => activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      labelText: hint, // <--- ဒီနေရာမှာ labelText လေး ထည့်ပေးလိုက်တာပါ
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'TEACHER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2234),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Teacher Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
              if (authMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  authMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: tLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF1A2234),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Login ဝင်မည်',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'အကောင့်မရှိသေးပါက - ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() => isRegisterView = true),
                child: const Text(
                  'Register အကောင့်သစ်ဆောက်ရန်',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterUI() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Teacher Register',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: regUserCtrl,
            decoration: InputDecoration(
              hintText: 'Username (ဥပမာ - KyawKyaw)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF16A34A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: regPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password (ဥပမာ - Kk@12345)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF16A34A)),
              ),
            ),
          ),
          if (authMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              authMsg,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: tRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'အကောင့်သစ် မှတ်ပုံတင်မည်',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => isRegisterView = false),
            child: const Text(
              'Login စာမျက်နှာသို့ ပြန်သွားမည်',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileUI() {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;
    if (statusMsg.contains('အတည်ပြုပြီး')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (statusMsg.contains('Reject')) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'ဆရာ ကိုယ်ရေးအချက်အလက်',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isEditMode ? pickAndUploadPhoto : null,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        image: getImgProv(photoUrl) != null
                            ? DecorationImage(
                                image: getImgProv(photoUrl)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: getImgProv(photoUrl) == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: bioCtrl,
                      enabled: isEditMode,
                      maxLines: 3,
                      decoration: _inputDeco('ကိုယ်ရေးအကျဉ်း (Bio)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                enabled: isEditMode,
                decoration: _inputDeco('အမည်'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['Male', 'Female'].contains(gender)
                          ? gender
                          : 'Male',
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text(
                            'Male (ကျား)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text(
                            'Female (မ)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      onChanged: isEditMode
                          ? (v) => setState(() => gender = v!)
                          : null,
                      decoration: _inputDeco('Gender'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: phoneCtrl,
                      enabled: isEditMode,
                      decoration: _inputDeco('ဖုန်းနံပါတ်'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: states.contains(stateVal)
                          ? stateVal
                          : states.first,
                      items: states
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEditMode
                          ? (v) => setState(() => stateVal = v!)
                          : null,
                      decoration: _inputDeco('တိုင်းဒေသကြီး'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: townCtrl,
                      enabled: isEditMode,
                      decoration: _inputDeco('မြို့နယ်'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'Government',
                            'International',
                            'Dual',
                          ].contains(currVal)
                          ? currVal
                          : 'Government',
                      items: ['Government', 'International', 'Dual']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEditMode
                          ? (v) => setState(() => currVal = v!)
                          : null,
                      decoration: _inputDeco('သင်ရိုး'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'Online',
                            'Inperson',
                            'Online & Inperson',
                          ].contains(modeVal)
                          ? modeVal
                          : 'Online',
                      items: ['Online', 'Inperson', 'Online & Inperson']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEditMode
                          ? (v) => setState(() => modeVal = v!)
                          : null,
                      decoration: _inputDeco('နည်းစနစ်'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildNewGradeSubjRow(
                "အတန်း (၁)",
                g1Val,
                (v) => setState(() => g1Val = v),
                s1Ctrl,
                "ဘာသာရပ် (၁)",
              ),
              const SizedBox(height: 12),
              _buildNewGradeSubjRow(
                "အတန်း (၂)",
                g2Val,
                (v) => setState(() => g2Val = v),
                s2Ctrl,
                "ဘာသာရပ် (၂)",
              ),
              const SizedBox(height: 12),
              _buildNewGradeSubjRow(
                "အတန်း (၃)",
                g3Val,
                (v) => setState(() => g3Val = v),
                s3Ctrl,
                "ဘာသာရပ် (၃)",
              ),
              const SizedBox(height: 12),
              _buildNewGradeSubjRow(
                "အတန်း (၄)",
                g4Val,
                (v) => setState(() => g4Val = v),
                s4Ctrl,
                "ဘာသာရပ် (၄)",
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'နေ့တိုင်း',
                            'စနေ၊တနင်္ဂနွေ',
                            'ရုံးပိတ်ရက်',
                            'ညှိနှိုင်း',
                          ].contains(daysVal)
                          ? daysVal
                          : 'နေ့တိုင်း',
                      items:
                          [
                                'နေ့တိုင်း',
                                'စနေ၊တနင်္ဂနွေ',
                                'ရုံးပိတ်ရက်',
                                'ညှိနှိုင်း',
                              ]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: isEditMode
                          ? (v) => setState(() => daysVal = v!)
                          : null,
                      decoration: _inputDeco('ရက်'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'မနက်',
                            'နေ့လည်',
                            'ညနေ',
                            'ည',
                            'ညှိနှိုင်း',
                          ].contains(timeVal)
                          ? timeVal
                          : 'မနက်',
                      items: ['မနက်', 'နေ့လည်', 'ညနေ', 'ည', 'ညှိနှိုင်း']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEditMode
                          ? (v) => setState(() => timeVal = v!)
                          : null,
                      decoration: _inputDeco('အချိန်'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: remCtrl,
                enabled: isEditMode,
                decoration: _inputDeco('ယခုလက်ရှိသင်ကြားနိုင်သည့်အချိန်'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: feeCtrl,
                enabled: isEditMode,
                decoration: _inputDeco('လစဉ်ကြေး (ကျပ်)'),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    statusMsg.isEmpty ? 'Status' : statusMsg,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!isEditMode)
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => isEditMode = true),
                    icon: const Icon(
                      Icons.edit_document,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Profile ပြင်ဆင်မည်',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('သိမ်းမည်'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => isEditMode = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildStudentRequestsUI(),

        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => setState(() => loggedInTutorId = null),
          icon: const Icon(Icons.logout, color: Colors.red, size: 18),
          label: const Text(
            'Logout ထွက်မည်',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNewGradeSubjRow(
    String label,
    String? val,
    ValueChanged<String?> onChanged,
    TextEditingController ctrl,
    String subLabel,
  ) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: grades.contains(val) ? val : null,
            hint: Text(label, style: const TextStyle(fontSize: 12)),
            items: grades
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: isEditMode ? onChanged : null,
            decoration: _inputDeco(''),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            enabled: isEditMode,
            decoration: _inputDeco(subLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRequestsUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'သင်တန်းသား အသစ်စာရင်း',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2234),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          FutureBuilder(
            future: supabase
                .from('requests')
                .select('*')
                .eq('tutor_id', loggedInTutorId!)
                .order('id', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data as List;
              if (data.isEmpty) {
                return const Text(
                  'တောင်းဆိုထားသော ကျောင်းသား မရှိသေးပါ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                );
              }
              return Column(
                children: data
                    .map(
                      (r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['student_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 12,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        r['student_phone'] ?? '-',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Teacher ဘက်မှ Post များကြည့်ရန် UI သစ်
  Widget _buildPostsUI() {
    return FutureBuilder(
      future: supabase
          .from('job_posts')
          .select('*')
          .eq('status', 'approved')
          .order('id', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final data = snapshot.data as List;
        if (data.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: Text(
                'ဖိတ်ခေါ်စာ မရှိသေးပါ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return Column(
          children: data.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ၁။ Title
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 50.0,
                            ), // Urgent badge နေရာချန်ထားရန်
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "လိုအပ်သော ဘာသာရပ်: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "${item['subject']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ၂။ Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${item['state'] ?? '-'}, ${item['township'] ?? '-'}",
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ၃။ Fee
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                size: 18,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${item['fee_offer'] ?? '-'} Ks",
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ၄။ Info Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info,
                                  size: 18,
                                  color: Color(0xFF60A5FA),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['details'] ?? '-',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ၅။ Apply Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FutureBuilder<bool>(
                              future: checkIfAlreadyApplied(
                                item['id'],
                                loggedInTutorId,
                              ),
                              builder: (context, snapshot) {
                                bool isApplied = snapshot.data ?? false;

                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isApplied
                                        ? Colors.grey
                                        : const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: isApplied
                                      ? null
                                      : () => applyJob(
                                          item['id'],
                                          loggedInTutorId,
                                        ),
                                  icon: const Icon(
                                    Icons.business_center,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isApplied
                                        ? 'လျှောက်ထားပြီးပါပြီ'
                                        : 'လျှောက်ထားရန် (Apply)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Urgent Badge (Top Right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316), // Orange Color
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Teacher ဘက်မှ Chat အပိုင်း
  Widget _buildChatUI() {
    Future<void> sendTextMsg() async {
      if (chatMsgCtrl.text.trim().isEmpty) return;
      final text = chatMsgCtrl.text.trim();
      chatMsgCtrl.clear();
      await supabase.from('chat_messages').insert({
        'tutor_id': loggedInTutorId,
        'sender': 'teacher',
        'message': text,
        'is_read': false, // Admin ဘက်တွင် 1 New ပေါ်စေရန်
      });
    }

    Future<void> sendChatImage() async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 25,
        );

        if (image != null) {
          final fileBytes = await image.readAsBytes();
          final base64Image = base64Encode(fileBytes);
          final ext = image.name.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
          final dataUri = 'data:image/$ext;base64,$base64Image';

          await supabase.from('chat_messages').insert({
            'tutor_id': loggedInTutorId,
            'sender': 'teacher',
            'message': '[ဓာတ်ပုံ]',
            'image_data': dataUri,
            'is_read': false, // Admin ဘက်တွင် 1 New ပေါ်စေရန်
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ပုံပို့ရာတွင် အမှားရှိပါသည် (ပုံအရွယ်အစား ကြီးလွန်းနေနိုင်ပါသည်)',
              ),
            ),
          );
        }
      }
    }

    return Container(
      height: 550,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.forum, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Text(
                'Admin Chat Panel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB),
              child: StreamBuilder(
                stream: supabase
                    .from('chat_messages')
                    .stream(primaryKey: ['id'])
                    .eq('tutor_id', loggedInTutorId!)
                    .order('timestamp', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snapshot.data as List;
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Admin ထံသို့ မေးမြန်းနိုင်ပါသည်',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final m = msgs[index];
                      final isMe = m['sender'] == 'teacher';
                      final rawMsg = m['message']?.toString() ?? '';
                      final imgData = m['image_data']?.toString();

                      // ပုံအမျိုးအစား ခွဲခြားခြင်း
                      String? finalImgUrl;
                      String textToShow = rawMsg;

                      if (imgData != null && imgData.trim().isNotEmpty) {
                        finalImgUrl = imgData;
                        if (rawMsg == '[ဓာတ်ပုံ]') textToShow = '';
                      } else if (rawMsg.startsWith('[IMAGE]')) {
                        finalImgUrl = rawMsg.substring(7);
                        textToShow = '';
                      } else if (rawMsg.startsWith('data:image')) {
                        finalImgUrl = rawMsg;
                        textToShow = '';
                      }

                      final hasImage = finalImgUrl != null;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.55,
                          ),
                          padding: hasImage && textToShow.isEmpty
                              ? const EdgeInsets.all(6)
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!hasImage || textToShow.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    isMe ? 'Me' : 'Admin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: getImgProv(finalImgUrl) != null
                                      ? Image(
                                          image: getImgProv(finalImgUrl)!,
                                          width: 250,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                ),
                              if (hasImage && textToShow.isNotEmpty)
                                const SizedBox(height: 8),
                              if (textToShow.isNotEmpty)
                                Text(
                                  textToShow,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? Colors.white : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF4B5563)),
                  onPressed: sendChatImage,
                  tooltip: 'ပုံပို့မည်',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: chatMsgCtrl,
                  decoration: InputDecoration(
                    hintText: 'စာရိုက်ပါ...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                  onSubmitted: (_) => sendTextMsg(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: sendTextMsg,
                  tooltip: 'ပို့မည်',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. STUDENT SCREEN
// =========================================================================
class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  Map<String, dynamic>? studentUser;
  bool isRegisterView = false;
  int activeTab = 0;

  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final regUserCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();

  final postSubjCtrl = TextEditingController();
  final postTownCtrl = TextEditingController();
  final postFeeCtrl = TextEditingController();
  final postDetCtrl = TextEditingController();
  String postState = 'ရန်ကုန်တိုင်းဒေသကြီး';

  String searchTown = '';
  String searchState = 'တိုင်း/ပြည်နယ် (အားလုံး)';
  String authMsg = '';

  Future<void> sLogin() async {
    final res = await supabase
        .from('students')
        .select('*')
        .eq('username', userCtrl.text.trim())
        .eq('password', passCtrl.text.trim());
    if (res.isNotEmpty) {
      setState(() {
        studentUser = res.first;
        authMsg = '';
      });
    } else {
      setState(() => authMsg = "Username သို့မဟုတ် Password မှားယွင်းနေပါသည်");
    }
  }

  Future<void> sRegister() async {
    if (regUserCtrl.text.isEmpty || regPassCtrl.text.isEmpty) return;
    try {
      await supabase.from('students').insert({
        'username': regUserCtrl.text.trim(),
        'password': regPassCtrl.text.trim(),
        'name': regNameCtrl.text.trim(),
        'phone': regPhoneCtrl.text.trim(),
      });
      setState(() {
        authMsg = "အကောင့်ဖွင့်ခြင်း အောင်မြင်ပါပြီ။ Login ဝင်ပါ";
        isRegisterView = false;
      });
    } catch (e) {
      setState(() => authMsg = "Username ရှိပြီးသားဖြစ်ပါသည်");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Student Area',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 14),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: studentUser == null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: isRegisterView ? _buildRegisterUI() : _buildLoginUI(),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabBtn(0, 'ဆရာရှာရန်'),
                          _buildTabBtn(1, 'Post တင်ရန်'),
                          _buildTabBtn(2, 'မိမိ၏ Post'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => studentUser = null),
                          icon: const Icon(
                            Icons.logout,
                            size: 14,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: activeTab == 0
                            ? _buildSearchTutorUI()
                            : (activeTab == 1
                                  ? _buildCreatePostUI()
                                  : _buildMyPostsUI()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabBtn(int index, String title) {
    final isActive = activeTab == index;
    return InkWell(
      onTap: () => setState(() => activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEF4444) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'STUDENT',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2234),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Student Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  hintText: 'Student Username',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
              if (authMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  authMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: sLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF1A2234),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Login ဝင်မည်',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'အကောင့်မရှိသေးပါက - ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() => isRegisterView = true),
                child: const Text(
                  'Register လုပ်ရန်',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterUI() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Student Register',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: regUserCtrl,
            decoration: InputDecoration(
              hintText: 'Username (ဥပမာ - MaMa)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: regPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password (မိမိဖုန်းနံပါတ်)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: regNameCtrl,
            decoration: InputDecoration(
              hintText: 'ကျောင်းသား/မိဘ အမည်',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: regPhoneCtrl,
            decoration: InputDecoration(
              hintText: 'ဆက်သွယ်ရန် ဖုန်းနံပါတ်',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          if (authMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              authMsg,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: sRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Register အကောင့်ဖွင့်မည်',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => isRegisterView = false),
            child: const Text(
              'Login သို့ ပြန်သွားမည်',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTutorUI() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: searchState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  items:
                      [
                            "တိုင်း/ပြည်နယ် (အားလုံး)",
                            "ရန်ကုန်တိုင်းဒေသကြီး",
                            "မန္တလေးတိုင်းဒေသကြီး",
                            "ပဲခူးတိုင်းဒေသကြီး",
                            "နေပြည်တော်",
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => searchState = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'မြို့နယ်ဖြင့်ရှာရန်',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  onChanged: (v) => setState(() => searchTown = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        FutureBuilder(
          future: supabase.from('tutors').select('*').eq('status', 'approved'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            var data = snapshot.data as List;
            data = data
                .where(
                  (t) =>
                      (t['name'] != null &&
                      t['name'].toString().trim().isNotEmpty),
                )
                .toList();

            if (searchState != 'တိုင်း/ပြည်နယ် (အားလုံး)') {
              data = data.where((t) => t['state'] == searchState).toList();
            }
            if (searchTown.isNotEmpty) {
              data = data
                  .where(
                    (t) =>
                        (t['township'] ?? '').toString().contains(searchTown),
                  )
                  .toList();
            }

            if (data.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(30.0),
                child: Text(
                  'ဤဒေသတွင် ဆရာမရှိသေးပါ',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: data.map((t) {
                List<String> subList = [];

                void addGradeIfValid(String? grade, String? subject) {
                  if (grade != null && grade.trim().isNotEmpty) {
                    final subjText =
                        (subject != null && subject.trim().isNotEmpty)
                        ? " ($subject)"
                        : "";
                    subList.add("• $grade$subjText");
                  }
                }

                addGradeIfValid(t['grade1'], t['subject1']);
                addGradeIfValid(t['grade2'], t['subject2']);
                addGradeIfValid(t['grade3'], t['subject3']);
                addGradeIfValid(t['grade4'], t['subject4']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              image: getImgProv(t['photo']) != null
                                  ? DecorationImage(
                                      image: getImgProv(t['photo'])!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: getImgProv(t['photo']) == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1A2234),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "(${t['gender'] ?? 'Male'})",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.bookmark,
                                      size: 14,
                                      color: Color(0xFFF97316),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${t['curriculum'] ?? 'Government'} | ${t['teaching_mode'] ?? 'Online'}",
                                      style: const TextStyle(
                                        color: Color(0xFFF97316),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${t['state'] ?? '-'}, ${t['township'] ?? '-'}",
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'သင်ကြားမည့် အတန်း/ဘာသာရပ်များ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subList.isEmpty
                                  ? '• မဖော်ပြထားပါ'
                                  : subList.join('\n'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ရက်/အချိန်: ${t['days'] ?? 'ညှိနှိုင်း'} (${t['time'] ?? 'ညှိနှိုင်း'})",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "လစဉ်ကြေး: ${t['fee'] ?? 'ညှိနှိုင်း'} Ks",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await supabase.from('requests').insert({
                              'tutor_id': t['id'],
                              'student_name': studentUser!['name'],
                              'student_phone': studentUser!['phone'],
                              'status': 'pending',
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Admin ထံ တောင်းဆိုချက် ပို့ပြီးပါပြီ',
                                ),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_in_talk, size: 18),
                          label: const Text(
                            'ဒီဆရာနဲ့ သင်မယ် (တောင်းဆိုရန်)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreatePostUI() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_square, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'ဆရာခေါ်ယူရန် Post တင်ပါ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2234),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),

          TextField(
            controller: postSubjCtrl,
            decoration: InputDecoration(
              hintText: 'လိုချင်သော ဘာသာရပ်/အတန်း',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: postState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                  items:
                      [
                            "ရန်ကုန်တိုင်းဒေသကြီး",
                            "မန္တလေးတိုင်းဒေသကြီး",
                            "ပဲခူးတိုင်းဒေသကြီး",
                            "နေပြည်တော်",
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => postState = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: postTownCtrl,
                  decoration: InputDecoration(
                    hintText: 'မြို့နယ်',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: postFeeCtrl,
            decoration: InputDecoration(
              hintText: 'ပေးနိုင်သော လစဉ်ကြေး',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: postDetCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'အသေးစိတ်အချက်အလက်များ',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (postSubjCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('လိုချင်သော ဘာသာရပ်/အတန်း ထည့်ပါ'),
                    ),
                  );
                  return;
                }
                await supabase.from('job_posts').insert({
                  'stu_name': studentUser!['name'],
                  'stu_phone': studentUser!['phone'],
                  'subject': postSubjCtrl.text,
                  'state': postState,
                  'township': postTownCtrl.text,
                  'fee_offer': postFeeCtrl.text,
                  'details': postDetCtrl.text,
                  'status': 'pending',
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post တင်ခြင်း အောင်မြင်ပါပြီ')),
                );
                postSubjCtrl.clear();
                postTownCtrl.clear();
                postFeeCtrl.clear();
                postDetCtrl.clear();
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text(
                'Post တင်မည်',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostsUI() {
    return Column(
      children: [
        // ၁။ စောင့်ဆိုင်း/လျှောက်ထားဆဲ ပို့စ်များ Box
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'စောင့်ဆိုင်း/လျှောက်ထားဆဲ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder(
                future: supabase
                    .from('job_posts')
                    .select('*, job_applications(id)')
                    .eq('stu_phone', studentUser!['phone'])
                    .neq('status', 'connected')
                    .order('id', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final data = snapshot.data as List;
                  if (data.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'စောင့်ဆိုင်းနေသော Post မရှိသေးပါ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }
                  return Column(
                    children: data.map((p) {
                      final apps = p['job_applications'] as List? ?? [];
                      final count = apps.length;

                      final isApproved = p['status'] == 'approved';
                      final statusColor = isApproved
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706);
                      final statusBgColor = isApproved
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFFEDD5);
                      final statusText = isApproved
                          ? 'ဆရာများ လျှောက်ထားနိုင်ပါပြီ'
                          : 'Admin စိစစ်ဆဲ';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF0FDF4,
                          ), // ပုံစံသစ် Light Green
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['subject'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${p['state'] ?? ''}, ${p['township'] ?? ''} | ${p['fee_offer'] ?? '-'} Ks",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          size: 14,
                                          color: Color(0xFF059669),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count ယောက် လျှောက်ထားသည်',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Edit & Delete ခလုတ်များ
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFFEFF6FF,
                                      ), // Light Blue
                                      foregroundColor: const Color(
                                        0xFF2563EB,
                                      ), // Blue text
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: BorderSide(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      // ပြင်မည် (Edit Post)
                                      final eSubjCtrl = TextEditingController(
                                        text: p['subject'],
                                      );
                                      final eTownCtrl = TextEditingController(
                                        text: p['township'],
                                      );
                                      final eFeeCtrl = TextEditingController(
                                        text: p['fee_offer'],
                                      );
                                      final eDetCtrl = TextEditingController(
                                        text: p['details'],
                                      );
                                      String eState =
                                          p['state'] ?? 'ရန်ကုန်တိုင်းဒေသကြီး';

                                      showDialog(
                                        context: context,
                                        builder: (ctx) => StatefulBuilder(
                                          builder: (context, setDialogState) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Post ပြင်ဆင်ရန်',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller: eSubjCtrl,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'ဘာသာရပ်/အတန်း',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    DropdownButtonFormField<
                                                      String
                                                    >(
                                                      initialValue:
                                                          [
                                                            "ရန်ကုန်တိုင်းဒေသကြီး",
                                                            "မန္တလေးတိုင်းဒေသကြီး",
                                                            "ပဲခူးတိုင်းဒေသကြီး",
                                                            "နေပြည်တော်",
                                                          ].contains(eState)
                                                          ? eState
                                                          : "ရန်ကုန်တိုင်းဒေသကြီး",
                                                      items:
                                                          [
                                                                "ရန်ကုန်တိုင်းဒေသကြီး",
                                                                "မန္တလေးတိုင်းဒေသကြီး",
                                                                "ပဲခူးတိုင်းဒေသကြီး",
                                                                "နေပြည်တော်",
                                                              ]
                                                              .map(
                                                                (
                                                                  s,
                                                                ) => DropdownMenuItem(
                                                                  value: s,
                                                                  child: Text(
                                                                    s,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                      onChanged: (v) =>
                                                          setDialogState(
                                                            () => eState = v!,
                                                          ),
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'တိုင်း/ပြည်နယ်',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: eTownCtrl,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'မြို့နယ်',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: eFeeCtrl,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'ပေးနိုင်သော ကြေး',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: eDetCtrl,
                                                      maxLines: 3,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'အသေးစိတ်အချက်အလက်',
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () async {
                                                    await supabase
                                                        .from('job_posts')
                                                        .update({
                                                          'subject':
                                                              eSubjCtrl.text,
                                                          'state': eState,
                                                          'township':
                                                              eTownCtrl.text,
                                                          'fee_offer':
                                                              eFeeCtrl.text,
                                                          'details':
                                                              eDetCtrl.text,
                                                          'status':
                                                              'pending', // ပြင်ပြီးပါက Admin ထံ အတည်ပြုချက် ပြန်တောင်းရမည်
                                                        })
                                                        .eq('id', p['id']);

                                                    if (context.mounted) {
                                                      Navigator.pop(ctx);
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Post ပြင်ဆင်ပြီးပါပြီ။ Admin ထံ အတည်ပြုချက် ပြန်တောင်းထားပါသည်။',
                                                          ),
                                                        ),
                                                      );
                                                      setState(
                                                        () {},
                                                      ); // UI Refresh လုပ်ရန်
                                                    }
                                                  },
                                                  child: const Text('ပြင်မည်'),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text(
                                      'ပြင်မည်',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFFFEF2F2,
                                      ), // Light Red
                                      foregroundColor: const Color(
                                        0xFFDC2626,
                                      ), // Red text
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: BorderSide(
                                          color: Colors.red.shade100,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      // ဖျက်မည် (Delete Post)
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Post ဖျက်ရန်',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: const Text(
                                            'ဤ Post ကို အပြီးတိုင် ဖျက်ပစ်မည် သေချာပါသလား?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                await supabase
                                                    .from('job_posts')
                                                    .delete()
                                                    .eq('id', p['id']);
                                                if (context.mounted) {
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Post အား ဖျက်ပစ်လိုက်ပါပြီ',
                                                      ),
                                                    ),
                                                  );
                                                  setState(
                                                    () {},
                                                  ); // UI Refresh လုပ်ရန်
                                                }
                                              },
                                              child: const Text('ဖျက်မည်'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete, size: 14),
                                    label: const Text(
                                      'ဖျက်မည်',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ၂။ ချိတ်ဆက်ပြီးသော စာရင်း Box
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ချိတ်ဆက်ပြီးသော စာရင်း',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              FutureBuilder(
                future: supabase
                    .from('requests')
                    .select('*, tutors(name, phone)')
                    .eq('student_phone', studentUser!['phone'])
                    .eq('status', 'approved'),
                builder: (context, snapshotReq) {
                  return FutureBuilder(
                    future: supabase
                        .from('job_posts')
                        .select('*')
                        .eq('stu_phone', studentUser!['phone'])
                        .eq('status', 'connected'),
                    builder: (context, snapshotPost) {
                      final reqData = snapshotReq.data as List? ?? [];
                      final postData = snapshotPost.data as List? ?? [];

                      if (reqData.isEmpty && postData.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'ချိတ်ဆက်ပြီးသော စာရင်း မရှိသေးပါ',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ...reqData.map((r) {
                            final tutor =
                                r['tutors'] as Map<String, dynamic>? ?? {};
                            final tName = tutor['name'] ?? 'ဆရာ';
                            final tPhone = tutor['phone'] ?? '-';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDCFCE7),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ဆရာ: $tName",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 14,
                                        color: Color(0xFF16A34A),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "ဖုန်း: $tPhone",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                          ...postData.map((p) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDCFCE7),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Post: ${p['subject']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Color(0xFF16A34A),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "သင်၏ Post အား ဆရာနှင့် ချိတ်ဆက်ပေးလိုက်ပါပြီ",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 4. ADMIN SCREEN
// =========================================================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool isAdminLogged = false;
  final passCtrl = TextEditingController();
  String errorMsg = '';

  void aLogin() {
    // .env ထဲမှ ADMIN_PASSWORD ကို ယူပါသည်
    final adminPass = dotenv.env['ADMIN_PASSWORD'];

    // စမ်းသပ်ရန်: .env ဖိုင်ထဲက တကယ်ဖတ်လို့ရလားမရလား Console ထဲမှာ ကြည့်နိုင်သည်
    debugPrint("Loaded Admin Password from .env: '$adminPass'");

    if (adminPass != null &&
        adminPass.isNotEmpty &&
        passCtrl.text == adminPass) {
      setState(() {
        isAdminLogged = true;
        errorMsg = '';
      });
    } else {
      setState(() => errorMsg = 'Password မှားယွင်းနေပါသည်');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: Text(
          !isAdminLogged ? 'Admin Login' : 'ADMIN DASHBOARD',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: !isAdminLogged
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Admin Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2234),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Admin Password ထည့်ပါ',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ),
                        if (errorMsg.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMsg,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: aLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'ဝင်ရောက်မည်',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ADMIN DASHBOARD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A2234),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => isAdminLogged = false),
                              icon: const Icon(
                                Icons.power_settings_new,
                                color: Colors.red,
                              ),
                              tooltip: 'Logout',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildNewAdminTile(
                            Icons.person_add,
                            "ဆရာသစ်\nအတည်ပြုရန်",
                            const Color(0xFFD1FAE5),
                            const Color(0xFF065F46),
                            () => _openPanel(
                              "ဆရာသစ် အတည်ပြုရန်",
                              _buildPendingTutors(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.people,
                            "ဆရာများ\nစာရင်း",
                            const Color(0xFFD1FAE5),
                            const Color(0xFF065F46),
                            () => _openPanel(
                              "ဆရာများ စာရင်း",
                              _buildApprovedTutors(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.assignment_late,
                            "စိစစ်ရန်\nPost များ",
                            const Color(0xFFDBEAFE),
                            const Color(0xFF1E3A8A),
                            () => _openPanel(
                              "စိစစ်ရန် Post များ",
                              _buildPendingPosts(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.assignment_turned_in,
                            "စိစစ်ပြီး\nPost များ",
                            const Color(0xFFDBEAFE),
                            const Color(0xFF1E3A8A),
                            () => _openPanel(
                              "စိစစ်ပြီး Post များ",
                              _buildApprovedPosts(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.swap_horiz,
                            "ချိတ်ဆက်ပြီး\nPost များ",
                            const Color(0xFFF3E8FF),
                            const Color(0xFF6B21A8),
                            () => _openPanel(
                              "ချိတ်ဆက်ပြီး Post များ",
                              _buildConnectedPosts(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.handshake,
                            "ဆရာများအား ချိတ်ဆက်ခြင်း\nအတည်ပြုရန်",
                            const Color(0xFFF3E8FF),
                            const Color(0xFF6B21A8),
                            () => _openPanel(
                              "ဆရာများအား ချိတ်ဆက်ခြင်း အတည်ပြုရန်",
                              _buildPendingRequests(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.notifications,
                            "အချက်ပေးစာ\nNotification",
                            const Color(0xFFFFEDD5),
                            const Color(0xFF9A3412),
                            () => _openPanel(
                              "အချက်ပေးစာ Notification",
                              _buildNotificationsPanel(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.chat,
                            "Chat\nစာပို့ခြင်း",
                            const Color(0xFFFFEDD5),
                            const Color(0xFF9A3412),
                            () => _openPanel(
                              "Chat စာပို့ခြင်း",
                              _buildAdminChatList(),
                            ),
                          ),
                          _buildNewAdminTile(
                            Icons.person_off,
                            "Blacklist\nစာရင်း",
                            const Color(0xFFFEE2E2),
                            const Color(0xFF991B1B),
                            () => _openPanel(
                              "BLACKLIST စာရင်း",
                              _buildBlacklistTutors(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNewAdminTile(
    IconData icon,
    String title,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: iconColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPanel(String title, Widget content) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (navContext) => Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A2234),
            centerTitle: true,
            elevation: 0,
            title: const Text(
              'ADMIN DASHBOARD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            leadingWidth: 110,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(navContext);
                  setState(() {}); // Data အသစ်ပြန်ခေါ်ရန်
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 14,
                ),
                label: const Text(
                  'နောက်သို့',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(navContext),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text(
                            'Back',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A2234),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(navContext);
                              setState(() => isAdminLogged = false);
                            },
                            icon: const Icon(
                              Icons.power_settings_new,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTutors() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder(
          future: supabase
              .from('tutors')
              .select('*')
              .eq('status', 'pending')
              .order('id', ascending: true),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data as List;
            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'စိစစ်ရန် မရှိသေးပါ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Column(
              children: data.map((t) {
                final isProfileComplete =
                    t['name'] != null && t['name'].toString().trim().isNotEmpty;
                final titleText = isProfileComplete
                    ? "${t['name']} (${t['gender'] ?? 'Male'})"
                    : "[Profile မဖြည့်ရသေးပါ]";
                final titleColor = isProfileComplete
                    ? const Color(0xFF1A2234)
                    : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "U: ${t['username']} | P: ${t['password']} | Ph: ${t['phone'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDBEAFE),
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Tutor Details',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (getImgProv(t['photo']) != null)
                                            Center(
                                              child: Image(
                                                image: getImgProv(t['photo'])!,
                                                height: 100,
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Text('အမည်: ${t['name'] ?? '-'}'),
                                          Text('ဖုန်း: ${t['phone'] ?? '-'}'),
                                          Text('ကျား/မ: ${t['gender'] ?? '-'}'),
                                          Text(
                                            'ဒေသ: ${t['state'] ?? '-'}, ${t['township'] ?? '-'}',
                                          ),
                                          Text(
                                            'သင်ရိုး: ${t['curriculum'] ?? '-'} | ${t['teaching_mode'] ?? '-'}',
                                          ),
                                          const Divider(),
                                          if (t['grade1'] != null &&
                                              t['grade1']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              '၁။ ${t['grade1']} (${t['subject1'] ?? '-'})',
                                            ),
                                          if (t['grade2'] != null &&
                                              t['grade2']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              '၂။ ${t['grade2']} (${t['subject2'] ?? '-'})',
                                            ),
                                          if (t['grade3'] != null &&
                                              t['grade3']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              '၃။ ${t['grade3']} (${t['subject3'] ?? '-'})',
                                            ),
                                          if (t['grade4'] != null &&
                                              t['grade4']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              '၄။ ${t['grade4']} (${t['subject4'] ?? '-'})',
                                            ),
                                          const Divider(),
                                          Text(
                                            'ရက်: ${t['days'] ?? '-'} | အချိန်: ${t['time'] ?? '-'}',
                                          ),
                                          Text(
                                            'လစဉ်ကြေး: ${t['fee'] ?? '-'} Ks',
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'မှတ်ချက်: ${t['bio'] ?? '-'}',
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('ပိတ်မည်'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 14),
                              label: const Text(
                                'Detail',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFE5E7EB,
                                ),
                                disabledForegroundColor: const Color(
                                  0xFF9CA3AF,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: isProfileComplete
                                  ? () async {
                                      await supabase
                                          .from('tutors')
                                          .update({'status': 'approved'})
                                          .eq('id', t['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'အတည်ပြုပေးလိုက်ပါပြီ',
                                            ),
                                          ),
                                        );
                                        setLocalState(() {});
                                        setState(() {});
                                      }
                                    }
                                  : null,
                              child: Text(
                                isProfileComplete ? 'Approve' : 'စောင့်ပါ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ၂။ ဆရာများ စာရင်း (Search 기능 ပါဝင်သည်)
  Widget _buildApprovedTutors() {
    String searchQuery = '';
    Future<List<dynamic>>? tutorsFuture;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        // စာရိုက်တိုင်း Future ပြန်မခေါ်စေရန် cache လုပ်ထားခြင်း
        tutorsFuture ??= supabase
            .from('tutors')
            .select('*')
            .eq('status', 'approved')
            .order('id', ascending: true);

        // Block / Reset လုပ်ပြီးပါက Data အသစ်ပြန်ခေါ်ရန်
        void refreshData() {
          setLocalState(() {
            tutorsFuture = supabase
                .from('tutors')
                .select('*')
                .eq('status', 'approved')
                .order('id', ascending: true);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar အပိုင်း
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                onChanged: (val) {
                  setLocalState(() {
                    searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'နာမည်၊ ဖုန်း၊ Username ဖြင့် ရှာရန်...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),

            // Tutors List အပိုင်း
            FutureBuilder(
              future: tutorsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data as List;

                // Search Filtering
                final filteredData = data.where((t) {
                  final searchLower = searchQuery.toLowerCase();
                  final name = (t['name'] ?? '').toString().toLowerCase();
                  final username = (t['username'] ?? '')
                      .toString()
                      .toLowerCase();
                  final phone = (t['phone'] ?? '').toString().toLowerCase();
                  return name.contains(searchLower) ||
                      username.contains(searchLower) ||
                      phone.contains(searchLower);
                }).toList();

                if (filteredData.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'ရှာဖွေမှုရလဒ် မတွေ့ပါ / ဆရာစာရင်း မရှိပါ',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredData.map((t) {
                    final nameStr =
                        (t['name'] != null &&
                            t['name'].toString().trim().isNotEmpty)
                        ? "${t['name']} (${t['gender'] ?? 'Male'})"
                        : "User: ${t['username']}";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A2234),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "U: ${t['username']} | P: ${t['password']} | Ph: ${t['phone'] ?? '-'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFEDD5),
                                    foregroundColor: const Color(0xFFD97706),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    final newPassCtrl = TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          width: 400,
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Password ပြန်သတ်မှတ်ရန်',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF1A2234),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              TextField(
                                                controller: newPassCtrl,
                                                decoration: InputDecoration(
                                                  hintText: 'Password အသစ်',
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 13,
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF10B981,
                                                              ),
                                                            ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF10B981,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        elevation: 0,
                                                      ),
                                                      onPressed: () async {
                                                        if (newPassCtrl.text
                                                            .trim()
                                                            .isEmpty) {
                                                          return;
                                                        }
                                                        await supabase
                                                            .from('tutors')
                                                            .update({
                                                              'password':
                                                                  newPassCtrl
                                                                      .text
                                                                      .trim(),
                                                            })
                                                            .eq('id', t['id']);
                                                        if (context.mounted) {
                                                          Navigator.pop(ctx);
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Password ပြောင်းလဲပြီးပါပြီ',
                                                              ),
                                                            ),
                                                          );
                                                          refreshData(); // အသစ်ပြန်ခေါ်ရန်
                                                        }
                                                      },
                                                      child: const Text(
                                                        'သိမ်းမည်',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFE5E7EB,
                                                            ),
                                                        foregroundColor:
                                                            const Color(
                                                              0xFF1F2937,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        elevation: 0,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child: const Text(
                                                        'ပိတ်မည်',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.vpn_key, size: 14),
                                  label: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    foregroundColor: const Color(0xFF2563EB),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Tutor Details',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (getImgProv(t['photo']) !=
                                                  null)
                                                Center(
                                                  child: Image(
                                                    image: getImgProv(
                                                      t['photo'],
                                                    )!,
                                                    height: 100,
                                                  ),
                                                ),
                                              const SizedBox(height: 10),
                                              Text('အမည်: ${t['name'] ?? '-'}'),
                                              Text(
                                                'ဖုန်း: ${t['phone'] ?? '-'}',
                                              ),
                                              Text(
                                                'ကျား/မ: ${t['gender'] ?? '-'}',
                                              ),
                                              Text(
                                                'ဒေသ: ${t['state'] ?? '-'}, ${t['township'] ?? '-'}',
                                              ),
                                              Text(
                                                'သင်ရိုး: ${t['curriculum'] ?? '-'} | ${t['teaching_mode'] ?? '-'}',
                                              ),
                                              const Divider(),
                                              if (t['grade1'] != null &&
                                                  t['grade1']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty)
                                                Text(
                                                  '၁။ ${t['grade1']} (${t['subject1'] ?? '-'})',
                                                ),
                                              if (t['grade2'] != null &&
                                                  t['grade2']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty)
                                                Text(
                                                  '၂။ ${t['grade2']} (${t['subject2'] ?? '-'})',
                                                ),
                                              if (t['grade3'] != null &&
                                                  t['grade3']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty)
                                                Text(
                                                  '၃။ ${t['grade3']} (${t['subject3'] ?? '-'})',
                                                ),
                                              if (t['grade4'] != null &&
                                                  t['grade4']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty)
                                                Text(
                                                  '၄။ ${t['grade4']} (${t['subject4'] ?? '-'})',
                                                ),
                                              const Divider(),
                                              Text(
                                                'ရက်: ${t['days'] ?? '-'} | အချိန်: ${t['time'] ?? '-'}',
                                              ),
                                              Text(
                                                'လစဉ်ကြေး: ${t['fee'] ?? '-'} Ks',
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'မှတ်ချက်: ${t['bio'] ?? '-'}',
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('ပိတ်မည်'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 14),
                                  label: const Text(
                                    'Detail',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Reason ထည့်ရန် Controller လေး တည်ဆောက်ပါမည်
                                    final reasonCtrl = TextEditingController();

                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Block Tutor',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '\'${t['name'] ?? t['username']}\' ကို Blacklist သွင်းမည် သေချာပါသလား?',
                                            ),
                                            const SizedBox(height: 16),
                                            // Reason ရိုက်ထည့်ရန် TextField လေး ထည့်လိုက်ပါပြီ
                                            TextField(
                                              controller: reasonCtrl,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'အကြောင်းရင်း ထည့်ပါ (Reason)',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: const Color(
                                                  0xFFF9FAFB,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.red,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () async {
                                              // ဘာမှမရိုက်ထည့်ခဲ့ရင် 'Admin Blocked' လို့ Default ထားပေးမည်
                                              final reason =
                                                  reasonCtrl.text.trim().isEmpty
                                                  ? 'Admin Blocked'
                                                  : reasonCtrl.text.trim();

                                              await supabase
                                                  .from('tutors')
                                                  .update({
                                                    'status': 'blacklisted',
                                                    'reject_reason':
                                                        reason, // ရိုက်ထည့်လိုက်တဲ့ Reason ဝင်သွားပါမည်
                                                  })
                                                  .eq('id', t['id']);

                                              if (context.mounted) {
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Blacklist သွင်းပြီးပါပြီ',
                                                    ),
                                                  ),
                                                );
                                                refreshData(); // အသစ်ပြန်ခေါ်ရန်
                                              }
                                            },
                                            child: const Text('Block လုပ်မည်'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.block, size: 14),
                                  label: const Text(
                                    'Block',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ၃။ စိစစ်ရန် Post များ (Approve အလုပ်လုပ်ရန် StatefulBuilder ဖြင့် ပြင်ဆင်ထားသည်)
  Widget _buildPendingPosts() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder(
          future: supabase
              .from('job_posts')
              .select('*')
              .eq('status', 'pending')
              .order('id', ascending: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data as List;
            if (data.isEmpty) {
              return const Center(
                child: Text(
                  'စိစစ်ရန် Post မရှိသေးပါ',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: data
                  .map(
                    (p) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['subject'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "ကျောင်းသား: ${p['stu_name']} (${p['stu_phone']})\nကြေး: ${p['fee_offer']} Ks",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF3B82F6,
                              ), // Blue Color
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              // Status ကို approved သို့ ပြောင်းလဲခြင်း
                              await supabase
                                  .from('job_posts')
                                  .update({'status': 'approved'})
                                  .eq('id', p['id']);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Post အား အတည်ပြုပေးလိုက်ပါပြီ',
                                    ),
                                    backgroundColor: Color(
                                      0xFF16A34A,
                                    ), // Green Color
                                  ),
                                );
                                // မျက်နှာပြင်ကို ချက်ချင်း Refresh လုပ်ခြင်း
                                setLocalState(() {});
                              }
                            },
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  // ၅။ စိစစ်ပြီး Post များ (Dialog အကျယ် ပြင်ဆင်ထားသည်)
  Widget _buildApprovedPosts() {
    return FutureBuilder(
      future: supabase
          .from('job_posts')
          .select('*, job_applications(*, tutors(*))')
          .eq('status', 'approved')
          .order('id', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Data Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as List;
        if (data.isEmpty) {
          return const Center(
            child: Text(
              'စိစစ်ပြီး Post မရှိသေးပါ',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: data.map((p) {
            final apps = p['job_applications'] as List? ?? [];
            final subj = p['subject'] ?? '-';
            final sName = p['stu_name'] ?? '-';
            final sPhone = p['stu_phone'] ?? '-';
            final state = p['state'] ?? '-';
            final town = p['township'] ?? '-';
            final fee = p['fee_offer'] ?? '-';
            final details = p['details'] ?? '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'ဘာသာရပ်: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        TextSpan(
                          text: subj,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        TextSpan(text: '\nကျောင်းသား: $sName ($sPhone)'),
                        TextSpan(text: '\nဒေသ: $state, $town'),
                        TextSpan(text: '\nကြေး: $fee Ks | Detail: $details'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // လျှောက်ထားသူ ခလုတ်
                      InkWell(
                        onTap: () {
                          // Dialog ဖြင့် လျှောက်ထားသူများကို ပြရန်
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Applicants for: $subj',
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              content: SizedBox(
                                width:
                                    450, // <--- ဤနေရာတွင် အကျယ်ကို 450 ဟု ကန့်သတ်လိုက်ပါသည်
                                child: apps.isEmpty
                                    ? const Text(
                                        "လျှောက်ထားသော ဆရာ မရှိသေးပါ",
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: apps.length,
                                        itemBuilder: (c, i) {
                                          final app = apps[i];
                                          final tutor =
                                              app['tutors']
                                                  as Map<String, dynamic>? ??
                                              {};
                                          final tName =
                                              tutor['name'] ?? 'Unknown';
                                          final tPhone = tutor['phone'] ?? '-';

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Ph: $tPhone',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFDBEAFE,
                                                              ),
                                                          foregroundColor:
                                                              const Color(
                                                                0xFF2563EB,
                                                              ),
                                                          elevation: 0,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          // Tutor Detail Dialog
                                                          showDialog(
                                                            context: context,
                                                            builder: (detailCtx) => AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              content: SingleChildScrollView(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    if (getImgProv(
                                                                          tutor['photo'],
                                                                        ) !=
                                                                        null)
                                                                      CircleAvatar(
                                                                        radius:
                                                                            40,
                                                                        backgroundImage:
                                                                            getImgProv(
                                                                              tutor['photo'],
                                                                            )!,
                                                                      ),
                                                                    const SizedBox(
                                                                      height:
                                                                          12,
                                                                    ),
                                                                    Text(
                                                                      '${tutor['username']} (Pass: ${tutor['password']})',
                                                                      style: const TextStyle(
                                                                        color: Color(
                                                                          0xFF1E3A8A,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const Divider(
                                                                      height:
                                                                          24,
                                                                    ),
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: Text(
                                                                        'အမည်: $tName (${tutor['gender'] ?? '-'})\n'
                                                                        'ဖုန်း: $tPhone\n'
                                                                        'ဒေသ: ${tutor['state'] ?? '-'}, ${tutor['township'] ?? '-'}\n'
                                                                        'သင်ရိုး: ${tutor['curriculum'] ?? '-'} | ${tutor['teaching_mode'] ?? '-'}\n'
                                                                        'အတန်း: ${tutor['grade1'] ?? '-'} (${tutor['subject1'] ?? '-'})\n'
                                                                        'ရက်/အချိန်: ${tutor['days'] ?? '-'} (${tutor['time'] ?? '-'})\n'
                                                                        'ကြေး: ${tutor['fee'] ?? '-'} Ks',
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          height:
                                                                              1.6,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          20,
                                                                    ),
                                                                    SizedBox(
                                                                      width: double
                                                                          .infinity,
                                                                      child: ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color(
                                                                            0xFFE5E7EB,
                                                                          ),
                                                                          foregroundColor:
                                                                              Colors.black87,
                                                                          elevation:
                                                                              0,
                                                                        ),
                                                                        onPressed: () =>
                                                                            Navigator.pop(
                                                                              detailCtx,
                                                                            ),
                                                                        child: const Text(
                                                                          'ပိတ်မည်',
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Detail',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF16A34A,
                                                              ),
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          // Hire (Done) လုပ္မည္
                                                          await supabase
                                                              .from('job_posts')
                                                              .update({
                                                                'status':
                                                                    'connected',
                                                              })
                                                              .eq(
                                                                'id',
                                                                p['id'],
                                                              );
                                                          if (context.mounted) {
                                                            Navigator.pop(ctx);
                                                            setState(() {});
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Hire (Done)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              actions: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text(
                                      'ပိတ်မည်',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'လျှောက်ထားသူ (${apps.length})',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Done ခလုတ်အစိမ်း
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildConnectedPosts() {
    return FutureBuilder(
      future: supabase.from('job_posts').select('*').eq('status', 'connected'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data as List;
        if (data.isEmpty) {
          return const Center(
            child: Text(
              'ချိတ်ဆက်ပြီးသော Post မရှိသေးပါ',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return Column(
          children: data
              .map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(p['subject'] ?? '-'),
                    subtitle: Text(
                      "ကျောင်းသား: ${p['stu_name']}\nကြေး: ${p['fee_offer']} Ks",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ၇။ ဆရာများအား ချိတ်ဆက်ခြင်း အတည်ပြုရန် (Direct Booking စိစစ်ရန်)
  Widget _buildPendingRequests() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder(
          // ဆရာ၏ အချက်အလက်အပြည့်အစုံကို ယူရန် tutors(*) ကို သုံးပါသည်
          future: supabase
              .from('requests')
              .select('*, tutors(*)')
              .order('id', ascending: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data as List;

            final pendingList = data
                .where((r) => r['status'] == 'pending')
                .toList();
            // Approved သို့မဟုတ် Rejected ဖြစ်သွားသော စာရင်းများကို History အဖြစ်ပြမည်
            final historyList = data
                .where(
                  (r) => r['status'] == 'approved' || r['status'] == 'rejected',
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // စိစစ်ဆဲ တောင်းဆိုမှုများ ခေါင်းစဉ်
                const Text(
                  'စိစစ်ဆဲ တောင်းဆိုမှုများ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 12),

                if (pendingList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'စိစစ်ရန် မရှိသေးပါ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...pendingList.map((r) {
                    final tutor = r['tutors'] as Map<String, dynamic>? ?? {};
                    final sName = r['student_name'] ?? 'Unknown';
                    final tName = tutor['name'] ?? 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), // Light Orange
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ကျောင်းသား:: $sName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ဆရာ: $tName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF97316,
                              ), // Orange
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () {
                              // Detail Dialog ခေါ်ရန်
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  contentPadding: const EdgeInsets.all(24),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ကျောင်းသား:: $sName (${r['student_phone'] ?? '-'})',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Divider(
                                        height: 24,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      Text(
                                        'ဆရာ: $tName (${tutor['phone'] ?? '-'})',
                                        style: const TextStyle(
                                          color: Color(0xFFD97706),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'ဒေသ: ${tutor['state'] ?? '-'}, ${tutor['township'] ?? '-'} | လစဉ်ကြေး: ${tutor['fee'] ?? '-'} Ks',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF16A34A,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () async {
                                                await supabase
                                                    .from('requests')
                                                    .update({
                                                      'status': 'approved',
                                                    })
                                                    .eq('id', r['id']);
                                                if (context.mounted) {
                                                  Navigator.pop(ctx);
                                                  setLocalState(() {});
                                                }
                                              },
                                              child: const Text(
                                                'ချိတ်ဆက်မည်',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFDC2626,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () async {
                                                await supabase
                                                    .from('requests')
                                                    .update({
                                                      'status': 'rejected',
                                                    })
                                                    .eq('id', r['id']);
                                                if (context.mounted) {
                                                  Navigator.pop(ctx);
                                                  setLocalState(() {});
                                                }
                                              },
                                              child: const Text(
                                                'ငြင်းပယ်မည်',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFE5E7EB,
                                                ),
                                                foregroundColor: Colors.black87,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text(
                                                'ပိတ်မည်',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // မှတ်တမ်းများ (History) ခေါင်းစဉ်
                const Text(
                  'မှတ်တမ်းများ (History)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),

                if (historyList.isEmpty)
                  const Text(
                    'မှတ်တမ်း မရှိသေးပါ',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...historyList.map((r) {
                    final tutor = r['tutors'] as Map<String, dynamic>? ?? {};
                    final sName = r['student_name'] ?? 'Unknown';
                    final tName = tutor['name'] ?? 'Unknown';
                    final isApproved = r['status'] == 'approved';

                    final statusText = isApproved
                        ? '[COMPLETED]'
                        : '[REJECTED]';
                    final statusColor = isApproved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626);
                    final textColor = isApproved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF9CA3AF);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: '$statusText ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            TextSpan(
                              text: 'S: $sName -> T: $tName',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsPanel() {
    // ၁။ အချိန် Format ပြောင်းပေးမည့် Helper (ဥပမာ - 8/4/2026, 12:52 PM)
    String formatDt(String? dtString) {
      if (dtString == null) return '-';
      try {
        final dt = DateTime.parse(dtString).toLocal();
        final hour = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        return "${dt.month}/${dt.day}/${dt.year}, $hour:$minute $ampm";
      } catch (e) {
        return dtString;
      }
    }

    // ၂။ Title ပေါ်မူတည်ပြီး ဘေးဘောင်အရောင်လေးတွေ ခွဲပေးမည့် Helper
    Color getColor(String title) {
      if (title.contains('အကောင့်သစ်')) {
        return const Color(0xFFEA580C); // လိမ္မော်ရောင်
      }
      if (title.contains('ဆရာခေါ်စာအသစ်')) {
        return const Color(0xFF2563EB); // အပြာရောင်
      }
      if (title.contains('လျှောက်လွှာ')) {
        return const Color(0xFF16A34A); // အစိမ်းရောင်
      }
      if (title.contains('Direct')) {
        return const Color(0xFF9333EA); // ခရမ်းရောင်
      }
      if (title.contains('Profile')) {
        return const Color(0xFF0D9488); // စိမ်းပြာရောင်
      }
      return const Color(0xFF1E3A8A); // အခြားစာများအတွက် Dark Blue
    }

    // ၃။ UI အပိုင်း
    return FutureBuilder(
      future: supabase
          .from('notifications')
          .select()
          .order('timestamp', ascending: false) // အသစ်ဆုံးကို အပေါ်ဆုံးထားမည်
          .limit(50), // နောက်ဆုံး Noti ၅၀ ခုကိုသာ ပြမည်
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notis = snapshot.data as List<dynamic>? ?? [];

        if (notis.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'အချက်ပေးစာ မရှိသေးပါ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: notis.map((item) {
            final title = item['title']?.toString() ?? 'Notification';
            final message = item['message']?.toString() ?? '';
            final timestamp = item['timestamp']?.toString();
            final color = getColor(title);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: color,
                    width: 4,
                  ), // ဘေးဘက် ကာလာလိုင်းလေး
                  top: BorderSide(color: Colors.grey.shade200),
                  right: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(
                          0xFF1E3A8A,
                        ), // ခေါင်းစဉ်ကို Dark Blue ထားမည်
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDt(timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Admin အတွက် 1 New ပေါ်စေမည့် Chat List
  Widget _buildAdminChatList() {
    Future<Map<String, dynamic>> fetchAdminChatData() async {
      final tutors = await supabase
          .from('tutors')
          .select('id, name, username, photo')
          .order('id', ascending: false);
      List unreadList = [];
      try {
        unreadList = await supabase
            .from('chat_messages')
            .select('tutor_id')
            .eq('sender', 'teacher')
            .eq('is_read', false);
      } catch (e) {
        // Fallback
      }
      return {'tutors': tutors, 'unread': unreadList};
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder(
          future: fetchAdminChatData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data as Map<String, dynamic>;
            final tutors = data['tutors'] as List;
            final unreadList = data['unread'] as List;

            final unreadCounts = <int, int>{};
            for (var row in unreadList) {
              final tId = row['tutor_id'] as int;
              unreadCounts[tId] = (unreadCounts[tId] ?? 0) + 1;
            }

            if (tutors.isEmpty) {
              return const Center(
                child: Text(
                  'Chat ပြောရန် ဆရာ မရှိသေးပါ',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: tutors.map((t) {
                final tId = t['id'] as int;
                final unreadCount = unreadCounts[tId] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: getImgProv(t['photo']),
                    ),
                    title: Text(t['name'] ?? t['username'] ?? 'Tutor'),
                    subtitle: const Text(
                      'Admin Chat သို့ ဝင်ရန် နှိပ်ပါ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount New',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.blue,
                          ),
                    onTap: () async {
                      try {
                        await supabase
                            .from('chat_messages')
                            .update({'is_read': true})
                            .eq('tutor_id', tId)
                            .eq('sender', 'teacher');
                      } catch (e) {
                        // Fallback
                      }

                      // ၁။ Chat ထဲသို့ ဝင်မည် (Chat မှ ပြန်ထွက်လာမှ အောက်လိုင်းများ ဆက်အလုပ်လုပ်မည်)
                      await _openPanel(
                        "${t['name'] ?? 'Tutor'} နှင့် Chat",
                        _buildAdminSingleChat(tId),
                      );

                      // ၂။ ပြန်ထွက်လာချိန်တွင် "1 New" ပျောက်သွားအောင် Refresh လုပ်မည်
                      setLocalState(() {});
                      setState(() {});
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Admin ဘက်မှ Chat အပိုင်း
  Widget _buildAdminSingleChat(int tutorId) {
    final chatCtrl = TextEditingController();

    Future<void> sendAdminTextMsg() async {
      if (chatCtrl.text.trim().isEmpty) return;
      final text = chatCtrl.text.trim();
      chatCtrl.clear();
      await supabase.from('chat_messages').insert({
        'tutor_id': tutorId,
        'sender': 'admin',
        'message': text,
        'is_read': false, // ထည့်သွင်းပေးလိုက်ပါသည်
      });
    }

    Future<void> sendAdminImage() async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 25,
        );

        if (image != null) {
          final fileBytes = await image.readAsBytes();
          final base64Image = base64Encode(fileBytes);
          final ext = image.name.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
          final dataUri = 'data:image/$ext;base64,$base64Image';

          await supabase.from('chat_messages').insert({
            'tutor_id': tutorId,
            'sender': 'admin',
            'message': '[ဓာတ်ပုံ]',
            'image_data': dataUri,
            'is_read': false,
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ပုံပို့ရာတွင် အမှားရှိပါသည် (ပုံအရွယ်အစား ကြီးလွန်းနေနိုင်ပါသည်)',
              ),
            ),
          );
        }
      }
    }

    return Container(
      height: 550,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB),
              child: StreamBuilder(
                stream: supabase
                    .from('chat_messages')
                    .stream(primaryKey: ['id'])
                    .eq('tutor_id', tutorId)
                    .order('timestamp', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snapshot.data as List;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final m = msgs[index];
                      final isAdmin = m['sender'] == 'admin';
                      final rawMsg = m['message']?.toString() ?? '';
                      final imgData = m['image_data']?.toString();

                      // ပုံအမျိုးအစား ခွဲခြားခြင်း
                      String? finalImgUrl;
                      String textToShow = rawMsg;

                      if (imgData != null && imgData.trim().isNotEmpty) {
                        finalImgUrl = imgData;
                        if (rawMsg == '[ဓာတ်ပုံ]') textToShow = '';
                      } else if (rawMsg.startsWith('[IMAGE]')) {
                        finalImgUrl = rawMsg.substring(7);
                        textToShow = '';
                      } else if (rawMsg.startsWith('data:image')) {
                        finalImgUrl = rawMsg;
                        textToShow = '';
                      }

                      final hasImage = finalImgUrl != null;

                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.55,
                          ),
                          padding: hasImage && textToShow.isEmpty
                              ? const EdgeInsets.all(6)
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(0xFF9333EA)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isAdmin ? 16 : 0),
                              bottomRight: Radius.circular(isAdmin ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!hasImage || textToShow.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    isAdmin ? 'Admin' : 'Teacher',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                          ? Colors.purple.shade100
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: getImgProv(finalImgUrl) != null
                                      ? Image(
                                          image: getImgProv(finalImgUrl)!,
                                          width: 250,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                ),
                              if (hasImage && textToShow.isNotEmpty)
                                const SizedBox(height: 8),
                              if (textToShow.isNotEmpty)
                                Text(
                                  textToShow,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isAdmin
                                        ? Colors.white
                                        : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF4B5563)),
                  onPressed: sendAdminImage,
                  tooltip: 'ပုံပို့မည်',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: chatCtrl,
                  decoration: InputDecoration(
                    hintText: 'စာရိုက်ပါ...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA)),
                    ),
                  ),
                  onSubmitted: (_) => sendAdminTextMsg(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: sendAdminTextMsg,
                  tooltip: 'ပို့မည်',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlacklistTutors() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder(
          future: supabase
              .from('tutors')
              .select('*')
              .eq('status', 'blacklisted')
              .order('id', ascending: true),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data as List;
            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Blacklist စာရင်း မရှိသေးပါ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Column(
              children: data.map((t) {
                final nameStr =
                    (t['name'] != null &&
                        t['name'].toString().trim().isNotEmpty)
                    ? t['name']
                    : "User: ${t['username']}";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.block,
                            color: Color(0xFFB91C1C),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            nameStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ph: ${t['phone'] ?? '-'} | အကြောင်းရင်း: ${t['reject_reason'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                  'Unblock Tutor',
                                  style: TextStyle(color: Color(0xFF16A34A)),
                                ),
                                content: Text(
                                  '\'$nameStr\' ကို Blacklist မှ ပယ်ဖျက်မည် သေချာပါသလား?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await supabase
                                          .from('tutors')
                                          .update({
                                            'status': 'approved',
                                            'reject_reason': '',
                                          })
                                          .eq('id', t['id']);
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Blacklist မှ ပယ်ဖျက်ပြီးပါပြီ',
                                            ),
                                          ),
                                        );
                                        setLocalState(() {});
                                      }
                                    },
                                    child: const Text('ပယ်ဖျက်မည်'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text(
                            'Blacklist မှ ပယ်ဖျက်မည် (Unblock)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// =========================================================================
// 5. STATIC PAGES (Static Screens)
// =========================================================================
class BlacklistScreen extends StatelessWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Black Listed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        color: Color(0xFFDC2626),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Black Listed စာရင်း',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: supabase
                        .from('tutors')
                        .select('*')
                        .eq('status', 'blacklisted'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFFDC2626),
                          ),
                        );
                      }
                      final data = snapshot.data as List;
                      if (data.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          child: Text(
                            'Blacklist စာရင်း မရှိသေးပါ',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }
                      return Column(
                        children: data
                            .map(
                              (t) => Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                color: const Color(0xFFFEF2F2),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: Color(0xFFFCA5A5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.block,
                                    color: Color(0xFFDC2626),
                                  ),
                                  title: Text(
                                    t['name'] ?? t['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      "အကြောင်းရင်း: ${t['reject_reason'] ?? '-'}",
                                      style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  const SizedBox(height: 24),
                  _buildText(
                    '၁။ ဤ Platform သည် ဆရာနှင့် ကျောင်းသား တိုက်ရိုက်ချိတ်ဆက်ပေးသော နေရာသာဖြစ်သည်။',
                  ),
                  _buildText(
                    '၂။ ချိတ်ဆက်မှု ဝန်ဆောင်ခကို ဆရာများဘက်မှ ပေးရပါမည်။',
                  ),
                  _buildText(
                    '၃။ ချိတ်ဆက်မှု ဝန်ဆောင်ခကို ကျောင်းသားများဘက်မှ ပေးစရာမလိုပါ။',
                  ),
                  _buildText(
                    '၄။ ချိတ်ဆက်မှု ဝန်ဆောင်ခမှာ ပထမလ၏ ၁၀% ကို ပေးချေရမှာဖြစ်ပါသည်။',
                  ),
                  _buildText(
                    '၅။ ကျောင်းသားမိဘများအနေဖြင့် လစာအား ပထမဦးဆုံးနေ့တွင် ဆရာအား တစ်လစာ ကြိုတင်ပေးချေရပါမည်။',
                  ),
                  _buildText('၆။ အချက်အလက်များကို မှန်ကန်စွာ ဖြည့်စွက်ရပါမည်။'),
                  _buildText(
                    '၇။ လိမ်လည်မှုများ၊ စည်းကမ်းဖောက်ဖျက်မှုများ တွေ့ရှိပါက Blacklist သွင်းခံရပါမည်။',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherGuideScreen extends StatelessWidget {
  const TeacherGuideScreen({super.key});

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Teacher Guide',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.co_present,
                        color: Color(0xFF0F766E),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Teacher User Guide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildText(
                    '၁။ အကောင့်အသစ်ပြုလုပ်ရန် Register တွင် မိမိ Username နှင့် Password ဖြည့်ပါ (ဥပမာ - KyawKyaw, Kk@12345)။',
                  ),
                  _buildText(
                    '၂။ Login ဝင်ပြီးနောက် မိမိ ကိုယ်ရေးအချက်အလက်၊ ဓာတ်ပုံ၊ သင်ကြားနိုင်သော အတန်း/ဘာသာရပ်များကို \'Profile ပြင်ဆင်မည်\' နှိပ်၍ ဖြည့်စွက်ပါ။',
                  ),
                  _buildText(
                    '၃။ အချက်အလက်များ ဖြည့်ပြီးပါက Admin ထံ အတည်ပြုချက်စောင့်ပါ။ Admin Approve ပေးမှသာ ကျောင်းသားများ မြင်တွေ့ရပါမည်။',
                  ),
                  _buildText(
                    '၄။ \'Post များ\' Tab တွင် ကျောင်းသားများ တင်ထားသော ဆရာခေါ်စာများကို လေ့လာ၍ \'Apply\' နှိပ်ပြီး လျှောက်ထားနိုင်ပါသည်။',
                  ),
                  _buildText(
                    '၅။ Admin နှင့် တိုက်ရိုက် စကားပြောလိုပါက \'Admin Chat\' ကို အသုံးပြုနိုင်ပါသည်။',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentGuideScreen extends StatelessWidget {
  const StudentGuideScreen({super.key});

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Student Guide',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, color: Color(0xFFEA580C), size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Student User Guide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildText(
                    '၁။ ပထမဦးစွာ Register တွင် အကောင့်ပြုလုပ်ပါ (ဥပမာ - Username: MaMa, Password: မိမိဖုန်းနံပါတ်)။',
                  ),
                  _buildText(
                    '၂။ \'ဆရာရှာရန်\' တွင် မိမိနေထိုင်ရာ တိုင်းနှင့် မြို့နယ် ရွေးချယ်/ရိုက်ထည့်ပြီး ကိုက်ညီသော ဆရာများ၏ Profile ကို ကြည့်ရှုနိုင်ပါသည်။',
                  ),
                  _buildText(
                    '၃။ သဘောကျသော ဆရာတွေ့ပါက \'ဒီဆရာနဲ့ သင်မယ်\' ကိုနှိပ်၍ Admin ထံ တောင်းဆိုနိုင်ပါသည်။',
                  ),
                  _buildText(
                    '၄။ \'Post တင်ရန်\' တွင် မိမိလိုချင်သော ဘာသာရပ်၊ သင်ကြားလိုသော ဒေသနှင့် ပေးနိုင်သည့် ကြေးနှုန်းထားများ ဖြည့်စွက်၍ Post တင်နိုင်ပါသည်။',
                  ),
                  _buildText(
                    '၅။ \'မိမိ၏ Post များ\' Tab တွင် မိမိတင်ထားသော Post ကို ဆရာမည်မျှ လျှောက်ထားသည်ကို ကြည့်ရှုနိုင်ပါသည်။',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2234),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text(
              'နောက်သို့',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Color(0xFF16A34A),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  const SizedBox(height: 24),
                  const Text(
                    'အဆင်မပြေမှုများနှင့် အကြံပြုလိုသည်များ ရှိပါက ဆက်သွယ်နိုင်ပါသည်။',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'teachermatching@gmail.com',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
