import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { fact, myth, tip, knowledge, advice }

class WellnessContentModel {
  final String id; // Unique String ID (e.g., 'fact_001') to prevent duplicates
  final String title;
  final String body;
  final String bodyHi;
  final String bodyOd;
  final ContentType type;
  final List<String> tags; // e.g., ['diabetes', 'general', 'weight_loss']
  final String? imageUrl;

  WellnessContentModel({
    required this.id,
    required this.title,
    required this.body,
    required this.bodyHi,
    required this.bodyOd,
    required this.type,
    required this.tags,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'bodyHi': bodyHi,
      'bodyOd': bodyOd,
      'type': type.name, // 'fact', 'myth', etc.
      'tags': tags,
      'imageUrl': imageUrl,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// 🎯 THE DATA LIBRARY
final List<WellnessContentModel> wellnessLibraryData = [
  // --- DIABETES / SUGAR ---
  WellnessContentModel(
    id: 'diabetes_tip_portioncontrol',
    type: ContentType.tip,
    tags: ['diabetes', 'diet'],
    title: "Portion Control Helps",
    body: "Smaller, balanced portions help prevent sudden glucose spikes.",
    bodyHi: "छोटी और संतुलित प्लेट शुगर लेवल को अचानक बढ़ने से रोकती है।",
    bodyOd: "ଛୋଟ ଏବଂ ସମତୋଳିତ ପ୍ଲେଟ୍ ହଠାତ୍ ଶୁଗର ବୃଦ୍ଧିକୁ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_fact_fiber',
    type: ContentType.fact,
    tags: ['diabetes', 'fiber'],
    title: "Fiber Slows Sugar Absorption",
    body:
        "High-fiber foods slow glucose absorption and support stable blood sugar.",
    bodyHi:
        "फाइबर युक्त भोजन ग्लूकोज अवशोषण को धीमा करता है और शुगर नियंत्रण में मदद करता है।",
    bodyOd: "ଫାଇବର୍ ଥିବା ଖାଦ୍ୟ ଗ୍ଲୁକୋଜ୍ ଶୋଷଣକୁ ଧୀର କରେ ଏବଂ ଶୁଗରକୁ ସ୍ଥିର ରଖେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_myth_riceban',
    type: ContentType.myth,
    tags: ['diabetes', 'carbs'],
    title: "Myth: Diabetics Can’t Eat Rice",
    body:
        "You can eat rice in controlled portions paired with protein or fiber.",
    bodyHi:
        "डायबिटीज में चावल बिल्कुल बंद नहीं है—बस मात्रा और संयोजन का ध्यान रखें।",
    bodyOd:
        "ଡାୟବେଟିଜ୍ ରେ ଚାଉଳ ପୂରାପୂରି ବନ୍ଦ ନୁହେଁ—ମାତ୍ରା ଓ ଠିକ୍ ବ୍ୟବସ୍ଥାପନ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'diabetes_advice_hydration',
    type: ContentType.advice,
    tags: ['diabetes', 'hydration'],
    title: "Hydration Matters",
    body: "Good hydration helps kidneys flush excess glucose effectively.",
    bodyHi:
        "पर्याप्त पानी किडनी को अतिरिक्त शुगर बाहर निकालने में मदद करता है।",
    bodyOd:
        "ପର୍ଯ୍ୟାପ୍ତ ପାଣି କିଡନିକୁ ଅତିରିକ୍ତ ଗ୍ଲୁକୋଜ୍ ବାହାର କରିବାରେ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_knowledge_glycemicindex',
    type: ContentType.knowledge,
    tags: ['diabetes', 'glycemic_index'],
    title: "Know Your GI",
    body: "Low-GI foods reduce spikes and help long-term sugar control.",
    bodyHi:
        "लो-GI भोजन शुगर स्पाइक्स को कम करता है और दीर्घकालीन नियंत्रण में मदद करता है।",
    bodyOd: "ଲୋ-GI ଖାଦ୍ୟ ଶୁଗର ବୃଦ୍ଧିକୁ କମାଇ ଦୀର୍ଘକାଳୀନ ନିୟନ୍ତ୍ରଣ ଦେଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'pcos_tip_strengthtraining',
    type: ContentType.tip,
    tags: ['pcos', 'exercise'],
    title: "Strength Training Helps Hormones",
    body:
        "Regular strength training improves insulin sensitivity and hormone balance.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग इंसुलिन संवेदनशीलता और हार्मोन संतुलन सुधारती है।",
    bodyOd:
        "ଷ୍ଟ୍ରେନ୍ଥ୍ ଟ୍ରେନିଂ ଇନ୍ସୁଲିନ୍ ସେନ୍ସିଟିଭିଟି ଏବଂ ହର୍ମୋନ ସମତୋଳନକୁ ଉନ୍ନତ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_fact_inflammation',
    type: ContentType.fact,
    tags: ['pcos', 'inflammation'],
    title: "PCOS and Inflammation",
    body:
        "Women with PCOS often have low-grade inflammation that affects metabolism.",
    bodyHi:
        "PCOS में अक्सर हल्की सूजन होती है जो मेटाबॉलिज़्म को प्रभावित करती है।",
    bodyOd: "PCOS ରେ ସାଧାରଣତଃ ହ୍ଳଦ୍ର ସୁଜନ ଥାଏ ଯାହା ମେଟାବୋଲିଜମ୍କୁ ପ୍ରଭାବ ପକାଏ।",
  ),
  WellnessContentModel(
    id: 'pcos_myth_weightonly',
    type: ContentType.myth,
    tags: ['pcos', 'misconceptions'],
    title: "Myth: PCOS Comes Only From Weight",
    body:
        "PCOS is hormonal, not just weight-related; even lean women can have it.",
    bodyHi: "PCOS केवल वजन से नहीं होता; पतली महिलाओं में भी यह हो सकता है।",
    bodyOd: "PCOS କେବଳ ୱେଟ୍ ନୁହେଁ; ପତଳା ମହିଳାମାନେ ମଧ୍ୟ ଏହାରେ ପୀଡିତ ହୋଇପାରନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'pcos_advice_sleepcycle',
    type: ContentType.advice,
    tags: ['pcos', 'sleep'],
    title: "Support Your Sleep Cycle",
    body: "Good sleep helps regulate hormones and reduces cravings.",
    bodyHi: "अच्छी नींद हार्मोन संतुलन में मदद करती है और क्रेविंग कम करती है।",
    bodyOd: "ଭଲ ଘୁମ୍ ହର୍ମୋନ ସମତୋଳନ ଏବଂ ଖାଦ୍ୟ ଇଚ୍ଛାକୁ କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'pcos_knowledge_insulinresistance',
    type: ContentType.knowledge,
    tags: ['pcos', 'insulin'],
    title: "Insulin Resistance in PCOS",
    body:
        "Many women with PCOS develop insulin resistance, affecting weight and periods.",
    bodyHi:
        "PCOS में कई महिलाओं में इंसुलिन रेसिस्टेंस होता है जो वजन और पीरियड्स को प्रभावित करता है।",
    bodyOd:
        "PCOS ରେ ବହୁତ ମହିଳା ଇନ୍ସୁଲିନ୍ ରେସିସ୍ଟାନ୍ସ ଜନ୍ମାଏ, ଯାହା ୱେଟ୍ ଏବଂ ପିରିଅଡ୍କୁ ପ୍ରଭାବିତ କରେ।",
  ),

  WellnessContentModel(
    id: 'hypertension_tip_saltlimit',
    type: ContentType.tip,
    tags: ['hypertension', 'diet'],
    title: "Limit Your Salt",
    body: "Keeping sodium low helps reduce blood pressure significantly.",
    bodyHi: "नमक की मात्रा कम रखने से ब्लड प्रेशर नियंत्रण में रहता है।",
    bodyOd: "ଲୁଣ କମ୍ ଖାଇବା ବ୍ଲଡ୍ ପ୍ରେସରକୁ ନିୟନ୍ତ୍ରଣରେ ରଖେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_fact_potassium',
    type: ContentType.fact,
    tags: ['hypertension', 'minerals'],
    title: "Potassium Protects",
    body: "Foods rich in potassium help counteract sodium’s effect on BP.",
    bodyHi:
        "पोटैशियम से भरपूर भोजन सोडियम के प्रभाव को कम कर BP नियंत्रण में मदद करता है।",
    bodyOd: "ପୋଟାସିଅମ୍ ଥିବା ଖାଦ୍ୟ ସୋଡିଅମ୍ ପ୍ରଭାବକୁ କମାଇ BP ସ୍ଥିର କରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_myth_onlymeds',
    type: ContentType.myth,
    tags: ['hypertension', 'lifestyle'],
    title: "Myth: Only Medicines Help",
    body:
        "Lifestyle changes like exercise and diet can lower BP as effectively as medicines.",
    bodyHi: "सिर्फ दवाइयाँ ही नहीं, व्यायाम और सही आहार भी BP कम कर सकते हैं।",
    bodyOd: "କେବଳ ଔଷଧ ନୁହେଁ, ବ୍ୟାୟାମ ଓ ଠିକ୍ ଆହାର ମଧ୍ୟ BP କମାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_advice_walk',
    type: ContentType.advice,
    tags: ['hypertension', 'exercise'],
    title: "Walk Daily",
    body: "A brisk 30-minute walk improves circulation and reduces BP.",
    bodyHi: "तेज़ 30 मिनट की वॉक सर्कुलेशन सुधारती है और BP कम करती है।",
    bodyOd: "ତୀବ୍ର 30 ମିନିଟ୍ ହାଟିବା ସର୍କୁଲେସନ୍ ଉନ୍ନତ କରେ ଏବଂ BP କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_knowledge_dash',
    type: ContentType.knowledge,
    tags: ['hypertension', 'diet'],
    title: "Know the DASH Diet",
    body: "DASH emphasizes fruits, vegetables, and low-fat dairy to lower BP.",
    bodyHi:
        "DASH डाइट फलों, सब्ज़ियों और लो-फैट डेयरी पर जोर देती है जिससे BP नियंत्रित होता है।",
    bodyOd: "DASH ଡାଏଟ୍ ଫଳ, ସବ୍ଜି ଓ ଲୋ ଫ୍ୟାଟ୍ ଡେରିରେ ଜୋର ଦେଇ BP କମାଏ।",
  ),

  WellnessContentModel(
    id: 'thyroid_tip_iodinerich',
    type: ContentType.tip,
    tags: ['thyroid', 'minerals'],
    title: "Iodine Supports Thyroid",
    body: "Foods with natural iodine help proper hormone production.",
    bodyHi: "आयोडीन युक्त भोजन थायराइड हार्मोन बनाने में सहायक है।",
    bodyOd: "ଆୟୋଡିନ୍ ଥିବା ଖାଦ୍ୟ ଠିକ୍ ହର୍ମୋନ ଉତ୍ପାଦନକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_hypoenergy',
    type: ContentType.fact,
    tags: ['thyroid', 'metabolism'],
    title: "Hypothyroid Slows Energy",
    body:
        "Low thyroid levels slow metabolism, causing fatigue and weight gain.",
    bodyHi:
        "कम थायराइड मेटाबॉलिज्म को धीमा करता है जिससे थकान और वजन बढ़ सकता है।",
    bodyOd: "କମ୍ ଥାଇରଏଡ୍ ମେଟାବୋଲିଜମ୍ କୁ ଧୀର କରେ, କ୍ଲାନ୍ତି ଏବଂ ୱେଟ୍ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_myth_onlywomen',
    type: ContentType.myth,
    tags: ['thyroid', 'awareness'],
    title: "Myth: Thyroid Affects Only Women",
    body: "Men can also develop thyroid disorders, though less commonly.",
    bodyHi: "थायराइड सिर्फ महिलाओं में नहीं होता, पुरुषों में भी हो सकता है।",
    bodyOd: "ଥାଇରଏଡ୍ କେବଳ ମହିଳାଙ୍କୁ ନୁହେଁ, ପୁରୁଷମାନେ ମଧ୍ୟ ପୀଡିତ ହୋଇପାରନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'thyroid_advice_timelymeds',
    type: ContentType.advice,
    tags: ['thyroid', 'medication'],
    title: "Take Thyroid Medicine Right",
    body:
        "Thyroid medication works best on an empty stomach at the same time daily.",
    bodyHi:
        "थायराइड दवा खाली पेट और रोज़ एक ही समय पर लेने से बेहतर असर करती है।",
    bodyOd: "ଥାଇରଏଡ୍ ଔଷଧ ଖାଲି ପେଟ୍ ଏବଂ ଏକ ସମୟରେ ନେଲେ ଭଲ କାମ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_knowledge_autoimmune',
    type: ContentType.knowledge,
    tags: ['thyroid', 'immune'],
    title: "Autoimmune Thyroid",
    body: "Hashimoto’s is an autoimmune condition causing hypothyroidism.",
    bodyHi: "हाशिमोटो एक ऑटोइम्यून बीमारी है जो हाइपोथायराइड पैदा करती है।",
    bodyOd: "ହାଶିମୋଟୋ ଏକ ଅଟୋଇମ୍ୟୁନ୍ ରୋଗ ଯାହା ହାଇପୋଥାଇରଏଡ୍ ସୃଷ୍ଟି କରେ।",
  ),

  WellnessContentModel(
    id: 'cardiac_tip_healthyfats',
    type: ContentType.tip,
    tags: ['cardiac', 'diet'],
    title: "Choose Healthy Fats",
    body:
        "Replacing saturated fats with unsaturated fats improves heart health.",
    bodyHi: "सैचुरेटेड फैट की जगह हेल्दी फैट लेने से हृदय स्वस्थ रहता है।",
    bodyOd: "ସାଚୁରେଟେଡ୍ ଫ୍ୟାଟ୍ ବଦଳରେ ହେଲ୍ଥି ଫ୍ୟାଟ୍ ନେଲେ ହୃଦୟ ସ୍ୱସ୍ଥ ରହେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_fact_walking',
    type: ContentType.fact,
    tags: ['cardiac', 'exercise'],
    title: "Walking Protects the Heart",
    body: "A 30-minute walk daily reduces heart disease risk significantly.",
    bodyHi: "30 मिनट की रोज़ाना वॉक हृदय रोग का खतरा कम करती है।",
    bodyOd: "ରୋଜ 30 ମିନିଟ୍ ହାଟିବା ହୃଦରୋଗ ଝୁଞ୍ଜଟ କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'cardiac_myth_cholonly',
    type: ContentType.myth,
    tags: ['cardiac', 'cholesterol'],
    title: "Myth: Only High Cholesterol Causes Heart Disease",
    body:
        "Blood pressure, stress, diabetes, and lifestyle also play major roles.",
    bodyHi:
        "हृदय रोग सिर्फ कोलेस्ट्रॉल से नहीं, BP, तनाव और डायबिटीज से भी होता है।",
    bodyOd:
        "ହୃଦରୋଗ କେବଳ କଲେଷ୍ଟରଲ୍ ନୁହେଁ, BP, ଷ୍ଟ୍ରେସ୍ ଏବଂ ଡାୟବେଟିଜ୍ ମଧ୍ୟ ଦାୟୀ।",
  ),
  WellnessContentModel(
    id: 'cardiac_advice_stresscut',
    type: ContentType.advice,
    tags: ['cardiac', 'stress'],
    title: "Manage Daily Stress",
    body: "Lowering stress reduces inflammation and protects your heart.",
    bodyHi: "तनाव कम करने से सूजन घटती है और दिल स्वस्थ रहता है।",
    bodyOd: "ଷ୍ଟ୍ରେସ୍ କମାଇଲେ ସୁଜନ୍ କମେ ଏବଂ ହୃଦୟ ରକ୍ଷିତ ରହେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_knowledge_bpcontrol',
    type: ContentType.knowledge,
    tags: ['cardiac', 'hypertension'],
    title: "BP Control Is Heart Protection",
    body: "Keeping BP normal reduces heart attack and stroke risk drastically.",
    bodyHi:
        "BP नियंत्रण रखने से हार्ट अटैक और स्ट्रोक का खतरा काफी कम होता है।",
    bodyOd: "BP ନିୟନ୍ତ୍ରଣ ହୃଦାଘାତ ଓ ଷ୍ଟ୍ରୋକ୍ ଝୁଞ୍ଞଟ କମାଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'renal_tip_waterbalance',
    type: ContentType.tip,
    tags: ['renal', 'hydration'],
    title: "Hydration for Kidney Health",
    body: "Adequate fluids help kidneys filter waste effectively.",
    bodyHi: "पर्याप्त पानी किडनी को अपशिष्ट छानने में मदद करता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି କିଡନିକୁ ବର୍ଜ୍ୟ ପଦାର୍ଥ ଚାନଁଇବାରେ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_fact_saltstrain',
    type: ContentType.fact,
    tags: ['renal', 'salt'],
    title: "Salt Adds Kidney Strain",
    body: "Excess sodium increases kidney workload and raises BP.",
    bodyHi: "अधिक सोडियम किडनी पर भार बढ़ाता है और BP बढ़ा सकता है।",
    bodyOd: "ଅଧିକ ସୋଡିଅମ୍ କିଡନିର କାମ ବଢ଼ାଇ BP ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_myth_proteinban',
    type: ContentType.myth,
    tags: ['renal', 'protein'],
    title: "Myth: All Protein Is Bad for Kidneys",
    body:
        "Moderate, good-quality protein is safe unless told otherwise by a doctor.",
    bodyHi:
        "सही मात्रा में अच्छा प्रोटीन सुरक्षित है, जब तक डॉक्टर मना न करें।",
    bodyOd: "ଠିକ୍ ମାତ୍ରାର ସୁସ୍ଥ ପ୍ରୋଟିନ୍ କିଡନି ପାଇଁ ସୁରକ୍ଷିତ।",
  ),
  WellnessContentModel(
    id: 'renal_advice_regularcheck',
    type: ContentType.advice,
    tags: ['renal', 'monitoring'],
    title: "Get Regular Kidney Tests",
    body: "Creatinine and urine tests help detect early kidney stress.",
    bodyHi:
        "क्रिएटिनिन और यूरिन टेस्ट किडनी की शुरुआती समस्या पकड़ने में मदद करते हैं।",
    bodyOd: "କ୍ରିଏଟିନିନ୍ ଓ ୟୁରିନ୍ ପରୀକ୍ଷା କିଡନି ସମସ୍ୟା ଶୀଘ୍ର ଚିହ୍ନଟ କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_knowledge_potassiumcontrol',
    type: ContentType.knowledge,
    tags: ['renal', 'minerals'],
    title: "Potassium Needs Monitoring",
    body:
        "Kidney patients must monitor potassium to avoid heart rhythm issues.",
    bodyHi:
        "किडनी मरीजों को पोटैशियम पर ध्यान रखना चाहिए ताकि हार्ट रिदम समस्या न हो।",
    bodyOd:
        "କିଡନି ରୋଗୀମାନେ ପୋଟାସିଅମ୍ ନିୟନ୍ତ୍ରଣ କରିବା ଜରୁରୀ, ନହେଲେ ହୃଦରିତ୍ମ ସମସ୍ୟା ହୋଇପାରେ।",
  ),

  WellnessContentModel(
    id: 'fattyliver_tip_sugarcut',
    type: ContentType.tip,
    tags: ['fatty_liver', 'diet'],
    title: "Reduce Added Sugar",
    body: "Lowering sugary foods helps reduce liver fat buildup.",
    bodyHi: "मीठे खाद्य कम करने से लिवर में जमा वसा कम होती है।",
    bodyOd: "ମିଠା ଖାଦ୍ୟ କମାଇଲେ ଲିଭର୍ ଫ୍ୟାଟ୍ କମେ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_fact_weightloss',
    type: ContentType.fact,
    tags: ['fatty_liver', 'weight_loss'],
    title: "Even 5% Weight Loss Helps",
    body:
        "A small weight loss improves liver enzymes and reduces fat accumulation.",
    bodyHi: "केवल 5% वजन घटाने से भी लिवर एंज़ाइम सुधरते हैं।",
    bodyOd: "ମାତ୍ର 5% ୱେଟ୍ କମିଲେ ମଧ୍ୟ ଲିଭର୍ ଇଂଜାଇମ୍ ଭଲ ହୋଇଯାଏ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_myth_friedfoodsok',
    type: ContentType.myth,
    tags: ['fatty_liver', 'oil'],
    title: "Myth: Fried Foods Are Harmless",
    body: "Fatty liver worsens with regularly fried or oily foods.",
    bodyHi: "फैटी लिवर में तले हुए भोजन से स्थिति खराब हो सकती है।",
    bodyOd: "ଫ୍ୟାଟି ଲିଭର୍ ରେ ତଳା ଖାଦ୍ୟ ଅବସ୍ଥା ଖରାପ କରେ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_advice_activity',
    type: ContentType.advice,
    tags: ['fatty_liver', 'exercise'],
    title: "Stay Active Daily",
    body:
        "Regular activity improves fat metabolism and supports liver recovery.",
    bodyHi:
        "नियमित सक्रियता वसा चयापचय सुधारती है और लिवर रिकवरी में मदद करती है।",
    bodyOd: "ନିୟମିତ ସକ୍ରିୟତା ଫ୍ୟାଟ୍ ମେଟାବୋଲିଜମ୍ ଉନ୍ନତ କରି ଲିଭର୍ ସୁସ୍ଥ କରେ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_knowledge_insulinlink',
    type: ContentType.knowledge,
    tags: ['fatty_liver', 'insulin'],
    title: "Insulin Resistance and Liver Fat",
    body: "High insulin levels promote fat storage in the liver.",
    bodyHi: "इंसुलिन रेसिस्टेंस लिवर में वसा जमाव बढ़ाता है।",
    bodyOd: "ଇନ୍ସୁଲିନ୍ ରେସିସ୍ଟାନ୍ସ ଲିଭର୍ ଫ୍ୟାଟ୍ ବୃଦ୍ଧି କରିଥାଏ।",
  ),

  WellnessContentModel(
    id: 'cholesterol_tip_oats',
    type: ContentType.tip,
    tags: ['cholesterol', 'fiber'],
    title: "Oats Lower Bad Cholesterol",
    body: "Beta-glucan fiber in oats reduces LDL cholesterol naturally.",
    bodyHi: "ओट्स में मौजूद बीटा-ग्लूकन LDL कोलेस्ट्रॉल कम करता है।",
    bodyOd: "ଓଟସ୍ ରେ ଥିବା ବେଟା-ଗ୍ଲୁକାନ୍ LDL କଲେଷ୍ଟରଲ୍ କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_fact_goodfatbenefits',
    type: ContentType.fact,
    tags: ['cholesterol', 'healthy_fats'],
    title: "Healthy Fats Improve Levels",
    body: "Unsaturated fats raise HDL and reduce LDL when used right.",
    bodyHi: "हेल्दी फैट HDL बढ़ाते हैं और LDL को कम करने में मदद करते हैं।",
    bodyOd: "ହେଲ୍ଥି ଫ୍ୟାଟ୍ HDL ବଢ଼ାଇ ଏବଂ LDL କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_myth_allfatbad',
    type: ContentType.myth,
    tags: ['cholesterol', 'diet'],
    title: "Myth: All Fat Is Bad",
    body: "Your body needs healthy fats for hormones and cell function.",
    bodyHi:
        "सभी फैट खराब नहीं; शरीर को कुछ हेल्दी फैट हार्मोन और कोशिका कार्य के लिए चाहिए।",
    bodyOd:
        "ସମସ୍ତ ଫ୍ୟାଟ୍ ଖରାପ ନୁହେଁ; ଶରୀରକୁ ହର୍ମୋନ ଓ ସେଲ୍ କାମ ପାଇଁ ଭଲ ଫ୍ୟାଟ୍ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'cholesterol_advice_labelcheck',
    type: ContentType.advice,
    tags: ['cholesterol', 'awareness'],
    title: "Check Food Labels",
    body:
        "Avoid trans fats and limit saturated fats by reading labels carefully.",
    bodyHi: "लेबल देखकर ट्रांस फैट से बचें और सैचुरेटेड फैट सीमित करें।",
    bodyOd:
        "ଲେବେଲ୍ ପଢ଼ି ଟ୍ରାନ୍ସ ଫ୍ୟାଟ୍ ରୁ ଦୂରେ ରୁହନ୍ତୁ ଏବଂ ସାଚୁରେଟେଡ୍ ଫ୍ୟାଟ୍ କମାନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_knowledge_lipids',
    type: ContentType.knowledge,
    tags: ['cholesterol', 'lipid_profile'],
    title: "Know Your Lipid Profile",
    body:
        "LDL, HDL, triglycerides, and total cholesterol all matter for heart health.",
    bodyHi:
        "LDL, HDL, ट्राइग्लिसराइड और कुल कोलेस्ट्रॉल सभी हृदय स्वास्थ्य में महत्वपूर्ण हैं।",
    bodyOd:
        "LDL, HDL, ଟ୍ରାଇଗ୍ଲିସରାଇଡ୍ ଏବଂ ମୋଟ କଲେଷ୍ଟରଲ୍ ହୃଦୟ ପାଇଁ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ।",
  ),

  WellnessContentModel(
    id: 'anemia_tip_ironsources',
    type: ContentType.tip,
    tags: ['anemia', 'iron'],
    title: "Add Iron-Rich Foods",
    body:
        "Green leafy vegetables, jaggery, and lentils help increase iron levels.",
    bodyHi: "हरी सब्ज़ियाँ, गुड़ और दालें आयरन स्तर बढ़ाने में मदद करती हैं।",
    bodyOd: "ଶାକସବ୍ଜି, ଗୁଡ଼ ଓ ଡାଲି ଆୟରନ୍ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_fact_vitcabsorption',
    type: ContentType.fact,
    tags: ['anemia', 'vitamins'],
    title: "Vitamin C Increases Iron Absorption",
    body:
        "Pairing iron foods with vitamin C improves absorption significantly.",
    bodyHi: "आयरन के साथ विटामिन C लेने से इसका अवशोषण बढ़ता है।",
    bodyOd: "ଆୟରନ୍ ସହ ଭିଟାମିନ C ନେଲେ ଶୋଷଣ ଭଲ ହୋଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_myth_onlywomen',
    type: ContentType.myth,
    tags: ['anemia', 'general'],
    title: "Myth: Only Women Get Anemia",
    body: "Men, children, and older adults can also develop anemia.",
    bodyHi:
        "एनीमिया सिर्फ महिलाओं में नहीं, पुरुषों और बच्चों में भी हो सकता है।",
    bodyOd: "ଏନିମିଆ କେବଳ ମହିଳାଙ୍କୁ ନୁହେଁ, ପୁରୁଷ ଓ ଶିଶୁମାନେ ମଧ୍ୟ ପୀଡିତ।",
  ),
  WellnessContentModel(
    id: 'anemia_advice_regulartests',
    type: ContentType.advice,
    tags: ['anemia', 'screening'],
    title: "Check Hemoglobin Regularly",
    body: "Regular tests help detect anemia early and manage it properly.",
    bodyHi:
        "समय-समय पर हीमोग्लोबिन चेक करवाने से एनीमिया जल्दी पकड़ में आता है।",
    bodyOd: "ନିୟମିତ ହିମୋଗ୍ଲୋବିନ ପରୀକ୍ଷା ଏନିମିଆ ଶୀଘ୍ର ଚିହ୍ନଟ କରେ।",
  ),
  WellnessContentModel(
    id: 'anemia_knowledge_types',
    type: ContentType.knowledge,
    tags: ['anemia', 'deficiency'],
    title: "Types of Anemia",
    body: "Iron, B12, and folate deficiency are common anemia causes.",
    bodyHi: "आयरन, B12 और फोलेट की कमी एनीमिया के मुख्य कारण हैं।",
    bodyOd: "ଆୟରନ୍, B12 ଓ ଫୋଲେଟ୍ ଅଭାବ ଏନିମିଆର ସାଧାରଣ କାରଣ।",
  ),

  WellnessContentModel(
    id: 'sicklecell_tip_hydration',
    type: ContentType.tip,
    tags: ['sickle_cell', 'hydration'],
    title: "Stay Hydrated",
    body: "Good hydration helps reduce sickling episodes.",
    bodyHi: "पर्याप्त पानी पीने से सिकलिंग एपिसोड कम हो सकते हैं।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ସିକଲିଂ ଏପିସୋଡ୍ କମାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_fact_triggers',
    type: ContentType.fact,
    tags: ['sickle_cell', 'awareness'],
    title: "Cold Can Trigger Pain",
    body:
        "Sudden cold exposure may worsen pain episodes in sickle cell disease.",
    bodyHi: "अचानक ठंड लगने से सिकल सेल दर्द बढ़ सकता है।",
    bodyOd: "ଅଚାନକ ଠଣ୍ଡାର ସମ୍ପର୍କ ସିକଲ ସେଲ୍ ବେଦନା ବଢ଼ାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_myth_contagious',
    type: ContentType.myth,
    tags: ['sickle_cell', 'general'],
    title: "Myth: Sickle Cell Is Contagious",
    body: "Sickle cell disease is inherited, not infectious.",
    bodyHi: "सिकल सेल कोई संक्रामक बीमारी नहीं, यह आनुवंशिक है।",
    bodyOd: "ସିକଲ ସେଲ୍ ଚୁଆଁ ନୁହେଁ, ଏହା ବଂଶାଗତ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_advice_painplan',
    type: ContentType.advice,
    tags: ['sickle_cell', 'selfcare'],
    title: "Have a Pain-Management Plan",
    body:
        "Knowing early signs and having a plan reduces discomfort and emergencies.",
    bodyHi:
        "जल्द पहचान और एक सही योजना दर्द को कम करती है और इमरजेंसी रोकती है।",
    bodyOd: "ସମୟରେ ଚିହ୍ନଟ ଏବଂ ଯୋଜନା ଥିଲେ ବେଦନା ଏବଂ ଆକସ୍ମିକ ସମସ୍ୟା କମିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_knowledge_genetics',
    type: ContentType.knowledge,
    tags: ['sickle_cell', 'genetics'],
    title: "Understand Sickle Cell Genetics",
    body:
        "Two carrier parents have a 25% chance of a child with sickle cell disease.",
    bodyHi:
        "दो कैरियर माता-पिता के बच्चे को 25% संभावना होती है कि उसे सिकल सेल हो।",
    bodyOd:
        "ଦୁଇଜଣ କ୍ୟାରିଅର୍ ଅଭିଭାବକଙ୍କର ଶିଶୁରେ 25% ସମ୍ଭାବନା ସିକଲ ସେଲ୍ ରୋଗ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_fact_wholegrains',
    type: ContentType.fact,
    tags: ['cholesterol', 'diet'],
    title: "Whole Grains Protect the Heart",
    body:
        "Whole grains like oats and barley help lower LDL cholesterol naturally.",
    bodyHi:
        "ओट्स और जौ जैसे साबुत अनाज एलडीएल कोलेस्ट्रॉल को प्राकृतिक रूप से कम करते हैं।",
    bodyOd:
        "ଓଟସ୍ ଏବଂ ଯବ ଭଳି ସମ୍ପୂର୍ଣ୍ଣ ଧାନ୍ୟ ଏଲ୍‌ଡିଏଲ୍‌ କଲେଷ୍ଟେରଲ୍‌କୁ ପ୍ରାକୃତିକ ଭାବେ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_tip_fiber',
    type: ContentType.tip,
    tags: ['cholesterol', 'fiber'],
    title: "Boost Fiber Intake",
    body:
        "Soluble fiber from fruits and legumes reduces cholesterol absorption in the gut.",
    bodyHi:
        "फलों और दालों में मौजूद घुलनशील फाइबर शरीर में कोलेस्ट्रॉल अवशोषण को कम करता है।",
    bodyOd: "ଫଳ ଏବଂ ଡାଲିର ଘୁଲନଶୀଲ ଫାଇବର୍ ଦେହରେ କଲେଷ୍ଟେରଲ୍‌ ଶୋଷଣକୁ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_myth_oilchange',
    type: ContentType.myth,
    tags: ['cholesterol', 'myth'],
    title: "Myth: Switching Oils Lowers Cholesterol",
    body:
        "Changing oils often doesn't guarantee cholesterol control; it is consistent moderation that helps.",
    bodyHi:
        "बार-बार तेल बदलने से कोलेस्ट्रॉल नियंत्रित नहीं होता; संतुलित मात्रा में उपयोग ही बेहतर है।",
    bodyOd:
        "ବାରମ୍ବାର ତେଲ ବଦଳାଇବାରେ କଲେଷ୍ଟେରଲ୍‌ ନିୟନ୍ତ୍ରଣ ହୁଏ ନାହିଁ; ସମ୍ମିଳିତ ମାତ୍ରାରେ ବ୍ୟବହାର କରିବା ଭଲ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_advice_statins',
    type: ContentType.advice,
    tags: ['cholesterol', 'medication'],
    title: "Follow Statin Schedule",
    body:
        "If prescribed statins, take them regularly to reduce LDL and prevent heart complications.",
    bodyHi:
        "यदि स्टैटिन दवा दी गई है तो इसे नियमित रूप से लें ताकि एलडीएल कम हो और हृदय रोगों का जोखिम घटे।",
    bodyOd:
        "ଯଦି ସ୍ଟାଟିନ୍‌ ଦୌଆ ଦିଆଯାଇଛି, ତାହେଲେ ନିୟମିତ ଭାବେ ନିଅନ୍ତୁ ଯେଣ୍ଣ ଏଲ୍‌ଡିଏଲ୍‌ କମିବ ଏବଂ ହୃଦ ଜଟିଳତା ହ୍ରାସ ପାଇବ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_knowledge_hdl',
    type: ContentType.knowledge,
    tags: ['cholesterol', 'heart_health'],
    title: "Know Your HDL",
    body:
        "HDL cholesterol protects your arteries by carrying bad cholesterol away from them.",
    bodyHi:
        "एचडीएल कोलेस्ट्रॉल खराब कोलेस्ट्रॉल को दूर ले जाकर आपकी धमनियों की रक्षा करता है।",
    bodyOd:
        "HDL କଲେଷ୍ଟେରଲ୍‌ ଖରାପ କଲେଷ୍ଟେରଲ୍‌କୁ ଦୂରେ ନେଇ ନଳୀଗୁଡ଼ିକୁ ସୁରକ୍ଷା କରେ।",
  ),

  // 56
  WellnessContentModel(
    id: 'anemia_fact_ironfoods',
    type: ContentType.fact,
    tags: ['anemia', 'minerals'],
    title: "Iron-Rich Foods Help Recovery",
    body:
        "Spinach, beetroot, jaggery, and legumes support hemoglobin production naturally.",
    bodyHi: "पालक, चुकंदर, गुड़ और दालें हीमोग्लोबिन बढ़ाने में मदद करती हैं।",
    bodyOd: "ପାଲଙ୍ଗ, ବିଟ୍‌, ଗୁଡ଼ ଏବଂ ଡାଲି ପ୍ରାକୃତିକ ଭାବେ ହିମୋଗ୍ଲୋବିନ୍‌ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_tip_vitc_absorption',
    type: ContentType.tip,
    tags: ['anemia', 'vitamins'],
    title: "Pair Iron With Vitamin C",
    body:
        "Vitamin C boosts iron absorption—add lemon or citrus fruits to meals.",
    bodyHi:
        "विटामिन C आयरन के अवशोषण को बढ़ाता है—भोजन में नींबू या साइट्रस फल शामिल करें।",
    bodyOd:
        "ଭିଟାମିନ୍‌ C ଲୋହା ଶୋଷଣ ବଢ଼ାଏ—ଖାଦ୍ୟରେ ଲେମ୍‌ନ୍‌ ବା ସିଟ୍ରସ୍‌ ଫଳ ଯୋଗ କରନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'anemia_myth_onlywomen',
    type: ContentType.myth,
    tags: ['anemia', 'myth'],
    title: "Myth: Only Women Get Anemia",
    body:
        "Men and children can also develop anemia due to poor diet or chronic illness.",
    bodyHi:
        "यह मिथक है कि एनीमिया केवल महिलाओं को होता है; पुरुष और बच्चे भी इससे प्रभावित हो सकते हैं।",
    bodyOd:
        "ଏହା ମିଥ୍‌ ଯେ କେବଳ ମହିଳାମାନେ ଏନିମିଆ ହୁଅନ୍ତି; ପୁରୁଷ ଏବଂ ଶିଶୁମାନେ ମଧ୍ୟ ହୋଇପାରନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'anemia_advice_supplements',
    type: ContentType.advice,
    tags: ['anemia', 'treatment'],
    title: "Don’t Skip Iron Supplements",
    body:
        "Iron supplements work best when taken regularly as prescribed by your doctor.",
    bodyHi:
        "डॉक्टर द्वारा बताए अनुसार नियमित रूप से आयरन सप्लीमेंट लेना सबसे प्रभावी होता है।",
    bodyOd:
        "ଡାକ୍ତର ନିର୍ଦ୍ଦେଶ ଅନୁସାରେ ନିୟମିତ ଲୋହା ସପ୍ଲିମେଣ୍ଟ ନିଅବା ଅତ୍ୟନ୍ତ ପ୍ରଭାବଶାଳୀ।",
  ),
  WellnessContentModel(
    id: 'anemia_knowledge_folic_acid',
    type: ContentType.knowledge,
    tags: ['anemia', 'vitamins'],
    title: "Folic Acid Makes RBCs",
    body:
        "Folic acid is essential for producing healthy red blood cells and preventing anemia.",
    bodyHi:
        "फोलिक एसिड स्वस्थ लाल रक्त कोशिकाओं के निर्माण के लिए आवश्यक है और एनीमिया रोकता है।",
    bodyOd:
        "ଫୋଲିକ୍‌ ଏସିଡ୍‌ ସୁସ୍ଥ ଲାଲ ରକ୍ତକଣି ତିୟାରି ପାଇଁ ଆବଶ୍ୟକ ଏବଂ ଏନିମିଆ ରୋକେ।",
  ),

  // 61
  WellnessContentModel(
    id: 'sicklecell_fact_genetic',
    type: ContentType.fact,
    tags: ['sickle_cell', 'genetics'],
    title: "Sickle Cell Is Genetic",
    body:
        "Sickle cell disease is inherited and cannot be acquired later in life.",
    bodyHi: "सिकल सेल बीमारी अनुवांशिक होती है और जीवन में बाद में नहीं होती।",
    bodyOd: "ସିକେଲ୍‌ ସେଲ୍‌ ରୋଗ ବାଂଶଗତ ଏବଂ ପରେ ଜୀବନରେ ହୁଏ ନାହିଁ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_tip_hydration',
    type: ContentType.tip,
    tags: ['sickle_cell', 'hydration'],
    title: "Stay Hydrated Always",
    body: "Proper hydration reduces the risk of painful sickle cell crises.",
    bodyHi:
        "पर्याप्त पानी पीना सिकल सेल संकट के दर्दनाक एपिसोड के जोखिम को कम करता है।",
    bodyOd: "ଯଥେଷ୍ଟ ପାଣି ପିବା ସିକେଲ୍‌ ସେଲ୍‌ ସଙ୍କଟର ବେଦନାଦାୟକ ଅବସ୍ଥାକୁ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_myth_cure',
    type: ContentType.myth,
    tags: ['sickle_cell', 'myth'],
    title: "Myth: Sickle Cell Has Quick Cure",
    body:
        "Sickle cell disease needs long-term management; there is no instant cure.",
    bodyHi:
        "सिकल सेल बीमारी का कोई त्वरित इलाज नहीं है; इसे दीर्घकालिक प्रबंधन की आवश्यकता होती है।",
    bodyOd:
        "ସିକେଲ୍‌ ସେଲ୍‌ ରୋଗର ଶୀଘ୍ର ଚିକିତ୍ସା ନାହିଁ; ଦୀର୍ଘକାଳୀନ ଦେଖଭାଳ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_advice_folic',
    type: ContentType.advice,
    tags: ['sickle_cell', 'vitamins'],
    title: "Daily Folic Acid Helps",
    body:
        "Folic acid supports red blood cell formation, important for sickle cell patients.",
    bodyHi:
        "फोलिक एसिड लाल रक्त कोशिकाओं के निर्माण में मदद करता है, जो सिकल सेल रोगियों के लिए जरूरी है।",
    bodyOd:
        "ଫୋଲିକ୍‌ ଏସିଡ୍‌ ଲାଲ ରକ୍ତକଣି ତିୟାରିକୁ ସମର୍ଥନ କରେ, ସିକେଲ୍‌ ସେଲ୍‌ ରୋଗୀଙ୍କ ପାଇଁ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ।",
  ),
  WellnessContentModel(
    id: 'sicklecell_knowledge_triggers',
    type: ContentType.knowledge,
    tags: ['sickle_cell', 'lifestyle'],
    title: "Know Crisis Triggers",
    body:
        "Cold temperatures, dehydration, and infections often trigger sickle cell pain episodes.",
    bodyHi:
        "ठंड, पानी की कमी और संक्रमण अक्सर सिकल सेल दर्द के एपिसोड को ट्रिगर करते हैं।",
    bodyOd:
        "ଥଣ୍ଡ, ପାଣିର ଅଭାବ ଏବଂ ସଂକ୍ରମଣ ସିକେଲ୍‌ ସେଲ୍‌ ବେଦନାକୁ ଉତ୍ପ୍ରେରିତ କରେ।",
  ),

  // 66
  WellnessContentModel(
    id: 'diabetes_fact_plate',
    type: ContentType.fact,
    tags: ['diabetes', 'diet'],
    title: "The Diabetic Plate Method Works",
    body:
        "Half plate veggies, one-quarter proteins, and one-quarter whole grains support blood sugar control.",
    bodyHi:
        "आधा प्लेट सब्जियाँ, एक-चौथाई प्रोटीन और एक-चौथाई अनाज ब्लड शुगर नियंत्रण में मदद करते हैं।",
    bodyOd:
        "ଆଧା ପ୍ଲେଟ୍‌ ସବ୍ଜି, ଏକ-ଚତୁର୍ଥାଂଶ ପ୍ରୋଟିନ୍‌ ଏବଂ ଏକ-ଚତୁର୍ଥାଂଶ ପୂର୍ଣ୍ଣ ଧାନ୍ୟ ରକ୍ତସର୍କରାକୁ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_tip_postmealwalk',
    type: ContentType.tip,
    tags: ['diabetes', 'lifestyle'],
    title: "Walk After Meals",
    body: "A 10–15 minute walk after food helps lower post-meal sugar spikes.",
    bodyHi:
        "भोजन के बाद 10–15 मिनट की वॉक भोजन के बाद बढ़ने वाली शुगर को कम करती है।",
    bodyOd: "ଖାଦ୍ୟ ପରେ 10–15 ମିନିଟ୍‌ ହାଟିବା ଖାଦ୍ୟ ପରେ ବଢ଼ୁଥିବା ସର୍କରାକୁ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'diabetes_myth_onlysugar',
    type: ContentType.myth,
    tags: ['diabetes', 'myth'],
    title: "Myth: Diabetes Comes From Sugar Alone",
    body:
        "Genetics, inactivity, sleep patterns, and body weight all play crucial roles.",
    bodyHi:
        "डायबिटीज केवल चीनी से नहीं होती; जीन, जीवनशैली और नींद भी महत्वपूर्ण कारक हैं।",
    bodyOd:
        "ଡାୟବିଟିଜ୍‌ କେବଳ ଚିନିରୁ ହୁଏ ନାହିଁ; ଜିନ୍‌, ଜୀବନଶୈଳୀ ଏବଂ ଘୁମ ମଧ୍ୟ ମହତ୍ତ୍ୱପୂର୍ଣ୍ଣ।",
  ),
  WellnessContentModel(
    id: 'diabetes_advice_medication',
    type: ContentType.advice,
    tags: ['diabetes', 'treatment'],
    title: "Be Consistent With Medication",
    body:
        "Skipping diabetes medicines can cause unpredictable spikes in blood sugar.",
    bodyHi: "डायबिटीज की दवा छोड़ना शुगर लेवल में अचानक उतार-चढ़ाव ला सकता है।",
    bodyOd: "ଡାଏବିଟିଜ୍‌ ଦୌଆ ଛାଡ଼ିଦେବାରେ ଅପେକ୍ଷିତ ନୁହେଁଥିବା ସର୍କରା ବଢ଼ିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'diabetes_knowledge_index',
    type: ContentType.knowledge,
    tags: ['diabetes', 'nutrition'],
    title: "Know Glycemic Index",
    body:
        "Foods with a low glycemic index raise blood sugar slowly and are safer for diabetics.",
    bodyHi:
        "लो ग्लाइसेमिक इंडेक्स वाले खाद्य पदार्थ धीरे-धीरे शुगर बढ़ाते हैं और डायबिटीज में बेहतर हैं।",
    bodyOd:
        "କମ୍‌ ଗ୍ଲାଇସେମିକ୍‌ ଇଣ୍ଡେକ୍ସ ଥିବା ଖାଦ୍ୟ ଧୀରେ ଧୀରେ ସର୍କରା ବଢ଼ାଏ ଏବଂ ଡାଏବିଟିଜ୍‌ ପାଇଁ ଭଲ।",
  ),

  // 71
  WellnessContentModel(
    id: 'pcos_fact_hormonalimbalance',
    type: ContentType.fact,
    tags: ['pcos', 'hormones'],
    title: "PCOS Is a Hormonal Condition",
    body:
        "PCOS occurs due to hormonal imbalance, not because of something you did wrong.",
    bodyHi: "पीसीओएस हार्मोनल असंतुलन के कारण होता है, यह आपकी गलती नहीं है।",
    bodyOd: "PCOS ହର୍ମୋନାଲ୍‌ ଅସନ୍ତୁଳନର କାରଣରେ ହୁଏ, ଏହା ଆପଣଙ୍କ ଦୋଷ ନୁହେଁ।",
  ),
  WellnessContentModel(
    id: 'pcos_tip_strengthtraining',
    type: ContentType.tip,
    tags: ['pcos', 'exercise'],
    title: "Add Strength Training",
    body:
        "Building muscle improves insulin sensitivity and helps manage PCOS symptoms.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग इंसुलिन संवेदनशीलता बढ़ाती है और पीसीओएस लक्षणों को नियंत्रित करती है।",
    bodyOd:
        "ଶକ୍ତି ଅଭ୍ୟାସ ଇନସୁଲିନ୍‌ ସେନ୍ସିଟିଭିଟିକୁ ବଢ଼ାଇ ପିସିଓଏସ୍‌ ଲକ୍ଷଣକୁ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_myth_weightlossfix',
    type: ContentType.myth,
    tags: ['pcos', 'myth'],
    title: "Myth: Weight Loss Cures PCOS",
    body:
        "Weight loss may improve symptoms but it does not cure PCOS entirely.",
    bodyHi:
        "वजन कम करने से लक्षण बेहतर हो सकते हैं, लेकिन इससे पीसीओएस पूरी तरह ठीक नहीं होता।",
    bodyOd: "ବେସି କମାଇଲେ ଲକ୍ଷଣ ସୁଧାରିପାରେ କିନ୍ତୁ PCOS ସମୁଲେ ସୁସ୍ଥ ହୁଏ ନାହିଁ।",
  ),
  WellnessContentModel(
    id: 'pcos_advice_cycles',
    type: ContentType.advice,
    tags: ['pcos', 'cycle'],
    title: "Track Your Menstrual Cycle",
    body:
        "Tracking helps identify irregularities and guides better treatment plans.",
    bodyHi:
        "पीरियड्स को ट्रैक करना अनियमितताओं को पहचानने में मदद करता है और बेहतर उपचार देता है।",
    bodyOd:
        "ମାସିକ ଚକ୍ରକୁ ଟ୍ରାକ୍‌ କରିବା ଅନିୟମିତତା ଜାଣିବାରେ ଏବଂ ଭଲ ଚିକିତ୍ସା ପାଇଁ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_knowledge_insulinresistance',
    type: ContentType.knowledge,
    tags: ['pcos', 'insulin'],
    title: "Insulin Resistance Matters",
    body:
        "Insulin resistance is a key component of PCOS and affects weight, skin, and hormones.",
    bodyHi:
        "इंसुलिन रेजिस्टेंस पीसीओएस का प्रमुख कारण है और वजन, त्वचा व हार्मोन को प्रभावित करता है।",
    bodyOd:
        "ଇନସୁଲିନ୍‌ ରେଜିସ୍ଟାନ୍ସ PCOS ର ମୁଖ୍ୟ ଅଂଶ ଏବଂ ଓଜନ, ଚର୍ମ ଓ ହର୍ମୋନକୁ ପ୍ରଭାବିତ କରେ।",
  ),

  // 76
  WellnessContentModel(
    id: 'hypertension_fact_silent',
    type: ContentType.fact,
    tags: ['hypertension', 'heart_health'],
    title: "High BP Is a Silent Condition",
    body:
        "Most people with high blood pressure have no symptoms until damage occurs.",
    bodyHi:
        "अक्सर हाई BP बिना लक्षणों के होता है और नुकसान होने पर ही पता चलता है।",
    bodyOd: "ଅନେକ ସମୟରେ ଉଚ୍ଚ BP ଲକ୍ଷଣ ବିନା ହୁଏ ଏବଂ କ୍ଷତି ହେବା ପରେ ଜାଣିପାରିବ।",
  ),
  WellnessContentModel(
    id: 'hypertension_tip_salt',
    type: ContentType.tip,
    tags: ['hypertension', 'diet'],
    title: "Reduce Added Salt",
    body:
        "Keeping daily salt below 5g significantly helps in lowering blood pressure.",
    bodyHi:
        "प्रतिदिन नमक 5g से कम रखने से ब्लड प्रेशर को काफी हद तक नियंत्रित किया जा सकता है।",
    bodyOd: "ଦିନକୁ 5g ରୁ କମ୍‌ ଲୁଣ୍‌ ବ୍ୟବହାର କଲେ ଉଚ୍ଚ ରକ୍ତଚାପ ନିୟନ୍ତ୍ରଣ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_myth_onlyelderly',
    type: ContentType.myth,
    tags: ['hypertension', 'myth'],
    title: "Myth: Only Elderly Have High BP",
    body:
        "Stress, poor lifestyle, and diet can cause high blood pressure even in younger adults.",
    bodyHi:
        "तनाव, खराब जीवनशैली और गलत खानपान के कारण युवा भी हाई BP का शिकार हो सकते हैं।",
    bodyOd:
        "ଚାପ, ଖରାପ ଜୀବନଶୈଳୀ, ଏବଂ ତୁଷ୍ଟ ଆହାର ଯୁବମାନଙ୍କରେ ମଧ୍ୟ ଉଚ୍ଚ BP ହେଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_advice_monitor',
    type: ContentType.advice,
    tags: ['hypertension', 'monitoring'],
    title: "Monitor BP Regularly",
    body:
        "Checking your BP at home helps identify trends and prevents complications.",
    bodyHi:
        "घर पर BP मॉनिटर करना पैटर्न समझने और जटिलताओं से बचने में मदद करता है।",
    bodyOd: "ଘରେ BP ମାପିବା ପାଟର୍ନ୍‌ ବୁଝିବା ଏବଂ ଜଟିଳତା ରୋକିବାକୁ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_knowledge_potassium',
    type: ContentType.knowledge,
    tags: ['hypertension', 'minerals'],
    title: "Potassium Balances Sodium",
    body:
        "Bananas, coconut water, and spinach help regulate BP by balancing sodium.",
    bodyHi:
        "केला, नारियल पानी और पालक पोटैशियम प्रदान करते हैं जो सोडियम संतुलन कर BP नियंत्रित करते हैं।",
    bodyOd:
        "କଦଳୀ, ନଡ଼ିଆ ପାଣି ଏବଂ ପାଲଙ୍ଗ ପୋଟାସିଅମ୍‌ ଦେଇ ସୋଡିଅମ୍‌କୁ ସନ୍ତୁଳନ କରି BP ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_common',
    type: ContentType.fact,
    tags: ['thyroid', 'hormones'],
    title: "Thyroid Disorders Are Common",
    body:
        "Millions experience thyroid imbalance, especially women, due to hormonal shifts.",
    bodyHi:
        "थायरॉयड असंतुलन बहुत आम है और हार्मोनल बदलावों के कारण महिलाओं में अधिक होता है।",
    bodyOd: "ଥାଇରଏଡ୍‌ ଅସନ୍ତୁଳନ ଅତ୍ୟନ୍ତ ସାଧାରଣ ଏବଂ ମହିଳାମାନଙ୍କରେ ଅଧିକ ଦେଖାଯାଏ।",
  ),
  WellnessContentModel(
    id: 'thyroid_tip_morningdose',
    type: ContentType.tip,
    tags: ['thyroid', 'medication'],
    title: "Take Thyroid Medicine on Empty Stomach",
    body: "Thyroid tablets absorb best when taken 30 minutes before breakfast.",
    bodyHi:
        "थायरॉयड की गोली नाश्ते से 30 मिनट पहले खाली पेट लें ताकि इसका असर बेहतर हो।",
    bodyOd:
        "ଥାଇରଏଡ୍‌ ଗୋଳି ଖାଲି ପେଟରେ ନାସ୍ତା ପୂର୍ବରୁ 30 ମିନିଟ୍‌ ନିଅଲେ ଶୋଷଣ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'thyroid_myth_weight',
    type: ContentType.myth,
    tags: ['thyroid', 'myth'],
    title: "Myth: Thyroid Stops Weight Loss Completely",
    body:
        "Weight loss becomes slower, not impossible, with controlled thyroid levels.",
    bodyHi: "थायरॉयड होने से वजन कम होना धीमा होता है, असंभव नहीं।",
    bodyOd: "ଥାଇରଏଡ୍‌ ଥିଲେ ଓଜନ କମାଇବା ଧୀର ହୁଏ, ଅସମ୍ଭବ ନୁହେଁ।",
  ),
  WellnessContentModel(
    id: 'thyroid_advice_protein',
    type: ContentType.advice,
    tags: ['thyroid', 'diet'],
    title: "Increase Protein Intake",
    body: "Protein-rich meals help support metabolism in thyroid imbalance.",
    bodyHi:
        "प्रोटीन युक्त भोजन थायरॉयड असंतुलन में मेटाबॉलिज़्म को समर्थन देता है।",
    bodyOd:
        "ପ୍ରୋଟିନ୍‌ ଭରା ଖାଦ୍ୟ ଥାଇରଏଡ୍‌ ଅସନ୍ତୁଳନରେ ମେଟାବୋଲିଜ୍‌ମକୁ ସମର୍ଥନ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_knowledge_iodine',
    type: ContentType.knowledge,
    tags: ['thyroid', 'minerals'],
    title: "Iodine Helps Thyroid Function",
    body:
        "Iodized salt ensures your thyroid gets enough iodine for hormone production.",
    bodyHi:
        "आयोडीन युक्त नमक थायरॉयड को हार्मोन बनाने के लिए आवश्यक आयोडीन प्रदान करता है।",
    bodyOd:
        "ଆୟୋଡାଇଜ୍‌ ଲୁଣ୍‌ ଥାଇରଏଡ୍‌କୁ ହର୍ମୋନ୍‌ ତିଆରି ପାଇଁ ଆବଶ୍ୟକ ଆୟୋଡିନ୍‌ ଯୋଗାଇ ଦେଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'cardiac_fact_arteries',
    type: ContentType.fact,
    tags: ['cardiac', 'heart_health'],
    title: "Heart Disease Affects Arteries",
    body:
        "Plaque buildup narrows arteries and reduces blood supply to the heart.",
    bodyHi:
        "प्लाक जमा होने से धमनियाँ संकरी होती हैं और हृदय में रक्त प्रवाह कम हो जाता है।",
    bodyOd: "ପ୍ଲାକ୍‌ ସଞ୍ଚୟ ନଳୀଗୁଡ଼ିକୁ ସଙ୍କୁଚିତ କରେ ଏବଂ ହୃଦକୁ ରକ୍ତ ପ୍ରବାହ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cardiac_tip_omega3',
    type: ContentType.tip,
    tags: ['cardiac', 'diet'],
    title: "Add Omega-3 Sources",
    body:
        "Flaxseeds, walnuts, and fatty fish help reduce inflammation and protect the heart.",
    bodyHi:
        "अलसी, अखरोट और फैटी फिश हृदय की सुरक्षा और सूजन कम करने में मदद करते हैं।",
    bodyOd: "ଆଲସି, ଅଖରୋଟ ଏବଂ ମାଛ ହୃଦକୁ ସୁରକ୍ଷା ଏବଂ ସୁଜିଲା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cardiac_myth_chestpain',
    type: ContentType.myth,
    tags: ['cardiac', 'myth'],
    title: "Myth: Only Chest Pain Signals Heart Attack",
    body:
        "Heart attacks can also present as jaw pain, back pain, or shortness of breath.",
    bodyHi:
        "दिल का दौरा केवल सीने में दर्द से नहीं होता—जबड़ा, पीठ दर्द या सांस फूलना भी लक्षण हैं।",
    bodyOd:
        "ହୃଦଘାତ କେବଳ ଛାତି ବେଦନା ନୁହେଁ—ଜହ୍ନା, ପିଠି ବେଦନା ବା ଶ୍ୱାସକଳେଷ ମଧ୍ୟ ଲକ୍ଷଣ।",
  ),
  WellnessContentModel(
    id: 'cardiac_advice_steps',
    type: ContentType.advice,
    tags: ['cardiac', 'exercise'],
    title: "Aim for 7,000 Steps Daily",
    body:
        "Moderate activity improves circulation and reduces heart disease risk.",
    bodyHi:
        "प्रतिदिन 7,000 कदम चलना रक्त संचार को सुधारता है और हृदय रोग के जोखिम को घटाता है।",
    bodyOd:
        "ପ୍ରତିଦିନ 7,000 ପାଦେ ହାଟିବା ରକ୍ତ ପ୍ରବାହ ସୁଧାରେ ଏବଂ ହୃଦ ଝୁମ୍ପ ହ୍ରାସ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_knowledge_bpcholesterol',
    type: ContentType.knowledge,
    tags: ['cardiac', 'risk_factors'],
    title: "BP & Cholesterol Work Together",
    body:
        "High BP and high cholesterol jointly increase the risk of heart attack.",
    bodyHi:
        "हाई BP और हाई कोलेस्ट्रॉल दोनों मिलकर हार्ट अटैक का जोखिम बढ़ाते हैं।",
    bodyOd: "ଉଚ୍ଚ BP ଏବଂ ଉଚ୍ଚ କଲେଷ୍ଟେରଲ୍‌ ମିଶି ହୃଦଘାତ ଝୁମ୍ପ ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'renal_fact_filtration',
    type: ContentType.fact,
    tags: ['renal', 'kidneys'],
    title: "Kidneys Filter Waste",
    body:
        "Your kidneys clean around 150 liters of blood daily through filtration.",
    bodyHi:
        "किडनी प्रतिदिन लगभग 150 लीटर रक्त को फ़िल्टर करके शरीर को साफ़ रखती है।",
    bodyOd: "କିଡ୍ନି ପ୍ରତିଦିନ 150 ଲିଟର ରକ୍ତକୁ ଫିଲ୍ଟର୍‌ କରି ଶରୀରକୁ ସଫା କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_tip_low_salt',
    type: ContentType.tip,
    tags: ['renal', 'diet'],
    title: "Lower Salt Intake",
    body:
        "Reducing sodium helps the kidneys function better and reduces swelling.",
    bodyHi: "सोडियम कम करने से किडनी का कार्य बेहतर होता है और सूजन घटती है।",
    bodyOd: "ସୋଡିଅମ୍‌ କମ୍‌ କରିଲେ କିଡ୍ନି କାମ କରିବା ଭଲ ହୁଏ ଏବଂ ସୋଜା କମିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'renal_myth_water',
    type: ContentType.myth,
    tags: ['renal', 'myth'],
    title: "Myth: More Water Always Helps",
    body:
        "Kidney patients may need controlled water intake depending on their condition.",
    bodyHi:
        "किडनी रोगियों के लिए अधिक पानी पीना हमेशा सही नहीं; मात्रा बीमारी पर निर्भर करती है।",
    bodyOd:
        "କିଡ୍ନି ରୋଗୀମାନଙ୍କ ପାଇଁ ଅଧିକ ପାଣି ସବୁବେଳେ ଭଲ ନୁହେଁ; ପରିମାଣ ଅବସ୍ଥାଉପରେ ନିର୍ଭର କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_advice_creatinine',
    type: ContentType.advice,
    tags: ['renal', 'monitoring'],
    title: "Track Creatinine",
    body:
        "Regular kidney tests help monitor progression and avoid complications.",
    bodyHi:
        "नियमित किडनी टेस्ट बीमारी की प्रगति को समझने और जटिलताओं से बचने में मदद करते हैं।",
    bodyOd:
        "ନିୟମିତ କିଡ୍ନି ପରୀକ୍ଷା ରୋଗର ଅବସ୍ଥା ବୁଝିବା ଏବଂ ଜଟିଳତା ରୋକିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_knowledge_proteinlimit',
    type: ContentType.knowledge,
    tags: ['renal', 'diet'],
    title: "Protein Needs Monitoring",
    body:
        "Kidney issues may require adjusting dietary protein levels to prevent overload.",
    bodyHi: "किडनी रोग में कभी-कभी प्रोटीन का सेवन सीमित करना पड़ सकता है।",
    bodyOd: "କିଡ୍ନି ସମସ୍ୟାରେ ପ୍ରୋଟିନ୍‌ ସେବନ କେବେ କେବେ କମାଇବାକୁ ପଡ଼େ।",
  ),

  // 96
  WellnessContentModel(
    id: 'fattyliver_fact_reversible',
    type: ContentType.fact,
    tags: ['fatty_liver', 'liver_health'],
    title: "Fatty Liver Can Be Reversed",
    body: "Lifestyle changes often reverse fatty liver in early stages.",
    bodyHi: "जीवनशैली में सुधार से शुरुआती चरणों में फैटी लिवर ठीक हो सकता है।",
    bodyOd: "ଜୀବନଶୈଳୀ ସୁଧାର କଲେ ଆରମ୍ଭିକ ଚରଣରେ ଫ୍ୟାଟି ଲିଭର୍‌ ସୁସ୍ଥ ହୋଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_tip_sugarcut',
    type: ContentType.tip,
    tags: ['fatty_liver', 'diet'],
    title: "Reduce Added Sugar",
    body:
        "Sugary foods quickly overload the liver and worsen fat accumulation.",
    bodyHi:
        "मीठे खाद्य पदार्थ लिवर में वसा जमा होने को बढ़ाते हैं, इसलिए इन्हें कम करें।",
    bodyOd: "ମିଠା ଖାଦ୍ୟ ଲିଭର୍‌ରେ ଚର୍ବି ସଞ୍ଚୟ ବଢ଼ାଏ, ସେହିପାଇଁ କମ୍‌ କରନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_myth_thinpeople',
    type: ContentType.myth,
    tags: ['fatty_liver', 'myth'],
    title: "Myth: Only Overweight People Get Fatty Liver",
    body:
        "Even lean individuals can develop fatty liver due to poor diet or high sugar intake.",
    bodyHi:
        "केवल मोटे लोग ही नहीं, दुबले लोग भी गलत खानपान से फैटी लिवर हो सकता है।",
    bodyOd:
        "କେବଳ ମୋଟା ଲୋକମାନେ ନୁହେଁ, ଦୁବଳମାନେ ମଧ୍ୟ ତୁଷ୍ଟ ଆହାରରୁ ଫ୍ୟାଟି ଲିଭର୍‌ ହୋଇପାରନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'fattyliver_advice_exercise',
    type: ContentType.advice,
    tags: ['fatty_liver', 'lifestyle'],
    title: "Exercise Regularly",
    body: "Physical activity improves liver enzymes and reduces liver fat.",
    bodyHi: "नियमित व्यायाम से लिवर एंजाइम सुधरते हैं और वसा कम होती है।",
    bodyOd: "ନିୟମିତ ବ୍ୟାୟାମ ଲିଭର୍‌ ଏନଜାଇମ୍‌ ସୁଧାରେ ଏବଂ ଚର୍ବି କମାଏ।",
  ),
  WellnessContentModel(
    id: 'fattyliver_knowledge_water',
    type: ContentType.knowledge,
    tags: ['fatty_liver', 'hydration'],
    title: "Hydration Supports Liver",
    body:
        "Adequate water helps your liver process nutrients and toxins efficiently.",
    bodyHi:
        "पर्याप्त पानी लिवर को पोषक तत्वों और टॉक्सिन को सही तरीके से प्रोसेस करने में मदद करता है।",
    bodyOd:
        "ପ୍ରଚୁର ପାଣି ଲିଭର୍‌କୁ ପୋଷକ ତଥା ବିଷାକ୍ତ ପଦାର୍ଥ ପ୍ରକ୍ରିୟାକରଣରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_tip_hydration_101',
    type: ContentType.tip,
    tags: ['diabetes', 'hydration'],
    title: "Stay Hydrated for Better Sugar Control",
    body:
        "Adequate water intake helps your body regulate blood glucose more efficiently.",
    bodyHi:
        "पर्याप्त पानी पीने से शरीर ब्लड शुगर को बेहतर तरीके से नियंत्रित करता है।",
    bodyOd:
        "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିଇବା ଶରୀରକୁ ରକ୍ତ ସକ୍କରାକୁ ଭଲଭାବେ ନିୟନ୍ତ୍ରଣ କରିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_fact_insulin_102',
    type: ContentType.fact,
    tags: ['pcos', 'insulin_resistance'],
    title: "Insulin Resistance is Common",
    body:
        "Most women with PCOS experience some level of insulin resistance, affecting hormone balance.",
    bodyHi:
        "पीसीओएस में अधिकांश महिलाओं में इंसुलिन रेजिस्टेंस पाया जाता है, जो हार्मोन संतुलन को प्रभावित करता है।",
    bodyOd:
        "ପିସିଓଏସ୍ ଥିବା ଅଧିକାଂଶ ମହିଳାଙ୍କରେ ଇନସୁଲିନ୍ ରେଜିଷ୍ଟାନ୍ସ ଦେଖାଯାଏ, ଯାହା ହରମୋନ ସନ୍ତୁଳନକୁ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_myth_salt_103',
    type: ContentType.myth,
    tags: ['hypertension', 'salt_intake'],
    title: "Myth: Only Table Salt Raises BP",
    body:
        "Hidden salt in packaged foods also contributes significantly to high blood pressure.",
    bodyHi:
        "मिथ: केवल नमक ही बीपी बढ़ाता है। पैक्ड फूड्स में छिपा नमक भी बीपी बढ़ाने में मुख्य कारण है।",
    bodyOd:
        "ମିଥ୍: କେବଳ ଲୁଣ ରକ୍ତଚାପ ବୃଦ୍ଧି କରେ। ପ୍ୟାକେଜ୍ ଖାଦ୍ୟରେ ଲୁକାଇଥିବା ଲୁଣ ମଧ୍ୟ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ଭୂମିକା ନିବାହ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_tip_selenium_104',
    type: ContentType.tip,
    tags: ['thyroid', 'minerals'],
    title: "Boost Thyroid with Selenium",
    body:
        "Brazil nuts and sunflower seeds provide selenium, supporting healthy thyroid hormone production.",
    bodyHi:
        "ब्राज़ील नट्स और सूरजमुखी के बीज सेलेनियम देते हैं, जो थायरॉयड हार्मोन उत्पादन में मदद करते हैं।",
    bodyOd:
        "ବ୍ରାଜିଲ୍ ନଟ୍ ଏବଂ ସୁର୍ଯ୍ୟମୁଖୀ ବିଆ ସେଲେନିଅମ୍ ଦେଇଥାଏ, ଯାହା ଥାଇରଏଡ୍ ହରମୋନ ଉତ୍ପାଦନକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_fact_oats_105',
    type: ContentType.fact,
    tags: ['cardiac', 'fiber'],
    title: "Oats Support Heart Health",
    body:
        "Beta-glucan in oats helps lower LDL cholesterol and improves heart protection.",
    bodyHi:
        "ओट्स में मौजूद बीटा-ग्लूकैन एलडीएल कोलेस्ट्रॉल को कम कर दिल की सेहत को बेहतर बनाता है।",
    bodyOd:
        "ଓଟ୍ସ୍ ରେ ଥିବା ବେଟା-ଗ୍ଲୁକାନ୍ LDL କଲେଷ୍ଟେରଲ କମାଇ ହୃଦ୍ୟର ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_advice_potassium_106',
    type: ContentType.advice,
    tags: ['renal', 'potassium_control'],
    title: "Be Careful with High-Potassium Foods",
    body:
        "Kidney patients should monitor fruits like bananas, oranges, and coconut water.",
    bodyHi:
        "किडनी रोगियों को केले, संतरे और नारियल पानी जैसे हाई-पोटैशियम फलों का ध्यान रखना चाहिए।",
    bodyOd:
        "କିଡନି ରୋଗୀମାନେ କଳା, କମଳା ଏବଂ ନଡିଆ ପାଣି ଭଳି ଉଚ୍ଚ ପୋଟାସିଆମ୍ ଖାଦ୍ୟରେ ସାବଧାନ ହେବା ଉଚିତ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_fact_protein_107',
    type: ContentType.fact,
    tags: ['fatty_liver', 'protein'],
    title: "Protein Helps Reduce Fatty Liver",
    body:
        "Adequate protein supports liver repair and reduces fat accumulation.",
    bodyHi:
        "पर्याप्त प्रोटीन लिवर की मरम्मत में मदद करता है और फैट जमा होने से रोकता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପ୍ରୋଟିନ୍ ଲିଭର ମରମତରେ ସାହାଯ୍ୟ କରେ ଏବଂ ଚର୍ବି ସଂଚୟ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_myth_eggs_108',
    type: ContentType.myth,
    tags: ['cholesterol', 'diet'],
    title: "Myth: Eggs Are Bad for Cholesterol",
    body:
        "Moderate egg intake is safe for most people; focus on reducing trans fats instead.",
    bodyHi:
        "मिथ: अंडे कोलेस्ट्रॉल बढ़ाते हैं। सीमित मात्रा में अंडे सुरक्षित हैं, ट्रांस फैट कम करना ज्यादा जरूरी है।",
    bodyOd:
        "ମିଥ୍: ଅଣ୍ଡା କଲେଷ୍ଟେରଲ ବଢ଼ାଏ। ସୀମିତ ଖପରୁ ଅଣ୍ଡା ସୁରକ୍ଷିତ, ଟ୍ରାନ୍ସ ଫ୍ୟାଟ୍ କମାଇବା ଅଧିକ ଜରୁରୀ।",
  ),
  WellnessContentModel(
    id: 'anemia_tip_ironC_109',
    type: ContentType.tip,
    tags: ['anemia', 'vitamin_c'],
    title: "Pair Iron with Vitamin C",
    body:
        "Vitamin C boosts iron absorption, making supplements and foods more effective.",
    bodyHi:
        "विटामिन C आयरन अवशोषण को बढ़ाता है, जिससे भोजन और सप्लीमेंट का असर बढ़ता है।",
    bodyOd:
        "ଭିଟାମିନ୍ C ଲୋହ ଶୋଷଣ ବୃଦ୍ଧି କରେ, ଯାହାରୁ ଖାଦ୍ୟ ଏବଂ ସପ୍ଲିମେଣ୍ଟ ଅଧିକ ପ୍ରଭାବୀ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_advice_hydration_110',
    type: ContentType.advice,
    tags: ['sickle_cell', 'hydration'],
    title: "Hydration Prevents Pain Episodes",
    body:
        "Proper hydration helps reduce the frequency of sickle cell pain crises.",
    bodyHi:
        "पर्याप्त पानी पीने से सिकल सेल रोग में दर्द के दौरे कम हो सकते हैं।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିଇବା ସିକେଲ୍ ସେଲ୍ ରୋଗରେ ବେଦନା ଘଟଣା କମାଇ ପାରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_fact_wholegrains_111',
    type: ContentType.fact,
    tags: ['diabetes', 'whole_grains'],
    title: "Whole Grains Support Glucose Control",
    body:
        "Whole grains like brown rice help slow glucose spikes by providing steady energy.",
    bodyHi:
        "ब्राउन राइस जैसे साबुत अनाज ऊर्जा को धीरे-धीरे देते हैं और शुगर स्पाइक कम करते हैं।",
    bodyOd:
        "ବ୍ରାଉନ ଚାଉଳ ଭଳି ସମ୍ପୂର୍ଣ୍ଣ ଧାନ୍ୟ ଗ୍ଲୁକୋଜ୍ ସ୍ପାଇକ୍ କମାଇ ସ୍ଥିର ଉର୍ଜା ଯୋଗାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'pcos_tip_strengthtraining_112',
    type: ContentType.tip,
    tags: ['pcos', 'exercise'],
    title: "Strength Training Helps Hormones",
    body:
        "Regular strength training improves insulin sensitivity and reduces PCOS symptoms.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग इंसुलिन संवेदनशीलता बढ़ाती है और पीसीओएस लक्षण कम करती है।",
    bodyOd:
        "ଷ୍ଟ୍ରେଂଥ୍ ଟ୍ରେନିଂ ଇନସୁଲିନ୍ ସେନ୍ସିଟିଭିଟି ବୃଦ୍ଧି କରି ପିସିଓଏସ୍ ଲକ୍ଷଣ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_advice_limit_caffeine_113',
    type: ContentType.advice,
    tags: ['hypertension', 'caffeine'],
    title: "Monitor Your Caffeine Intake",
    body:
        "Too much caffeine may temporarily spike blood pressure, so moderation is wise.",
    bodyHi:
        "अधिक कैफीन से ब्लड प्रेशर अस्थायी रूप से बढ़ सकता है, इसलिए संतुलित मात्रा जरूरी है।",
    bodyOd:
        "ଅଧିକ କାଫିନ୍ ରକ୍ତଚାପକୁ ଅସ୍ଥାୟୀ ଭାବରେ ବଢ଼ାଇ ପାରେ, ତେଣୁ ସମ୍ୟକ୍ ପରିମାଣ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_iodine_114',
    type: ContentType.fact,
    tags: ['thyroid', 'nutrition'],
    title: "Iodine Is Essential for Thyroid Hormones",
    body:
        "Iodine deficiency can slow thyroid function, making iodized salt important.",
    bodyHi:
        "आयोडीन की कमी थायरॉयड को धीमा कर सकती है, इसलिए आयोडीन युक्त नमक आवश्यक है।",
    bodyOd:
        "ଆୟୋଡିନ୍ ଅଭାବ ଥାଇରଏଡ୍ କାର୍ଯ୍ୟକୁ ଧୀର କରେ, ଏହିକାରଣରେ ଆୟୋଡିଜ୍ ଲୁଣ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'cardiac_tip_walnuts_115',
    type: ContentType.tip,
    tags: ['cardiac', 'healthy_fats'],
    title: "Walnuts Support Heart Health",
    body:
        "Omega-3 fats in walnuts help reduce inflammation and protect heart function.",
    bodyHi: "अखरोट में मौजूद ओमेगा-3 फैट सूजन कम कर दिल की रक्षा करते हैं।",
    bodyOd: "ଆଖରୋଟରେ ଥିବା ଓମେଗା-3 ଚର୍ବି ସୁଜିଲା କମାଇ ହୃଦୟକୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_fact_fluidbalance_116',
    type: ContentType.fact,
    tags: ['renal', 'hydration'],
    title: "Kidneys Maintain Fluid Balance",
    body:
        "Healthy kidneys regulate fluid and electrolyte levels to support body function.",
    bodyHi: "स्वस्थ किडनी शरीर में द्रव और इलेक्ट्रोलाइट संतुलन बनाए रखती हैं।",
    bodyOd: "ସ୍ୱସ୍ଥ କିଡନି ଶରୀରରେ ତରଳ ଏବଂ ଇଲେକ୍ଟ୍ରୋଲାଏଟ୍ ସନ୍ତୁଳନ ରଖେ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_myth_only_alcohol_117',
    type: ContentType.myth,
    tags: ['fatty_liver', 'awareness'],
    title: "Myth: Only Alcohol Causes Fatty Liver",
    body:
        "High sugar intake, obesity, and inactivity can also lead to fatty liver disease.",
    bodyHi:
        "मिथ: फैटी लिवर सिर्फ शराब से होता है। ज्यादा चीनी, मोटापा और निष्क्रियता भी इसका कारण हैं।",
    bodyOd:
        "ମିଥ୍: କେବଳ ମଦ୍ ଫ୍ୟାଟି ଲିଭର କରେ। ଅଧିକ ସକ୍କରା, ମୋଟାପଣ ଏବଂ କ୍ରିୟାହୀନତା ମଧ୍ୟ କାରଣ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_tip_fiber_118',
    type: ContentType.tip,
    tags: ['cholesterol', 'fiber'],
    title: "Fiber Helps Lower Cholesterol",
    body:
        "Soluble fiber binds excess cholesterol and promotes heart protection.",
    bodyHi:
        "घुलनशील फाइबर अतिरिक्त कोलेस्ट्रॉल को बांधकर दिल की सेहत को बेहतर करता है।",
    bodyOd:
        "ଘୁଳନଶୀଳ ଫାଇବର୍ ଅତିରିକ୍ତ କଲେଷ୍ଟେରଲ୍ ସହିତ ବାନ୍ଧି ହୃଦୟକୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'anemia_fact_folate_119',
    type: ContentType.fact,
    tags: ['anemia', 'vitamins'],
    title: "Folate Prevents Certain Types of Anemia",
    body:
        "Folate-rich foods help form healthy red blood cells and prevent deficiency anemia.",
    bodyHi:
        "फोलेट से भरपूर भोजन स्वस्थ लाल रक्त कोशिकाएँ बनाने में मदद करता है और एनीमिया रोकता है।",
    bodyOd: "ଫୋଲେଟ୍ ଧନ୍ୟ ଖାଦ୍ୟ ସ୍ୱସ୍ଥ ଲାଲ ରକ୍ତକଣି ଗଠନ କରି ଅନିମିଆ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_fact_fever_120',
    type: ContentType.fact,
    tags: ['sickle_cell', 'infections'],
    title: "Fever Can Trigger Sickle Crises",
    body:
        "Infections and fever increase the risk of pain crises in sickle cell patients.",
    bodyHi:
        "बुखार और संक्रमण सिकल सेल रोगियों में दर्द के एपिसोड बढ़ा सकते हैं।",
    bodyOd: "ଜ୍ୱର ଏବଂ ସଂକ୍ରମଣ ସିକେଲ୍ ସେଲ୍ ରୋଗୀମାନଙ୍କରେ ବେଦନା ଘଟଣା ବଢ଼ାଇ ପାରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_advice_sleep_121',
    type: ContentType.advice,
    tags: ['diabetes', 'sleep'],
    title: "Prioritize Good Sleep",
    body:
        "Poor sleep increases insulin resistance and can worsen glucose levels.",
    bodyHi: "खराब नींद इंसुलिन रेजिस्टेंस बढ़ाकर शुगर लेवल को खराब करती है।",
    bodyOd: "ଖରାପ ଘୁମ୍ ଇନସୁଲିନ୍ ରେଜିଷ୍ଟାନ୍ସ ବଢ଼ାଇ ଗ୍ଲୁକୋଜ୍ ସ୍ତର ଖରାପ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_myth_junkfood_only_122',
    type: ContentType.myth,
    tags: ['pcos', 'nutrition'],
    title: "Myth: PCOS Comes Only from Junk Food",
    body: "PCOS has hormonal and genetic components; diet is only one factor.",
    bodyHi:
        "मिथ: पीसीओएस सिर्फ जंक फूड से होता है। इसमें हार्मोनल और आनुवंशिक कारण भी होते हैं।",
    bodyOd:
        "ମିଥ୍: ପିସିଓଏସ୍ କେବଳ ଜଙ୍କ ଫୁଡ଼ର କାରଣ। ଏଥିରେ ହରମୋନାଲ୍ ଏବଂ ଜିନେଟିକ୍ ଅଂଶ ମଧ୍ୟ ଅଛି।",
  ),
  WellnessContentModel(
    id: 'hypertension_tip_steps_123',
    type: ContentType.tip,
    tags: ['hypertension', 'exercise'],
    title: "Walking Helps Lower BP",
    body:
        "Just 30 minutes of brisk walking can significantly reduce blood pressure.",
    bodyHi: "सिर्फ 30 मिनट की तेज चाल से चलना बीपी को काफी कम कर सकता है।",
    bodyOd: "କେବଳ 30 ମିନିଟ୍ ତିବ୍ର ହାଟିବା ରକ୍ତଚାପ କମାଇ ପାରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_advice_protein_124',
    type: ContentType.advice,
    tags: ['thyroid', 'protein'],
    title: "Protein Supports Thyroid Hormones",
    body:
        "Adequate protein intake supports enzyme and hormone production in thyroid conditions.",
    bodyHi:
        "पर्याप्त प्रोटीन थायरॉयड हार्मोन और एंजाइम निर्माण में मदद करता है।",
    bodyOd:
        "ପର୍ଯ୍ୟାପ୍ତ ପ୍ରୋଟିନ୍ ଥାଇରଏଡ୍ ହରମୋନ ଓ ଏନ୍ଜାଇମ୍ ଉତ୍ପାଦନକୁ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_myth_oilfree_125',
    type: ContentType.myth,
    tags: ['cardiac', 'diet'],
    title: "Myth: Zero-Oil Diet Is Necessary",
    body:
        "Healthy fats from nuts and seeds are essential for heart and hormone function.",
    bodyHi:
        "मिथ: जीरो-ऑयल ही सही है। नट्स और बीजों के अच्छे फैट दिल और हार्मोन के लिए जरूरी हैं।",
    bodyOd:
        "ମିଥ୍: ଶୂନ୍ୟ ତେଲ ଡାଏଟ୍ ଆବଶ୍ୟକ। ନଟ୍ ଏବଂ ବିଆର ସ୍ୱସ୍ଥ ଚର୍ବି ହୃଦୟ ପାଇଁ ଜରୁରୀ।",
  ),
  WellnessContentModel(
    id: 'renal_tip_low_sodium_126',
    type: ContentType.tip,
    tags: ['renal', 'salt_intake'],
    title: "Reduce Salt for Kidney Support",
    body:
        "Lowering salt intake reduces kidney stress and helps maintain fluid balance.",
    bodyHi:
        "नमक कम करने से किडनी पर दबाव कम होता है और फ्लूइड संतुलन बेहतर रहता है।",
    bodyOd: "ଲୁଣ କମ୍ କରିବା କିଡନିର ଚାପ କମାଇ ପରିବାହ ସନ୍ତୁଳନ ରଖେ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_tip_green_tea_127',
    type: ContentType.tip,
    tags: ['fatty_liver', 'antioxidants'],
    title: "Green Tea Supports Liver Fat Reduction",
    body:
        "Green tea's antioxidants may help reduce inflammation and liver fat accumulation.",
    bodyHi:
        "ग्रीन टी के एंटीऑक्सीडेंट सूजन और लिवर में फैट जमाव को कम करने में मदद कर सकते हैं।",
    bodyOd: "ଗ୍ରୀନ୍ ଚାର ଅ୍ୟାଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ସୁଜିଲା ଓ ଲିଭର ଚର୍ବି କମାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_knowledge_transfat_128',
    type: ContentType.knowledge,
    tags: ['cholesterol', 'trans_fat'],
    title: "Trans Fats Raise Bad Cholesterol",
    body:
        "Foods with trans fats significantly increase LDL cholesterol and heart risk.",
    bodyHi:
        "ट्रांस फैट वाले खाद्य पदार्थ एलडीएल को बहुत तेजी से बढ़ाते हैं और दिल के लिए हानिकारक हैं।",
    bodyOd: "ଟ୍ରାନ୍ସ ଫ୍ୟାଟ୍ ଖାଦ୍ୟଗୁଡ଼ିକ୍ LDL କଲେଷ୍ଟେରଲ୍ ବଢ଼ାଇ ହୃଦୟ ବିପଦ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_tip_beetroot_129',
    type: ContentType.tip,
    tags: ['anemia', 'vegetables'],
    title: "Beetroot Supports Blood Building",
    body:
        "Beetroot provides natural folate and iron, supporting hemoglobin formation.",
    bodyHi:
        "चुकंदर प्राकृतिक आयरन और फोलेट देता है, जो हीमोग्लोबिन बढ़ाने में मदद करता है।",
    bodyOd: "ବିଟ୍ ରୁଟ୍ ଲୋହ ଏବଂ ଫୋଲେଟ୍ ଯୋଗାଇ ହିମୋଗ୍ଲୋବିନ୍ ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_tip_warmth_130',
    type: ContentType.tip,
    tags: ['sickle_cell', 'selfcare'],
    title: "Stay Warm to Prevent Crises",
    body:
        "Cold temperatures may trigger pain episodes, so keeping warm is important.",
    bodyHi:
        "ठंड सिकल सेल दर्द को बढ़ा सकती है, इसलिए शरीर को गर्म रखना जरूरी है।",
    bodyOd:
        "ଥଣ୍ଡ ଯନ୍ତ୍ରଣା ଯୋଗୁଁ ବେଦନା ଘଟଣା ବଢ଼ିଯାଇପାରେ, ତେଣୁ ଗରମ ରହିବା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'diabetes_myth_fruits_131',
    type: ContentType.myth,
    tags: ['diabetes', 'fruits'],
    title: "Myth: Diabetics Should Avoid Fruits",
    body:
        "Most fruits can be eaten in moderation; choose low-GI ones like apples or guava.",
    bodyHi:
        "मिथ: डायबिटिक लोग फल नहीं खा सकते। अधिकांश फल सीमित मात्रा में सुरक्षित होते हैं।",
    bodyOd:
        "ମିଥ୍: ଡାଇବେଟିସ୍ ରୋଗୀ ଫଳ ଖାଇପାରିବେ ନାହିଁ। ଅଧିକାଂଶ ଫଳ ସୀମିତ ଭାବରେ ସୁରକ୍ଷିତ।",
  ),
  WellnessContentModel(
    id: 'pcos_fact_inflammation_132',
    type: ContentType.fact,
    tags: ['pcos', 'inflammation'],
    title: "PCOS Is Linked with Inflammation",
    body:
        "Low-grade inflammation can contribute to hormonal imbalance in PCOS.",
    bodyHi: "पीसीओएस में हल्की सूजन भी हार्मोनल असंतुलन का कारण बन सकती है।",
    bodyOd: "ପିସିଓଏସ୍ ରେ ସାମାନ୍ୟ ସୁଜିଲା ମଧ୍ୟ ହରମୋନ ସନ୍ତୁଳନ ଭଙ୍ଗ କରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_fact_potassium_133',
    type: ContentType.fact,
    tags: ['hypertension', 'minerals'],
    title: "Potassium Helps Relax Blood Vessels",
    body:
        "Potassium-rich foods help regulate blood pressure by easing vessel tension.",
    bodyHi:
        "पोटैशियम युक्त भोजन रक्त वाहिकाओं को आराम देकर बीपी कम करने में मदद करता है।",
    bodyOd: "ପୋଟାସିଆମ୍ ଧନ୍ୟ ଖାଦ୍ୟ ରକ୍ତନଳୀର ଚାପ କମାଇ ରକ୍ତଚାପ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_tip_zinc_134',
    type: ContentType.tip,
    tags: ['thyroid', 'minerals'],
    title: "Add Zinc for Thyroid Balance",
    body: "Zinc supports thyroid hormone conversion and immune function.",
    bodyHi: "जिंक थायरॉयड हार्मोन के रूपांतरण और प्रतिरक्षा में सहायक है।",
    bodyOd: "ଜିଙ୍କ ଥାଇରଏଡ୍ ହରମୋନ ରୂପାନ୍ତରଣ ଓ ପ୍ରତିରୋଧକତାକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_advice_reduce_stress_135',
    type: ContentType.advice,
    tags: ['cardiac', 'stress'],
    title: "Manage Stress for Heart Health",
    body:
        "Chronic stress raises blood pressure and affects long-term heart health.",
    bodyHi:
        "लंबे समय का तनाव बीपी बढ़ाता है और दिल की सेहत को नुकसान पहुंचाता है।",
    bodyOd: "ଦୀର୍ଘସ୍ଥାୟୀ ଚାପ ରକ୍ତଚାପ ବଢ଼ାଇ ହୃଦୟ ସ୍ୱାସ୍ଥ୍ୟ ଖରାପ କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_knowledge_creatinine_136',
    type: ContentType.knowledge,
    tags: ['renal', 'lab_tests'],
    title: "Creatinine Reflects Kidney Filtration",
    body:
        "High creatinine levels indicate reduced kidney function and filtration capacity.",
    bodyHi: "क्रिएटिनिन का बढ़ना किडनी की कमजोरी का संकेत देता है।",
    bodyOd: "ଉଚ୍ଚ କ୍ରିଏଟିନିନ୍ କିଡନି କାର୍ଯ୍ୟକ୍ଷମତା କମିବାର ଚିହ୍ନ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_fact_visceral_fat_137',
    type: ContentType.fact,
    tags: ['fatty_liver', 'weight_loss'],
    title: "Visceral Fat Worsens Liver Health",
    body: "Belly fat increases liver fat accumulation and inflammation risk.",
    bodyHi: "पेट की चर्बी लिवर में फैट जमा होने और सूजन का खतरा बढ़ाती है।",
    bodyOd: "ପେଟ ଚର୍ବି ଲିଭରରେ ଚର୍ବି ସଂଚୟ ଓ ସୁଜିଲା ବଢ଼ାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_myth_fatfree_138',
    type: ContentType.myth,
    tags: ['cholesterol', 'diet'],
    title: "Myth: Only Fat-Free Foods Are Safe",
    body:
        "Natural fats from seeds, nuts, and olive oil protect heart health when eaten moderately.",
    bodyHi:
        "मिथ: सिर्फ फैट-फ्री भोजन ही सही है। बीज, नट्स और ऑलिव ऑयल के प्राकृतिक फैट दिल के लिए अच्छे होते हैं।",
    bodyOd:
        "ମିଥ୍: ଫ୍ୟାଟ-ଫ୍ରି ଖାଦ୍ୟ ହିଁ ସୁରକ୍ଷିତ। ନଟ୍, ବିଆ ଓ ଜୈତୁନ ତେଲର ଫ୍ୟାଟ୍ ହୃଦୟ ପାଇଁ ଭଲ।",
  ),
  WellnessContentModel(
    id: 'anemia_advice_sprouts_139',
    type: ContentType.advice,
    tags: ['anemia', 'plant_protein'],
    title: "Sprouts Can Boost Iron Intake",
    body:
        "Sprouted pulses improve iron absorption and support hemoglobin levels.",
    bodyHi: "अंकुरित दालें आयरन अवशोषण बढ़ाकर हीमोग्लोबिन में सुधार करती हैं।",
    bodyOd: "ଅଂକୁରିତ ଡାଲି ଲୋହ ଶୋଷଣ ବଢ଼ାଇ ହିମୋଗ୍ଲୋବିନ୍ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_knowledge_genetic_140',
    type: ContentType.knowledge,
    tags: ['sickle_cell', 'genetics'],
    title: "Sickle Cell Is a Genetic Condition",
    body: "It is inherited from parents and not caused by diet or lifestyle.",
    bodyHi:
        "सिकल सेल एक आनुवंशिक स्थिति है, यह भोजन या लाइफस्टाइल से नहीं होता।",
    bodyOd:
        "ସିକେଲ୍ ସେଲ୍ ଏକ ଜିନେଟିକ୍ ଅବସ୍ଥା, ଏହା ଖାଦ୍ୟ କିମ୍ବା ଲାଇଫ୍‌ଷ୍ଟାଇଲ୍‌ରୁ ହୁଏ ନାହିଁ।",
  ),
  WellnessContentModel(
    id: 'diabetes_tip_plate_141',
    type: ContentType.tip,
    tags: ['diabetes', 'portion_control'],
    title: "Use the Diabetes Plate Method",
    body:
        "Fill half your plate with vegetables, one-quarter protein, and one-quarter whole grains.",
    bodyHi:
        "प्लेट का आधा हिस्सा सब्जियों से, एक चौथाई प्रोटीन और एक चौथाई साबुत अनाज से भरें।",
    bodyOd:
        "ପ୍ଲେଟର ଆଧା ସବ୍ଜି, ଏକ ଚତୁର୍ଥାଂଶ ପ୍ରୋଟିନ୍ ଓ ଏକ ଚତୁର୍ଥାଂଶ ସମ୍ପୂର୍ଣ୍ଣ ଧାନ୍ୟ ରଖନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'pcos_advice_lowgi_142',
    type: ContentType.advice,
    tags: ['pcos', 'low_gi'],
    title: "Choose Low-GI Foods",
    body:
        "Low-glycemic foods help stabilize energy and improve insulin response in PCOS.",
    bodyHi:
        "लो-जीआई भोजन ऊर्जा को स्थिर रखता है और इंसुलिन प्रतिक्रिया में सुधार करता है।",
    bodyOd:
        "ଲୋ-GI ଖାଦ୍ୟ ଉର୍ଜା ସ୍ଥିର ରଖି ପିସିଓଏସ୍‌ରେ ଇନସୁଲିନ୍ ପ୍ରତିକ୍ରିୟା ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_myth_stressonly_143',
    type: ContentType.myth,
    tags: ['hypertension', 'awareness'],
    title: "Myth: Only Stress Raises BP",
    body:
        "Salt, alcohol, obesity, and inactivity also contribute to high blood pressure.",
    bodyHi:
        "मिथ: सिर्फ तनाव से बीपी बढ़ता है। नमक, शराब, मोटापा और निष्क्रियता भी कारण हैं।",
    bodyOd:
        "ମିଥ୍: କେବଳ ଚାପ ରକ୍ତଚାପ ବଢ଼ାଏ। ଲୁଣ, ମଦ୍ୟପାନ, ମୋଟାପଣ ଓ କ୍ରିୟାହୀନତା ମଧ୍ୟ କାରଣ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_stress_144',
    type: ContentType.fact,
    tags: ['thyroid', 'stress'],
    title: "Stress Affects Thyroid Function",
    body:
        "Chronic stress can disrupt hormone production in thyroid conditions.",
    bodyHi: "लंबा तनाव थायरॉयड हार्मोन संतुलन को बिगाड़ सकता है।",
    bodyOd: "ଦୀର୍ଘ ସ୍ଟ୍ରେସ୍ ଥାଇରଏଡ୍ ହରମୋନ ସନ୍ତୁଳନ ଭଙ୍ଗ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_tip_meditation_145',
    type: ContentType.tip,
    tags: ['cardiac', 'mindfulness'],
    title: "Meditation Protects Heart Health",
    body:
        "Even 10 minutes of meditation can lower heart rate and reduce tension.",
    bodyHi: "सिर्फ 10 मिनट ध्यान करने से दिल की धड़कन और तनाव कम हो सकता है।",
    bodyOd: "ମାତ୍ର 10 ମିନିଟ୍ ଧ୍ୟାନ ହୃଦ୍ଗତି ଓ ଚାପ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'renal_myth_protein_146',
    type: ContentType.myth,
    tags: ['renal', 'protein'],
    title: "Myth: All Proteins Harm Kidneys",
    body:
        "Moderate protein intake is safe for many patients; excess is what strains kidneys.",
    bodyHi:
        "मिथ: प्रोटीन हमेशा किडनी को नुकसान पहुंचाता है। संतुलित मात्रा सुरक्षित होती है।",
    bodyOd: "ମିଥ୍: ସମସ୍ତ ପ୍ରୋଟିନ୍ କିଡନିକୁ କ୍ଷତି କରେ। ସମ୍ୟକ୍ ପରିମାଣ ସୁରକ୍ଷିତ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_advice_steps_147',
    type: ContentType.advice,
    tags: ['fatty_liver', 'exercise'],
    title: "Daily Steps Reduce Liver Fat",
    body:
        "Walking 7,000–10,000 steps a day can significantly reduce liver fat.",
    bodyHi: "रोज़ 7,000–10,000 कदम चलने से लिवर फैट काफी कम होता है।",
    bodyOd: "ଦିନକୁ 7,000–10,000 ପାଦଚାଳା ଲିଭର ଚର୍ବି କମାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_fact_hdl_148',
    type: ContentType.fact,
    tags: ['cholesterol', 'healthy_fats'],
    title: "HDL is the Protective Cholesterol",
    body:
        "HDL cholesterol helps move excess fat from tissues back to the liver.",
    bodyHi: "HDL कोलेस्ट्रॉल शरीर से खराब फैट को हटाकर लिवर तक पहुंचाता है।",
    bodyOd: "HDL କଲେଷ୍ଟେରଲ୍ ଅତିରିକ୍ତ ଚର୍ବିକୁ ଶରୀରରୁ ଲିଭରକୁ ନେଇଯାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_myth_only_iron_149',
    type: ContentType.myth,
    tags: ['anemia', 'awareness'],
    title: "Myth: Only Iron Deficiency Causes Anemia",
    body:
        "Anemia can also result from low B12, folate, chronic disease, or genetic factors.",
    bodyHi:
        "मिथ: एनीमिया सिर्फ आयरन की कमी से होता है। B12, फोलेट और बीमारियों से भी हो सकता है।",
    bodyOd:
        "ମିଥ୍: ଅନିମିଆ କେବଳ ଲୋହ ଅଭାବରୁ ହୁଏ। B12, ଫୋଲେଟ୍ ଓ ରୋଗମାନେ ମଧ୍ୟ କାରଣ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_advice_vaccines_150',
    type: ContentType.advice,
    tags: ['sickle_cell', 'immunity'],
    title: "Vaccinations Reduce Infection Risk",
    body:
        "Vaccinations help prevent infections that can trigger painful sickle crises.",
    bodyHi:
        "टीकाकरण संक्रमण के जोखिम को कम करता है और दर्द के दौरे से बचाता है।",
    bodyOd: "ଟିକା ଦେବା ସଂକ୍ରମଣ ଝୁମକୁ କମାଇ ବେଦନା ଘଟଣାରୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_tip_lowgi_151',
    type: ContentType.tip,
    tags: ['diabetes', 'low_gi'],
    title: "Choose Low-GI Foods",
    body:
        "Low-glycemic foods like millets and legumes help control post-meal sugar spikes.",
    bodyHi:
        "मिलेट्स और दालों जैसे लो-जीआई खाद्य पदार्थ खाने के बाद शुगर स्पाइक को नियंत्रित करते हैं।",
    bodyOd:
        "ମିଲେଟ୍ ଏବଂ ଡାଲି ଭଳି ଲୋ GI ଖାଦ୍ୟ ଖାଇବା ପରେ ଚିନି ବୃଦ୍ଧିକୁ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_fact_footcare_152',
    type: ContentType.fact,
    tags: ['diabetes', 'foot_care'],
    title: "Foot Care is Essential",
    body:
        "Diabetes reduces nerve sensation, making daily foot checks important.",
    bodyHi:
        "डायबिटीज़ नसों की संवेदना कम कर देता है, इसलिए रोज़ाना पैर की जांच ज़रूरी है।",
    bodyOd:
        "ଡାଇବେଟିଜ୍ ସ୍ନାୟୁ ସନ୍ବେଦନା କମାଇଦିଏ, ସେଥିପାଇଁ ପ୍ରତିଦିନ ପାଦ ପରୀକ୍ଷା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'diabetes_advice_mealspread_153',
    type: ContentType.advice,
    tags: ['diabetes', 'meal_timing'],
    title: "Spread Meals Through the Day",
    body: "Eat smaller, frequent meals to avoid sudden glucose fluctuations.",
    bodyHi:
        "छोटे-छोटे और बार-बार भोजन लेने से अचानक ग्लूकोज उतार-चढ़ाव से बचा जा सकता है।",
    bodyOd:
        "ଛୋଟ ଏବଂ ମଧ୍ୟମ ତାତ୍ତ୍ୱିକ ଭୋଜନ ଖାଇଲେ ଅଚାନକ ଗ୍ଲୁକୋଜ୍ ପରିବର୍ତ୍ତନ ରୋକାଯାଏ।",
  ),
  WellnessContentModel(
    id: 'pcos_tip_strengthtrain_154',
    type: ContentType.tip,
    tags: ['pcos', 'exercise'],
    title: "Use Strength Training",
    body:
        "Strength workouts improve insulin sensitivity and hormone balance in PCOS.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग पीसीओएस में इंसुलिन संवेदनशीलता और हार्मोन संतुलन सुधारती है।",
    bodyOd:
        "ଷ୍ଟ୍ରେଙ୍ଗ୍ଥ ଟ୍ରେନିଂ ପିସିଓଏସ୍‌ରେ ଇନସୁଲିନ୍ ସନ୍ବେଦନା ଏବଂ ହରମୋନ ସନ୍ତୁଳନ ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_fact_inflammation_155',
    type: ContentType.fact,
    tags: ['pcos', 'inflammation'],
    title: "PCOS Involves Inflammation",
    body:
        "Women with PCOS often experience low-grade inflammation, affecting metabolism.",
    bodyHi:
        "पीसीओएस वाली महिलाओं में लो-ग्रेड इंफ्लेमेशन पाया जाता है, जो मेटाबॉलिज्म को प्रभावित करता है।",
    bodyOd:
        "ପିସିଓଏସ୍ ମହିଳାମାନେ ଲୋ-ଗ୍ରେଡ୍ ଜ୍ୱରାଭାବ ଅନୁଭବ କରନ୍ତି, ଯାହା ମେଟାବଲିଜମ୍‌କୁ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_advice_sleep_156',
    type: ContentType.advice,
    tags: ['pcos', 'sleep'],
    title: "Prioritize Deep Sleep",
    body:
        "Good sleep improves hormone regulation and reduces cravings in PCOS.",
    bodyHi: "अच्छी नींद हार्मोन संतुलन सुधारती है और क्रेविंग कम करती है।",
    bodyOd: "ଭଲ ଘୁମ ହରମୋନ ନିୟନ୍ତ୍ରଣ ସୁଧାରେ ଏବଂ ଖାଦ୍ୟ ଇଚ୍ଛା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_tip_labels_157',
    type: ContentType.tip,
    tags: ['hypertension', 'salt_intake'],
    title: "Read Sodium on Labels",
    body: "Always check packaged food labels for sodium to protect your BP.",
    bodyHi: "पैक्ड फूड खरीदने से पहले सोडियम लेबल ज़रूर पढ़ें।",
    bodyOd: "ପ୍ୟାକେଜ୍ ଫୁଡ୍ କିଣିବା ପୂର୍ବରୁ ସୋଡିଆମ୍ ଲେବେଲ୍ ଦେଖିବା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'hypertension_fact_potassium_158',
    type: ContentType.fact,
    tags: ['hypertension', 'potassium'],
    title: "Potassium Lowers BP",
    body:
        "Foods rich in potassium help relax blood vessel walls and reduce BP.",
    bodyHi:
        "पोटैशियम से भरपूर खाद्य पदार्थ रक्त वाहिकाओं को आराम दे कर बीपी कम करते हैं।",
    bodyOd: "ପୋଟାସିଆମ୍ ଯୁକ୍ତ ଖାଦ୍ୟ ରକ୍ତନାଳୀକୁ ଶିଥିଳ କରି BP କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_advice_activity_159',
    type: ContentType.advice,
    tags: ['hypertension', 'exercise'],
    title: "Stay Active Every Day",
    body:
        "Even 20–30 minutes of walking daily can significantly lower blood pressure.",
    bodyHi: "रोज़ 20–30 मिनट की वॉक भी बीपी को काफी कम कर सकती है।",
    bodyOd: "ଦିନକୁ 20–30 ମିନିଟ୍ ହାଟିବା ରକ୍ତଚାପକୁ ଅନେକ କମାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_tip_protein_160',
    type: ContentType.tip,
    tags: ['thyroid', 'protein'],
    title: "Add Protein for Thyroid Support",
    body: "Protein-rich meals help maintain steady thyroid hormone production.",
    bodyHi: "प्रोटीन युक्त भोजन थायरॉयड हार्मोन उत्पादन को स्थिर बनाए रखता है।",
    bodyOd: "ପ୍ରୋଟିନ୍ ଯୁକ୍ତ ଖାଦ୍ୟ ଥାଇରଏଡ୍ ହରମୋନ ଉତ୍ପାଦନକୁ ସ୍ଥିର ରଖେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_autoimmune_161',
    type: ContentType.fact,
    tags: ['thyroid', 'autoimmune'],
    title: "Many Thyroid Cases Are Autoimmune",
    body:
        "Hashimoto’s and Graves’ disease are common autoimmune thyroid disorders.",
    bodyHi: "हाशिमोटो और ग्रेव्स बीमारी आम ऑटोइम्यून थायरॉयड विकार हैं।",
    bodyOd: "ହାସିମୋଟୋ ଏବଂ ଗ୍ରେଭସ୍ ରୋଗ ସାଧାରଣ ଅଟୋଇମ୍ୟୁନ୍ ଥାଇରଏଡ୍ ବିକାର।",
  ),
  WellnessContentModel(
    id: 'thyroid_advice_medtiming_162',
    type: ContentType.advice,
    tags: ['thyroid', 'medication'],
    title: "Take Thyroid Medicine on Empty Stomach",
    body:
        "Thyroid tablets work best when taken 30–45 minutes before breakfast.",
    bodyHi: "थायरॉयड दवा नाश्ते से 30–45 मिनट पहले खाली पेट लें।",
    bodyOd:
        "ଥାଇରଏଡ୍ ଔଷଧ ଖାଲି ପେଟରେ ନାଷ୍ତା ପୂର୍ବରୁ 30–45 ମିନିଟ୍ ପ୍ରଥମେ ନେଲେ ଭଲ କାମ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_tip_omega3_163',
    type: ContentType.tip,
    tags: ['cardiac', 'omega3'],
    title: "Include Omega-3 Foods",
    body:
        "Flaxseeds, walnuts, and fish oil support heart health and reduce inflammation.",
    bodyHi: "अलसी, अखरोट और फिश ऑयल हृदय स्वास्थ्य को बेहतर बनाते हैं।",
    bodyOd: "ତିଲ, ଅଖରୋଟ ଏବଂ ମାଛ ତେଲ ହୃଦ୍ୟ ସ୍ୱାସ୍ଥ୍ୟକୁ ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_fact_bpchol_164',
    type: ContentType.fact,
    tags: ['cardiac', 'cholesterol'],
    title: "BP and Cholesterol Are Linked",
    body:
        "High blood pressure often coexists with high cholesterol, increasing heart risk.",
    bodyHi:
        "उच्च बीपी और उच्च कोलेस्ट्रॉल अक्सर साथ पाए जाते हैं और हार्ट रिस्क बढ़ाते हैं।",
    bodyOd: "ଉଚ୍ଚ BP ଏବଂ କଲେଷ୍ଟେରଲ ସହିତ ଦେଖାଯାଏ ଏବଂ ହୃଦ୍ୟ ଜୋଖିମ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'cardiac_advice_walk_165',
    type: ContentType.advice,
    tags: ['cardiac', 'activity'],
    title: "Walk After Meals",
    body:
        "A short 10-minute walk after meals helps maintain heart and glucose health.",
    bodyHi: "खाने के बाद 10 मिनट चलना दिल और शुगर दोनों के लिए लाभदायक है।",
    bodyOd: "ଖାଇ ହେବା ପରେ 10 ମିନିଟ୍ ହାଟିବା ହୃଦ୍ୟ ଏବଂ ଚିନି ପାଇଁ ଭଲ।",
  ),
  WellnessContentModel(
    id: 'renal_tip_fluidtrack_166',
    type: ContentType.tip,
    tags: ['renal', 'fluid'],
    title: "Track Fluid Intake",
    body: "Kidney patients must monitor daily water intake to avoid overload.",
    bodyHi: "किडनी मरीजों को पानी की मात्रा का रोज़ाना ध्यान रखना चाहिए।",
    bodyOd: "କିଡନି ରୋଗୀମାନେ ପ୍ରତିଦିନ ପାଣି ଗ୍ରହଣ ଟ୍ରାକ୍ କରିବା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'renal_fact_proteinlimit_167',
    type: ContentType.fact,
    tags: ['renal', 'protein_control'],
    title: "Protein Needs Adjusting in CKD",
    body:
        "Chronic kidney disease requires controlled protein intake to reduce strain.",
    bodyHi:
        "सीकेडी में प्रोटीन का नियंत्रित सेवन जरूरी है ताकि किडनी पर दबाव कम हो।",
    bodyOd: "CKD ରେ ପ୍ରୋଟିନ୍ ନିୟନ୍ତ୍ରିତ ରଖିବା କିଡନି ଉପରେ ଚାପ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'renal_advice_saltlimit_168',
    type: ContentType.advice,
    tags: ['renal', 'salt_control'],
    title: "Limit Salt Strictly",
    body: "Lower sodium intake helps prevent fluid retention in kidney issues.",
    bodyHi: "सोडियम कम करना किडनी रोग में फ्लूइड रिटेंशन से बचाता है।",
    bodyOd: "ସୋଡିଆମ୍ କମ୍ କଲେ କିଡନି ସମସ୍ୟାରେ ପାଣି ଜମା ରୋକିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_tip_millets_169',
    type: ContentType.tip,
    tags: ['fatty_liver', 'millets'],
    title: "Switch to Millets",
    body: "Millets improve liver fat metabolism and support weight loss.",
    bodyHi:
        "मिलेट्स लिवर फैट मेटाबॉलिज्म सुधारते हैं और वजन घटाने में मदद करते हैं।",
    bodyOd: "ମିଲେଟ୍ ଲିଭର ଫ୍ୟାଟ୍ ମେଟାବଲିଜମ୍ ସୁଧାରେ ଏବଂ ଓଜନ ହ୍ରାସକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_fact_sugar_170',
    type: ContentType.fact,
    tags: ['fatty_liver', 'sugar'],
    title: "Excess Sugar Worsens Fatty Liver",
    body: "Fructose-heavy foods promote fat buildup in the liver.",
    bodyHi: "अधिक फ्रक्टोज़ लिवर में फैट जमा होने की प्रक्रिया बढ़ाता है।",
    bodyOd: "ଅଧିକ ଫ୍ରକ୍ଟୋଜ୍ ଲିଭରରେ ଚର୍ବି ଜମା ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'fatty_liver_advice_portion_171',
    type: ContentType.advice,
    tags: ['fatty_liver', 'portion_control'],
    title: "Watch Portion Sizes",
    body: "Smaller meals reduce liver load and support fat reversal.",
    bodyHi:
        "छोटे भागों में खाना लिवर पर भार कम करता है और फैट घटाने में मदद करता है।",
    bodyOd: "ଛୋଟ ଭାଗରେ ଭୋଜନ କଲେ ଲିଭରରେ ଚାପ କମେ ଏବଂ ଚର୍ବି ହ୍ରାସ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_tip_nuts_172',
    type: ContentType.tip,
    tags: ['cholesterol', 'nuts'],
    title: "Eat a Handful of Nuts",
    body: "Walnuts and almonds raise good cholesterol and protect the heart.",
    bodyHi:
        "अखरोट और बादाम अच्छा कोलेस्ट्रॉल बढ़ाते हैं और दिल की रक्षा करते हैं।",
    bodyOd: "ଅଖରୋଟ ଏବଂ ବାଦାମ୍ ଭଲ କଲେଷ୍ଟେରଲ ବଢ଼ାଇ ହୃଦ୍ୟକୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_fact_transfat_173',
    type: ContentType.fact,
    tags: ['cholesterol', 'trans_fat'],
    title: "Trans Fats Raise LDL Quickly",
    body:
        "Fried and packaged foods rich in trans fats worsen cholesterol levels rapidly.",
    bodyHi:
        "ट्रांस फैट से भरपूर तले और पैक्ड फूड एलडीएल बहुत तेजी से बढ़ाते हैं।",
    bodyOd: "ଟ୍ରାନ୍ସ ଫ୍ୟାଟ୍ ଯୁକ୍ତ ତଳା ଖାଦ୍ୟ LDL କୁ ଖୁବ ଶୀଘ୍ର ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'cholesterol_advice_fiber_174',
    type: ContentType.advice,
    tags: ['cholesterol', 'fiber'],
    title: "Add More Soluble Fiber",
    body: "Soluble fiber binds cholesterol and lowers absorption.",
    bodyHi: "घुलनशील फाइबर कोलेस्ट्रॉल को बांधकर अवशोषण कम करता है।",
    bodyOd: "ଘୁଳିବା ଫାଇବର୍ କଲେଷ୍ଟେରଲକୁ ବାନ୍ଧି ଶୋଷଣ କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_tip_beetroot_175',
    type: ContentType.tip,
    tags: ['anemia', 'iron'],
    title: "Use Beetroot for Iron Boost",
    body:
        "Beetroot helps improve hemoglobin levels when paired with vitamin C.",
    bodyHi:
        "चुकंदर विटामिन C के साथ लेने पर हीमोग्लोबिन बढ़ाने में मदद करता है।",
    bodyOd: "ଚୁକୁନ୍ଡା ଭିଟାମିନ୍ C ସହ ନେଲେ ହିମୋଗ୍ଲୋବିନ୍ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'anemia_fact_female_176',
    type: ContentType.fact,
    tags: ['anemia', 'women_health'],
    title: "Women Face Higher Anemia Risk",
    body: "Menstruation and low dietary iron increase risk in women.",
    bodyHi:
        "महिलाओं में मासिक धर्म और कम आयरन सेवन के कारण एनीमिया का जोखिम अधिक होता है।",
    bodyOd: "ମହିଳାମାନେ ମାସିକ ଏବଂ କମ୍ ଲୋହ ଆହାର ଦ୍ୱାରା ଅଧିକ ଜୋଖିମରେ ରହନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'anemia_advice_donttea_177',
    type: ContentType.advice,
    tags: ['anemia', 'caffeine'],
    title: "Avoid Tea With Iron Meals",
    body: "Tea reduces iron absorption, so keep a 1-hour gap.",
    bodyHi: "चाय आयरन अवशोषण कम करती है, इसलिए 1 घंटे का अंतर रखें।",
    bodyOd: "ଚା ଲୋହ ଶୋଷଣ କମାଏ, ତେଣୁ 1 ଘଣ୍ଟା ବ୍ୟବଧାନ ରଖନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_tip_folic_178',
    type: ContentType.tip,
    tags: ['sickle_cell', 'folate'],
    title: "Take Folate-Rich Foods",
    body: "Folate supports healthy red blood cell formation in sickle cell.",
    bodyHi: "फोलेट लाल रक्त कोशिकाओं के निर्माण में मदद करता है।",
    bodyOd: "ଫୋଲେଟ୍ ସିକେଲ୍ ସେଲ୍‌ରେ ରକ୍ତକଣି ଗଠନ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_fact_pain_179',
    type: ContentType.fact,
    tags: ['sickle_cell', 'pain_crisis'],
    title: "Pain Crises Are Triggered by Dehydration",
    body: "Lack of fluids thickens blood and worsens blockage in sickle cell.",
    bodyHi: "डिहाइड्रेशन खून को गाढ़ा कर सिकल सेल में दर्द बढ़ा सकता है।",
    bodyOd: "ଡିହାଇଡ୍ରେସନ୍ ରକ୍ତକୁ ଘନ କରି ସିକେଲ୍ ସେଲ୍ ଦର୍ଦ୍ଦ ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_advice_avoidcold_180',
    type: ContentType.advice,
    tags: ['sickle_cell', 'temperature'],
    title: "Stay Warm in Cold Weather",
    body: "Cold triggers vaso-constriction, increasing pain risks.",
    bodyHi: "ठंड रक्त वाहिकाओं को संकुचित कर दर्द का जोखिम बढ़ाती है।",
    bodyOd: "ଥଣ୍ଡା ପାଣି ରକ୍ତନାଳୀକୁ ସଙ୍କୋଚିତ କରି ବେଦନା ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'diabetes_tip_plate_181',
    type: ContentType.tip,
    tags: ['diabetes', 'portion_control'],
    title: "Use the Diabetes Plate Method",
    body:
        "Half veggies, quarter protein, and quarter whole grains help manage glucose.",
    bodyHi:
        "आधी सब्जियाँ, चौथाई प्रोटीन और चौथाई अनाज शुगर कंट्रोल में मदद करते हैं।",
    bodyOd:
        "ଆଧା ସବ୍ଜି, ଚତୁର୍ଥାଂଶ ପ୍ରୋଟିନ୍ ଏବଂ ଚତୁର୍ଥାଂଶ ଅନାଜ ଗ୍ଲୁକୋଜ୍ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'diabetes_fact_dawn_182',
    type: ContentType.fact,
    tags: ['diabetes', 'glucose'],
    title: "Dawn Phenomenon is Normal",
    body: "Morning high sugars occur due to nighttime hormone release.",
    bodyHi: "सुबह शुगर बढ़ना नाइटटाइम हार्मोन रिलीज़ के कारण सामान्य है।",
    bodyOd: "ସକାଳେ ଚିନି ବଢ଼ିବା ରାତିରେ ହରମୋନ ମୁକ୍ତି ଦ୍ୱାରା ସାଧାରଣ।",
  ),
  WellnessContentModel(
    id: 'diabetes_advice_stress_183',
    type: ContentType.advice,
    tags: ['diabetes', 'stress'],
    title: "Reduce Daily Stress",
    body: "Stress hormones raise blood sugar, so relaxation practices help.",
    bodyHi: "तनाव हार्मोन शुगर बढ़ाते हैं, इसलिए रिलैक्सेशन ज़रूरी है।",
    bodyOd: "ଚାପ ହରମୋନ ଚିନି ବଢ଼ାଏ, ତେଣୁ ଶାନ୍ତି ପ୍ରାକ୍ରିୟା ଜରୁରୀ।",
  ),
  WellnessContentModel(
    id: 'pcos_tip_water_184',
    type: ContentType.tip,
    tags: ['pcos', 'hydration'],
    title: "Stay Hydrated for Hormone Balance",
    body: "Water helps regulate appetite and hormone rhythm.",
    bodyHi: "पर्याप्त पानी हार्मोन संतुलन और भूख नियंत्रण में मदद करता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ହରମୋନ ସନ୍ତୁଳନ ଏବଂ ଭୋକ ନିୟନ୍ତ୍ରଣରେ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_fact_weightloss_185',
    type: ContentType.fact,
    tags: ['pcos', 'weight_loss'],
    title: "Even 5% Weight Loss Helps PCOS",
    body: "Small reductions improve cycles and reduce symptoms.",
    bodyHi: "केवल 5% वजन कम करने से ही पीसीओएस में चक्र और लक्षण सुधरते हैं।",
    bodyOd: "କେବଳ 5% ଓଜନ କମିଲେ ପିସିଓଏସ୍ ଲକ୍ଷଣ ଏବଂ ଚକ୍ର ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'pcos_advice_lowcarb_186',
    type: ContentType.advice,
    tags: ['pcos', 'diet'],
    title: "Try Lower-Carb Meals",
    body: "Reducing carbs improves insulin response in PCOS.",
    bodyHi: "कार्ब कम करने से इंसुलिन प्रतिक्रिया बेहतर होती है।",
    bodyOd: "କାର୍ବ କମାଲେ ପିସିଓଏସ୍‌ରେ ଇନସୁଲିନ୍ ପ୍ରତିକ୍ରିୟା ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_tip_pacewalk_187',
    type: ContentType.tip,
    tags: ['hypertension', 'activity'],
    title: "Practice Brisk Walking",
    body: "A faster walking pace helps reduce blood pressure effectively.",
    bodyHi: "तेज़ चाल में चलना बीपी को बेहतर तरीके से कम करता है।",
    bodyOd: "ତୀବ୍ର ଗତିରେ ହାଟିଲେ BP ଫଳଦାୟକ ଭାବରେ କମେ।",
  ),
  WellnessContentModel(
    id: 'hypertension_fact_renin_188',
    type: ContentType.fact,
    tags: ['hypertension', 'hormones'],
    title: "Hormones Influence BP",
    body: "Renin and aldosterone play key roles in BP regulation.",
    bodyHi:
        "रेनिन और एल्डोस्टेरोन हार्मोन बीपी नियंत्रण में मुख्य भूमिका निभाते हैं।",
    bodyOd: "ରେନିନ୍ ଏବଂ ଆଲଡୋସ୍ଟେରୋନ୍ BP ନିୟନ୍ତ୍ରଣରେ ମୁଖ୍ୟ ଭୂମିକା ନେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'hypertension_advice_limitcoffee_189',
    type: ContentType.advice,
    tags: ['hypertension', 'caffeine'],
    title: "Limit Caffeine Intake",
    body: "Excess caffeine temporarily spikes BP, so moderation is key.",
    bodyHi: "अधिक कैफीन बीपी बढ़ा सकता है, इसलिए सीमित मात्रा में लें।",
    bodyOd: "ଅଧିକ କଫିନ୍ BP ବଢ଼ାଏ, ତେଣୁ ସୀମିତ କରନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'thyroid_tip_iodine_190',
    type: ContentType.tip,
    tags: ['thyroid', 'iodine'],
    title: "Ensure Adequate Iodine",
    body: "Iodized salt supports thyroid hormone formation.",
    bodyHi: "आयोडीन युक्त नमक थायरॉयड हार्मोन बनने में मदद करता है।",
    bodyOd: "ଆୟୋଡିନ୍ ଥିବା ଲୁଣ ଥାଇରଏଡ୍ ହରମୋନ ଗଠନକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'thyroid_fact_women_191',
    type: ContentType.fact,
    tags: ['thyroid', 'women_health'],
    title: "Women Are More Affected",
    body:
        "Thyroid issues occur more commonly in women due to hormonal variations.",
    bodyHi:
        "हार्मोनल परिवर्तनों के कारण थायरॉयड समस्याएं महिलाओं में अधिक होती हैं।",
    bodyOd: "ହରମୋନ ପରିବର୍ତ୍ତନ ଦ୍ୱାରା ମହିଳାମାନେ ଥାଇରଏଡ୍ ସମସ୍ୟାରେ ଅଧିକ ପ୍ରଭାବିତ।",
  ),
  WellnessContentModel(
    id: 'thyroid_advice_mindfulcarb_192',
    type: ContentType.advice,
    tags: ['thyroid', 'diet'],
    title: "Manage Carbs Smartly",
    body: "Balanced carbs support thyroid energy and metabolism.",
    bodyHi: "संतुलित कार्ब सेवन थायरॉयड ऊर्जा और मेटाबॉलिज्म सुधारता है।",
    bodyOd: "ସନ୍ତୁଳିତ କାର୍ବ ଥାଇରଏଡ୍ ଶକ୍ତି ଏବଂ ମେଟାବଲିଜମ୍ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'cardiac_tip_pulsecheck_193',
    type: ContentType.tip,
    tags: ['cardiac', 'vitals'],
    title: "Check Pulse Regularly",
    body: "Tracking your pulse helps monitor heart rhythm changes early.",
    bodyHi: "नियमित नाड़ी जांच हृदय की धड़कन में बदलाव का पता जल्दी लगाती है।",
    bodyOd: "ନିୟମିତ ନାଡ଼ି ଚେକ୍ କଲେ ହୃଦ୍ୟ ଲୟର ପରିବର୍ତ୍ତନ ଶୀଘ୍ର ଧରାପଡ଼େ।",
  ),
  WellnessContentModel(
    id: 'cardiac_fact_sugarheart_194',
    type: ContentType.fact,
    tags: ['cardiac', 'sugar'],
    title: "High Sugar Harms the Heart",
    body:
        "Persistently high glucose stiffens arteries and raises cardiac risk.",
    bodyHi:
        "लगातार उच्च शुगर धमनियों को सख्त करती है और दिल का जोखिम बढ़ाती है।",
    bodyOd: "ଅଧିକ ଚିନି ଧମନୀକୁ କଠୋର କରି ହୃଦ୍ୟ ଜୋଖିମ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'cardiac_advice_stress_195',
    type: ContentType.advice,
    tags: ['cardiac', 'stress'],
    title: "Control Stress for Heart Safety",
    body: "Chronic stress strains your heart and raises BP.",
    bodyHi: "लगातार तनाव दिल पर दबाव डालता है और बीपी बढ़ाता है।",
    bodyOd: "ଦୀର୍ଘକାଳୀନ ଚାପ ହୃଦ୍ୟକୁ ଚାପ ଦେଇ BP ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'renal_tip_lowphos_196',
    type: ContentType.tip,
    tags: ['renal', 'phosphorus'],
    title: "Limit High-Phosphorus Foods",
    body:
        "Avoid cola, processed foods, and excess dairy to protect your kidneys.",
    bodyHi:
        "कोला, प्रोसेस्ड फूड और ज्यादा डेयरी से बचें क्योंकि इनमें फॉस्फोरस अधिक होता है।",
    bodyOd: "କୋଲା, ପ୍ରସ୍ତୁତ ଖାଦ୍ୟ ଏବଂ ଅଧିକ ଡେଉରି କିଡନି ପାଇଁ ହାନିକାରକ।",
  ),
  WellnessContentModel(
    id: 'renal_fact_bloodfilter_197',
    type: ContentType.fact,
    tags: ['renal', 'function'],
    title: "Kidneys Filter 150 Liters Daily",
    body: "Healthy kidneys filter blood constantly to remove toxins.",
    bodyHi: "स्वस्थ किडनी रोज़ लगभग 150 लीटर रक्त को फ़िल्टर करती हैं।",
    bodyOd: "ସୁସ୍ଥ କିଡନି ଦିନକୁ 150 ଲିଟର ରକ୍ତ ଫିଲ୍ଟର୍ କରେ।",
  ),
  WellnessContentModel(
    id: 'renal_advice_bpcontrol_198',
    type: ContentType.advice,
    tags: ['renal', 'bp_control'],
    title: "Control BP to Save Kidneys",
    body: "High BP damages kidney blood vessels over time.",
    bodyHi:
        "उच्च बीपी समय के साथ किडनी की रक्त वाहिकाओं को नुकसान पहुंचाता है।",
    bodyOd: "ଉଚ୍ଚ BP କିଡନି ରକ୍ତନାଳୀକୁ କ୍ଷତି କରେ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_tip_antioxidants_199',
    type: ContentType.tip,
    tags: ['sickle_cell', 'antioxidants'],
    title: "Eat Antioxidant-Rich Foods",
    body: "Berries and citrus help reduce oxidative stress in sickle cell.",
    bodyHi: "बेरी और सिट्रस जैसे खाद्य पदार्थ ऑक्सीडेटिव स्ट्रेस कम करते हैं।",
    bodyOd: "ବେରୀ ଏବଂ ସିଟ୍ରସ୍ ଖାଦ୍ୟ ଅକ୍ସିଡେଟିଭ୍ ସ୍ଟ୍ରେସ୍ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'sickle_cell_fact_genetic_200',
    type: ContentType.fact,
    tags: ['sickle_cell', 'genetics'],
    title: "Sickle Cell Is Genetic",
    body: "It is an inherited blood disorder passed from parents to children.",
    bodyHi: "सिकल सेल एक अनुवांशिक रोग है जो माता-पिता से बच्चों में जाता है।",
    bodyOd: "ସିକେଲ୍ ସେଲ୍ ଜନ୍ମଜାତ ରୋଗ, ମାତାପିତାରୁ ଶିଶୁଙ୍କୁ ଯାଏ।",
  ),
  WellnessContentModel(
    id: 'minerals_fact_zinc_immunity_201',
    type: ContentType.fact,
    tags: ['minerals', 'immunity'],
    title: "Zinc Boosts Immunity",
    body:
        "Zinc supports immune cell function and helps your body fight infections effectively.",
    bodyHi:
        "जिंक इम्यून कोशिकाओं को मजबूत करता है और शरीर को संक्रमण से लड़ने में मदद करता है।",
    bodyOd:
        "ଜିଙ୍କ ରୋଗପ୍ରତିରୋଧ କୋଷଗୁଡ଼ିକୁ ସୁଦୃଢ କରି ଶରୀରକୁ ସଂକ୍ରମଣ ସହିତ ଲଢ଼ିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_tip_b12_energy_202',
    type: ContentType.tip,
    tags: ['deficiency', 'energy_levels'],
    title: "Low Energy? Check B12",
    body:
        "Vitamin B12 deficiency commonly causes fatigue and weakness; timely testing helps recovery.",
    bodyHi:
        "थकान और कमजोरी बी12 की कमी का संकेत हो सकते हैं, समय पर जांच करवाना जरूरी है।",
    bodyOd:
        "କ୍ଲାନ୍ତି ଏବଂ ଦୁର୍ବଳତା B12 ଅଭାବର ସଙ୍କେତ ହୋଇପାରେ, ସମୟରେ ପରୀକ୍ଷା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'vitamins_myth_supplements_only_203',
    type: ContentType.myth,
    tags: ['vitamins', 'diet'],
    title: "Myth: Vitamins Only Come from Supplements",
    body:
        "Whole foods like fruits, vegetables, and nuts are rich natural sources of vitamins.",
    bodyHi:
        "मिथ: विटामिन केवल सप्लीमेंट से मिलते हैं। फल, सब्जियाँ और नट्स विटामिन के प्राकृतिक स्रोत हैं।",
    bodyOd:
        "ମିଥ୍: ଭିଟାମିନ୍ କେବଳ ସପ୍ଲିମେଣ୍ଟରୁ ମିଳେ। ଫଳ, ସବ୍ଜି ଏବଂ ନଟ୍ସ ସ୍ୱାଭାବିକ ଭିଟାମିନ୍ ଉତ୍ସ।",
  ),
  WellnessContentModel(
    id: 'protein_fact_muscle_204',
    type: ContentType.fact,
    tags: ['protein', 'muscle_health'],
    title: "Protein Builds Muscle",
    body:
        "Your body needs protein to repair and grow muscle, especially after physical activity.",
    bodyHi:
        "शारीरिक गतिविधि के बाद मांसपेशियों की मरम्मत और विकास के लिए प्रोटीन जरूरी है।",
    bodyOd: "ଶାରୀରିକ କାର୍ଯ୍ୟ ପରେ ପେଶୀ ମରାମତି ଏବଂ ବୃଦ୍ଧି ପାଇଁ ପ୍ରୋଟିନ୍ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'fiber_tip_digestion_205',
    type: ContentType.tip,
    tags: ['fiber', 'digestion'],
    title: "Add Fiber for Smooth Digestion",
    body:
        "Fiber-rich foods support bowel movement and prevent constipation naturally.",
    bodyHi: "फाइबर युक्त भोजन पाचन को बेहतर बनाता है और कब्ज से बचाता है।",
    bodyOd: "ଫାଇବର୍ ଭରିଥିବା ଖାଦ୍ୟ ପଚନକୁ ସହାଯ୍ୟ କରେ ଏବଂ କବ୍ଜ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'hydration_knowledge_cells_206',
    type: ContentType.knowledge,
    tags: ['hydration', 'cell_function'],
    title: "Hydration Supports Every Cell",
    body:
        "Water is essential for nutrient delivery and temperature regulation in the body.",
    bodyHi:
        "पानी शरीर में पोषक तत्व पहुँचाने और तापमान नियंत्रित करने के लिए आवश्यक है।",
    bodyOd: "ପାଣି ଶରୀରରେ ପୋଷକ ଦେବା ଏବଂ ତାପମାତ୍ରା ନିୟନ୍ତ୍ରଣ ପାଇଁ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'minerals_tip_iron_sources_207',
    type: ContentType.tip,
    tags: ['minerals', 'iron'],
    title: "Boost Iron Naturally",
    body:
        "Include spinach, beans, jaggery, and lentils to improve daily iron intake.",
    bodyHi: "दैनिक आयरन बढ़ाने के लिए पालक, दालें, गुड़ और बीन्स शामिल करें।",
    bodyOd: "ଦିନିକିଆ ଲୋହ ବଢ଼ାଇବାକୁ ପାଳକ, ଡାଲି, ଗୁଡ଼ ଏବଂ ବିଆନ୍ସ ଖାଉଥିବେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_fact_vitd_bone_208',
    type: ContentType.fact,
    tags: ['deficiency', 'bone_health'],
    title: "Vitamin D Deficiency Weakens Bones",
    body:
        "Low vitamin D levels reduce calcium absorption and may lead to bone pain.",
    bodyHi:
        "विटामिन D की कमी कैल्शियम अवशोषण को कम करती है और हड्डियों में दर्द पैदा कर सकती है।",
    bodyOd: "ଭିଟାମିନ୍ D ଅଭାବ କ୍ୟାଲସିୟମ୍ ଶୋଷଣ କମାଇ ହାଡ଼ିରେ ବିଥା ହୋଇପାରେ।",
  ),

  // --- Continue generating in the same format ---
  // To keep output within limits, I will continue with the remaining items below:
  WellnessContentModel(
    id: 'vitamins_tip_fruits_209',
    type: ContentType.tip,
    tags: ['vitamins', 'fruits'],
    title: "Eat Colorful Fruits",
    body:
        "A variety of fruits ensures a wide range of vitamins for overall wellness.",
    bodyHi:
        "रंग-बिरंगे फल विभिन्न विटामिन प्रदान करते हैं और संपूर्ण स्वास्थ्य को समर्थन देते हैं।",
    bodyOd:
        "ବିବିଧ ରଙ୍ଗର ଫଳ ଭିନ୍ନ ଭିନ୍ନ ଭିଟାମିନ୍ ଦେଉଛି ଏବଂ ସ୍ୱାସ୍ଥ୍ୟକୁ ସମର୍ଥନ କରେ।",
  ),
  WellnessContentModel(
    id: 'protein_myth_heavy_210',
    type: ContentType.myth,
    tags: ['protein', 'diet'],
    title: "Myth: Protein Makes You Heavy",
    body:
        "Protein does not cause bulk; it helps maintain muscle and boosts metabolism.",
    bodyHi:
        "मिथ: प्रोटीन शरीर भारी करता है। यह मांसपेशियों को बनाए रखता है और मेटाबॉलिज़्म बढ़ाता है।",
    bodyOd:
        "ମିଥ୍: ପ୍ରୋଟିନ୍ ଶରୀରକୁ ଭାରୀ କରେ। ଏହା ପେଶୀକୁ ରକ୍ଷା କରେ ଏବଂ ମେଟାବଲିଜ୍ମ ବଢ଼ାଏ।",
  ),

  // ---- Items 211–250 continue below ----
  WellnessContentModel(
    id: 'fiber_advice_wholegrains_211',
    type: ContentType.advice,
    tags: ['fiber', 'whole_grains'],
    title: "Choose Whole Grains Daily",
    body:
        "Whole grains provide fiber that improves digestion and stabilizes blood sugar.",
    bodyHi:
        "होल ग्रेन्स फाइबर देते हैं जो पाचन सुधारते हैं और ब्लड शुगर को स्थिर रखते हैं।",
    bodyOd: "ହୋଲଗ୍ରେନ୍ସ୍ ଫାଇବର୍ ଦେଇ ପଚନ ସୁଧାରେ ଏବଂ ରକ୍ତ ସକ୍କରା ସ୍ଥିର ରଖେ।",
  ),

  WellnessContentModel(
    id: 'hydration_fact_brain_212',
    type: ContentType.fact,
    tags: ['hydration', 'brain_health'],
    title: "Your Brain Needs Water",
    body: "Even mild dehydration affects concentration, mood, and memory.",
    bodyHi: "हल्का डिहाइड्रेशन भी ध्यान, मूड और याददाश्त को प्रभावित करता है।",
    bodyOd: "ସାନା ଡିହାଇଡ୍ରେସନ୍ ମଧ୍ୟ ଧ୍ୟାନ, ମନୋଭାବ ଏବଂ ସ୍ମୃତିକୁ ପ୍ରଭାବିତ କରେ।",
  ),

  WellnessContentModel(
    id: 'minerals_knowledge_magnesium_213',
    type: ContentType.knowledge,
    tags: ['minerals', 'sleep'],
    title: "Magnesium Supports Sleep",
    body: "Magnesium relaxes muscles and helps regulate sleep patterns.",
    bodyHi:
        "मैग्नीशियम मांसपेशियों को आराम देता है और नींद के पैटर्न को बेहतर बनाता है।",
    bodyOd: "ମାଗ୍ନେସିୟମ୍ ପେଶୀକୁ ଶିଥିଳ କରି ନିଦ୍ରା ନିୟମିତ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_tip_calcium_rich_214',
    type: ContentType.tip,
    tags: ['deficiency', 'calcium'],
    title: "Add Calcium-Rich Foods",
    body:
        "Ragi, milk, paneer, and leafy greens help prevent calcium deficiency.",
    bodyHi: "रागी, दूध, पनीर और हरी सब्जियाँ कैल्शियम की कमी से बचाती हैं।",
    bodyOd: "ରାଗି, ଦୁଧ, ପନିର୍ ଏବଂ ଶାକ ଶାବୁ କ୍ୟାଲସିୟମ୍ ଅଭାବ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'vitamins_fact_antioxidants_215',
    type: ContentType.fact,
    tags: ['vitamins', 'antioxidants'],
    title: "Antioxidant Vitamins Protect Cells",
    body:
        "Vitamins A, C, and E protect cells from damage caused by free radicals.",
    bodyHi: "विटामिन A, C और E कोशिकाओं को फ्री रेडिकल नुकसान से बचाते हैं।",
    bodyOd: "ଭିଟାମିନ୍ A, C ଏବଂ E କୋଷକୁ ଫ୍ରି ର୍ୟାଡିକାଲ୍ ନଷ୍ଟରୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_tip_breakfast_216',
    type: ContentType.tip,
    tags: ['protein', 'breakfast'],
    title: "Add Protein Early",
    body:
        "A protein-rich breakfast improves satiety and keeps energy stable throughout the day.",
    bodyHi:
        "प्रोटीन युक्त नाश्ता आपको लंबे समय तक भरा हुआ महसूस कराता है और ऊर्जा स्थिर रखता है।",
    bodyOd: "ପ୍ରୋଟିନ୍ ଭରିଥିବା ଖାଦ୍ୟ ପ୍ରାତଃରାଶି ଦିନ ଭରି ଶକ୍ତି ସ୍ଥିର ରଖେ।",
  ),

  WellnessContentModel(
    id: 'fiber_myth_only_salads_217',
    type: ContentType.myth,
    tags: ['fiber', 'diet'],
    title: "Myth: Fiber Only Comes from Salads",
    body: "Fiber is also found in whole grains, lentils, fruits, and nuts.",
    bodyHi:
        "मिथ: फाइबर सिर्फ सलाद में होता है। फाइबर अनाज, दालें, फल और नट्स में भी मिलता है।",
    bodyOd:
        "ମିଥ୍: ଫାଇବର୍ କେବଳ ସାଲାଡ୍ ରେ ଥାଏ। ଏହା ଅନାଜ, ଡାଲି, ଫଳ ଏବଂ ନଟ୍ସରେ ମଧ୍ୟ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_advice_thirst_218',
    type: ContentType.advice,
    tags: ['hydration', 'habits'],
    title: "Don’t Wait for Thirst",
    body:
        "Thirst is a late sign of dehydration; sip water regularly throughout the day.",
    bodyHi:
        "प्यास लगना डिहाइड्रेशन का देर से आने वाला संकेत है, दिन भर थोड़ा-थोड़ा पानी पीते रहें।",
    bodyOd:
        "ତିଆରି ଲାଗିବା ଡିହାଇଡ୍ରେସନ୍ର ବିଳମ୍ବିତ ସଙ୍କେତ; ଦିନଭରି ଥରେ ଥରେ ପାଣି ପିଅ।",
  ),

  WellnessContentModel(
    id: 'minerals_fact_potassium_219',
    type: ContentType.fact,
    tags: ['minerals', 'heart_health'],
    title: "Potassium Supports Heart Rhythm",
    body:
        "Adequate potassium helps maintain normal heartbeat and blood pressure.",
    bodyHi:
        "पोटैशियम सामान्य हार्टबीट और ब्लड प्रेशर बनाए रखने में मदद करता है।",
    bodyOd: "ପୋଟାସିୟମ୍ ହୃଦ୍ୟ ଧଡ଼କଣ ସ୍ଥିର ରଖିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_advice_folate_220',
    type: ContentType.advice,
    tags: ['deficiency', 'folate'],
    title: "Prevent Folate Deficiency",
    body:
        "Add leafy greens, beans, and citrus fruits for sufficient folate intake.",
    bodyHi:
        "हरी सब्जियाँ, बीन्स और साइट्रस फल फोलेट की कमी रोकने में सहायक हैं।",
    bodyOd: "ଶାକ ଶାବୁ, ବିଆନ୍ସ ଏବଂ ସିଟ୍ରସ୍ ଫଳ ଫୋଲେଟ୍ ଅଭାବ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'vitamins_tip_vitc_skin_221',
    type: ContentType.tip,
    tags: ['vitamins', 'skin_health'],
    title: "Vitamin C for Glowing Skin",
    body:
        "Vitamin C supports collagen production and brightens the skin naturally.",
    bodyHi:
        "विटामिन C कोलेजन उत्पादन बढ़ाता है और त्वचा को प्राकृतिक ग्लो देता है।",
    bodyOd: "ଭିଟାମିନ୍ C କଲାଜେନ୍ ବୃଦ୍ଧି କରି ଚର୍ମକୁ ପ୍ରାକୃତିକ ତେଜ ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'protein_fact_weightloss_222',
    type: ContentType.fact,
    tags: ['protein', 'weight_loss'],
    title: "Protein Aids Weight Loss",
    body: "Higher protein intake boosts metabolism and reduces cravings.",
    bodyHi: "ज्यादा प्रोटीन मेटाबॉलिज्म बढ़ाता है और क्रेविंग्स कम करता है।",
    bodyOd: "ଅଧିକ ପ୍ରୋଟିନ୍ ମେଟାବଲିଜ୍ମ ବଢ଼ାଏ ଏବଂ ଖାଇବା ଇଚ୍ଛା କମାଏ।",
  ),

  WellnessContentModel(
    id: 'fiber_tip_waterpair_223',
    type: ContentType.tip,
    tags: ['fiber', 'hydration'],
    title: "Pair Fiber with Water",
    body:
        "Fiber needs water to work properly, preventing bloating or discomfort.",
    bodyHi:
        "फाइबर के साथ पर्याप्त पानी जरूरी है, वरना सूजन या असहजता हो सकती है।",
    bodyOd: "ଫାଇବର୍ ପାଇଁ ପାଣି ଆବଶ୍ୟକ, ନହେଲେ ଫୁଲା ହେବାର ସମସ୍ୟା ହୋଇପାରେ।",
  ),

  WellnessContentModel(
    id: 'hydration_fact_joints_224',
    type: ContentType.fact,
    tags: ['hydration', 'joint_health'],
    title: "Water Cushions Your Joints",
    body:
        "Hydration keeps joints lubricated and reduces friction during movement.",
    bodyHi:
        "हाइड्रेशन जोड़ों को चिकना रखता है और मूवमेंट के दौरान घर्षण कम करता है।",
    bodyOd: "ପାଣି ସନ୍ଧିକୁ ଲୁବ୍ରିକେଟ୍ ରଖି ଘଷ୍ମଣ କମାଏ।",
  ),

  WellnessContentModel(
    id: 'minerals_myth_salt_only_225',
    type: ContentType.myth,
    tags: ['minerals', 'sodium'],
    title: "Myth: Sodium Only Comes from Salt",
    body: "Packaged foods contain hidden sodium, often more than table salt.",
    bodyHi:
        "मिथ: सोडियम केवल नमक से मिलता है। पैक्ड फूड्स में छिपा सोडियम अधिक होता है।",
    bodyOd: "ମିଥ୍: ସୋଡିୟମ୍ କେବଳ ଲୁଣରୁ ମିଳେ। ପ୍ୟାକ୍ ଖାଦ୍ୟରେ ଅଧିକ ସୋଡିୟମ୍ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'deficiency_knowledge_proteinlack_226',
    type: ContentType.knowledge,
    tags: ['deficiency', 'protein'],
    title: "Protein Deficiency Signs",
    body:
        "Hair fall, muscle loss, and slow healing may indicate low protein intake.",
    bodyHi:
        "बाल झड़ना, मांसपेशियों का कम होना और धीमी रिकवरी प्रोटीन की कमी के संकेत हैं।",
    bodyOd: "ଚୁଳ ଝରିବା, ପେଶୀ କମିବା ଏବଂ ଧୀର ଠିକ୍ ହେବା ପ୍ରୋଟିନ୍ ଅଭାବର ସଙ୍କେତ।",
  ),

  WellnessContentModel(
    id: 'vitamins_advice_multicolorplate_227',
    type: ContentType.advice,
    tags: ['vitamins', 'diet'],
    title: "Make a Multicolor Plate",
    body: "Different colors in food offer different vitamins and antioxidants.",
    bodyHi: "रंग-बिरंगा खाना अलग-अलग विटामिन और एंटीऑक्सीडेंट देता है।",
    bodyOd: "ବିବିଧ ରଙ୍ଗର ଖାଦ୍ୟ ଭିନ୍ନ ଭିନ୍ନ ଭିଟାମିନ୍ ଏବଂ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'protein_tip_snacks_228',
    type: ContentType.tip,
    tags: ['protein', 'snacks'],
    title: "Choose Protein Snacks",
    body:
        "Roasted chana, boiled eggs, or paneer cubes keep you full for longer.",
    bodyHi:
        "भुना चना, उबला अंडा और पनीर स्नैक्स आपको लंबे समय तक भरा रखते हैं।",
    bodyOd:
        "ଭୁନା ଚନା, ସିଧା ଅଣ୍ଡା ଏବଂ ପନିର୍ ସ୍ନାକ୍ସ ଦୀର୍ଘ ସମୟ ପର୍ଯ୍ୟନ୍ତ ପୁରା ରଖେ।",
  ),

  WellnessContentModel(
    id: 'fiber_fact_guthealth_229',
    type: ContentType.fact,
    tags: ['fiber', 'gut_health'],
    title: "Fiber Feeds Good Gut Bacteria",
    body:
        "Prebiotic fiber supports healthy microbiome and reduces inflammation.",
    bodyHi:
        "प्रीबायोटिक फाइबर अच्छे बैक्टीरिया को पोषण देता है और सूजन कम करता है।",
    bodyOd: "ପ୍ରିବାୟୋଟିକ୍ ଫାଇବର୍ ଭଲ ବ୍ୟାକ୍ଟେରିଆକୁ ଖାଦ୍ୟ ଦିଏ ଏବଂ ସୁଜନ କମାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_tip_morningwater_230',
    type: ContentType.tip,
    tags: ['hydration', 'habits'],
    title: "Drink Water After Waking Up",
    body: "Morning hydration kickstarts digestion and boosts metabolism.",
    bodyHi:
        "सुबह उठकर पानी पीने से पाचन सक्रिय होता है और मेटाबॉलिज्म बढ़ता है।",
    bodyOd: "ସକାଳେ ଉଠି ପାଣି ପିଇବା ପଚନକୁ ଚାଲୁ କରେ ଏବଂ ମେଟାବଲିଜ୍ମ ବଢ଼ାଏ।",
  ),

  // --------- Continue 231–250 ---------
  WellnessContentModel(
    id: 'minerals_tip_calcium_pair_231',
    type: ContentType.tip,
    tags: ['minerals', 'calcium'],
    title: "Pair Calcium with Vitamin D",
    body: "Vitamin D improves calcium absorption and supports bone strength.",
    bodyHi: "विटामिन D कैल्शियम अवशोषण बढ़ाता है और हड्डियाँ मजबूत करता है।",
    bodyOd: "ଭିଟାମିନ୍ D କ୍ୟାଲସିୟମ୍ ଶୋଷଣ ବଢ଼ାଇ ହାଡ଼ିକୁ ମଜବୁତ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_fact_iodine_232',
    type: ContentType.fact,
    tags: ['deficiency', 'iodine'],
    title: "Iodine Deficiency Affects Thyroid",
    body:
        "Low iodine intake may lead to thyroid swelling and hormonal imbalance.",
    bodyHi: "आयोडीन की कमी थायरॉयड सूजन और हार्मोन असंतुलन का कारण बन सकती है।",
    bodyOd: "ଆୟୋଡିନ୍ ଅଭାବ ଥାଇରଏଡ୍ ସୁଜନ ଏବଂ ହରମୋନ୍ ଅସନ୍ତୁଳନର କାରଣ।",
  ),

  WellnessContentModel(
    id: 'vitamins_knowledge_bcomplex_233',
    type: ContentType.knowledge,
    tags: ['vitamins', 'metabolism'],
    title: "B Vitamins Support Metabolism",
    body: "The B-complex group converts food into energy your body can use.",
    bodyHi: "बी-कॉम्प्लेक्स भोजन को ऊर्जा में बदलने में मदद करता है।",
    bodyOd: "B-କମ୍ପ୍ଲେକ୍ସ ଖାଦ୍ୟକୁ ଶକ୍ତିରେ ପରିଣତ କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_advice_splitintake_234',
    type: ContentType.advice,
    tags: ['protein', 'meal_planning'],
    title: "Spread Protein Through the Day",
    body:
        "Split protein intake across meals for optimal absorption and muscle repair.",
    bodyHi:
        "दिनभर में थोड़ी-थोड़ी मात्रा में प्रोटीन लेना अधिक फायदेमंद होता है।",
    bodyOd: "ଦିନ ଭରି ଥୋଡ଼ା କରି ପ୍ରୋଟିନ୍ ଖାଇବା ଅଧିକ ଉପକାରୀ।",
  ),

  WellnessContentModel(
    id: 'fiber_myth_carbs_235',
    type: ContentType.myth,
    tags: ['fiber', 'carbs'],
    title: "Myth: All Carbs Lack Fiber",
    body: "Whole grains and fruits are rich in fiber, unlike refined carbs.",
    bodyHi:
        "मिथ: सभी कार्ब्स में फाइबर नहीं होता। होल ग्रेन और फल फाइबर से भरपूर होते हैं।",
    bodyOd:
        "ମିଥ୍: ସମସ୍ତ କାର୍ବରେ ଫାଇବର୍ ନଥାଏ। ହୋଲଗ୍ରେନ୍ ଏବଂ ଫଳରେ ପ୍ରଚୁର ଫାଇବର୍ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_fact_metabolism_236',
    type: ContentType.fact,
    tags: ['hydration', 'metabolism'],
    title: "Water Boosts Metabolism",
    body: "Drinking enough water supports calorie burning and digestion.",
    bodyHi: "पर्याप्त पानी पीना मेटाबॉलिज्म और पाचन को बेहतर बनाता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିଇବା ମେଟାବଲିଜ୍ମ ଏବଂ ପଚନ ବଢ଼ାଏ।",
  ),

  WellnessContentModel(
    id: 'minerals_advice_electrolytes_237',
    type: ContentType.advice,
    tags: ['minerals', 'electrolytes'],
    title: "Maintain Electrolyte Balance",
    body:
        "Electrolytes like sodium, potassium, and magnesium support hydration and muscle function.",
    bodyHi:
        "सोडियम, पोटैशियम और मैग्नीशियम जैसे इलेक्ट्रोलाइट हाइड्रेशन और मांसपेशियों के लिए जरूरी हैं।",
    bodyOd:
        "ସୋଡିୟମ୍, ପୋଟାସିୟମ୍ ଓ ମାଗ୍ନେସିୟମ୍ ହାଇଡ୍ରେସନ୍ ଏବଂ ପେଶୀକାର୍ଯ୍ୟ ପାଇଁ ଆବଶ୍ୟକ।",
  ),

  WellnessContentModel(
    id: 'deficiency_tip_vitk_238',
    type: ContentType.tip,
    tags: ['deficiency', 'vitamin_k'],
    title: "Add Vitamin K Foods",
    body:
        "Spinach, cabbage, and broccoli prevent vitamin K deficiency naturally.",
    bodyHi: "पालक, पत्ता गोभी और ब्रोकोली विटामिन K की कमी से बचाते हैं।",
    bodyOd: "ପାଳକ, ବନ୍ଦା କୋବି ଏବଂ ବ୍ରକୋଲି Vitamin K ଅଭାବ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'vitamins_fact_sun_239',
    type: ContentType.fact,
    tags: ['vitamins', 'sunlight'],
    title: "Sunlight Creates Vitamin D",
    body: "Morning sunlight helps your body synthesize vitamin D naturally.",
    bodyHi:
        "सुबह की धूप शरीर को प्राकृतिक रूप से विटामिन D बनाने में मदद करती है।",
    bodyOd: "ସକାଳ ବେଳିଆ ସୂର୍ଯ୍ୟାଲୋକ ଶରୀରକୁ Vitamin D ତିଆରି କରିବାରେ ସହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_knowledge_aminoacids_240',
    type: ContentType.knowledge,
    tags: ['protein', 'amino_acids'],
    title: "Proteins Are Made of Amino Acids",
    body:
        "Your body uses amino acids from protein to build tissues and enzymes.",
    bodyHi:
        "प्रोटीन में मौजूद अमीनो एसिड शरीर में ऊतकों और एंजाइम बनाने में उपयोग होते हैं।",
    bodyOd:
        "ପ୍ରୋଟିନ୍ର ଆମିନୋ ଆସିଡ୍ ଶରୀରର ତନ୍ତୁ ଓ ଏନ୍ଜାଇମ୍ ତିଆରି ପାଇଁ ବ୍ୟବହୃତ ହେଉଛି।",
  ),

  WellnessContentModel(
    id: 'fiber_advice_prebiotic_241',
    type: ContentType.advice,
    tags: ['fiber', 'prebiotics'],
    title: "Choose Prebiotic Fiber",
    body:
        "Foods like onions, bananas, and oats support beneficial gut bacteria.",
    bodyHi:
        "प्याज, केला और ओट्स अच्छे बैक्टीरिया बढ़ाने वाले प्रीबायोटिक फाइबर के स्रोत हैं।",
    bodyOd:
        "ପିଆଜ, କଦଳୀ ଓ ଓଟସ୍ ପ୍ରିବାୟୋଟିକ୍ ଫାଇବର୍ ଦେଇ ଭଲ ବ୍ୟାକ୍ଟେରିଆ ବଢ଼ାନ୍ତି।",
  ),

  WellnessContentModel(
    id: 'hydration_myth_juice_242',
    type: ContentType.myth,
    tags: ['hydration', 'drinks'],
    title: "Myth: Juice Hydrates Like Water",
    body: "Water hydrates best; juices may contain excess sugar.",
    bodyHi:
        "मिथ: जूस पानी जितना हाइड्रेट करता है। पानी सबसे बेहतर है, जूस में चीनी अधिक हो सकती है।",
    bodyOd:
        "ମିଥ୍: ରସ୍ ପାଣି ପରି ହାଇଡ୍ରେଟ୍ କରେ। ପାଣି ସର୍ବୋତ୍କୃଷ୍ଟ; ରସରେ ଅଧିକ ସକ୍କରା ଥାଇପାରେ।",
  ),

  WellnessContentModel(
    id: 'minerals_fact_phosphorus_243',
    type: ContentType.fact,
    tags: ['minerals', 'bone_health'],
    title: "Phosphorus Supports Bone Strength",
    body: "Phosphorus works with calcium to maintain strong bones and teeth.",
    bodyHi:
        "फॉस्फोरस कैल्शियम के साथ मिलकर हड्डियों और दांतों को मजबूत रखता है।",
    bodyOd: "ଫସ୍ଫରସ୍ କ୍ୟାଲସିୟମ୍ ସହିତ ମିଶି ହାଡ଼ି ଓ ଦାନ୍ତକୁ ମଜବୁତ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_advice_multinutrient_244',
    type: ContentType.advice,
    tags: ['deficiency', 'diet'],
    title: "Prevent Multiple Deficiencies",
    body:
        "A varied diet with fruits, vegetables, whole grains, and proteins reduces risk of deficiencies.",
    bodyHi:
        "फल, सब्जियाँ, अनाज और प्रोटीन वाला विविध भोजन कमी के जोखिम को कम करता है।",
    bodyOd: "ଫଳ, ସବ୍ଜି, ଅନାଜ ଓ ପ୍ରୋଟିନ୍ ସହିତ ବିବିଧ ଖାଦ୍ୟ ଅଭାବର ଝୁମକ କମାଏ।",
  ),

  WellnessContentModel(
    id: 'vitamins_tip_biotin_245',
    type: ContentType.tip,
    tags: ['vitamins', 'hair_health'],
    title: "Biotin for Strong Hair",
    body: "Eggs, peanuts, and whole grains naturally boost biotin intake.",
    bodyHi:
        "अंडे, मूंगफली और अनाज बायोटिन के प्राकृतिक स्रोत हैं और बाल मजबूत बनाते हैं।",
    bodyOd: "ଅଣ୍ଡା, ବାଦାମ୍ ଓ ଅନାଜ ବାୟୋଟିନ୍ ବଢ଼ାଇ ଚୁଳ ସୁସ୍ଥ କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_myth_only_gym_246',
    type: ContentType.myth,
    tags: ['protein', 'fitness'],
    title: "Myth: Protein Is Only for Gym-Goers",
    body: "Everyone needs protein for immunity, hormones, and daily repair.",
    bodyHi:
        "मिथ: प्रोटीन सिर्फ जिम वालों के लिए है। हर व्यक्ति को इम्युनिटी और शरीर की मरम्मत के लिए प्रोटीन चाहिए।",
    bodyOd:
        "ମିଥ୍: ପ୍ରୋଟିନ୍ କେବଳ ଜିମ୍ କରୁଥିବା ଲୋକ ପାଇଁ। ସବୁଠି ଦିନିକିଆ ଶରୀର ନିର୍ମାଣ ପାଇଁ ଆବଶ୍ୟକ।",
  ),

  WellnessContentModel(
    id: 'fiber_knowledge_soluble_247',
    type: ContentType.knowledge,
    tags: ['fiber', 'soluble'],
    title: "Soluble Fiber Lowers Cholesterol",
    body:
        "Soluble fiber binds with cholesterol and helps remove it from the body.",
    bodyHi:
        "घुलनशील फाइबर कोलेस्ट्रॉल को बांधकर शरीर से बाहर निकालने में मदद करता है।",
    bodyOd: "ଘୁଲନଶୀଳ ଫାଇବର୍ କଲେଷ୍ଟେରଲ୍ ସହିତ ବାନ୍ଧି ଶରୀରରୁ ବାହାର କରେ।",
  ),

  WellnessContentModel(
    id: 'hydration_advice_coconutwater_248',
    type: ContentType.advice,
    tags: ['hydration', 'natural_drinks'],
    title: "Use Coconut Water Wisely",
    body:
        "Coconut water hydrates well but should be consumed in moderation due to potassium.",
    bodyHi:
        "नारियल पानी हाइड्रेशन देता है, लेकिन इसमें पोटैशियम अधिक होता है इसलिए सीमित मात्रा में पिएं।",
    bodyOd:
        "ନଡିଆ ପାଣି ହାଇଡ୍ରେଟ୍ କରେ, କିନ୍ତୁ ଅଧିକ ପୋଟାସିୟମ୍ ଥିବାରୁ ମାପ ମାପି ପିବା ଉଚିତ।",
  ),

  WellnessContentModel(
    id: 'minerals_tip_trace_249',
    type: ContentType.tip,
    tags: ['minerals', 'trace_minerals'],
    title: "Don’t Ignore Trace Minerals",
    body: "Copper, manganese, and chromium support metabolism and immunity.",
    bodyHi:
        "कॉपर, मैंगनीज़ और क्रोमियम जैसे सूक्ष्म खनिज मेटाबॉलिज्म और इम्युनिटी के लिए जरूरी हैं।",
    bodyOd:
        "କପର୍, ମ୍ୟାଙ୍ଗାନିଜ୍ ଓ କ୍ରୋମିଅମ୍ ମେଟାବଲିଜ୍ମ ଏବଂ ରୋଗପ୍ରତିରୋଧ ପାଇଁ ଦରକାରୀ।",
  ),

  WellnessContentModel(
    id: 'deficiency_fact_hidden_250',
    type: ContentType.fact,
    tags: ['deficiency', 'symptoms'],
    title: "Deficiencies Often Stay Hidden",
    body:
        "Mild deficiencies may not show symptoms early but can affect long-term health.",
    bodyHi:
        "हल्की कमी तुरंत दिखाई नहीं देती, लेकिन लंबे समय में स्वास्थ्य पर असर डालती है।",
    bodyOd:
        "ସାନା ଅଭାବ ଶୀଘ୍ର ସଙ୍କେତ ଦିଏ ନାହିଁ, କିନ୍ତୁ ଦୀଘରେ ସ୍ୱାସ୍ଥ୍ୟ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'minerals_fact_zinc_immunity_251',
    type: ContentType.fact,
    tags: ['minerals', 'immunity'],
    title: "Zinc Strengthens Immunity",
    body:
        "Zinc plays a crucial role in immune cell function and helps lower infection risk.",
    bodyHi:
        "जिंक प्रतिरक्षा कोशिकाओं के काम में महत्वपूर्ण भूमिका निभाता है और संक्रमण के जोखिम को कम करता है।",
    bodyOd:
        "ଜିଙ୍କ ରୋଗପ୍ରତିରୋଧକ କୋଷର କାର୍ଯ୍ୟକୁ ସମର୍ଥନ କରି ସଂକ୍ରମଣ ଝୁମକୁ କମାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'minerals_tip_magnesium_sleep_252',
    type: ContentType.tip,
    tags: ['minerals', 'sleep'],
    title: "Magnesium Helps Relaxation",
    body:
        "Magnesium-rich foods like spinach and almonds can support better sleep quality.",
    bodyHi:
        "मैग्नीशियम से भरपूर पालक और बादाम नींद की गुणवत्ता को बेहतर बनाने में मदद करते हैं।",
    bodyOd: "ମ୍ୟାଗ୍ନେସିଆମ୍ ଭରା ପାଳଙ୍କ ଏବଂ ବାଦାମ ଭଲ ଘୁମକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'minerals_myth_calcium_only_milk_253',
    type: ContentType.myth,
    tags: ['minerals', 'calcium'],
    title: "Myth: Calcium Comes Only from Milk",
    body:
        "Leafy greens, sesame seeds, and ragi are also excellent calcium sources.",
    bodyHi:
        "मिथ: कैल्शियम केवल दूध से मिलता है। हरी पत्तेदार सब्जियाँ, तिल और रागी भी अच्छे स्रोत हैं।",
    bodyOd:
        "ମିଥ୍: କ୍ୟାଲ୍ସିୟମ୍ କେବଳ ଦୁଧରେ ମିଳେ। ସାଗ, ତିଳ ଏବଂ ରାଗି ମଧ୍ୟ ଉତ୍କୃଷ୍ଟ ସ୍ରୋତ।",
  ),
  WellnessContentModel(
    id: 'minerals_advice_iron_blockers_254',
    type: ContentType.advice,
    tags: ['minerals', 'iron'],
    title: "Avoid Iron Blockers with Meals",
    body:
        "Tea and coffee reduce iron absorption, so keep them at least 1 hour away from meals.",
    bodyHi:
        "चाय और कॉफी आयरन अवशोषण को कम करती हैं, इसलिए भोजन से 1 घंटे का अंतर रखें।",
    bodyOd:
        "ଚା ଏବଂ କଫି ଲୋହ ଶୋଷଣ କମାଇଦେଇଥାଏ, ତେଣୁ ଭୋଜନରୁ 1 ଘଣ୍ଟା ଦୂରରେ ନିଅନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'minerals_knowledge_potassium_balance_255',
    type: ContentType.knowledge,
    tags: ['minerals', 'electrolytes'],
    title: "Potassium Maintains Electrolyte Balance",
    body:
        "Potassium regulates fluid balance and supports muscle and nerve function.",
    bodyHi:
        "पोटैशियम द्रव संतुलन को नियंत्रित करता है और मांसपेशियों तथा नसों के कार्य को समर्थन देता है।",
    bodyOd:
        "ପୋଟାସିଆମ୍ ପରିବଳନ ଣିୟନ୍ତ୍ରଣ କରି ମାଂସପେଶୀ ଓ ସ୍ନାୟୁ କାର୍ଯ୍ୟକୁ ସମର୍ଥନ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_fact_b12_signs_256',
    type: ContentType.fact,
    tags: ['deficiency', 'vitamin_b12'],
    title: "B12 Deficiency Affects Nerves",
    body: "Low B12 levels may cause tingling, fatigue, and memory issues.",
    bodyHi:
        "बी12 की कमी सुन्नपन, थकान और याददाश्त की समस्याएँ पैदा कर सकती है।",
    bodyOd: "B12 ଅଭାବରେ ଝିଣ୍ଝିଣି, କ୍ଲାନ୍ତି ଏବଂ ସ୍ମୃତି ସମସ୍ୟା ହୋଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_tip_vitd_sun_257',
    type: ContentType.tip,
    tags: ['deficiency', 'vitamin_d'],
    title: "Use Morning Sunlight for Vitamin D",
    body:
        "10–15 minutes of early sunlight helps your body naturally synthesize vitamin D.",
    bodyHi:
        "सुबह की 10–15 मिनट धूप से शरीर प्राकृतिक रूप से विटामिन D बनाता है।",
    bodyOd:
        "ସକାଳର 10–15 ମିନଟ୍ ଧୂପରେ ରହିଲେ ଶରୀର ସ୍ୱଭାବିକ ଭାବେ ଭିଟାମିନ୍ D ତିଆରି କରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_myth_only_thin_people_258',
    type: ContentType.myth,
    tags: ['deficiency', 'nutrition'],
    title: "Myth: Only Thin People Have Deficiencies",
    body:
        "Even overweight individuals may lack vitamins, minerals, and protein due to poor diet quality.",
    bodyHi:
        "मिथ: केवल पतले लोगों में कमी होती है। खराब आहार गुणवत्ता के कारण मोटे लोगों में भी कमी हो सकती है।",
    bodyOd:
        "ମିଥ୍: କେବଳ ପତଳା ଲୋକଙ୍କରେ ଅଭାବ ଥାଏ। ଖରାପ ଖାଦ୍ୟ ଗୁଣବତ୍ତାରୁ ମୋଟା ଲୋକମାନେ ମଧ୍ୟ ଅଭାବରେ ଥାଇପାରନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'deficiency_advice_iodine_salt_259',
    type: ContentType.advice,
    tags: ['deficiency', 'iodine'],
    title: "Use Iodized Salt Correctly",
    body: "Add iodized salt at the end of cooking to preserve iodine content.",
    bodyHi: "आयोडीन युक्त नमक को पकाने के अंत में डालें ताकि आयोडीन बना रहे।",
    bodyOd: "ଆଯୋଡାଇଜ୍ଡ ଲୁଣକୁ ରାନ୍ଧଣା ଶେଷରେ ଦିଅନ୍ତୁ ଯାହାରୁ ଆଯୋଡିନ୍ ରହିପାରିବ।",
  ),
  WellnessContentModel(
    id: 'deficiency_knowledge_folate_pregnancy_260',
    type: ContentType.knowledge,
    tags: ['deficiency', 'folate'],
    title: "Folate Is Essential in Pregnancy",
    body:
        "Folate prevents neural tube defects and supports healthy fetal development.",
    bodyHi:
        "फोलेट गर्भावस्था में बहुत जरूरी है क्योंकि यह न्यूरल ट्यूब दोष को रोकता है।",
    bodyOd:
        "ଫୋଲେଟ୍ ଗର୍ଭାବସ୍ଥାରେ ଅତ୍ୟାବଶ୍ୟକ, ଏହା ନ୍ୟୁରାଲ୍ ଟ୍ୟୁବ୍ ତ୍ରୁଟିକୁ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'vitamins_fact_a_vision_261',
    type: ContentType.fact,
    tags: ['vitamins', 'eyesight'],
    title: "Vitamin A Protects Vision",
    body:
        "Carrots, pumpkin, and papaya help maintain night vision and eye health.",
    bodyHi: "गाजर, कद्दू और पपीता विटामिन A देकर आँखों की सेहत सुधारते हैं।",
    bodyOd: "ଗାଜର, କଦଳୀ ଏବଂ ପପାୟା ଭିଟାମିନ୍ A ଦେଇ ଚକ୍ଷୁ ସୁସ୍ଥ ରଖନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'vitamins_tip_bcomplex_energy_262',
    type: ContentType.tip,
    tags: ['vitamins', 'energy'],
    title: "B-Complex Boosts Energy",
    body:
        "Whole grains, sprouts, and legumes provide B vitamins that support metabolism.",
    bodyHi:
        "होल ग्रेन्स, स्प्राउट्स और दालें B-कॉम्प्लेक्स देती हैं जो ऊर्जा मेटाबोलिज़्म बढ़ाते हैं।",
    bodyOd:
        "ହୋଲ୍ ଗ୍ରେନ୍, ଅଂକୁରିତ ଦାଳି ଏବଂ ଡାଲି B-ଭିଟାମିନ୍ ଦେଇ ଶକ୍ତି ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'vitamins_myth_vitc_only_citrus_263',
    type: ContentType.myth,
    tags: ['vitamins', 'vitamin_c'],
    title: "Myth: Vitamin C Comes Only from Citrus",
    body:
        "Guava, amla, and capsicum contain more vitamin C than many citrus fruits.",
    bodyHi:
        "मिथ: विटामिन C केवल खट्टे फलों से मिलता है। अमरूद, आँवला और शिमला मिर्च में इसकी मात्रा अधिक होती है।",
    bodyOd:
        "ମିଥ୍: ଭିଟାମିନ୍ C କେବଳ ଖଟା ଫଳରୁ ମିଳେ। ଅମ୍ବା, ଆମଳା ଏବଂ କାପ୍ସିକମ୍‌ରେ ଅଧିକ ଥାଏ।",
  ),
  WellnessContentModel(
    id: 'vitamins_advice_k2_calcium_264',
    type: ContentType.advice,
    tags: ['vitamins', 'bone_health'],
    title: "Vitamin K2 Helps Calcium Use",
    body:
        "K2 directs calcium to bones instead of arteries, improving bone strength.",
    bodyHi:
        "विटामिन K2 कैल्शियम को हड्डियों तक पहुँचाता है, जिससे हड्डियाँ मजबूत होती हैं।",
    bodyOd: "ଭିଟାମିନ୍ K2 କ୍ୟାଲ୍ସିୟମ୍‌କୁ ହାଡ଼ରେ ପହଞ୍ଚାଇ ଅର୍ଟେରିରେ ସଂଚୟକୁ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'vitamins_knowledge_fat_soluble_265',
    type: ContentType.knowledge,
    tags: ['vitamins', 'diet'],
    title: "Fat-Soluble Vitamins Need Fat",
    body: "Vitamins A, D, E, and K absorb better when eaten with healthy fats.",
    bodyHi:
        "A, D, E और K विटामिन अच्छे फैट्स के साथ लेने पर बेहतर अवशोषित होते हैं।",
    bodyOd: "A, D, E ଏବଂ K ଭିଟାମିନ୍ ସ୍ୱସ୍ଥ ଫ୍ୟାଟ୍‌ ସହିତ ଖାଇଲେ ଭଲ ଶୋଷିତ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'protein_fact_muscle_repair_266',
    type: ContentType.fact,
    tags: ['protein', 'recovery'],
    title: "Protein Repairs Muscles",
    body:
        "Adequate protein intake supports muscle recovery after daily activity or exercise.",
    bodyHi: "पर्याप्त प्रोटीन मांसपेशियों की मरम्मत और रिकवरी में मदद करता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପ୍ରୋଟିନ୍ ମାଂସପେଶୀ ପୁନଃଘଟନରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'protein_tip_plant_sources_267',
    type: ContentType.tip,
    tags: ['protein', 'plant_based'],
    title: "Use Diverse Plant Proteins",
    body:
        "Combining lentils, chickpeas, nuts, and seeds improves protein quality.",
    bodyHi:
        "दालें, चना, मेवे और बीज मिलाकर खाने से प्रोटीन की गुणवत्ता बढ़ती है।",
    bodyOd:
        "ଡାଲି, ବୁଟ, ବାଦାମ ଏବଂ ବିଆ ମିଶାଇ ଖାଇଲେ ପ୍ରୋଟିନ୍ ଗୁଣବତ୍ତା ବୃଦ୍ଧି पାଏ।",
  ),
  WellnessContentModel(
    id: 'protein_myth_only_gym_268',
    type: ContentType.myth,
    tags: ['protein', 'diet'],
    title: "Myth: Only Gym-Goers Need Protein",
    body:
        "Everyone needs adequate protein for hormones, immunity, and cell repair.",
    bodyHi:
        "मिथ: प्रोटीन सिर्फ जिम वालों के लिए है। हर किसी को प्रोटीन की आवश्यकता होती है।",
    bodyOd:
        "ମିଥ୍: ପ୍ରୋଟିନ୍ କେବଳ ଜିମ୍ କରୁଥିବାଙ୍କ ପାଇଁ। ସମସ୍ତଙ୍କୁ ପ୍ରୋଟିନ୍ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'protein_advice_even_distribution_269',
    type: ContentType.advice,
    tags: ['protein', 'meal_planning'],
    title: "Distribute Protein Across Meals",
    body:
        "Spreading protein through the day improves absorption and muscle repair.",
    bodyHi:
        "दिन भर में प्रोटीन को बाँटकर खाने से इसका अवशोषण और फायदा बढ़ता है।",
    bodyOd: "ଦିନରେ ସମାନ ପ୍ରମାଣରେ ପ୍ରୋଟିନ୍ ନେଲେ ଶୋଷଣ ଓ ରିପେୟର ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'protein_knowledge_aminos_270',
    type: ContentType.knowledge,
    tags: ['protein', 'amino_acids'],
    title: "Amino Acids Build the Body",
    body:
        "Proteins break down into amino acids that support growth, repair, and immunity.",
    bodyHi:
        "प्रोटीन अमीनो एसिड में टूटकर शरीर की वृद्धि, मरम्मत और प्रतिरक्षा में सहायक होते हैं।",
    bodyOd:
        "ପ୍ରୋଟିନ୍ ଅମିନୋ ଆମ୍ଲରେ ବିଭକ୍ତ ହୋଇ ବୃଦ୍ଧି, ମରାମତ ଓ ରୋଗପ୍ରତିରୋଧକତାକୁ ସମର୍ଥନ କରେ।",
  ),

  WellnessContentModel(
    id: 'fiber_fact_digestive_health_271',
    type: ContentType.fact,
    tags: ['fiber', 'digestion'],
    title: "Fiber Improves Digestion",
    body: "Fiber adds bulk to stool and supports smooth bowel movement.",
    bodyHi: "फाइबर मल में बल्क बढ़ाकर पाचन और साफ मल त्याग में मदद करता है।",
    bodyOd: "ଫାଇବର୍ ମଳକୁ ଦୃଢ଼ କରି ପଚନ ଏବଂ ସଫା ପାଖାନ୍ତରେ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'fiber_tip_soluble_control_272',
    type: ContentType.tip,
    tags: ['fiber', 'blood_sugar'],
    title: "Soluble Fiber Helps Sugar Control",
    body:
        "Oats, chia seeds, and fruits slow glucose absorption for steady sugars.",
    bodyHi:
        "ओट्स, चिया सीड्स और फल घुलनशील फाइबर देते हैं जो ब्लड शुगर नियंत्रित रखते हैं।",
    bodyOd: "ଓଟ୍ସ୍, ଚିଆ ବିଆ ଏବଂ ଫଳ ଘୁଲନଶୀଳ ଫାଇବର୍ ଦେଇ ଗ୍ଲୁକୋଜ୍ ଶୋଷଣ କମାନ୍ତି।",
  ),
  WellnessContentModel(
    id: 'fiber_myth_only_salad_273',
    type: ContentType.myth,
    tags: ['fiber', 'foods'],
    title: "Myth: Fiber Comes Only from Salads",
    body:
        "Whole grains, sprouts, fruits, and nuts are excellent fiber sources.",
    bodyHi:
        "मिथ: फाइबर सिर्फ सलाद से मिलता है। अनाज, स्प्राउट्स, फल और मेवे भी अच्छे स्रोत हैं।",
    bodyOd:
        "ମିଥ୍: ଫାଇବର୍ କେବଳ ସାଲାଡରେ ଥାଏ। ଅନାଜ, ଅଂକୁରିତ ଦାଳି, ଫଳ ଓ ବାଦାମ ଉତ୍କୃଷ୍ଟ ସ୍ରୋତ।",
  ),
  WellnessContentModel(
    id: 'fiber_advice_increase_gradually_274',
    type: ContentType.advice,
    tags: ['fiber', 'digestion'],
    title: "Increase Fiber Slowly",
    body: "Gradual increase prevents bloating and allows your gut to adjust.",
    bodyHi: "फाइबर धीरे-धीरे बढ़ाएँ ताकि गैस और असहजता न हो।",
    bodyOd: "ଫାଇବର୍ ଧୀରେ ଧୀରେ ବଢ଼ାନ୍ତୁ, ଏଥିରେ ଗ୍ୟାସ୍ ଏବଂ ଅସୁବିଧା ହୁଏ ନାହିଁ।",
  ),
  WellnessContentModel(
    id: 'fiber_knowledge_prebiotics_275',
    type: ContentType.knowledge,
    tags: ['fiber', 'gut_health'],
    title: "Prebiotic Fiber Feeds Good Bacteria",
    body:
        "Onions, garlic, and bananas nourish gut microbes and improve digestion.",
    bodyHi:
        "प्याज़, लहसुन और केले प्रीबायोटिक फाइबर देकर आंतों की सेहत सुधारते हैं।",
    bodyOd:
        "ପିଆଜ, ରସୁଣ ଏବଂ କଦଳୀ ପ୍ରିବାୟୋଟିକ୍ ଫାଇବର୍ ଦେଇ ଆନ୍ତ ଜୀବାଣୁକୁ ପୋଷଣ କରେ।",
  ),

  WellnessContentModel(
    id: 'hydration_fact_kidney_276',
    type: ContentType.fact,
    tags: ['hydration', 'kidney'],
    title: "Water Supports Kidney Function",
    body: "Proper hydration helps flush waste and prevents stone formation.",
    bodyHi:
        "पर्याप्त पानी किडनी को कचरा बाहर निकालने और पथरी रोकने में मदद करता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି କିଡନିକୁ ବର୍ଜ୍ୟ ଜିନିଷ ଫ୍ଲଷ୍ କରି ପଥରି ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_sip_day_277',
    type: ContentType.tip,
    tags: ['hydration', 'daily_habits'],
    title: "Sip Water Through the Day",
    body:
        "Small, frequent sips keep you better hydrated than large, infrequent gulps.",
    bodyHi: "दिन भर छोटे-छोटे घूंट लेने से शरीर बेहतर हाइड्रेट रहता है।",
    bodyOd: "ଦିନଭର ଥୋଡ଼ା ଥୋଡ଼ା ପାଣି ପିଲେ ଶରୀର ଭଲ ହାଇଡ୍ରେଟ୍ ରହେ।",
  ),
  WellnessContentModel(
    id: 'hydration_myth_only_thirst_278',
    type: ContentType.myth,
    tags: ['hydration', 'awareness'],
    title: "Myth: Drink Water Only When Thirsty",
    body: "Thirst is a late signal; mild dehydration begins earlier.",
    bodyHi:
        "मिथ: प्यास लगने पर ही पानी चाहिए। प्यास लगना देरी से मिलने वाला संकेत है।",
    bodyOd: "ମିଥ୍: ପିଆସ ଲାଗିଲେ ମାତ୍ର ପାଣି ଦରକାର। ପିଆସ ଦେରିର ସଙ୍କେତ।",
  ),
  WellnessContentModel(
    id: 'hydration_advice_electrolytes_279',
    type: ContentType.advice,
    tags: ['hydration', 'electrolytes'],
    title: "Use Electrolytes in Heat",
    body:
        "During hot weather or workouts, add electrolytes to replenish lost salts.",
    bodyHi:
        "गरमी या वर्कआउट के दौरान इलेक्ट्रोलाइट्स लेना जरूरी नमक की भरपाई करता है।",
    bodyOd:
        "ଗରମ ହେଲେ କିମ୍ବା ୱର୍କଆଉଟରେ ଇଲେକ୍ଟ୍ରୋଲାଇଟ୍ ନେଲେ ନଷ୍ଟ ହୋଇଥିବା ଲୁଣ ପୂରଣ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'hydration_knowledge_food_water_280',
    type: ContentType.knowledge,
    tags: ['hydration', 'foods'],
    title: "Foods Also Hydrate",
    body:
        "Cucumber, watermelon, and oranges provide water along with vitamins.",
    bodyHi: "खीरा, तरबूज और संतरा पानी के साथ विटामिन भी प्रदान करते हैं।",
    bodyOd: "କାକୁଡ଼ି, ତରଭୁଜ ଏବଂ କମଳା ପାଣି ସହିତ ଭିଟାମିନ୍ ଦେଇଥାଏ।",
  ),

  // ... continuing items up to 300 ...
  WellnessContentModel(
    id: 'minerals_fact_copper_energy_281',
    type: ContentType.fact,
    tags: ['minerals', 'energy'],
    title: "Copper Helps Energy Production",
    body: "Copper is required for converting food into usable energy.",
    bodyHi: "कॉपर भोजन को ऊर्जा में बदलने में मदद करता है।",
    bodyOd: "ତାମା ଖାଦ୍ୟକୁ ଶକ୍ତିରେ ପରିଣତ କରିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'minerals_tip_calcium_split_282',
    type: ContentType.tip,
    tags: ['minerals', 'bone_health'],
    title: "Split Calcium Intake",
    body: "Smaller, divided doses of calcium improve absorption.",
    bodyHi: "कैल्शियम को छोटे-छोटे हिस्सों में लेने से अवशोषण बेहतर होता है।",
    bodyOd: "କ୍ୟାଲ୍ସିୟମ୍ କୁ ଛୋଟ ମାତ୍ରାରେ ବାଣ୍ଟି ନେଲେ ଶୋଷଣ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'deficiency_fact_protein_loss_283',
    type: ContentType.fact,
    tags: ['deficiency', 'protein'],
    title: "Protein Deficiency Weakens Muscles",
    body: "Low protein intake leads to muscle loss and reduced immunity.",
    bodyHi:
        "प्रोटीन की कमी मांसपेशियों को कमजोर करती है और प्रतिरक्षा घटाती है।",
    bodyOd: "ପ୍ରୋଟିନ୍ ଅଭାବ ମାଂସପେଶୀ କମାଇ ରୋଗପ୍ରତିରୋଧକତା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'vitamins_advice_multivitamin_284',
    type: ContentType.advice,
    tags: ['vitamins', 'supplements'],
    title: "Use Supplements Only When Needed",
    body: "Multivitamins help only when your diet lacks essential nutrients.",
    bodyHi:
        "मल्टीविटामिन तभी फायदेमंद हैं जब आहार में आवश्यक पोषक तत्व कम हों।",
    bodyOd: "ଡାଏଟରେ ପୋଷକ ଅଭାବ ଥିଲେ ମାତ୍ର ମଲ୍ଟିଭିଟାମିନ୍ ଉପକାରୀ।",
  ),
  WellnessContentModel(
    id: 'protein_myth_expensive_285',
    type: ContentType.myth,
    tags: ['protein', 'budget'],
    title: "Myth: Protein-Rich Diet Is Expensive",
    body:
        "Affordable foods like eggs, dal, peanuts, and curd are excellent protein sources.",
    bodyHi:
        "मिथ: प्रोटीन आहार महंगा होता है। अंडा, दाल, मूंगफली और दही अच्छे और सस्ते स्रोत हैं।",
    bodyOd:
        "ମିଥ୍: ପ୍ରୋଟିନ୍ ଡାଏଟ୍ ଦାମି। ଅଣ୍ଡା, ଡାଲି, ବାଦାମ ଓ ଦହି ସସ୍ତା ଓ ଭଲ ସ୍ରୋତ।",
  ),
  WellnessContentModel(
    id: 'fiber_fact_heart_286',
    type: ContentType.fact,
    tags: ['fiber', 'heart_health'],
    title: "Fiber Protects Heart Health",
    body: "High-fiber diets lower LDL cholesterol and improve blood pressure.",
    bodyHi: "फाइबर युक्त आहार LDL कोलेस्ट्रॉल कम करता है और BP सुधारता है।",
    bodyOd: "ଫାଇବର୍ ଭରା ଡାଏଟ୍ LDL କଲେଷ୍ଟେରଲ କମାଇ BP ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_track_287',
    type: ContentType.tip,
    tags: ['hydration', 'tracking'],
    title: "Track Your Daily Water",
    body: "Use a bottle or app reminder to build consistent hydration habits.",
    bodyHi:
        "पानी की मात्रा ट्रैक करने के लिए बोतल या ऐप रिमाइंडर का उपयोग करें।",
    bodyOd: "ପାଣି ଦିନକର ମାପ ନିୟମିତ କରିବା ପାଇଁ ବୋତଲ କିମ୍ବା ଆପ୍‌ ବ୍ୟବହାର କରନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'minerals_knowledge_iron_heme_288',
    type: ContentType.knowledge,
    tags: ['minerals', 'absorption'],
    title: "Heme Iron Absorbs Better",
    body:
        "Animal sources provide heme iron, which the body absorbs more efficiently.",
    bodyHi: "नॉन-वेज स्रोत हीम आयरन देते हैं, जिसका अवशोषण अधिक होता है।",
    bodyOd: "ପଶୁ ଉତ୍ସରେ ଥିବା ହିମ୍ ଲୋହ ଦେହ ଭଲ ଶୋଷିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_tip_rich_breakfast_289',
    type: ContentType.tip,
    tags: ['deficiency', 'meal_planning'],
    title: "Start Day with Nutrient-Rich Breakfast",
    body: "A balanced breakfast prevents nutrient gaps and boosts energy.",
    bodyHi: "संतुलित नाश्ता पोषक तत्वों की कमी रोककर ऊर्जा बढ़ाता है।",
    bodyOd: "ସନ୍ତୁଳିତ ନାସ୍ତା ପୋଷକ ଅଭାବ ରୋକି ଶକ୍ତି ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'vitamins_fact_e_antioxidant_290',
    type: ContentType.fact,
    tags: ['vitamins', 'antioxidants'],
    title: "Vitamin E Protects Cells",
    body: "It acts as an antioxidant, reducing cell damage from free radicals.",
    bodyHi:
        "विटामिन E एंटीऑक्सिडेंट की तरह काम कर कोशिकाओं को नुकसान से बचाता है।",
    bodyOd: "ଭିଟାମିନ୍ E ଏଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ୍ ଭାବେ କୋଷକୁ କ୍ଷତିରୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'protein_advice_bedtime_291',
    type: ContentType.advice,
    tags: ['protein', 'sleep'],
    title: "Add Light Protein at Night",
    body: "A low-fat protein snack supports overnight muscle repair.",
    bodyHi:
        "रात में हल्का प्रोटीन लेने से मांसपेशियों की रिकवरी बेहतर होती है।",
    bodyOd: "ରାତିରେ ହଲକା ପ୍ରୋଟିନ୍ ନେଲେ ମାଂସପେଶୀ ରିପେୟର ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'fiber_myth_weightloss_only_292',
    type: ContentType.myth,
    tags: ['fiber', 'weight_loss'],
    title: "Myth: Fiber Is Only for Weight Loss",
    body: "Fiber also benefits heart, gut, and blood sugar regulation.",
    bodyHi:
        "मिथ: फाइबर सिर्फ वजन घटाने के लिए है। यह दिल, आंत और शुगर नियंत्रण के लिए भी जरूरी है।",
    bodyOd:
        "ମିଥ୍: ଫାଇବର୍ କେବଳ ବଜନ କମିବା ପାଇଁ। ଏହା ହୃଦୟ, ଆନ୍ତ, ସୁଗର୍ ନିୟନ୍ତ୍ରଣ ପାଇଁ ମଧ୍ୟ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_brain_293',
    type: ContentType.fact,
    tags: ['hydration', 'brain'],
    title: "Hydration Boosts Brain Function",
    body: "Even mild dehydration reduces focus and increases fatigue.",
    bodyHi: "हल्का डिहाइड्रेशन भी ध्यान और ऊर्जा को प्रभावित करता है।",
    bodyOd: "ସାନା ଡିହାଇଡ୍ରେସନ୍‌ ମଧ୍ୟ ଧ୍ୟାନ ଏବଂ ଶକ୍ତି କମାଇଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'minerals_tip_iron_cast_294',
    type: ContentType.tip,
    tags: ['minerals', 'cooking'],
    title: "Cook in Iron Vessels",
    body: "Iron pans naturally increase the iron content in food.",
    bodyHi: "लोहे के बर्तन में खाना पकाने से भोजन में आयरन बढ़ता है।",
    bodyOd: "ଲୋହାର ପାତ୍ରରେ ରାନ୍ଧିଲେ ଖାଦ୍ୟରେ ଲୋହ ବଢ଼େ।",
  ),
  WellnessContentModel(
    id: 'deficiency_fact_skin_295',
    type: ContentType.fact,
    tags: ['deficiency', 'skin'],
    title: "Deficiencies Affect Skin Health",
    body: "Low vitamins and minerals can lead to dryness, acne, or dullness.",
    bodyHi:
        "विटामिन और खनिजों की कमी से त्वचा में रूखापन, मुंहासे और चमक की कमी हो सकती है।",
    bodyOd: "ଭିଟାମିନ୍ ଓ ଖନିଜ ଅଭାବରେ ଚର୍ମ ଶୁଷ୍କତା, ପିପୁଣି ଓ ନିର୍ମଳତା ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'vitamins_tip_kids_growth_296',
    type: ContentType.tip,
    tags: ['vitamins', 'children'],
    title: "Vitamins Support Children's Growth",
    body: "Colorful fruits and vegetables help meet daily nutrient needs.",
    bodyHi:
        "रंग-बिरंगे फल और सब्जियाँ बच्चों की पोषण ज़रूरतों को पूरा करती हैं।",
    bodyOd: "ରଙ୍ଗିନ ଫଳ ଓ ସବ୍ଜି ବାଳକମାନଙ୍କର ପୋଷକ ଆବଶ୍ୟକତା ପୂରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'protein_fact_hair_297',
    type: ContentType.fact,
    tags: ['protein', 'hair'],
    title: "Protein Supports Healthy Hair",
    body:
        "Hair is made of keratin, a protein that needs adequate dietary intake.",
    bodyHi:
        "बाल केराटिन से बने होते हैं, जो एक प्रोटीन है और आहार में इसकी जरूरत होती है।",
    bodyOd: "ଚୁଳ କେରାଟିନ୍ ନାମକ ପ୍ରୋଟିନ୍‌ରୁ ନିର୍ମିତ, ତେଣୁ ପ୍ରୋଟିନ୍ ଖାଦ୍ୟ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'fiber_advice_with_water_298',
    type: ContentType.advice,
    tags: ['fiber', 'hydration'],
    title: "Combine Fiber with Water",
    body: "Fiber works best when you stay well-hydrated.",
    bodyHi: "फाइबर के साथ पर्याप्त पानी पीने से इसका असर बेहतर होता है।",
    bodyOd: "ଫାଇବର୍ ସହିତ ପର୍ଯ୍ୟାପ୍ତ ପାଣି ନେଲେ ପ୍ରଭାବ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'hydration_knowledge_urine_color_299',
    type: ContentType.knowledge,
    tags: ['hydration', 'awareness'],
    title: "Urine Color Shows Hydration",
    body:
        "Light yellow urine indicates healthy hydration, while dark yellow shows dehydration.",
    bodyHi:
        "हल्का पीला मूत्र अच्छी हाइड्रेशन का संकेत है, गहरा पीला डिहाइड्रेशन का।",
    bodyOd:
        "ହାଲୁକା ହଳଦିଆ ପିଶାବ ଭଲ ହାଇଡ୍ରେସନ୍‌, ଗাঢ଼ା ହଳଦିଆ ଡିହାଇଡ୍ରେସନ୍‌ ସୂଚନା।",
  ),
  WellnessContentModel(
    id: 'minerals_advice_multimineral_300',
    type: ContentType.advice,
    tags: ['minerals', 'supplements'],
    title: "Don’t Self-Medicate Minerals",
    body:
        "Excess minerals like iron or zinc can cause toxicity; take supplements only with guidance.",
    bodyHi:
        "आयरन या जिंक जैसे खनिजों की अधिकता हानिकारक हो सकती है, सप्लीमेंट केवल सलाह से लें।",
    bodyOd:
        "ଲୋହ କିମ୍ବା ଜିଙ୍କ ଅଧିକ ହେଲେ ହାନିକାରକ, ସପ୍ଲିମେଣ୍ଟ୍ କେବଳ ଦେଶନାରେ ନିଅନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'minerals_fact_copper_301',
    type: ContentType.fact,
    tags: ['minerals', 'metabolism'],
    title: "Copper Supports Enzyme Function",
    body:
        "Copper helps enzymes involved in energy production and iron metabolism.",
    bodyHi:
        "कॉपर ऊर्जा उत्पादन और आयरन मेटाबॉलिज़्म से जुड़े एंजाइमों को सपोर्ट करता है।",
    bodyOd:
        "ତାମା ଶକ୍ତି ଉତ୍ପାଦନ ଏବଂ ଲୋହ ମେଟାବୋଲିଜମ୍ ସହିତ ସମ୍ବନ୍ଧିତ ଏନଜାଇମ୍‌ଗୁଡ଼ିକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_tip_multi_302',
    type: ContentType.tip,
    tags: ['deficiency', 'diet'],
    title: "Fill Gaps with Variety",
    body:
        "Eating a wide variety of foods helps prevent multiple micronutrient deficiencies.",
    bodyHi:
        "विविध आहार लेने से शरीर में कई माइक्रोन्यूट्रिएंट की कमी को रोका जा सकता है।",
    bodyOd:
        "ବିଭିନ୍ନ ପ୍ରକାରର ଖାଦ୍ୟ ଖାଇଲେ ଅନେକ ମାଇକ୍ରୋନ୍ୟୁଟ୍ରିଏଣ୍ଟ ଅଭାବ ରୋକାଯାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'vitamins_myth_megadose_303',
    type: ContentType.myth,
    tags: ['vitamins', 'supplements'],
    title: "Myth: More Vitamins Are Always Better",
    body:
        "Megadoses of vitamins can cause toxicity and should be avoided unless prescribed.",
    bodyHi:
        "मिथ: ज्यादा विटामिन हमेशा फायदेमंद होते हैं। अत्यधिक मात्रा नुकसान पहुँचा सकती है।",
    bodyOd: "ମିଥ୍: ଅଧିକ ଭିଟାମିନ ସବୁବେଳେ ଭଲ। ଅଧିକ ମାତ୍ରା ବିଷାକ୍ତ ହୋଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'protein_fact_skin_304',
    type: ContentType.fact,
    tags: ['protein', 'skin_health'],
    title: "Protein Builds Skin Structure",
    body: "Collagen, made from protein, supports skin elasticity and repair.",
    bodyHi: "प्रोटीन से बना कोलेजन त्वचा की लोच और मरम्मत में महत्वपूर्ण है।",
    bodyOd: "ପ୍ରୋଟିନ୍‌ରୁ ତିଆରି କଲାଜେନ୍ ଚର୍ମର ଲଚିଳାପଣ ଏବଂ ମରାମତିକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'fiber_tip_sloweat_305',
    type: ContentType.tip,
    tags: ['fiber', 'eating_habits'],
    title: "Slow Eating Enhances Fiber Benefits",
    body:
        "Eating slowly improves digestion and allows fiber to work more effectively.",
    bodyHi: "धीरे खाने से पाचन बेहतर होता है और फाइबर का असर बढ़ता है।",
    bodyOd: "ଧୀରେ ଖାଇବା ଜୀର୍ଣ୍ଣକୁ ସୁଧାରେ ଏବଂ ଫାଇବରର ଲାଭ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'hydration_advice_elderly_306',
    type: ContentType.advice,
    tags: ['hydration', 'elderly'],
    title: "Elderly Need Frequent Hydration",
    body:
        "Older adults may feel less thirst, so scheduled drinking is important.",
    bodyHi: "बुजुर्गों में प्यास कम लगती है, इसलिए समय पर पानी पीना जरूरी है।",
    bodyOd: "ବୟସ୍କମାନେ କମ୍ ପିଆସ ଅନୁଭବ କରନ୍ତି, ତେଣୁ ସମୟମତେ ପାଣି ପିଇବା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'minerals_knowledge_trace_307',
    type: ContentType.knowledge,
    tags: ['minerals', 'trace_elements'],
    title: "Trace Minerals Matter",
    body:
        "Elements like zinc, copper, and iodine are required in tiny amounts but vital for body functions.",
    bodyHi:
        "जिंक, कॉपर और आयोडीन जैसे ट्रेस मिनरल्स कम मात्रा में जरूरी लेकिन बेहद महत्वपूर्ण होते हैं।",
    bodyOd:
        "ଜିଙ୍କ୍, ତାମା ଏବଂ ଆୟୋଡିନ୍ ପରି ଟ୍ରେସ୍ ଖଣିଜ ଅଲ୍ପ ମାତ୍ରାରେ ଦରକାର ହେଲେ ମଧ୍ୟ ଅତ୍ୟାବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'deficiency_fact_folate_308',
    type: ContentType.fact,
    tags: ['deficiency', 'folate'],
    title: "Folate Deficiency Affects Red Blood Cells",
    body: "Low folate levels can cause megaloblastic anemia and fatigue.",
    bodyHi: "फोलेट की कमी मेगालोब्लास्टिक एनीमिया और थकान पैदा कर सकती है।",
    bodyOd: "ଫୋଲେଟ୍ ଅଭାବ ମେଗାଲୋବ୍ଲାଷ୍ଟିକ୍ ଅନିମିଆ ଏବଂ କ୍ଲାନ୍ତି ସୃଷ୍ଟି କରେ।",
  ),
  WellnessContentModel(
    id: 'vitamins_tip_d3_309',
    type: ContentType.tip,
    tags: ['vitamins', 'sunlight'],
    title: "Morning Sun Helps Vitamin D",
    body:
        "Short exposure to early morning sunlight boosts your body's natural vitamin D production.",
    bodyHi:
        "सुबह की धूप में थोड़ी देर रहना शरीर में विटामिन D बनने में मदद करता है।",
    bodyOd: "ସକାଳ ବେଳି ଧୁପ୍‌ରେ କିଛି ସମୟ ରହିବାରେ ଭିଟାମିନ୍ D ଉତ୍ପାଦନ ବଢ଼େ।",
  ),
  WellnessContentModel(
    id: 'protein_myth_only_gym_310',
    type: ContentType.myth,
    tags: ['protein', 'general'],
    title: "Myth: Only Gym-Goers Need Protein",
    body:
        "Protein is essential for everyone as it supports hormones, immunity, and daily repair.",
    bodyHi:
        "मिथ: प्रोटीन सिर्फ जिम जाने वालों के लिए है। यह हर किसी के शरीर की मरम्मत और इम्युनिटी के लिए जरूरी है।",
    bodyOd: "ମିଥ୍: ପ୍ରୋଟିନ୍ କେବଳ ଜିମ୍ କରୁଥିବାମାନେ ଦରକାର। ଏହା ସବୁଙ୍କୁ ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'fiber_fact_chol_311',
    type: ContentType.fact,
    tags: ['fiber', 'cholesterol'],
    title: "Fiber Helps Lower Cholesterol",
    body:
        "Soluble fiber binds cholesterol in the gut and reduces its absorption.",
    bodyHi: "घुलनशील फाइबर कोलेस्ट्रॉल को बाँधकर उसके अवशोषण को कम करता है।",
    bodyOd: "ଦ୍ରାବ୍ୟ ଫାଇବର କଲେଷ୍ଟେରଲକୁ ବାନ୍ଧି ତାହାର ଶୋଷଣ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_cues_312',
    type: ContentType.tip,
    tags: ['hydration', 'lifestyle'],
    title: "Watch Early Signs of Dehydration",
    body:
        "Dry mouth, headache, and dark urine indicate your body needs more water.",
    bodyHi:
        "सूखा मुँह, सिरदर्द और गहरा पेशाब डिहाइड्रेशन के शुरुआती लक्षण हैं।",
    bodyOd: "ମୁଖ ଶୁଖିବା, ମୁଣ୍ଡବେଦନା ଏବଂ ଗାଢ଼ ପିଶାବ ଜଳାଭାବର ଚିହ୍ନ।",
  ),
  WellnessContentModel(
    id: 'minerals_advice_iodine_313',
    type: ContentType.advice,
    tags: ['minerals', 'thyroid_health'],
    title: "Use Iodized Salt Regularly",
    body: "Iodine supports thyroid hormone production and prevents goiter.",
    bodyHi:
        "आयोडीन थायरॉयड हार्मोन बनने में मदद करता है और गण्डमाला से बचाता है।",
    bodyOd: "ଆୟୋଡିନ୍ ଥାଇରଏଡ୍ ହରମୋନ ସୃଷ୍ଟିକୁ ସହାଯ୍ୟ କରେ ଏବଂ ଗଳଗଣ୍ଠୁ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_knowledge_multi_314',
    type: ContentType.knowledge,
    tags: ['deficiency', 'poor_diet'],
    title: "Long-Term Poor Diet Causes Multiple Deficiencies",
    body:
        "Low-quality diets often lead to simultaneous gaps in iron, calcium, folate, and B vitamins.",
    bodyHi:
        "लंबे समय तक खराब आहार से आयरन, कैल्शियम, फोलेट और B-विटामिन जैसे कई पोषक तत्वों की कमी होती है।",
    bodyOd:
        "ଦୀର୍ଘ ସମୟ ଖରାପ ଆହାର ଫଳରେ ଲୋହ, କ୍ୟାଲସିୟମ୍, ଫୋଲେଟ୍ ଏବଂ B-ଭିଟାମିନ୍ ଅଭାବ ହୋଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'vitamins_fact_K_315',
    type: ContentType.fact,
    tags: ['vitamins', 'blood_clotting'],
    title: "Vitamin K Helps Clot Blood",
    body: "It supports proper wound healing and reduces excess bleeding risk.",
    bodyHi:
        "विटामिन K घाव भरने और अत्यधिक रक्तस्राव रोकने में महत्वपूर्ण भूमिका निभाता है।",
    bodyOd: "ଭିଟାମିନ୍ K ରକ୍ତ ଜମାଯିବାକୁ ସହାଯ୍ୟ କରେ ଏବଂ ଅତ୍ୟଧିକ ରକ୍ତସ୍ରାବ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'protein_tip_breakfast_316',
    type: ContentType.tip,
    tags: ['protein', 'meal_planning'],
    title: "Add Protein to Breakfast",
    body:
        "A protein-rich breakfast stabilizes energy and reduces mid-morning cravings.",
    bodyHi:
        "प्रोटीन से भरपूर नाश्ता ऊर्जा बनाए रखता है और बीच-बीच में भूख कम करता है।",
    bodyOd: "ପ୍ରୋଟିନ୍-ଧନ୍ୟ ଜଳଖିଆ ଶକ୍ତି ସ୍ଥିର ରଖେ ଏବଂ ମଧ୍ୟାହ୍ନ ପୂର୍ବ ଭୋକ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'fiber_myth_only_salad_317',
    type: ContentType.myth,
    tags: ['fiber', 'diet'],
    title: "Myth: Fiber Comes Only from Salads",
    body:
        "Whole grains, pulses, fruits, nuts, and seeds are excellent fiber sources.",
    bodyHi:
        "मिथ: फाइबर सिर्फ सलाद से मिलता है। साबुत अनाज, दालें और फल भी अच्छे स्रोत हैं।",
    bodyOd:
        "ମିଥ୍: ଫାଇବର କେବଳ ସାଲାଡ୍‌ରୁ ମିଳେ। ସମସ୍ତ ଧାନ୍ୟ, ଡାଲି, ଫଳ ଏବଂ ବିଆ ମଧ୍ୟ ଉତ୍କୃଷ୍ଟ ଉତ୍ସ।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_temp_318',
    type: ContentType.fact,
    tags: ['hydration', 'temperature'],
    title: "Body Needs More Water in Heat",
    body:
        "Hot weather increases sweat loss, making hydration even more important.",
    bodyHi: "गर्मी में पसीना अधिक निकलता है, इसलिए पानी की जरूरत भी बढ़ती है।",
    bodyOd: "ଗରମ ହୃତାପରେ ଘାମ ବେଶି ହୁଏ, ସେଥି ପାଇଁ ପାଣିର ଆବଶ୍ୟକତା ଅଧିକ।",
  ),
  WellnessContentModel(
    id: 'minerals_tip_combo_319',
    type: ContentType.tip,
    tags: ['minerals', 'absorption'],
    title: "Pair Minerals Smartly",
    body:
        "Vitamin C enhances iron absorption, while calcium can reduce iron absorption when taken together.",
    bodyHi: "विटामिन C आयरन अवशोषण बढ़ाता है, जबकि कैल्शियम इसे कम कर सकता है।",
    bodyOd: "ଭିଟାମିନ୍ C ଲୋହ ଶୋଷଣ ବଢ଼ାଏ, କ୍ୟାଲସିୟମ୍ ଏହାକୁ କମାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'deficiency_advice_checkups_320',
    type: ContentType.advice,
    tags: ['deficiency', 'screening'],
    title: "Annual Nutrient Screening Helps",
    body:
        "Checking iron, B12, D3, and calcium levels yearly helps detect deficiencies early.",
    bodyHi:
        "आयरन, B12, D3 और कैल्शियम की सालाना जांच से कमी जल्दी पकड़ में आती है।",
    bodyOd:
        "ଲୋହ, B12, D3 ଏବଂ କ୍ୟାଲସିୟମ୍‌ର ବାର୍ଷିକ ପରୀକ୍ଷା ଅଭାବକୁ ଶୀଘ୍ର ଚିହ୍ନଟ କରେ।",
  ),

  // Continue in same style…
  WellnessContentModel(
    id: 'vitamins_advice_balance_321',
    type: ContentType.advice,
    tags: ['vitamins', 'balanced_diet'],
    title: "Rely on Food Before Supplements",
    body:
        "Natural foods provide vitamins in their most bioavailable and balanced form.",
    bodyHi: "प्राकृतिक भोजन विटामिन का सबसे प्रभावी और संतुलित रूप देता है।",
    bodyOd:
        "ପ୍ରାକୃତିକ ଖାଦ୍ୟରୁ ଭିଟାମିନ୍ ସବୁଠୁ ବେଶି ଫଳଦାୟକ ଏବଂ ସନ୍ତୁଳିତ ରୂପରେ ମିଳେ।",
  ),

  WellnessContentModel(
    id: 'protein_fact_muscleloss_322',
    type: ContentType.fact,
    tags: ['protein', 'aging'],
    title: "Low Protein Speeds Muscle Loss",
    body:
        "Older adults need more protein to prevent age-related muscle decline.",
    bodyHi: "कम प्रोटीन लेने से उम्र के साथ मांसपेशियाँ जल्दी कमजोर होती हैं।",
    bodyOd: "କମ୍ ପ୍ରୋଟିନ୍ ଖାଇଲେ ବୟସ୍ ସହିତ ପେଶୀ ଦୁର୍ବଳତା ଶୀଘ୍ର ବଢ଼େ।",
  ),

  WellnessContentModel(
    id: 'fiber_knowledge_gutbugs_323',
    type: ContentType.knowledge,
    tags: ['fiber', 'gut_health'],
    title: "Fiber Feeds Good Gut Bacteria",
    body:
        "Prebiotic fibers help maintain a healthy microbiome that supports digestion and immunity.",
    bodyHi: "प्रीबायोटिक फाइबर आंतों के अच्छे बैक्टीरिया को पोषण देता है।",
    bodyOd: "ପ୍ରିବାଓଟିକ୍ ଫାଇବର ଆନ୍ତର ସତ୍କାରୀ ବ୍ୟାକ୍ଟେରିଆକୁ ପୋଷଣ ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_tip_startday_324',
    type: ContentType.tip,
    tags: ['hydration', 'morning'],
    title: "Start Your Day with Water",
    body:
        "Drinking a glass of water in the morning helps kick-start digestion and metabolism.",
    bodyHi: "सुबह पानी पीने से पाचन और मेटाबॉलिज्म सक्रिय होते हैं।",
    bodyOd: "ସକାଳେ ପାଣି ପିଇବାରେ ପାଚନ ଏବଂ ମେଟାବୋଲିଜମ୍ ସକ୍ରିୟ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'minerals_myth_only_salt_325',
    type: ContentType.myth,
    tags: ['minerals', 'sodium'],
    title: "Myth: Sodium Comes Only from Salt",
    body: "Packaged snacks, bread, and sauces also contain high sodium.",
    bodyHi:
        "मिथ: सोडियम सिर्फ नमक से मिलता है। पैक्ड स्नैक्स और सॉस में भी बहुत सोडियम होता है।",
    bodyOd:
        "ମିଥ୍: ସୋଡିୟମ୍ କେବଳ ଲୁଣରୁ ମିଳେ। ପ୍ୟାକେଜ୍ ନସ୍ତା ଏବଂ ସସ୍‌ରେ ମଧ୍ୟ ବହୁତ ସୋଡିୟମ୍ ରହିଥାଏ।",
  ),

  WellnessContentModel(
    id: 'deficiency_tip_menstrual_326',
    type: ContentType.tip,
    tags: ['deficiency', 'women_health'],
    title: "Monitor Iron During Heavy Periods",
    body:
        "Women with heavy flow are at higher risk of iron deficiency and should check levels regularly.",
    bodyHi:
        "अधिक मासिक धर्म वाली महिलाओं में आयरन की कमी का खतरा ज्यादा होता है।",
    bodyOd: "ଅଧିକ ରଜସ୍ରାବ ଥିବା ମହିଳାମାନେ ଲୋହ ଅଭାବର ଅଧିକ ଜୋଖିରେ ଅଛନ୍ତି।",
  ),

  WellnessContentModel(
    id: 'vitamins_fact_Bcomplex_327',
    type: ContentType.fact,
    tags: ['vitamins', 'energy'],
    title: "B-Complex Helps Energy Production",
    body: "B vitamins assist enzymes that convert food into usable energy.",
    bodyHi:
        "B-कॉम्प्लेक्स आहार को ऊर्जा में बदलने की प्रक्रिया में मदद करता है।",
    bodyOd: "B-କମ୍ପ୍ଲେକ୍ସ ଖାଦ୍ୟକୁ ଶକ୍ତିରେ ପରିଣତ କରିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_advice_snacks_328',
    type: ContentType.advice,
    tags: ['protein', 'snacks'],
    title: "Choose High-Protein Snacks",
    body:
        "Nuts, curd, roasted chana, or boiled eggs keep hunger controlled for longer.",
    bodyHi: "नट्स, दही, भुना चना या उबला अंडा लंबे समय तक पेट भरा रखते हैं।",
    bodyOd: "ନଟ୍ସ୍, ଦହି, ଭୁନା ଚଣା କିମ୍ବା ସେଧା ଅଣ୍ଡା ଦୀର୍ଘ ସମୟ ଭୋକ କମାଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'fiber_tip_millet_329',
    type: ContentType.tip,
    tags: ['fiber', 'grains'],
    title: "Add Millets for Extra Fiber",
    body:
        "Millets like ragi, bajra, and jowar boost fiber and improve fullness.",
    bodyHi:
        "रागी, बाजरा और ज्वार जैसे मिलेट फाइबर बढ़ाते हैं और पेट भरा महसूस कराते हैं।",
    bodyOd: "ରାଗି, ବାଜରା ଓ ଝୱାର ପରି ମିଲେଟ୍ ଫାଇବର ବଢ଼ାଇ ତୃପ୍ତି ବଢ଼ାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_myth_juice_330',
    type: ContentType.myth,
    tags: ['hydration', 'beverages'],
    title: "Myth: Fruit Juice Hydrates Like Water",
    body:
        "Juices contain sugar and lack electrolytes; plain water hydrates more effectively.",
    bodyHi:
        "मिथ: जूस पानी जितना हाइड्रेट करता है। जूस में शुगर होती है और पानी जितना असरदार नहीं है।",
    bodyOd:
        "ମିଥ୍: ଫଳରସ ପାଣି ପରି ହାଇଡ୍ରେଟ୍ କରେ। ଏଥିରେ ସୁଗର ଥାଏ ଏବଂ ପାଣି ପରି ପ୍ରଭାବଶାଳୀ ନୁହେଁ।",
  ),

  WellnessContentModel(
    id: 'minerals_fact_magmuscle_331',
    type: ContentType.fact,
    tags: ['minerals', 'muscle_function'],
    title: "Magnesium Supports Muscle Relaxation",
    body: "It prevents cramps and helps muscles recover efficiently.",
    bodyHi:
        "मैग्नीशियम मांसपेशियों के खिंचाव को रोकता है और रिकवरी में मदद करता है।",
    bodyOd: "ମ୍ୟାଗ୍ନେସିୟମ୍ ପେଶୀ ଯନ୍ତ୍ରଣା ରୋକେ ଏବଂ ପୁନରୁତ୍ଥାନ ଉନ୍ନତ କରେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_knowledge_hidden_332',
    type: ContentType.knowledge,
    tags: ['deficiency', 'symptoms'],
    title: "Deficiencies Often Show Subtle Symptoms",
    body:
        "Fatigue, hair fall, and brittle nails may indicate underlying nutrient gaps.",
    bodyHi:
        "थकान, बाल झड़ना और नाखून टूटना पोषक तत्वों की कमी का संकेत हो सकता है।",
    bodyOd: "କ୍ଲାନ୍ତି, କେଶପାତ ଓ ଭଞ୍ଜନଶୀଳ ନଖ ପୋଷକ ଅଭାବର ସଙ୍କେତ।",
  ),

  WellnessContentModel(
    id: 'vitamins_tip_natfood_333',
    type: ContentType.tip,
    tags: ['vitamins', 'food_sources'],
    title: "Eat Colorful Foods for Vitamins",
    body:
        "Different colors in fruits and vegetables indicate different vitamin profiles.",
    bodyHi: "रंग-बिरंगे फल और सब्जियाँ अलग-अलग विटामिन प्रदान करती हैं।",
    bodyOd: "ବିଭିନ୍ନ ରଙ୍ଗର ଫଳ ଓ ଶାକରେ ଭିନ୍ନ ଭିଟାମିନ୍ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'protein_fact_immunity_334',
    type: ContentType.fact,
    tags: ['protein', 'immune_function'],
    title: "Protein Powers Immunity",
    body: "Antibodies are made from protein, making adequate intake essential.",
    bodyHi: "एंटीबॉडीज़ प्रोटीन से बनती हैं, इसलिए पर्याप्त प्रोटीन जरूरी है।",
    bodyOd: "ଆଣ୍ଟିବଡି ପ୍ରୋଟିନ୍‌ରୁ ତିଆରି ହୁଏ, ସେଇଥିପାଇଁ ପ୍ରଚୁର ପ୍ରୋଟିନ୍ ଦରକାର।",
  ),

  WellnessContentModel(
    id: 'fiber_advice_gradual_335',
    type: ContentType.advice,
    tags: ['fiber', 'digestion'],
    title: "Increase Fiber Gradually",
    body: "A sudden rise in fiber can cause bloating; increase intake slowly.",
    bodyHi: "फाइबर को अचानक बढ़ाने से गैस हो सकती है, इसे धीरे-धीरे बढ़ाएँ।",
    bodyOd: "ହଟାତ୍ ଫାଇବର ବଢ଼ାଇଲେ ଗ୍ୟାସ୍ ହୋଇପାରେ, ଧୀରେ ଧୀରେ ବଢ଼ାନ୍ତୁ।",
  ),

  WellnessContentModel(
    id: 'hydration_tip_eatwater_336',
    type: ContentType.tip,
    tags: ['hydration', 'fruits'],
    title: "Eat Water-Rich Foods",
    body:
        "Cucumber, watermelon, oranges, and tomatoes also contribute to hydration.",
    bodyHi: "खीरा, तरबूज, संतरा और टमाटर भी शरीर को हाइड्रेट करते हैं।",
    bodyOd: "କାକୁଡି, ତରଭୁଜ, କମଳା ଓ ଟମାଟୋ ଶରୀରକୁ ହାଇଡ୍ରେଟ୍ କରେ।",
  ),

  WellnessContentModel(
    id: 'minerals_myth_supponly_337',
    type: ContentType.myth,
    tags: ['minerals', 'supplements'],
    title: "Myth: Minerals Must Come from Supplements",
    body: "A balanced diet usually provides enough minerals without pills.",
    bodyHi:
        "मिथ: खनिज केवल सप्लीमेंट से मिलते हैं। संतुलित आहार से पर्याप्त मात्रा मिल जाती है।",
    bodyOd: "ମିଥ୍: ଖଣିଜ କେବଳ ସପ୍ଲିମେଣ୍ଟରୁ ମିଳେ। ସନ୍ତୁଳିତ ଆହାରରେ ପ୍ରଚୁର ମିଳେ।",
  ),

  WellnessContentModel(
    id: 'deficiency_fact_B12neu_338',
    type: ContentType.fact,
    tags: ['deficiency', 'neurology'],
    title: "B12 Deficiency Affects Nerves",
    body: "Low B12 can cause tingling, numbness, and memory problems.",
    bodyHi: "B12 की कमी झुनझुनी, सुन्नपन और स्मृति समस्याएँ पैदा कर सकती है।",
    bodyOd: "B12 ଅଭାବରେ ଝିନ୍ଝିନ୍, ସୁନ୍ନପଣ ଓ ସ୍ମୃତି ସମସ୍ୟା ହୋଇପାରେ।",
  ),

  WellnessContentModel(
    id: 'vitamins_advice_fatmeal_339',
    type: ContentType.advice,
    tags: ['vitamins', 'fat_soluble'],
    title: "Take Fat-Soluble Vitamins with Meals",
    body: "Vitamins A, D, E, and K absorb better when eaten with healthy fats.",
    bodyHi: "A, D, E और K विटामिन स्वस्थ वसा के साथ बेहतर अवशोषित होते हैं।",
    bodyOd: "A, D, E ଓ K ଭିଟାମିନ୍ ସ୍ୱସ୍ଥ ଚର୍ବି ସହିତ ଭଲ ଶୋଷିତ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'protein_tip_legumes_340',
    type: ContentType.tip,
    tags: ['protein', 'vegetarian'],
    title: "Use Legumes as Protein Staples",
    body: "Rajma, chana, dal, and soy provide high-quality plant protein.",
    bodyHi: "राजमा, चना, दाल और सोया बेहतरीन प्लांट प्रोटीन स्रोत हैं।",
    bodyOd: "ରାଜମା, ଚଣା, ଡାଲି ଓ ସୋୟା ଉତ୍କୃଷ୍ଟ ଉଦ୍ଭିଦ ପ୍ରୋଟିନ୍।",
  ),

  WellnessContentModel(
    id: 'fiber_fact_weight_341',
    type: ContentType.fact,
    tags: ['fiber', 'weight_management'],
    title: "Fiber Helps Control Appetite",
    body: "High-fiber foods keep you full longer and reduce overeating.",
    bodyHi: "फाइबर युक्त भोजन पेट भरा रखता है और ज्यादा खाने से बचाता है।",
    bodyOd: "ଫାଇବର ଧନ୍ୟ ଖାଦ୍ୟ ଦୀର୍ଘ ସମୟ ପେଟ ଭରା ରଖେ ଏବଂ ଅଧିକ ଖାଇବା କମାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_advice_kidney_342',
    type: ContentType.advice,
    tags: ['hydration', 'kidneys'],
    title: "Keep Hydration for Kidney Health",
    body: "Adequate water supports toxin removal and prevents kidney stones.",
    bodyHi:
        "पानी की पर्याप्त मात्रा किडनी को टॉक्सिन बाहर निकालने में मदद करती है और स्टोन रोकती है।",
    bodyOd:
        "ପର୍ଯ୍ୟାପ୍ତ ପାଣି କିଡନିକୁ ବିଷାକ୍ତ ପଦାର୍ଥ ବାହାର କରିବାରେ ସାହାଯ୍ୟ କରେ ଏବଂ ଷ୍ଟୋନ୍ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'minerals_tip_zinc_343',
    type: ContentType.tip,
    tags: ['minerals', 'immunity'],
    title: "Boost Immunity with Zinc",
    body: "Seeds, nuts, and legumes provide zinc that supports immune cells.",
    bodyHi:
        "बीज, नट्स और दालें जिंक देती हैं, जो इम्युनिटी को मजबूत बनाती हैं।",
    bodyOd: "ବିଆ, ନଟ୍ସ ଓ ଡାଲି ଜିଙ୍କ୍ ଦିଏ, ଯେଉଁଥିରେ ପ୍ରତିରୋଧକ ସକ୍ତି ବଢ଼େ।",
  ),

  WellnessContentModel(
    id: 'deficiency_tip_elderly_344',
    type: ContentType.tip,
    tags: ['deficiency', 'aging'],
    title: "Elderly Need More B12",
    body: "Absorption of B12 decreases with age, increasing deficiency risk.",
    bodyHi:
        "उम्र के साथ B12 का अवशोषण घटता है, इसलिए बुजुर्गों में इसकी कमी आम है।",
    bodyOd: "ବୟସ୍ ବଢ଼ିଲେ B12 ଶୋଷଣ କମିଯାଏ, ସେଥିପାଇଁ ଅଭାବ ସାଧାରଣ।",
  ),

  WellnessContentModel(
    id: 'vitamins_fact_Eantiox_345',
    type: ContentType.fact,
    tags: ['vitamins', 'antioxidants'],
    title: "Vitamin E Protects Cells",
    body:
        "It acts as an antioxidant, preventing cell damage caused by free radicals.",
    bodyHi: "विटामिन E एंटीऑक्सीडेंट है जो कोशिकाओं को नुकसान से बचाता है।",
    bodyOd: "ଭିଟାମିନ୍ E ଏକ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଯେଉଁଥିରେ କୋଷକୁ କ୍ଷତିରୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'protein_myth_heavy_346',
    type: ContentType.myth,
    tags: ['protein', 'digestion'],
    title: "Myth: Protein Is Hard to Digest",
    body:
        "A healthy digestive system handles protein easily when portions are balanced.",
    bodyHi:
        "मिथ: प्रोटीन पचाना मुश्किल है। संतुलित मात्रा में यह आसानी से पच जाता है।",
    bodyOd: "ମିଥ୍: ପ୍ରୋଟିନ୍ ଜୀର୍ଣ୍ଣ କଷ୍ଟକର। ଠିକ୍ ପରିମାଣରେ ଏହା ସହଜରେ ପଚେ।",
  ),

  WellnessContentModel(
    id: 'fiber_knowledge_prebiotic_347',
    type: ContentType.knowledge,
    tags: ['fiber', 'prebiotics'],
    title: "Prebiotic Fiber Supports Gut Flora",
    body:
        "Foods like garlic, onions, and oats help feed beneficial gut bacteria.",
    bodyHi:
        "लहसुन, प्याज़ और ओट्स जैसे खाद्य पदार्थ आंतों के अच्छे बैक्टीरिया को पोषण देते हैं।",
    bodyOd: "ରସୁଣ, ପିଆଜ ଏବଂ ଓଟ୍ସ ଆନ୍ତର ସତ୍କାରୀ ବ୍ୟାକ୍ଟେରିଆକୁ ପୋଷଣ ଦେଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'hydration_myth_thirst_348',
    type: ContentType.myth,
    tags: ['hydration', 'awareness'],
    title: "Myth: Thirst Is the First Sign of Dehydration",
    body:
        "By the time you feel thirsty, your body is already mildly dehydrated.",
    bodyHi:
        "मिथ: प्यास डिहाइड्रेशन का पहला संकेत है। प्यास लगने तक शरीर पहले ही पानी की कमी झेल रहा होता है।",
    bodyOd:
        "ମିଥ୍: ପିଆସ ହେଉଛି ପ୍ରଥମ ଜଳାଭାବ ଚିହ୍ନ। ପିଆସ ଲାଗିବା ସମୟରେ ଶରୀର ପୂର୍ବରୁ ହିଁ ଜଳାଭାବରେ ଅଛି।",
  ),

  WellnessContentModel(
    id: 'minerals_advice_combo_349',
    type: ContentType.advice,
    tags: ['minerals', 'diet_planning'],
    title: "Balance Mineral Intake",
    body:
        "Too much of one mineral can interfere with the absorption of another, so eat a varied diet.",
    bodyHi:
        "एक खनिज की अधिकता दूसरे के अवशोषण को प्रभावित कर सकती है, इसलिए विविध आहार लें।",
    bodyOd:
        "ଏକ ଖଣିଜ ଅଧିକ ଲେବାରେ ଅନ୍ୟଟିର ଶୋଷଣ କମିଯାଏ, ତେଣୁ ବିଭିନ୍ନ ପ୍ରକାରର ଖାଦ୍ୟ ଖାନ୍ତୁ।",
  ),

  WellnessContentModel(
    id: 'deficiency_advice_foodfirst_350',
    type: ContentType.advice,
    tags: ['deficiency', 'nutrition'],
    title: "Correct Deficiencies Through Diet First",
    body:
        "Food-based solutions should be tried before supplements, unless medically required.",
    bodyHi:
        "सप्लीमेंट से पहले आहार से कमी सुधारने की कोशिश करनी चाहिए, जब तक कि डॉक्टर सलाह न दें।",
    bodyOd:
        "ଚିକିତ୍ସକ ସୁପରିଶ ନ ଥାଇ ପର୍ଯ୍ୟନ୍ତ ସପ୍ଲିମେଣ୍ଟ ପୂର୍ବରୁ ଆହାର ଦ୍ୱାରା ଅଭାବ ସୁଧାରନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_tip_portion_351',
    type: ContentType.tip,
    tags: ['weight_loss', 'portion_control'],
    title: "Portion Control Works",
    body:
        "Using smaller plates helps reduce calorie intake without feeling deprived.",
    bodyHi: "छोटी प्लेट का उपयोग करने से बिना भूख लगे कैलोरी कम होती है।",
    bodyOd: "ଛୋଟ ପ୍ଲେଟ ବ୍ୟବହାର କଲେ ଭୋକ ଲାଗିବା ଛଡ଼ା କ୍ୟାଲୋରି କମେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_fact_calories_352',
    type: ContentType.fact,
    tags: ['weight_gain', 'calories'],
    title: "Surplus Calories Are Essential",
    body:
        "Gaining weight needs a consistent calorie surplus from nutritious foods.",
    bodyHi:
        "वजन बढ़ाने के लिए पौष्टिक भोजन से लगातार कैलोरी सरप्लस जरूरी होता है।",
    bodyOd: "ଓଜନ ବଢ଼ାଇବାକୁ ପୌଷ୍ଟିକ ଖାଦ୍ୟରୁ ସ୍ଥିର କ୍ୟାଲୋରି ସର୍ପ୍ଲସ୍ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'metabolism_myth_speed_353',
    type: ContentType.myth,
    tags: ['metabolism', 'myth'],
    title: "Myth: Thin People Always Have Fast Metabolism",
    body:
        "Body size doesn’t guarantee metabolic speed; lifestyle plays a major role.",
    bodyHi:
        "पतला शरीर होना तेज मेटाबॉलिज़्म की गारंटी नहीं है; जीवनशैली बड़ा प्रभाव डालती है।",
    bodyOd:
        "ଦୁବଳ ଶରୀର ହେବାର୍ଥ ଶୀଘ୍ର ମେଟାବୋଲିଜ୍ମ ନୁହେଁ; ଜୀବନଶୈଳୀ ମୁଖ୍ୟଭାବେ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_tip_water_354',
    type: ContentType.tip,
    tags: ['appetite_control', 'hydration'],
    title: "Drink Water Before Meals",
    body:
        "A glass of water before meals may reduce overeating and support digestion.",
    bodyHi:
        "भोजन से पहले एक गिलास पानी पीने से ओवरईटिंग कम होती है और पाचन बेहतर होता है।",
    bodyOd: "ଖାଇବା ପୂର୍ବରୁ ପାଣି ପିଲେ ଅଧିକ ଖାଇବା କମେ ଏବଂ ପଚନ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'mental_health_fact_brainfood_355',
    type: ContentType.fact,
    tags: ['mental_health', 'nutrition'],
    title: "Brain Needs Good Nutrition",
    body:
        "Omega-3 fats, B-vitamins, and antioxidants support mood and cognitive health.",
    bodyHi:
        "ओमेगा-3, बी-विटामिन और एंटीऑक्सीडेंट मूड और दिमागी स्वास्थ्य में मदद करते हैं।",
    bodyOd:
        "ଓମେଗା-3, ବି-ଭିଟାମିନ ଏବଂ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ମନୋଭାବ ଓ ମସ୍ତିଷ୍କ ସ୍ୱାସ୍ଥ୍ୟକୁ ସହାୟତା କରେ।",
  ),
  WellnessContentModel(
    id: 'stress_tip_breathing_356',
    type: ContentType.tip,
    tags: ['stress', 'breathing'],
    title: "Slow Breathing Helps",
    body:
        "Five minutes of slow, deep breathing can lower stress hormones quickly.",
    bodyHi: "पाँच मिनट की धीमी, गहरी सांसें तनाव हार्मोन को कम कर सकती हैं।",
    bodyOd: "ପାଞ୍ଚ ମିନିଟ୍ ଧୀରେ ଗଭୀର ଶ୍ୱାସ ନେଲେ ଚାପ ହର୍ମୋନ କମିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_knowledge_cycles_357',
    type: ContentType.knowledge,
    tags: ['sleep', 'circadian_rhythm'],
    title: "Sleep Works in Cycles",
    body:
        "Your body repairs and restores itself during sleep cycles, especially deep sleep.",
    bodyHi:
        "नींद के चक्रों में शरीर अपनी मरम्मत और पुनर्स्थापना करता है, खासतौर पर गहरी नींद में।",
    bodyOd: "ନିଦ୍ରା ଚକ୍ରରେ ଶରୀର ନିଜକୁ ମରାମତ କରେ, ବିଶେଷକରି ଗଭୀର ନିଦ୍ରାରେ।",
  ),
  WellnessContentModel(
    id: 'mood_advice_routine_358',
    type: ContentType.advice,
    tags: ['mood', 'lifestyle'],
    title: "Create a Mood-Supporting Routine",
    body:
        "Consistent wake times, movement, and sunlight exposure boost mood naturally.",
    bodyHi:
        "नियमित जागने का समय, हल्की गतिविधि और धूप का संपर्क मूड को स्वाभाविक रूप से बेहतर बनाते हैं।",
    bodyOd:
        "ନିୟମିତ ଉଠିବା ସମୟ, ହାଲୁକା ଗତିବିଧି ଏବଂ ସୂର୍ଯ୍ୟାଲୋକ ମନୋଭାବକୁ ନିଜେହିଁ ଉନ୍ନତ କରେ।",
  ),
  WellnessContentModel(
    id: 'food_grains_fact_fiber_359',
    type: ContentType.fact,
    tags: ['food_grains', 'fiber'],
    title: "Whole Grains Aid Gut Health",
    body:
        "Whole grains like brown rice and jowar provide fiber that supports digestion.",
    bodyHi:
        "ब्राउन राइस और ज्वार जैसे साबुत अनाज फाइबर देते हैं जो पाचन में मदद करते हैं।",
    bodyOd: "ବ୍ରାଉନ ଚାଉଳ ଓ ଝୌଆ ଭଳି ସାବୁତ ଧାନ୍ୟ ପଚନ ପାଇଁ ଆବଶ୍ୟକ ଫାଇବର୍ ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'pulses_tip_protein_360',
    type: ContentType.tip,
    tags: ['pulses', 'protein'],
    title: "Add Pulses for Protein",
    body:
        "Lentils, chana, and rajma offer plant-based protein for daily meals.",
    bodyHi:
        "दालें, चना और राजमा रोज़ाना प्रोटीन का अच्छा पौधे-आधारित स्रोत हैं।",
    bodyOd: "ଡାଲି, ଚଣା ଏବଂ ରାଜମା ଦୈନିକ ଉଦ୍ଭିଦ ଆଧାରିତ ପ୍ରୋଟିନ୍ ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'indian_vegetables_fact_micronutrients_361',
    type: ContentType.fact,
    tags: ['indian_vegetables', 'micronutrients'],
    title: "Indian Veggies Are Micronutrient-Rich",
    body: "Bhindi, lauki, and spinach provide essential vitamins and minerals.",
    bodyHi: "भिंडी, लौकी और पालक जरूरी विटामिन व मिनरल्स से भरपूर होते हैं।",
    bodyOd: "ଭିଣ୍ଡି, ଲାଉ ଏବଂ ପାଳଙ୍ଗ ଆବଶ୍ୟକ ଭିଟାମିନ ଓ ଖଣିଜରେ ପୁରା।",
  ),
  WellnessContentModel(
    id: 'indian_fruits_tip_seasonal_362',
    type: ContentType.tip,
    tags: ['indian_fruits', 'seasonal'],
    title: "Choose Seasonal Fruits",
    body:
        "Seasonal fruits like guava, mango, and jamun offer better nutrition and taste.",
    bodyHi: "अमरुद, आम और जामुन जैसे मौसमी फल अधिक पोषण और स्वाद देते हैं।",
    bodyOd: "ପେରା, ଆମ୍ବ ଓ ଜାମୁନ ଭଳି ଋତୁକାଳୀନ ଫଳ ଅଧିକ ପୋଷଣ ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'spices_knowledge_antioxidants_363',
    type: ContentType.knowledge,
    tags: ['spices', 'antioxidants'],
    title: "Spices Offer Antioxidants",
    body:
        "Turmeric, cinnamon, and cloves protect the body from oxidative stress.",
    bodyHi: "हल्दी, दालचीनी और लौंग शरीर को ऑक्सीडेटिव तनाव से बचाते हैं।",
    bodyOd: "ହଳଦୀ, ଦାଳଚିନି ଓ ଲବଙ୍ଗ ଅକ୍ସିଡେଟିଭ୍ ଚାପରୁ ଶରୀରକୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'nuts_seeds_fact_healthyfats_364',
    type: ContentType.fact,
    tags: ['nuts_seeds', 'healthy_fats'],
    title: "Healthy Fats in Nuts & Seeds",
    body: "Almonds, walnuts, and flaxseeds support heart and brain health.",
    bodyHi: "बादाम, अखरोट और अलसी दिल और दिमाग के लिए फायदेमंद होते हैं।",
    bodyOd: "ବାଦାମ, ଆଖରୋଟ ଓ ତିଲ୍ ହୃଦୟ ଏବଂ ମସ୍ତିଷ୍କ ପାଇଁ ଉପକାରୀ।",
  ),
  WellnessContentModel(
    id: 'dairy_myth_weight_365',
    type: ContentType.myth,
    tags: ['dairy', 'weight_loss'],
    title: "Myth: Dairy Prevents Weight Loss",
    body: "Moderate low-fat dairy can fit into a healthy weight-loss diet.",
    bodyHi:
        "लो-फैट डेयरी सीमित मात्रा में वजन घटाने के आहार में शामिल की जा सकती है।",
    bodyOd: "ଲୋ-ଫ୍ୟାଟ୍ ଡେରି ସୀମିତ ପରିମାଣରେ ଓଜନ କମାଇବା ଖାଦ୍ୟରେ ରହିପାରେ।",
  ),
  WellnessContentModel(
    id: 'millets_tip_satiety_366',
    type: ContentType.tip,
    tags: ['millets', 'satiety'],
    title: "Millets Keep You Full",
    body: "Ragi, bajra, and jowar digest slowly, helping control hunger.",
    bodyHi: "रागी, बाजरा और ज्वार धीरे पचते हैं और भूख नियंत्रित करते हैं।",
    bodyOd: "ରାଗି, ବାଜରା ଓ ଝୌଆ ଧୀରେ ପଚେଇ ଭୋକକୁ ନିୟନ୍ତ୍ରଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_fact_activity_367',
    type: ContentType.fact,
    tags: ['weight_loss', 'activity'],
    title: "Movement Matters More Than You Think",
    body: "Daily steps and simple movement boost calorie burn effectively.",
    bodyHi: "दैनिक कदम और हल्की गतिविधि भी कैलोरी बर्न बढ़ाती है।",
    bodyOd: "ଦିନସର ହାଟିବା ଓ ସହଜ ଗତିବିଧି କ୍ୟାଲୋରି ଦାହକୁ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_tip_snacks_368',
    type: ContentType.tip,
    tags: ['weight_gain', 'snacking'],
    title: "Healthy High-Calorie Snacks",
    body: "Peanut chikki, banana shakes, and nuts help gain weight safely.",
    bodyHi:
        "मूंगफली चिक्की, केले का शेक और मेवे सुरक्षित रूप से वजन बढ़ाने में मदद करते हैं।",
    bodyOd: "ବାଦାମ, କଳା ଶେକ୍ ଓ ମୁଂଫଳ ସ୍ୱାସ୍ଥ୍ୟକର ଭାବେ ଓଜନ ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_tip_strength_369',
    type: ContentType.tip,
    tags: ['metabolism', 'strength_training'],
    title: "Build Muscle to Boost Metabolism",
    body: "Strength training increases resting metabolic rate naturally.",
    bodyHi: "स्ट्रेंथ ट्रेनिंग से आराम के समय का मेटाबॉलिज़्म भी बढ़ता है।",
    bodyOd: "ଶକ୍ତି ଅଭ୍ୟାସ ଶରୀରର ବିଶ୍ରାମ ସମୟର ମେଟାବୋଲିଜ୍ମ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_fact_protein_370',
    type: ContentType.fact,
    tags: ['appetite_control', 'protein'],
    title: "Protein Reduces Cravings",
    body: "Protein helps regulate hunger hormones and keeps you full longer.",
    bodyHi: "प्रोटीन भूख हार्मोन को नियंत्रित कर लंबे समय तक भरापन देता है।",
    bodyOd:
        "ପ୍ରୋଟିନ୍ ଭୋକ ହର୍ମୋନ୍ କୁ ନିୟନ୍ତ୍ରଣ କରି ଦୀର୍ଘ ସମୟ ପର୍ଯ୍ୟନ୍ତ ପେଟ ଭରିରଖେ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_tip_portion_371',
    type: ContentType.tip,
    tags: ['weight_loss', 'portion_control'],
    title: "Smaller Plates, Better Control",
    body:
        "Using smaller plates naturally reduces overeating by controlling portion size.",
    bodyHi:
        "छोटी प्लेट का उपयोग करने से परोसने की मात्रा नियंत्रित होती है और अधिक खाने से बचाव होता है।",
    bodyOd:
        "ଛୋଟ ପ୍ଲେଟ୍ ବ୍ୟବହାର କଲେ ପୋର୍ସନ୍ କନ୍ଟ୍ରୋଲ୍ ହୁଏ ଏବଂ ଅଧିକ ଖାଇବା ରୋକାଯାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_fact_fiber_372',
    type: ContentType.fact,
    tags: ['weight_loss', 'fiber'],
    title: "Fiber Keeps You Full Longer",
    body:
        "High-fiber foods slow digestion and reduce hunger, supporting long-term weight loss.",
    bodyHi:
        "फाइबर युक्त भोजन पाचन को धीमा करता है और लंबे समय तक भूख कम रखता है।",
    bodyOd: "ଫାଇବର୍ ଥିବା ଖାଦ୍ୟ ପାଚନକୁ ଧୀର କରି ଦୀର୍ଘ ସମୟ ପର୍ଯ୍ୟନ୍ତ ଭୋକ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_myth_starvation_373',
    type: ContentType.myth,
    tags: ['weight_loss', 'diet'],
    title: "Myth: Starving Helps You Lose Weight",
    body: "Skipping meals slows metabolism and leads to weight gain over time.",
    bodyHi:
        "मिथ: भूखे रहने से वजन कम होता है। असल में, इससे मेटाबॉलिज्म धीमा होता है और वजन बढ़ सकता है।",
    bodyOd:
        "ମିଥ୍: ଖାଇବା ଛାଡ଼ିଲେ ଓଜନ୍ କମିବ। ପ୍ରକୃତରେ ଏହା ମେଟାବୋଲିଜମ୍ କମାଇ ଓଜନ୍ ବଢ଼ାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_advice_steps_374',
    type: ContentType.advice,
    tags: ['weight_loss', 'activity'],
    title: "Increase Daily Steps",
    body:
        "Aim for 8,000–10,000 steps a day to boost calorie burn effortlessly.",
    bodyHi:
        "कैलोरी खर्च बढ़ाने के लिए रोज़ 8,000–10,000 कदम चलने का लक्ष्य रखें।",
    bodyOd: "କ୍ୟାଲୋରି ଜଳନ ବଢ଼ାଇବାକୁ ପ୍ରତିଦିନ 8,000–10,000 ପଦକ୍ଷେପ ଚାଲନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_tip_calorie_dense_375',
    type: ContentType.tip,
    tags: ['weight_gain', 'nutrition'],
    title: "Choose Calorie-Dense Foods",
    body:
        "Nuts, ghee, and bananas help add calories without large meal volumes.",
    bodyHi:
        "मेवे, घी और केले ज्यादा मात्रा खाए बिना कैलोरी बढ़ाने में मदद करते हैं।",
    bodyOd: "ଗଜବାଦାମ, ଘିଅ ଏବଂ କଦଳୀ ବେଶି ପରିମାଣ ଖାଇବା ଛାଡ଼ା କ୍ୟାଲୋରି ବଢ଼ାଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_fact_protein_376',
    type: ContentType.fact,
    tags: ['weight_gain', 'protein'],
    title: "Protein Helps Build Lean Mass",
    body:
        "Increasing protein intake supports healthy weight gain by building muscle, not fat.",
    bodyHi:
        "प्रोटीन का सेवन बढ़ाने से वसा नहीं बल्कि मांसपेशियाँ बढ़ती हैं, जो स्वस्थ वजन बढ़ाने में मदद करता है।",
    bodyOd:
        "ପ୍ରୋଟିନ୍ ବଢ଼ାଇଲେ ଚର୍ବି ନୁହେଁ, ମାଂସପେଶୀ ବଢ଼େ ଯାହା ସ୍ୱସ୍ଥ ଓଜନ ବୃଦ୍ଧିକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_myth_junk_377',
    type: ContentType.myth,
    tags: ['weight_gain', 'diet'],
    title: "Myth: Junk Food Helps You Gain Weight Safely",
    body:
        "Unhealthy foods add fat, not strength, and cause long-term complications.",
    bodyHi:
        "मिथ: जंक फूड से स्वस्थ वजन बढ़ता है। यह केवल चर्बी बढ़ाता है और शरीर को नुकसान पहुंचाता है।",
    bodyOd:
        "ମିଥ୍: ଜଙ୍କ୍ ଫୁଡ୍ ସ୍ୱସ୍ଥ ଓଜନ ବଢ଼ାଏ। ଏହା କେବଳ ଚର୍ବି ବଢ଼ାଇ ଦେହକୁ କ୍ଷତି କରେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_advice_strength_378',
    type: ContentType.advice,
    tags: ['weight_gain', 'exercise'],
    title: "Add Strength Training",
    body:
        "Resistance exercise promotes healthy muscle gain and improves appetite.",
    bodyHi:
        "रेज़िस्टेंस ट्रेनिंग मांसपेशी बढ़ाने में मदद करती है और भूख में सुधार लाती है।",
    bodyOd: "ରେଜିଷ୍ଟାନ୍ସ ଟ୍ରେନିଙ୍ଗ୍ ସ୍ୱସ୍ଥ ମାଂସପେଶୀ ବୃଦ୍ଧି ଓ ଭୋକ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'metabolism_tip_water_379',
    type: ContentType.tip,
    tags: ['metabolism', 'hydration'],
    title: "Drink Water Early Morning",
    body: "A glass of water after waking up helps kickstart metabolism.",
    bodyHi: "सुबह उठते ही एक गिलास पानी पीने से मेटाबॉलिज्म सक्रिय होता है।",
    bodyOd: "ସକାଳେ ଉଠିଲେ ପାଣି ପିଇବାରେ ମେଟାବୋଲିଜମ୍ ସକ୍ରିୟ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_fact_muscle_380',
    type: ContentType.fact,
    tags: ['metabolism', 'muscle'],
    title: "More Muscle, Higher Metabolism",
    body: "Muscle tissue burns more calories at rest than fat tissue.",
    bodyHi:
        "मांसपेशियाँ आराम की अवस्था में भी वसा की तुलना में अधिक कैलोरी जलाती हैं।",
    bodyOd: "ମାଂସପେଶୀ ବିଶ୍ରାମ ସମୟରେ ମଧ୍ୟ ଚର୍ବି ତୁଳନାରେ ଅଧିକ କ୍ୟାଲୋରି ଜଳାଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_myth_spot_381',
    type: ContentType.myth,
    tags: ['metabolism', 'weight_loss'],
    title: "Myth: Some Foods Directly Melt Fat",
    body:
        "No food burns fat instantly; only calorie deficit and activity improve fat loss.",
    bodyHi:
        "मिथ: कुछ खाद्य पदार्थ तुरंत फैट पिघलाते हैं। असल में, केवल कैलोरी घाटा और गतिविधि से फैट घटता है।",
    bodyOd:
        "ମିଥ୍: କିଛି ଖାଦ୍ୟ ସିଧାସଳଖ ଚର୍ବି ଗଳାଏ। ପ୍ରକୃତରେ କେବଳ କ୍ୟାଲୋରି ଘାଟତି ଓ କାର୍ଯ୍ୟକଳାପ ଫାଟ୍ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_advice_meals_382',
    type: ContentType.advice,
    tags: ['metabolism', 'meal_timing'],
    title: "Don’t Skip Meals",
    body:
        "Regular meals help maintain metabolic stability and prevent overeating later.",
    bodyHi:
        "समय पर भोजन करने से मेटाबॉलिज्म स्थिर रहता है और बाद में ज्यादा खाने से बचाव होता है।",
    bodyOd: "ସମୟରେ ଭୋଜନ କଲେ ମେଟାବୋଲିଜମ୍ ସ୍ଥିର ରହେ ଏବଂ ପରେ ଅଧିକ ଖାଇବା ରୋକାଯାଏ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_tip_protein_383',
    type: ContentType.tip,
    tags: ['appetite_control', 'protein'],
    title: "Prioritize Protein at Breakfast",
    body:
        "A protein-rich start reduces hunger and cravings throughout the day.",
    bodyHi: "प्रोटीन युक्त नाश्ता पूरे दिन भूख और क्रेविंग को कम करता है।",
    bodyOd: "ପ୍ରୋଟିନ୍ ଥିବା ଖାଦ୍ୟରେ ଦିନ ଆରମ୍ଭ କଲେ ଭୋକ୍ ଓ ଇଚ୍ଛା କମେ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_fact_sleep_384',
    type: ContentType.fact,
    tags: ['appetite_control', 'sleep'],
    title: "Poor Sleep Increases Hunger Hormones",
    body: "Lack of sleep raises ghrelin levels, making cravings stronger.",
    bodyHi: "कम नींद से घ्रेलिन हार्मोन बढ़ता है, जिससे क्रेविंग बढ़ती है।",
    bodyOd: "କମ୍ ଘୁମ୍ ଘ୍ରେଲିନ୍ ହରମୋନ୍ ବଢ଼ାଇ ଭୋକ୍ ଓ ଇଚ୍ଛାକୁ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_myth_water_385',
    type: ContentType.myth,
    tags: ['appetite_control', 'hydration'],
    title: "Myth: Drinking Water Stops All Hunger",
    body:
        "Water reduces temporary hunger, but balanced meals are still essential.",
    bodyHi:
        "मिथ: पानी पीने से भूख पूरी तरह खत्म हो जाती है। यह केवल थोड़ी देर के लिए मदद करता है।",
    bodyOd:
        "ମିଥ୍: ପାଣି ପିଲେ ଭୋକ୍ ସମ୍ପୂର୍ଣ୍ଣ ଶାନ୍ତ ହୁଏ। ଏହା କେବଳ କିଛି ସମୟ ପାଇଁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_advice_mindful_386',
    type: ContentType.advice,
    tags: ['appetite_control', 'mindful_eating'],
    title: "Eat Slowly and Mindfully",
    body:
        "Taking 20 minutes per meal helps your brain register fullness properly.",
    bodyHi:
        "धीरे और ध्यानपूर्वक खाने से पेट भरने का संकेत सही समय पर मिलता है।",
    bodyOd: "ଧୀରେ ଏବଂ ସଚେତନ ଭାବେ ଖାଇଲେ ପେଟ୍ ଭରିବାର ସଙ୍କେତ ସମୟରେ ମିଳେ।",
  ),
  WellnessContentModel(
    id: 'mental_health_tip_breathing_387',
    type: ContentType.tip,
    tags: ['mental_health', 'breathing'],
    title: "Try Deep Breathing Breaks",
    body: "Just 2 minutes of deep breathing can calm your nervous system.",
    bodyHi:
        "सिर्फ 2 मिनट की गहरी साँसें आपके नर्वस सिस्टम को शांत कर देती हैं।",
    bodyOd: "କେବଳ 2 ମିନିଟ୍ ଗଭୀର ଶ୍ୱାସ ନେବାରେ ନର୍ଭସ୍ ସିଷ୍ଟମ୍ ଶାନ୍ତ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'mental_health_fact_sunlight_388',
    type: ContentType.fact,
    tags: ['mental_health', 'sunlight'],
    title: "Sunlight Boosts Serotonin",
    body: "Natural light exposure improves mood and energy levels.",
    bodyHi:
        "धूप में रहने से सेरोटोनिन बढ़ता है, जिससे मूड और ऊर्जा बेहतर होती है।",
    bodyOd: "ଧାଡ଼ିରେ ରହିଲେ ସେରୋଟୋନିନ୍ ବଢ଼େ ଏବଂ ମନସ୍ଥିତି ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'mental_health_myth_willpower_389',
    type: ContentType.myth,
    tags: ['mental_health', 'misconception'],
    title: "Myth: Mental Health Is Just About Willpower",
    body: "Mental health conditions require support, not just strong will.",
    bodyHi:
        "मिथ: मानसिक स्वास्थ्य सिर्फ इच्छाशक्ति पर निर्भर है। यह उचित सहायता की भी आवश्यकता रखता है।",
    bodyOd:
        "ମିଥ୍: ମାନସିକ ସ୍ୱାସ୍ଥ୍ୟ କେବଳ ଇଚ୍ଛାଶକ୍ତିରେ ନିର୍ଭର। ଏଥିରେ ସହାଯ୍ୟ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'mental_health_advice_routine_390',
    type: ContentType.advice,
    tags: ['mental_health', 'routine'],
    title: "Maintain a Simple Daily Routine",
    body: "Predictable habits reduce stress and improve emotional balance.",
    bodyHi: "नियमित दिनचर्या तनाव कम करती है और भावनात्मक संतुलन बढ़ाती है।",
    bodyOd: "ନିୟମିତ ଦୈନନ୍ଦିନ ଅଭ୍ୟାସ ଷ୍ଟ୍ରେସ୍ କମାଇ ଭାବନାତ୍ମକ ସନ୍ତୁଳନ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'stress_tip_journaling_391',
    type: ContentType.tip,
    tags: ['stress', 'journaling'],
    title: "Write to Release Stress",
    body: "Journaling helps clear overwhelming thoughts and improves clarity.",
    bodyHi:
        "जर्नलिंग परेशान करने वाले विचारों को हल्का करती है और स्पष्टता लाती है।",
    bodyOd: "ଜର୍ନାଲ୍ ଲେଖିବା ଭାବନାକୁ ହଳକା କରେ ଏବଂ ସ୍ପଷ୍ଟତା ଆଣେ।",
  ),
  WellnessContentModel(
    id: 'stress_fact_cortisol_392',
    type: ContentType.fact,
    tags: ['stress', 'hormones'],
    title: "Stress Raises Cortisol Levels",
    body: "High cortisol affects digestion, sleep, and immunity.",
    bodyHi:
        "अधिक तनाव से कॉर्टिसोल बढ़ता है, जिससे पाचन, नींद और प्रतिरक्षा प्रभावित होती है।",
    bodyOd:
        "ଅଧିକ ଷ୍ଟ୍ରେସ୍ କର୍ଟିସୋଲ୍ ବଢ଼ାଇ ପାଚନ, ଘୁମ୍ ଓ ପ୍ରତିରୋଧକ ଶକ୍ତିକୁ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'stress_myth_avoidance_393',
    type: ContentType.myth,
    tags: ['stress', 'coping'],
    title: "Myth: Ignoring Stress Makes It Go Away",
    body: "Stress improves when managed actively, not avoided.",
    bodyHi:
        "मिथ: तनाव को नजरअंदाज करने से वह खत्म हो जाता है। असल में, इसे संभालना जरूरी है।",
    bodyOd:
        "ମିଥ୍: ଷ୍ଟ୍ରେସ୍ ଅନଦେଖା କଲେ ସେ ଆପେଘଟେ ହରାଏ। ପ୍ରକୃତରେ ଏହାକୁ ସଠିକ୍ ପ୍ରବନ୍ଧନ ଦରକାର।",
  ),
  WellnessContentModel(
    id: 'stress_advice_breaks_394',
    type: ContentType.advice,
    tags: ['stress', 'self_care'],
    title: "Take Short Relaxing Breaks",
    body: "Micro-breaks reduce stress load and increase productivity.",
    bodyHi: "छोटे-छोटे ब्रेक तनाव को कम करते हैं और उत्पादकता बढ़ाते हैं।",
    bodyOd: "ଛୋଟ ବିରତି ଷ୍ଟ୍ରେସ୍ କମାଇ କାର୍ଯ୍ୟକ୍ଷମତା ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_tip_caffeine_395',
    type: ContentType.tip,
    tags: ['sleep', 'caffeine'],
    title: "Avoid Caffeine After 4 PM",
    body: "Late caffeine intake disrupts deep sleep cycles.",
    bodyHi: "शाम 4 बजे के बाद कैफीन लेने से गहरी नींद प्रभावित होती है।",
    bodyOd: "ସନ୍ଧ୍ୟା 4 ପରେ କାଫେଇନ୍ ନେଲେ ଗଭୀର ଘୁମ୍ ବାଧିତ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_darkness_396',
    type: ContentType.fact,
    tags: ['sleep', 'environment'],
    title: "Dark Rooms Improve Melatonin Release",
    body:
        "Complete darkness signals the brain to start sleep hormone production.",
    bodyHi:
        "अंधेरा कमरा मेलाटोनिन बनने में मदद करता है, जिससे नींद बेहतर होती है।",
    bodyOd: "ଅନ୍ଧାର କକ୍ଷ ମେଲଟୋନିନ୍ ବିକାଶକୁ ଉତ୍ତେଜିତ କରି ଘୁମ୍ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_myth_snoring_397',
    type: ContentType.myth,
    tags: ['sleep', 'misconception'],
    title: "Myth: Snoring Means Good Sleep",
    body: "Snoring can indicate sleep apnea, which affects rest quality.",
    bodyHi:
        "मिथ: खर्राटे अच्छी नींद का संकेत हैं। यह कई बार स्लीप एपनिया का लक्षण होता है।",
    bodyOd: "ମିଥ୍: ନାକଡକ୍ ଭଲ ଘୁମ୍ର ସଙ୍କେତ। ଏହା ସ୍ଲିପ୍ ଏପନିଆର ଲକ୍ଷଣ ହୋଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_advice_routine_398',
    type: ContentType.advice,
    tags: ['sleep', 'routine'],
    title: "Follow a Fixed Sleep Schedule",
    body: "Going to bed at the same time daily improves sleep quality.",
    bodyHi: "रोज़ एक ही समय पर सोने से नींद की गुणवत्ता बेहतर होती है।",
    bodyOd: "ପ୍ରତିଦିନ ସମାନ ସମୟରେ ଘୁମାଲେ ଘୁମ୍ ଗୁଣବତ୍ତା ଉନ୍ନତ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'mood_tip_music_399',
    type: ContentType.tip,
    tags: ['mood', 'self_care'],
    title: "Listen to Uplifting Music",
    body: "Music quickly shifts emotional state and reduces stress.",
    bodyHi:
        "सुकून देने वाला संगीत मूड को जल्दी बेहतर करता है और तनाव कम करता है।",
    bodyOd: "ସଙ୍ଗୀତ ମନସ୍ଥିତିକୁ ଶୀଘ୍ର ସୁଧାରେ ଏବଂ ଷ୍ଟ୍ରେସ୍ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'mood_fact_food_400',
    type: ContentType.fact,
    tags: ['mood', 'nutrition'],
    title: "Food Affects Mood Strongly",
    body: "Balanced meals stabilize blood sugar, reducing mood swings.",
    bodyHi: "संतुलित भोजन ब्लड शुगर को स्थिर रखकर मूड स्विंग को कम करता है।",
    bodyOd: "ସନ୍ତୁଳିତ ଭୋଜନ ରକ୍ତ ସକ୍କରା ସ୍ଥିର ରଖି ମନୋଭାବ ପରିବର୍ତ୍ତନ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_tip_plate_401',
    type: ContentType.tip,
    tags: ['weight_loss', 'meal_planning'],
    title: "Use a Smaller Plate",
    body:
        "Downsizing your plate reduces calorie intake without feeling deprived.",
    bodyHi:
        "छोटी प्लेट का उपयोग करने से कैलोरी कम खपत होती है और भूख भी नियंत्रित रहती है।",
    bodyOd:
        "ଛୋଟ ପ୍ଲେଟ ବ୍ୟବହାର କଲେ କ୍ୟାଲୋରୀ କମ୍ ଖର୍ଚ୍ଚ ହୁଏ ଏବଂ ପେଟ ଭରିବା ଭାବ ରହେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_fact_calorie_402',
    type: ContentType.fact,
    tags: ['weight_gain', 'nutrition'],
    title: "Calorie Surplus is Essential",
    body:
        "To gain weight safely, you must consistently eat more calories than you burn.",
    bodyHi: "वजन बढ़ाने के लिए रोज़ाना खर्च से अधिक कैलोरी लेना ज़रूरी है।",
    bodyOd:
        "ଓଜନ ବଢାଇବା ପାଇଁ ନିୟମିତ ଭାବେ ଖର୍ଚ୍ଚ ହେଉଥିବାଠାରୁ ଅଧିକ କ୍ୟାଲୋରୀ ନେବା ଆବଶ୍ୟକ।",
  ),
  WellnessContentModel(
    id: 'metabolism_knowledge_age_403',
    type: ContentType.knowledge,
    tags: ['metabolism', 'aging'],
    title: "Metabolism Slows With Age",
    body:
        "As you get older, muscle mass drops, reducing metabolic rate naturally.",
    bodyHi:
        "उम्र बढ़ने के साथ मांसपेशियाँ कम होती हैं, जिससे मेटाबॉलिज़्म धीमा होता है।",
    bodyOd: "ବୟସ ବଢିଲେ ପେଶୀ କମିଯାଏ ଏବଂ ମେଟାବୋଲିଜମ୍ ସ୍ୱାଭାବିକ ଭାବେ କମିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_tip_water_404',
    type: ContentType.tip,
    tags: ['appetite_control', 'hydration'],
    title: "Drink Water Before Meals",
    body:
        "Having a glass of water 20 minutes before food helps naturally reduce overeating.",
    bodyHi: "खाने से 20 मिनट पहले पानी पीने से ज़्यादा खाने की आदत कम होती है।",
    bodyOd: "ଖାଇବା ପୂର୍ବରୁ 20 ମିନିଟ୍ ପାଣି ପିଅଲେ ଅଧିକ ଖାଇବା ହ୍ରାସ ପାଏ।",
  ),
  WellnessContentModel(
    id: 'mental_health_advice_breaks_405',
    type: ContentType.advice,
    tags: ['mental_health', 'selfcare'],
    title: "Take Micro-Breaks",
    body:
        "Short breaks during the day reset your brain and reduce mental fatigue.",
    bodyHi:
        "दिन भर छोटे-छोटे ब्रेक मानसिक थकान कम करते हैं और मन को रीसेट करते हैं।",
    bodyOd: "ଦିନ ସାରା ଛୋଟ ବିରତି ମାନସିକ କ୍ଲାନ୍ତି କମାଏ ଏବଂ ମନକୁ ରିସେଟ୍ କରେ।",
  ),
  WellnessContentModel(
    id: 'stress_myth_ignore_406',
    type: ContentType.myth,
    tags: ['stress', 'awareness'],
    title: "Myth: Ignoring Stress Makes It Go Away",
    body:
        "Untreated stress often worsens over time and impacts overall wellbeing.",
    bodyHi: "मानसिक तनाव को नज़रअंदाज़ करना इसे और बढ़ा देता है।",
    bodyOd: "ଚାପକୁ ଅନଦେଖା କଲେ ଏହା ସମୟ ସହିତ ଅଧିକ ବୃଦ୍ଧି ପାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_rem_407',
    type: ContentType.fact,
    tags: ['sleep', 'brain_health'],
    title: "REM Sleep Restores Memory",
    body:
        "REM sleep enhances learning and strengthens long-term memory storage.",
    bodyHi: "REM नींद सीखने और याद्दाश्त को मजबूत करने में मदद करती है।",
    bodyOd: "REM ଘୁମ ଶିଖିବା ଏବଂ ସ୍ମୃତିକୁ ଦୃଢ କରିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'mood_tip_sunlight_408',
    type: ContentType.tip,
    tags: ['mood', 'lifestyle'],
    title: "Get Morning Sunlight",
    body: "10–15 minutes of early sunlight boosts serotonin and lifts mood.",
    bodyHi:
        "सुबह की धूप 10–15 मिनट लेने से मूड बेहतर होता है और सेरोटोनिन बढ़ता है।",
    bodyOd: "ସକାଳେ 10–15 ମିନିଟ୍ ସୂର୍ଯ୍ୟ କିରଣ ନେଲେ ମନସ୍ତିତି ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'food_grains_knowledge_whole_409',
    type: ContentType.knowledge,
    tags: ['food_grains', 'fiber'],
    title: "Whole Grains Aid Digestion",
    body:
        "Whole grains contain bran and germ, supporting gut health and steady energy.",
    bodyHi:
        "साबुत अनाज में चोकर और जर्म होता है जो पाचन और ऊर्जा को बेहतर बनाता है।",
    bodyOd:
        "ସାବୁତ ଅନାଜରେ ଚୋକା ଏବଂ ଜର୍ମ ଥାଏ ଯାହା ଦିଗେଷ୍ଟିଭ୍ ସ୍ୱାସ୍ଥ୍ୟ ଉନ୍ନତ କରେ।",
  ),
  WellnessContentModel(
    id: 'pulses_fact_protein_410',
    type: ContentType.fact,
    tags: ['pulses', 'protein'],
    title: "Pulses Are High-Quality Plant Protein",
    body:
        "Lentils, rajma, and chana provide essential amino acids for muscle repair.",
    bodyHi: "दालें, राजमा और चना शरीर को ज़रूरी अमीनो एसिड देते हैं।",
    bodyOd: "ଡାଲ, ରାଜମା ଏବଂ ଚଣା ଶରୀର ପାଇଁ ଆବଶ୍ୟକ ଆମିନୋ ଆମ୍ଲ ଦିଅନ୍ତି।",
  ),

  // Continue 411–450 in same structure
  WellnessContentModel(
    id: 'indian_vegetables_tip_variety_411',
    type: ContentType.tip,
    tags: ['indian_vegetables', 'meal_planning'],
    title: "Mix Colors on Your Plate",
    body:
        "Different colored vegetables provide diverse antioxidants for immunity.",
    bodyHi:
        "थाली में अलग-अलग रंग की सब्जियाँ लेना प्रतिरक्षा को मजबूत करता है।",
    bodyOd: "ବିଭିନ୍ନ ରଙ୍ଗର ସବ୍ଜି ଖାଇଲେ ପ୍ରତିରୋଧକ କ୍ଷମତା ବଢେ।",
  ),
  WellnessContentModel(
    id: 'indian_fruits_fact_fiber_412',
    type: ContentType.fact,
    tags: ['indian_fruits', 'fiber'],
    title: "Fruits Support Gut Health",
    body:
        "Guava, apple, and papaya provide soluble fiber that improves digestion.",
    bodyHi: "अमरूद, सेब और पपीता घुलनशील फाइबर देकर पाचन को बेहतर बनाते हैं।",
    bodyOd: "ପେରା, ସେଓ, ପପିତା ଦେହକୁ ଫାଇବର ଦେଇ ପାଚନ ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'spices_myth_spicy_unhealthy_413',
    type: ContentType.myth,
    tags: ['spices', 'health'],
    title: "Myth: All Spicy Foods Are Unhealthy",
    body:
        "Moderate spices like turmeric and cumin have strong anti-inflammatory benefits.",
    bodyHi: "हल्दी और जीरा जैसे मसालों में सूजन कम करने के गुण होते हैं।",
    bodyOd: "ହଳଦୀ ଓ ଜିରା ପରି ମସଲାରେ ଶୋଥ କମାଇବାର ଗୁଣ ଅଛି।",
  ),
  WellnessContentModel(
    id: 'nuts_seeds_advice_portions_414',
    type: ContentType.advice,
    tags: ['nuts_seeds', 'snacking'],
    title: "Stick to Smart Portions",
    body:
        "A handful of nuts daily supports heart health without adding excess calories.",
    bodyHi:
        "एक मुट्ठी मेवे रोज़ दिल की सेहत के लिए अच्छे होते हैं, कैलोरी भी नियंत्रित रहती है।",
    bodyOd:
        "ଦିନକୁ ଏକ ମୁଠି ନଟ୍ସ ନେଲେ ହୃଦୟ ସ୍ୱାସ୍ଥ୍ୟ ଭଲ ରହେ ଏବଂ କ୍ୟାଲୋରୀ ବଢେ ନାହିଁ।",
  ),
  WellnessContentModel(
    id: 'dairy_fact_calcium_415',
    type: ContentType.fact,
    tags: ['dairy', 'bone_health'],
    title: "Dairy Supports Bone Strength",
    body:
        "Milk and curd provide calcium and vitamin D needed for strong bones.",
    bodyHi: "दूध और दही हड्डियों के लिए ज़रूरी कैल्शियम और विटामिन D देते हैं।",
    bodyOd: "ଦୁଧ ଏବଂ ଦହି ହାଡ଼ ପାଇଁ ଆବଶ୍ୟକ କ୍ୟାଲସିୟମ୍ ଓ ଭିଟାମିନ୍ D ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'millets_knowledge_glutenfree_416',
    type: ContentType.knowledge,
    tags: ['millets', 'digestive_health'],
    title: "Millets Are Naturally Gluten-Free",
    body: "Ragi, bajra, and jowar support digestion and suit sensitive guts.",
    bodyHi:
        "रागी, बाजरा और ज्वार ग्लूटेन-फ्री होते हैं और पाचन के लिए अच्छे हैं।",
    bodyOd: "ରାଗି, ବାଜରା ଓ ଝୋୱାର ଗ୍ଲୁଟେନ୍-ମୁକ୍ତ ଏବଂ ପାଚନ ପାଇଁ ଉପକାରୀ।",
  ),

  // Continue 417–450 similarly…
  WellnessContentModel(
    id: 'weight_loss_fact_neat_417',
    type: ContentType.fact,
    tags: ['weight_loss', 'activity'],
    title: "Daily Movement Matters",
    body:
        "Non-exercise activity like walking can burn more calories than workouts.",
    bodyHi: "दिनभर की हलचल कभी-कभी कसरत से भी ज़्यादा कैलोरी जलाती है।",
    bodyOd: "ଦିନଭର ହାଟିବା ଭଳି କାମ ସର୍କାରୀ ଅଭ୍ୟାସଠାରୁ ଅଧିକ କ୍ୟାଲୋରୀ ଜଳାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_tip_snacks_418',
    type: ContentType.tip,
    tags: ['weight_gain', 'snacking'],
    title: "Choose Energy-Dense Snacks",
    body: "Peanut chikki, banana shake, and dates help healthy weight gain.",
    bodyHi:
        "मूंगफली चिक्की, केला शेक और खजूर स्वस्थ वजन बढ़ाने में मदद करते हैं।",
    bodyOd: "ବଦାମ ଚିକ୍କି, କଦଳୀ ଶେକ୍ ଏବଂ ଖଜୁର ଓଜନ ବଢାଇବାରେ ସାହାଯ୍ୟକାରୀ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_fact_neat_417',
    type: ContentType.fact,
    tags: ['weight_loss', 'activity'],
    title: "Daily Movement Burns More Than You Think",
    body:
        "Light daily movement like walking and standing can burn significant calories over time.",
    bodyHi:
        "रोज़मर्रा की हल्की गतिविधियाँ जैसे चलना और खड़े रहना धीरे-धीरे काफी कैलोरी जला सकती हैं।",
    bodyOd:
        "ପ୍ରତିଦିନର ହାଲୁକା ଗତିବିଧି ଯେପରିକି ହାଟିବା ଓ ଠିଆ ରହିବା, ସମୟ ସହିତ ଭଲ ପରିମାଣରେ କ୍ୟାଲୋରୀ ଜଳାଉଥାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_tip_snacks_418',
    type: ContentType.tip,
    tags: ['weight_gain', 'snacking'],
    title: "Add High-Calorie Snacks",
    body:
        "Snacks like peanut chikki, banana shake, and trail mix help increase healthy calories.",
    bodyHi:
        "मूंगफली चिक्की, केला शेक और ट्रेल मिक्स जैसे स्नैक्स स्वस्थ कैलोरी बढ़ाने में मदद करते हैं।",
    bodyOd:
        "ବଦାମ ଚିକ୍କି, କଦଳୀ ଶେକ୍ ଓ ଟ୍ରେଲ୍ ମିକ୍ସ ଭଳି ନାସ୍ତା ଶରୀରକୁ ସ୍ୱସ୍ଥ କ୍ୟାଲୋରୀ ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_tip_strength_419',
    type: ContentType.tip,
    tags: ['metabolism', 'exercise'],
    title: "Build Muscle to Boost Metabolism",
    body:
        "Strength training increases muscle mass, raising your resting metabolic rate.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग से मांसपेशियाँ बढ़ती हैं जिससे मेटाबॉलिक रेट भी बढ़ता है।",
    bodyOd: "ଷ୍ଟ୍ରେଙ୍ଗ୍ଥ ଟ୍ରେନିଙ୍ଗ୍ ପେଶୀ ବଢ଼ାଇ ମେଟାବୋଲିଜମ୍ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'appetite_control_advice_sloweat_420',
    type: ContentType.advice,
    tags: ['appetite_control', 'mindful_eating'],
    title: "Eat Slowly to Reduce Overeating",
    body:
        "Your brain needs around 20 minutes to register fullness, so slow eating prevents excess intake.",
    bodyHi:
        "दिमाग को पेट भरने का संकेत देने में लगभग 20 मिनट लगते हैं, इसलिए धीरे-धीरे खाएँ।",
    bodyOd:
        "ମଗଜକୁ ପେଟ ଭରିବାର ଅନୁଭୁତି ପହଞ୍ଚିବାକୁ 20 ମିନିଟ୍ ଲାଗେ, ସେହିପାଇଁ ଧୀରେ ଖାଇବା ଜରୁରି।",
  ),
  WellnessContentModel(
    id: 'mental_health_knowledge_brainbreak_421',
    type: ContentType.knowledge,
    tags: ['mental_health', 'productivity'],
    title: "Brain Breaks Improve Clarity",
    body: "Short breaks reset your mental focus and reduce cognitive overload.",
    bodyHi:
        "छोटे ब्रेक मानसिक फोकस को रीसेट करते हैं और दिमागी थकान कम करते हैं।",
    bodyOd: "ସ୍ୱଳ୍ପ ବିରତି ମନକୁ ରିସେଟ୍ କରେ ଏବଂ ମାନସିକ କ୍ଲାନ୍ତି କମାଏ।",
  ),
  WellnessContentModel(
    id: 'stress_fact_cortisol_422',
    type: ContentType.fact,
    tags: ['stress', 'hormones'],
    title: "Stress Raises Cortisol",
    body:
        "Chronic stress increases cortisol, which affects sleep, appetite, and immunity.",
    bodyHi:
        "लंबे समय का तनाव कोर्टिसोल बढ़ाता है, जो नींद, भूख और प्रतिरक्षा पर असर करता है।",
    bodyOd:
        "ଦୀର୍ଘକାଳୀନ ଚାପ କର୍ଟିସଲ୍ ବଢ଼ାଏ, ଯେହା ଘୁମ, ଭୋକ ଓ ପ୍ରତିରୋଧକତାକୁ ପ୍ରଭାବିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_tip_routine_423',
    type: ContentType.tip,
    tags: ['sleep', 'routine'],
    title: "Stick to a Sleep Schedule",
    body:
        "Sleeping and waking at the same time daily improves sleep quality naturally.",
    bodyHi: "प्रतिदिन एक ही समय पर सोना और उठना नींद की गुणवत्ता सुधारता है।",
    bodyOd: "ଦିନ ସାରା ସମାନ ସମୟରେ ଘୁମେଇବା ଓ ଉଠିବା ଘୁମର ଗୁଣୋତ୍ତମତା ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'mood_myth_foodonly_424',
    type: ContentType.myth,
    tags: ['mood', 'awareness'],
    title: "Myth: Food Alone Controls Mood",
    body:
        "While food influences mood, sleep, stress levels, and hormones play major roles too.",
    bodyHi:
        "मूड सिर्फ खाने से नहीं, बल्कि नींद, तनाव और हार्मोन से भी प्रभावित होता है।",
    bodyOd:
        "ମନସ୍ତିତି କେବଳ ଖାଦ୍ୟରୁ ନୁହେଁ, ଘୁମ, ଚାପ ଓ ହରମୋନ୍ ମଧ୍ୟ ବଡ଼ ଭୂମିକା ନେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'food_grains_advice_portions_425',
    type: ContentType.advice,
    tags: ['food_grains', 'meal_balance'],
    title: "Balance Your Grain Portions",
    body:
        "Half your grains should be whole grains to support digestion and energy.",
    bodyHi: "अच्छी पाचन शक्ति और ऊर्जा के लिए आधे अनाज साबुत अनाज रखें।",
    bodyOd: "ଦିଗେଷ୍ଟିଓନ୍ ଓ ଉର୍ଜା ପାଇଁ ଅନାଜର ଅର୍ଦ୍ଧ ଭାଗ ସାବୁତ ରଖନ୍ତୁ।",
  ),
  WellnessContentModel(
    id: 'pulses_tip_combination_426',
    type: ContentType.tip,
    tags: ['pulses', 'protein'],
    title: "Combine Pulses for Better Protein",
    body: "Mixing dal, rajma, and chana improves amino acid balance.",
    bodyHi: "दाल, राजमा और चना साथ लेने से अमीनो एसिड प्रोफाइल बेहतर होता है।",
    bodyOd: "ଡାଲ, ରାଜମା ଏବଂ ଚଣା ମିଶାଇ ଖାଇଲେ ଆମିନୋ ଆମ୍ଲର ଗୁଣ ଉନ୍ନତ ହୋଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'indian_vegetables_fact_micronutrients_427',
    type: ContentType.fact,
    tags: ['indian_vegetables', 'micronutrients'],
    title: "Indian Veggies Are Nutrient Dense",
    body:
        "Bhindi, lauki, and brinjal offer vitamins and antioxidants beneficial for health.",
    bodyHi: "भिंडी, लौकी और बैंगन में विटामिन और एंटीऑक्सीडेंट भरपूर होते हैं।",
    bodyOd: "ଭିଣ୍ଡି, ଲାଉ ଏବଂ ବାଇଗଣରେ ପ୍ରଚୁର ଭିଟାମିନ୍ ଓ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଥାଏ।",
  ),
  WellnessContentModel(
    id: 'indian_fruits_tip_whole_428',
    type: ContentType.tip,
    tags: ['indian_fruits', 'fiber'],
    title: "Prefer Whole Fruits Over Juices",
    body:
        "Whole fruits retain fiber that helps digestion and prevents sugar spikes.",
    bodyHi: "जूस की बजाय साबुत फल लें क्योंकि इनमें फाइबर ज्यादा होता है।",
    bodyOd: "ରସ ପିବାଠାରୁ ସାବୁତ ଫଳ ଖାଇବା ଭଲ, କାରଣ ଏଥିରେ ଅଧିକ ଫାଇବର୍ ରହେ।",
  ),
  WellnessContentModel(
    id: 'spices_fact_turmeric_429',
    type: ContentType.fact,
    tags: ['spices', 'antiinflammatory'],
    title: "Turmeric Reduces Inflammation",
    body:
        "Curcumin in turmeric has scientifically proven anti-inflammatory properties.",
    bodyHi: "हल्दी में मौजूद करक्यूमिन सूजन कम करने में मदद करता है।",
    bodyOd: "ହଳଦୀରେ ଥିବା କର୍କୁମିନ୍ ଶୋଥ କମାଇବାରେ ପ୍ରମାଣିତ।",
  ),
  WellnessContentModel(
    id: 'nuts_seeds_tip_soaking_430',
    type: ContentType.tip,
    tags: ['nuts_seeds', 'digestion'],
    title: "Soak Nuts for Better Absorption",
    body:
        "Soaking almonds and walnuts improves nutrient absorption and reduces bloating.",
    bodyHi:
        "भीगे बादाम और अखरोट पोषक तत्वों के अवशोषण को बढ़ाते हैं और गैस कम करते हैं।",
    bodyOd: "ବାଦାମ ଓ ଆଖରଟ୍ ଭିଜାଇ ଖାଇଲେ ପୋଷକତତ୍ୱ ଭଲ ଭାବେ ଶୋଷିତ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'dairy_myth_weightgain_431',
    type: ContentType.myth,
    tags: ['dairy', 'weight_management'],
    title: "Myth: Dairy Always Causes Weight Gain",
    body:
        "Low-fat dairy supports muscle and bone health without excess calories.",
    bodyHi:
        "लो-फैट डेयरी वजन नहीं बढ़ाती बल्कि हड्डियों और मांसपेशियों के लिए बेहतर है।",
    bodyOd: "ଲୋ-ଫ୍ୟାଟ୍ ଡେୟରି ଓଜନ ବଢ଼ାଏ ନାହିଁ, ହାଡ଼ ଓ ପେଶୀ ପାଇଁ ଭଲ।",
  ),
  WellnessContentModel(
    id: 'millets_advice_diversify_432',
    type: ContentType.advice,
    tags: ['millets', 'meal_planning'],
    title: "Rotate Different Millets",
    body: "Mixing ragi, bajra, and jowar gives a better range of nutrients.",
    bodyHi:
        "रागी, बाजरा और ज्वार को बदल-बदलकर खाने से पोषण संतुलन अच्छा होता है।",
    bodyOd: "ରାଗି, ବାଜରା, ଝୋୟାର ପାଳେ ପାଳେ ଖାଇଲେ ପୂଷ୍ଟି ସନ୍ତୁଳନ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_tip_water_433',
    type: ContentType.tip,
    tags: ['weight_loss', 'hydration'],
    title: "Water Helps Control Cravings",
    body: "Hydrating regularly prevents mistaking thirst for hunger.",
    bodyHi: "पर्याप्त पानी पीना भूख और प्यास की गलतफहमी को रोकता है।",
    bodyOd: "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିଲେ ତ୍ରୁଷ୍ଣାକୁ ଭୋକ ଭାବି ଖାଇବା ବନ୍ଦ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_fact_strength_434',
    type: ContentType.fact,
    tags: ['weight_gain', 'exercise'],
    title: "Strength Training Helps Gain Mass",
    body:
        "Resistance workouts stimulate muscle growth, supporting healthy weight gain.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग मांसपेशियाँ बढ़ाती है और स्वस्थ वजन बढ़ाने में सहायक है।",
    bodyOd: "ଷ୍ଟ୍ରେଙ୍ଗ୍ଥ ଟ୍ରେନିଙ୍ଗ୍ ପେଶୀ ବୃଦ୍ଧି କରେ ଓ ସ୍ୱସ୍ଥ ଓଜନ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'metabolism_myth_fast_435',
    type: ContentType.myth,
    tags: ['metabolism', 'awareness'],
    title: "Myth: Fast Metabolism Alone Burns Fat",
    body:
        "Fat loss depends more on habits like diet, activity, and sleep—not metabolism alone.",
    bodyHi:
        "वजन कम करना सिर्फ मेटाबॉलिज्म पर नहीं बल्कि आदतों जैसे डाइट, गतिविधि और नींद पर निर्भर है।",
    bodyOd:
        "ଓଜନ କମିବା କେବଳ ମେଟାବୋଲିଜମ୍ ଉପରେ ନୁହେଁ, ଖାଦ୍ୟ, ଗତିବିଧି ଓ ଘୁମ ଉପରେ ନିର୍ଭର।",
  ),
  WellnessContentModel(
    id: 'appetite_control_fact_protein_436',
    type: ContentType.fact,
    tags: ['appetite_control', 'protein'],
    title: "Protein Keeps You Fuller Longer",
    body: "High-protein meals delay hunger by stabilizing blood sugar.",
    bodyHi:
        "प्रोटीन युक्त भोजन पेट लंबे समय तक भरा रखता है और ब्लड शुगर भी स्थिर करता है।",
    bodyOd: "ପ୍ରୋଟିନ୍ ଯୁକ୍ତ ଖାଦ୍ୟ ପେଟ ଅଧିକ ସମୟ ପର୍ଯ୍ୟନ୍ତ ଭରି ରଖେ।",
  ),
  WellnessContentModel(
    id: 'mental_health_tip_journaling_437',
    type: ContentType.tip,
    tags: ['mental_health', 'mindfulness'],
    title: "Try Journaling for Clarity",
    body: "Writing your thoughts reduces mental clutter and emotional stress.",
    bodyHi: "जर्नलिंग करने से मन में चल रही उलझन कम होती है और तनाव घटता है।",
    bodyOd: "ଜର୍ନାଲିଂ କଲେ ମନର ଅସ୍ଥିରତା କମେ ଓ ଚାପ ହ୍ରାସ ପାଏ।",
  ),
  WellnessContentModel(
    id: 'stress_tip_breathing_438',
    type: ContentType.tip,
    tags: ['stress', 'relaxation'],
    title: "Practice Slow Breathing",
    body:
        "Deep breathing activates the relaxation response, lowering stress quickly.",
    bodyHi: "धीमी और गहरी साँसें तनाव तेजी से कम करती हैं।",
    bodyOd: "ଧୀରେ ଗଭୀର ଶ୍ୱାସ ନେଲେ ଚାପ ତୁରନ୍ତ କମିଯାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_advice_caffeine_439',
    type: ContentType.advice,
    tags: ['sleep', 'lifestyle'],
    title: "Avoid Caffeine After Evening",
    body:
        "Caffeine stays in your system for hours and can disturb nighttime sleep.",
    bodyHi: "शाम के बाद कैफीन लेने से रात की नींद खराब हो सकती है।",
    bodyOd: "ସନ୍ଧ୍ୟା ପରେ କ୍ୟାଫେଇନ୍ ନେଲେ ରାତିର ଘୁମ ଭଙ୍ଗିଯାଇପାରେ।",
  ),
  WellnessContentModel(
    id: 'mood_fact_serotonin_440',
    type: ContentType.fact,
    tags: ['mood', 'hormones'],
    title: "Serotonin Regulates Mood",
    body:
        "Sunlight, movement, and balanced meals help increase serotonin naturally.",
    bodyHi:
        "धूप, गतिविधि और संतुलित भोजन से सेरोटोनिन प्राकृतिक रूप से बढ़ता है।",
    bodyOd: "ସୂର୍ଯ୍ୟ ଆଲୋକ, ଗତିବିଧି ଓ ସନ୍ତୁଳିତ ଖାଦ୍ୟ ସେରୋଟୋନିନ୍ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'food_grains_tip_milletmix_441',
    type: ContentType.tip,
    tags: ['food_grains', 'millets'],
    title: "Mix Millets with Rice or Wheat",
    body:
        "Combining millets adds fiber and nutrients without changing taste drastically.",
    bodyHi: "चावल या गेहूँ में थोड़ी मात्रा में मिलेट मिलाने से पोषण बढ़ता है।",
    bodyOd: "ଭାତ କିମ୍ବା ଗହମରେ ଥୋଡ଼ା ମିଲେଟ୍ ମିଶାଇଲେ ପୂଷ୍ଟି ବଢ଼େ।",
  ),
  WellnessContentModel(
    id: 'pulses_advice_digestive_442',
    type: ContentType.advice,
    tags: ['pulses', 'digestion'],
    title: "Soak Pulses for Easier Digestion",
    body: "Soaking reduces gas-forming compounds and improves absorption.",
    bodyHi:
        "दालें भिगोने से गैस बनने की संभावना कम होती है और पाचन बेहतर होता है।",
    bodyOd: "ଡାଲ ଭିଜାଇଲେ ଗ୍ୟାସ ହେବା କମେ ଏବଂ ପାଚନ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'indian_vegetables_myth_potato_443',
    type: ContentType.myth,
    tags: ['indian_vegetables', 'misconceptions'],
    title: "Myth: Potatoes Are Always Unhealthy",
    body: "Potatoes are nutritious when eaten boiled, baked, or in moderation.",
    bodyHi:
        "उबला या बेक्ड आलू पोषक होते हैं, समस्या सिर्फ तले हुए रूप में होती है।",
    bodyOd: "ଉବା ଅଥବା ବେକ୍ କରା ପିତାଳୁ ସ୍ୱସ୍ଥ; ତଳିଲେ ସମସ୍ୟା ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'indian_fruits_fact_antioxidants_444',
    type: ContentType.fact,
    tags: ['indian_fruits', 'antioxidants'],
    title: "Indian Fruits Are Antioxidant-Rich",
    body: "Jamun, amla, and mango protect cells from oxidative stress.",
    bodyHi: "जामुन, आँवला और आम एंटीऑक्सीडेंट से भरपूर होते हैं।",
    bodyOd: "ଜାମୁ, ଆଁଓଳା ଓ ଆମ୍ବ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟରେ ଧନୀ।",
  ),
  WellnessContentModel(
    id: 'spices_advice_cinnamon_445',
    type: ContentType.advice,
    tags: ['spices', 'blood_sugar'],
    title: "Use Cinnamon for Balance",
    body: "Cinnamon may help stabilize blood sugar when used moderately.",
    bodyHi:
        "दालचीनी सीमित मात्रा में लेने से ब्लड शुगर संतुलित रखने में मदद कर सकती है।",
    bodyOd:
        "ଦାଲଚିନି ସୀମିତ ମାତ୍ରାରେ ନେଲେ ରକ୍ତଶର୍କରା ସନ୍ତୁଳିତ ରହିବାକୁ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'nuts_seeds_fact_omega_446',
    type: ContentType.fact,
    tags: ['nuts_seeds', 'heart_health'],
    title: "Seeds Provide Omega-3",
    body:
        "Flaxseeds and chia seeds offer plant-based omega-3 that supports heart health.",
    bodyHi: "अलसी और चिया सीड्स पादप आधारित ओमेगा-3 प्रदान करते हैं।",
    bodyOd: "ଆଲସି ଓ ଚିଆ ବୀଜ ହୃଦୟ ପାଇଁ ଉପକାରୀ ଓମେଗା-3 ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'dairy_tip_fermented_447',
    type: ContentType.tip,
    tags: ['dairy', 'gut_health'],
    title: "Include Fermented Dairy",
    body: "Curd and buttermilk support gut bacteria and improve digestion.",
    bodyHi: "दही और छाछ आँतों के लिए लाभदायक होते हैं और पाचन बेहतर करते हैं।",
    bodyOd: "ଦହି ଓ ଛାସ୍ ଆନ୍ତ୍ରୀୟ ସ୍ୱାସ୍ଥ୍ୟ ପାଇଁ ଭଲ ଏବଂ ପାଚନ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'millets_fact_lowgi_448',
    type: ContentType.fact,
    tags: ['millets', 'energy'],
    title: "Millets Have a Low Glycemic Index",
    body:
        "They release energy slowly, making them great for steady blood sugar.",
    bodyHi:
        "मिलेट्स का ग्लाइसेमिक इंडेक्स कम होता है, जिससे ऊर्जा धीरे-धीरे मिलती है।",
    bodyOd: "ମିଲେଟ୍‌ର GI କମ୍ ଥାଏ, ଯାହା ଶରୀରକୁ ଧୀରେ ଶକ୍ତି ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_advice_steps_449',
    type: ContentType.advice,
    tags: ['weight_loss', 'activity'],
    title: "Aim for 7,000–10,000 Steps",
    body: "Daily steps help burn calories and maintain a healthy metabolism.",
    bodyHi:
        "7,000–10,000 कदम रोज़ चलना कैलोरी जलाने और मेटाबॉलिज्म के लिए फायदेमंद है।",
    bodyOd:
        "ଦିନକୁ 7,000–10,000 ପଦକ୍ଷେପ ହାଟିଲେ କ୍ୟାଲୋରୀ ଜଳେ ଓ ମେଟାବୋଲିଜମ୍ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'weight_gain_tip_oils_450',
    type: ContentType.tip,
    tags: ['weight_gain', 'healthy_fats'],
    title: "Add Healthy Oils",
    body:
        "Cold-pressed oils like sesame or groundnut add calories without extra volume.",
    bodyHi:
        "तिल और मूंगफली का कोल्ड-प्रेस्ड तेल स्वस्थ तरीके से कैलोरी बढ़ाता है।",
    bodyOd: "ତିଳ ବା ବାଦାମର କୋଲ୍ଡ୍-ପ୍ରେସ୍ଡ ତେଲ ସ୍ୱସ୍ଥ ଭାବେ କ୍ୟାଲୋରୀ ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'weight_loss_tip_451',
    type: ContentType.tip,
    tags: ['weight_loss', 'metabolism'],
    title: "Start Meals with Veggies",
    body:
        "Eating vegetables first increases fullness and reduces total calorie intake.",
    bodyHi:
        "सब्ज़ियों से भोजन शुरू करने से पेट जल्दी भरता है और कैलोरी सेवन कम होता है।",
    bodyOd: "ସବ୍ଜିରୁ ଭୋଜନ ଆରମ୍ଭ କଲେ ପେଟ ଶୀଘ୍ର ପୁରା ହୁଏ ଏବଂ କେଲୋରି କମ୍ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'weight_gain_fact_452',
    type: ContentType.fact,
    tags: ['weight_gain', 'protein'],
    title: "Muscle Gain Needs Protein",
    body:
        "Healthy weight gain relies on adequate protein to support muscle growth.",
    bodyHi:
        "स्वस्थ वजन बढ़ाने के लिए पर्याप्त प्रोटीन ज़रूरी है ताकि मांसपेशियाँ बन सकें।",
    bodyOd:
        "ସ୍ୱସ୍ଥ ଓଜନ ବୃଦ୍ଧି ପାଇଁ ପ୍ରୋଟିନ୍ ଆବଶ୍ୟକ, ଯାହା ମାଂସପେଶୀ ବିକାଶକୁ ସହାୟତା କରେ।",
  ),

  WellnessContentModel(
    id: 'metabolism_tip_453',
    type: ContentType.tip,
    tags: ['metabolism', 'hydration'],
    title: "Water Boosts Metabolism",
    body:
        "Staying hydrated can slightly increase metabolic rate and support fat burning.",
    bodyHi:
        "हाइड्रेटेड रहने से मेटाबॉलिज्म थोड़ा बढ़ता है और फैट बर्निंग में मदद मिलती है।",
    bodyOd: "ଜଳ ଶରୀରରେ ରହିଲେ ମେଟାବୋଲିଜମ୍ କିଛି ବଢ଼େ ଏବଂ ଚର୍ବି ଘଟିବାରେ ସହଯୋଗ କରେ।",
  ),

  WellnessContentModel(
    id: 'appetite_control_myth_454',
    type: ContentType.myth,
    tags: ['appetite_control', 'general'],
    title: "Myth: Skipping Meals Reduces Hunger",
    body: "Skipping meals often increases cravings and overeating later.",
    bodyHi:
        "मील्स स्किप करना भूख कम नहीं करता, बल्कि बाद में क्रेविंग और ओवरईटिंग बढ़ाता है।",
    bodyOd: "ଖାଦ୍ୟ ଛାଡ଼ିବାରୁ ଭୋକ କମେ ନାହିଁ; ପରେ ଅଧିକ ଖାଇବା ଓ ଇଚ୍ଛା ବଢ଼େ।",
  ),

  WellnessContentModel(
    id: 'mental_health_fact_455',
    type: ContentType.fact,
    tags: ['mental_health', 'mood'],
    title: "Mood Affects Eating",
    body: "Stress and sadness can trigger emotional eating and cravings.",
    bodyHi: "तनाव और उदासी भावनात्मक खाने और क्रेविंग को बढ़ा सकती है।",
    bodyOd: "ଚାପ ଏବଂ ଦୁଃଖ ଭାବନାତ୍ମକ ଖାଦ୍ୟ ସେବନ ଓ ଇଚ୍ଛାକୁ ବଢ଼ାଇପାରେ।",
  ),

  WellnessContentModel(
    id: 'stress_advice_456',
    type: ContentType.advice,
    tags: ['stress', 'mental_health'],
    title: "Try Micro-Breaks",
    body:
        "Taking 2-3 minute breaks during work reduces stress and improves focus.",
    bodyHi:
        "काम के दौरान 2–3 मिनट के छोटे ब्रेक तनाव कम करते हैं और ध्यान बेहतर बनाते हैं।",
    bodyOd: "କାମ ସମୟରେ 2–3 ମିନିଟ୍ ବିରତି ନେଲେ ଚାପ କମେ ଏବଂ କେନ୍ଦ୍ରୀକରଣ ଭଳି ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'sleep_tip_457',
    type: ContentType.tip,
    tags: ['sleep', 'mental_health'],
    title: "Limit Screens Before Bed",
    body: "Avoiding screens 60 minutes before sleep improves sleep quality.",
    bodyHi:
        "सोने से 60 मिनट पहले स्क्रीन बंद करने से नींद की गुणवत्ता बेहतर होती है।",
    bodyOd: "ଶୋଇବା ପୂର୍ବରୁ 60 ମିନିଟ୍ ସ୍କ୍ରିନ୍ ବନ୍ଦ କଲେ ଘୁମର ଗୁଣତ୍ୱ ଉନ୍ନତି ପାଏ।",
  ),

  WellnessContentModel(
    id: 'mood_fact_458',
    type: ContentType.fact,
    tags: ['mood', 'mental_health'],
    title: "Sunlight Lifts Mood",
    body:
        "Even 10 minutes of morning sunlight can improve mood-regulating hormones.",
    bodyHi: "सुबह की 10 मिनट धूप मूड को बेहतर करने वाले हार्मोन बढ़ाती है।",
    bodyOd:
        "ସକାଳ 10 ମିନିଟ୍ ସୂର୍ଯ୍ୟାଲୋକ ମନୋଭାବ ଉନ୍ନତି କରୁଥିବା ହରମୋନ୍ କୁ ବଢ଼ାଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'food_grains_tip_459',
    type: ContentType.tip,
    tags: ['food_grains', 'fiber'],
    title: "Choose Whole Grains",
    body: "Whole grains improve digestion and help control appetite.",
    bodyHi: "साबुत अनाज पाचन सुधारते हैं और भूख को नियंत्रण में मदद करते हैं।",
    bodyOd: "ସମ୍ପୂର୍ଣ୍ଣ ଅନାଜ ପାଚନ ଭଲ କରେ ଏବଂ ଭୋକ ନିୟନ୍ତ୍ରଣରେ ସହାୟକ।",
  ),

  WellnessContentModel(
    id: 'pulses_fact_460',
    type: ContentType.fact,
    tags: ['pulses', 'protein'],
    title: "Pulses Are Protein-Rich",
    body:
        "Lentils and beans provide plant-based protein ideal for weight goals.",
    bodyHi: "दालें और बीन्स पौधा-आधारित प्रोटीन का बेहतरीन स्रोत हैं।",
    bodyOd: "ଡାଲି ଏବଂ ବିନ୍ସ ଉଦ୍ଭିଦ ଆଧାରିତ ପ୍ରୋଟିନ୍ର ଭଲ ସ୍ରୋତ।",
  ),

  WellnessContentModel(
    id: 'indian_vegetables_tip_461',
    type: ContentType.tip,
    tags: ['indian_vegetables', 'fiber'],
    title: "Add One Green Veg Daily",
    body: "Leafy vegetables support digestion and reduce cravings.",
    bodyHi:
        "रोज़ एक हरी सब्ज़ी शामिल करना पाचन सुधारता है और क्रेविंग घटाता है।",
    bodyOd: "ପ୍ରତିଦିନ ଗୋଟିଏ ହରିତ ସବ୍ଜି ଖାଇଲେ ପାଚନ ଭଲ ହୁଏ ଏବଂ ଇଚ୍ଛା କମେ।",
  ),

  WellnessContentModel(
    id: 'indian_fruits_fact_462',
    type: ContentType.fact,
    tags: ['indian_fruits', 'vitamins'],
    title: "Seasonal Fruits = Better Nutrition",
    body:
        "Seasonal fruits often contain more antioxidants and higher vitamin levels.",
    bodyHi: "मौसमी फल ज़्यादा एंटीऑक्सीडेंट और विटामिन प्रदान करते हैं।",
    bodyOd: "ଋତୁକାଳୀନ ଫଳରେ ଅଧିକ ଆନ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଏବଂ ଭିଟାମିନ୍ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'spices_myth_463',
    type: ContentType.myth,
    tags: ['spices', 'metabolism'],
    title: "Myth: Spices Burn Major Fat",
    body:
        "Spices may slightly boost metabolism but cannot replace healthy eating.",
    bodyHi:
        "मसाले मेटाबॉलिज्म थोड़ा बढ़ाते हैं लेकिन वजन घटाने का बड़ा तरीका नहीं हैं।",
    bodyOd:
        "ମସଲା ମେଟାବୋଲିଜମ୍ କିଛି ବଢ଼ାଇପାରେ, କିନ୍ତୁ ଗୁରୁତ୍ୱପର୍ଣ୍ଣ ଚର୍ବି ଘଟିବାର ଉପାୟ ନୁହେଁ।",
  ),

  WellnessContentModel(
    id: 'nuts_seeds_tip_464',
    type: ContentType.tip,
    tags: ['nuts_seeds', 'healthy_fats'],
    title: "Eat Nuts in Small Portions",
    body:
        "Nuts provide good fats but are calorie-dense, so small servings work best.",
    bodyHi:
        "मेवे अच्छे फैट देते हैं पर कैलोरी अधिक होती है, इसलिए कम मात्रा में खाएँ।",
    bodyOd: "ନଟ୍ସ ଭଲ ଚର୍ବି ଦେଇଥାଏ କିନ୍ତୁ କେଲୋରି ଅଧିକ, ସେଥିପାଇଁ ଛୋଟ ପରିମାଣ ଭଲ।",
  ),

  WellnessContentModel(
    id: 'dairy_fact_465',
    type: ContentType.fact,
    tags: ['dairy', 'protein'],
    title: "Dairy Supports Bone Health",
    body: "Milk and curd offer calcium and protein essential for bones.",
    bodyHi: "दूध और दही हड्डियों के लिए ज़रूरी कैल्शियम और प्रोटीन देते हैं।",
    bodyOd: "ଦୁଧ ଏବଂ ଦହି ହାଡ଼ ପାଇଁ ଆବଶ୍ୟକ କ୍ୟାଲସିୟମ୍ ଓ ପ୍ରୋଟିନ୍ ଯୋଗାଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'millets_tip_466',
    type: ContentType.tip,
    tags: ['millets', 'fiber'],
    title: "Include Millets Twice a Week",
    body: "Millets improve digestion and keep blood sugar steady.",
    bodyHi:
        "हफ्ते में दो बार मिलेट्स खाने से पाचन सुधरता है और ब्लड शुगर स्थिर रहती है।",
    bodyOd: "ସପ୍ତାହେ ଦୁଇଥର ମିଲେଟ୍ ଖାଇଲେ ପାଚନ ଭଲ ହୁଏ ଏବଂ ରକ୍ତସର୍କରା ସ୍ଥିର ରହେ।",
  ),

  WellnessContentModel(
    id: 'weight_loss_fact_467',
    type: ContentType.fact,
    tags: ['weight_loss', 'fiber'],
    title: "Fiber Reduces Hunger Naturally",
    body: "High-fiber meals slow digestion and keep you fuller for longer.",
    bodyHi: "फाइबर युक्त भोजन पाचन धीमा करता है और पेट लंबे समय तक भरा रखता है।",
    bodyOd: "ଅଧିକ ଫାଇବର ଭୋଜନ ପାଚନ ଧୀର କରେ ଏବଂ ଦୀର୍ଘ ସମୟ ପାଇଁ ପେଟ ଭରା ରଖେ।",
  ),

  WellnessContentModel(
    id: 'weight_gain_tip_468',
    type: ContentType.tip,
    tags: ['weight_gain', 'healthy_fats'],
    title: "Add Healthy Calorie Boosters",
    body: "Peanut butter, ghee, and nuts help increase calories safely.",
    bodyHi:
        "पीनट बटर, घी और मेवे सुरक्षित रूप से कैलोरी बढ़ाने में मदद करते हैं।",
    bodyOd: "ପିନଟ ବଟର, ଘିଅ ଏବଂ ନଟ୍ସ ସୁରକ୍ଷାପୂର୍ବକ କେଲୋରି ବଢ଼ାଇବାରେ ସହାୟକ।",
  ),

  WellnessContentModel(
    id: 'metabolism_fact_469',
    type: ContentType.fact,
    tags: ['metabolism', 'muscle_health'],
    title: "Muscle Mass Raises Metabolism",
    body: "More muscle pushes your body to burn more calories daily.",
    bodyHi: "मांसपेशियों की मात्रा बढ़ने से शरीर रोज़ अधिक कैलोरी जलाता है।",
    bodyOd: "ମାଂସପେଶୀ ବଢ଼ିଲେ ଶରୀର ପ୍ରତିଦିନ ଅଧିକ କେଲୋରି ଖର୍ଚ୍ଚ କରେ।",
  ),

  WellnessContentModel(
    id: 'appetite_control_tip_470',
    type: ContentType.tip,
    tags: ['appetite_control', 'protein'],
    title: "Add Protein to Every Meal",
    body: "Protein stabilizes hunger and reduces overeating.",
    bodyHi:
        "हर भोजन में प्रोटीन शामिल करने से भूख नियंत्रित रहती है और ओवरईटिंग कम होती है।",
    bodyOd: "ପ୍ରତି ଭୋଜନରେ ପ୍ରୋଟିନ୍ ରଖିଲେ ଭୋକ ନିୟନ୍ତ୍ରିତ ହୁଏ ଏବଂ ଅଧିକ ଖାଇବା କମେ।",
  ),

  WellnessContentModel(
    id: 'mental_health_tip_471',
    type: ContentType.tip,
    tags: ['mental_health', 'stress'],
    title: "Practice Mindful Breathing",
    body: "Slow breathing reduces stress signals and calms the mind.",
    bodyHi: "धीमी और गहरी सांसें तनाव कम करती हैं और मन को शांत करती हैं।",
    bodyOd: "ଧୀର ଏବଂ ଗଭୀର ଶ୍ୱାସ ଚାପ କମାଇ ମନକୁ ସାନ୍ତ କରେ।",
  ),

  WellnessContentModel(
    id: 'sleep_fact_472',
    type: ContentType.fact,
    tags: ['sleep', 'hormones'],
    title: "Poor Sleep Raises Hunger Hormones",
    body: "Lack of sleep increases ghrelin, making you feel hungrier.",
    bodyHi: "कम नींद से घ्रेलिन हार्मोन बढ़ता है जिससे ज़्यादा भूख लगती है।",
    bodyOd: "ଘୁମ କମ୍ ହେଲେ ଘ୍ରେଲିନ୍ ବଢ଼େ ଏବଂ ଅଧିକ ଭୋକ ଲାଗେ।",
  ),

  WellnessContentModel(
    id: 'mood_tip_473',
    type: ContentType.tip,
    tags: ['mood', 'mental_health'],
    title: "Use Music Therapy",
    body: "Listening to calming music can lift mood and reduce anxiety.",
    bodyHi: "शांत संगीत सुनना मूड बेहतर करता है और चिंता कम करता है।",
    bodyOd: "ଶାନ୍ତ ସଙ୍ଗୀତ ଶୁଣିଲେ ମନୋଭାବ ଭଲ ହୁଏ ଏବଂ ଚିନ୍ତା କମେ।",
  ),

  WellnessContentModel(
    id: 'food_grains_fact_474',
    type: ContentType.fact,
    tags: ['food_grains', 'energy'],
    title: "Carbs Fuel the Brain",
    body: "Whole grains provide steady energy for brain function.",
    bodyHi: "साबुत अनाज मस्तिष्क के लिए स्थिर ऊर्जा प्रदान करते हैं।",
    bodyOd: "ସମ୍ପୂର୍ଣ୍ଣ ଅନାଜ ମସ୍ତିଷ୍କ ପାଇଁ ସ୍ଥିର ଶକ୍ତି ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'pulses_tip_475',
    type: ContentType.tip,
    tags: ['pulses', 'fiber'],
    title: "Mix Your Dals",
    body: "Combining different lentils boosts nutrient diversity.",
    bodyHi: "विभिन्न दालें मिलाकर खाने से पोषक तत्वों की विविधता बढ़ती है।",
    bodyOd: "ଭିନ୍ନ ଡାଲି ମିଶାଇ ଖାଇଲେ ପୋଷକତତ୍ତ୍ୱର ବିଭିନ୍ନତା ବଢ଼େ।",
  ),
  WellnessContentModel(
    id: 'millets_fact_lowgi_476',
    type: ContentType.fact,
    tags: ['millets', 'glycemic_index'],
    title: "Millets Have a Naturally Low GI",
    body:
        "Millets release glucose slowly, helping maintain steady blood sugar and preventing energy crashes.",
    bodyHi:
        "बाजरा, रागी और अन्य मिलेट्स का ग्लाइसेमिक इंडेक्स कम होता है, जिससे ग्लूकोज़ धीरे-धीरे रिलीज़ होता है और ऊर्जा स्थिर बनी रहती है।",
    bodyOd:
        "ମିଲେଟ୍‍ସର ଗ୍ଲାଇସେମିକ୍ ଇଣ୍ଡେକ୍ସ କମ୍ ଥାଏ, ଯାହା ରକ୍ତରେ ସ୍ଲୋ-ରିଲିଜ୍ ଗ୍ଲୁକୋଜ ପ୍ରଦାନ କରେ ଏବଂ ଏନର୍ଜିକୁ ସ୍ଥିର ରଖେ।",
  ),

  WellnessContentModel(
    id: 'millets_tip_breakfastswap_477',
    type: ContentType.tip,
    tags: ['millets', 'breakfast'],
    title: "Swap Breakfast for Millets",
    body:
        "Replacing refined grains with millet-based breakfast can boost fiber and improve metabolism.",
    bodyHi:
        "रिफाइंड अनाज की जगह मिलेट्स वाला नाश्ता लेने से फाइबर बढ़ता है और मेटाबॉलिज़्म में सुधार आता है।",
    bodyOd:
        "ରିଫାଇନ୍ ଗ୍ରେନ୍ ପ୍ରତିଯୋଗୀ ମିଲେଟ୍ ଭିତ୍ତିକ ଛାକୁ ପ୍ରୟୋଗ କରିଲେ ଫାଇବର ବଢ଼େ ଏବଂ ମେଟାବଲିଜ୍ମ ଭଲ ହୋଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'millets_advice_portioncontrol_478',
    type: ContentType.advice,
    tags: ['millets', 'portion'],
    title: "Watch Millet Portions",
    body:
        "Millets are healthy but still caloric; keep portions moderate to support healthy weight.",
    bodyHi:
        "मिलेट्स पौष्टिक होते हैं लेकिन कैलोरी युक्त भी, इसलिए वजन नियंत्रित रखने के लिए पोर्शन संतुलित रखें।",
    bodyOd:
        "ମିଲେଟ୍ ସ୍ୱାସ୍ଥ୍ୟକର ହେଲେ ମଧ୍ୟ କ୍ୟାଲୋରି ରହିଥାଏ, ସେଥିପାଇଁ ୱେଟ୍ କଣ୍ଟ୍ରୋଲ ପାଇଁ ପୋର୍ଷନ୍ ସଠିକ୍ ରଖନ୍ତୁ।",
  ),

  WellnessContentModel(
    id: 'dairy_fact_proteinrich_479',
    type: ContentType.fact,
    tags: ['dairy', 'protein'],
    title: "Dairy is a Strong Protein Source",
    body:
        "Curd, paneer, and milk provide complete protein with all essential amino acids.",
    bodyHi:
        "दही, पनीर और दूध पूर्ण प्रोटीन प्रदान करते हैं, जिसमें सभी आवश्यक अमीनो एसिड होते हैं।",
    bodyOd:
        "ଦହି, ପନିର ଓ ଦୁଧ ପୂର୍ଣ୍ଣ ପ୍ରୋଟିନ୍ ଦେଇଥାଏ, ଯେଉଁଥିରେ ସମସ୍ତ ଆବଶ୍ୟକ ଆମିନୋ ଏସିଡ୍ ରହେ।",
  ),

  WellnessContentModel(
    id: 'dairy_tip_lactoseintolerance_480',
    type: ContentType.tip,
    tags: ['dairy', 'digestion'],
    title: "Try Curd If Milk Upsets Your Stomach",
    body:
        "Curd is easier to digest than milk and often better tolerated by people with mild lactose intolerance.",
    bodyHi:
        "दूध से असहजता हो तो दही का सेवन करें, यह पचने में आसान होता है और हल्की लैक्टोज असहिष्णुता में भी अनुकूल रहता है।",
    bodyOd:
        "ଦୁଧ ଜୀର୍ଣ୍ଣ ନହେଲେ ଦହି ଖାନ୍ତୁ, ଏହା ସହଜରେ ପଚେ ଏବଂ ହାଲୁକା ଲ୍ୟାକ୍ଟୋଜ୍ ସମସ୍ୟାରେ ଭଲ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'dairy_myth_weightgain_481',
    type: ContentType.myth,
    tags: ['dairy', 'weight_gain'],
    title: "Myth: Dairy Always Causes Weight Gain",
    body:
        "Moderate dairy intake does not cause weight gain and can actually support muscle mass.",
    bodyHi:
        "मिथक: डेयरी हमेशा वजन बढ़ाती है। तथ्य: संतुलित मात्रा में डेयरी लेने से वजन नहीं बढ़ता और मांसपेशियों को समर्थन मिलता है।",
    bodyOd:
        "ମିଥ୍: ଡେରି ସଦା ୱେଟ୍ ବଢ଼ାଏ। ସତ୍ୟ: ସଠିକ୍ ପରିମାଣରେ ଡେରି ଖାଲେ ଯୌଜନ୍ ବଢ଼େ ନାହିଁ, ବରଂ ମାଂସପେଶୀକୁ ସାହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'dairy_knowledge_calciumabsorption_482',
    type: ContentType.knowledge,
    tags: ['dairy', 'calcium'],
    title: "Dairy Absorbs Better Than Supplements",
    body:
        "Natural calcium from dairy is absorbed more efficiently than calcium tablets.",
    bodyHi:
        "डेयरी से मिलने वाला प्राकृतिक कैल्शियम सप्लीमेंट की तुलना में शरीर द्वारा बेहतर अवशोषित किया जाता है।",
    bodyOd:
        "ଡେରିର ପ୍ରାକୃତିକ କାଲସିୟମ୍ ସପ୍ଲିମେଣ୍ଟ ତୁଳନାରେ ଦେହେ ଅଧିକ ଭାବରେ ଅବଶୋଷଣ କରେ।",
  ),

  WellnessContentModel(
    id: 'nuts_seeds_fact_omegarich_483',
    type: ContentType.fact,
    tags: ['nuts_seeds', 'omega_3'],
    title: "Nuts & Seeds Contain Healthy Omega Fats",
    body:
        "Flaxseed, walnuts, and chia are rich in omega-3 fats that support heart and brain health.",
    bodyHi:
        "अलसी, अखरोट और चिया ओमेगा-3 वसा से भरपूर होते हैं, जो हृदय और मस्तिष्क के स्वास्थ्य को समर्थन देते हैं।",
    bodyOd:
        "ଫ୍ଲାକ୍ସସିଡ୍, ଆଖରୋଟ୍ ଓ ଚିଆରେ ଓମେଗା-3 ଫାଟ୍ ଥାଏ ଯାହା ହୃଦୟ ଓ ମଗଜ ସ୍ୱାସ୍ଥ୍ୟ ପାଇଁ ଉପକାରୀ।",
  ),

  WellnessContentModel(
    id: 'nuts_seeds_tip_snacksmart_484',
    type: ContentType.tip,
    tags: ['nuts_seeds', 'snacking'],
    title: "Use Nuts for Smart Snacking",
    body:
        "A handful of nuts can curb cravings, provide protein, and keep your energy steady.",
    bodyHi:
        "नट्स की छोटी मुट्ठी भूख को नियंत्रित करती है, प्रोटीन देती है और ऊर्जा स्थिर रखती है।",
    bodyOd:
        "ଏକ ମୁଠି ନଟ୍ ସ୍ନାକ୍ ଇଚ୍ଛା ହ୍ରାସ କରେ, ପ୍ରୋଟିନ୍ ଦେଇଥାଏ ଏବଂ ଏନର୍ଜିକୁ ସ୍ଥିର ରଖେ।",
  ),

  WellnessContentModel(
    id: 'nuts_seeds_myth_fatty_485',
    type: ContentType.myth,
    tags: ['nuts_seeds', 'fat'],
    title: "Myth: Nuts Make You Fat",
    body:
        "Nuts contain healthy fats and, when eaten in moderation, support weight control.",
    bodyHi:
        "मिथक: नट्स वजन बढ़ाते हैं। सत्य: संतुलित मात्रा में नट्स खाने से वजन नहीं बढ़ता, बल्कि हेल्दी फैट वजन प्रबंधन में सहयोग करते हैं।",
    bodyOd:
        "ମିଥ୍: ନଟ୍ ସ୍ଥୂଳ କରେ। ସତ୍ୟ: ସୀମିତ ପରିମାଣରେ ତାହା ଖାଲେ ହେଲ୍ଥି ଫାଟ୍ ଯୌଜନ୍ ନିୟନ୍ତ୍ରଣକୁ ସହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'spices_fact_antioxidants_486',
    type: ContentType.fact,
    tags: ['spices', 'immunity'],
    title: "Indian Spices Are Powerful Antioxidants",
    body:
        "Turmeric, cinnamon, and cloves reduce inflammation and boost immunity.",
    bodyHi:
        "हल्दी, दालचीनी और लौंग में प्रबल एंटीऑक्सीडेंट होते हैं जो सूजन कम करते हैं और प्रतिरक्षा बढ़ाते हैं।",
    bodyOd:
        "ହଳଦି, ଦାଲଚିନି ଓ ଲବଙ୍ଗରେ ଶକ୍ତିଶାଳୀ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଥାଏ ଯାହା ସୁଜ ହ୍ରାସ କରେ ଓ ଇମ୍ୟୁନିଟି ବଢ଼ାଏ।",
  ),

  WellnessContentModel(
    id: 'spices_tip_digestiveboost_487',
    type: ContentType.tip,
    tags: ['spices', 'digestion'],
    title: "Use Spices to Boost Digestion",
    body: "Jeera, ajwain, and ginger soothe the gut and reduce bloating.",
    bodyHi:
        "जीरा, अजवाइन और अदरक पाचन को मजबूत बनाते हैं और पेट फूलना कम करते हैं।",
    bodyOd: "ଜିରା, ଅଜୱଇନ୍ ଓ ଅଦା ପାଚନ ସୁଧାରେ ଏବଂ ଗ୍ୟାସ୍ ହ୍ରାସ କରେ।",
  ),

  WellnessContentModel(
    id: 'spices_myth_spicyunhealthy_488',
    type: ContentType.myth,
    tags: ['spices', 'diet'],
    title: "Myth: Spicy Food is Always Unhealthy",
    body: "Spices in moderate amounts support metabolism and digestive health.",
    bodyHi:
        "मिथक: मसालेदार भोजन हमेशा हानिकारक होता है। तथ्य: सीमित मात्रा में मसाले मेटाबॉलिज़्म और पाचन में लाभकारी होते हैं।",
    bodyOd:
        "ମିଥ୍: ଜ୍ୱଳନୀୟ ଖାଦ୍ୟ ସଦା ଖରାପ। ସତ୍ୟ: ସୀମିତ ମସଲା ମେଟାବଲିଜ୍ମ ଓ ପାଚନରେ ଉପକାରୀ।",
  ),

  WellnessContentModel(
    id: 'indian_fruits_fact_micronutrients_489',
    type: ContentType.fact,
    tags: ['indian_fruits', 'vitamins'],
    title: "Indian Fruits Are Packed With Micronutrients",
    body:
        "Amla, papaya, banana, and guava provide vitamin C, folate, potassium, and antioxidants.",
    bodyHi:
        "आंवला, पपीता, केला और अमरूद विटामिन C, फोलेट, पोटैशियम और एंटीऑक्सीडेंट से भरपूर होते हैं।",
    bodyOd:
        "ଆଁଳା, ପପିତା, କଦଳୀ ଓ ପେରାରେ ଭିଟାମିନ୍ C, ଫୋଲେଟ୍, ପଟାସିଅମ୍ ଓ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'indian_fruits_tip_substituterefined_490',
    type: ContentType.tip,
    tags: ['indian_fruits', 'snacking'],
    title: "Replace Sweets With Fruits",
    body:
        "Using fruits as snacks satisfies sweet cravings while adding fiber and vitamins.",
    bodyHi:
        "स्नैक्स में फलों का उपयोग मीठा खाने की इच्छा को कम करता है और फाइबर व विटामिन प्रदान करता है।",
    bodyOd:
        "ସ୍ନାକ୍ ସ୍ୱରୂପ ଫଳ ଖାଇବା ମିଠା ଇଚ୍ଛା କମେ ଏବଂ ଫାଇବର ଓ ଭିଟାମିନ୍ ଦେଇଥାଏ।",
  ),

  WellnessContentModel(
    id: 'indian_fruits_myth_sugarhigh_491',
    type: ContentType.myth,
    tags: ['indian_fruits', 'sugar'],
    title: "Myth: Fruits Are 'Too Sugary'",
    body:
        "Fruit sugar comes with fiber, vitamins, and antioxidants that slow absorption and support health.",
    bodyHi:
        "मिथक: फल बहुत मीठे होते हैं। सत्य: फलों में मौजूद शुगर फाइबर, विटामिन और एंटीऑक्सीडेंट के साथ आती है, जिससे अवशोषण धीमा होता है।",
    bodyOd:
        "ମିଥ୍: ଫଳରେ ଅଧିକ ଚିନି। ସତ୍ୟ: ଫଳରେ ଥିବା ଚିନି ଫାଇବର ଓ ପୋଷକତତ୍ୱ ସହିତ ଥାଏ, ଯାହା ଶୋଷଣ ସ୍ଲୋ କରେ।",
  ),

  WellnessContentModel(
    id: 'indian_vegetables_fact_phytochemicals_492',
    type: ContentType.fact,
    tags: ['indian_vegetables', 'antioxidants'],
    title: "Indian Vegetables Are Rich in Phytochemicals",
    body:
        "Brinjal, okra, and bottle gourd support gut, liver, and heart health.",
    bodyHi:
        "बैंगन, भिंडी और लौकी महत्वपूर्ण फ़ाइटोकेमिकल्स से भरपूर होते हैं, जो आंत, यकृत और हृदय के स्वास्थ्य में मदद करते हैं।",
    bodyOd:
        "ବାଇଗଣ, ଭିଣ୍ଡି ଓ ଲାଉରେ ଫାଇଟୋକେମିକାଲ୍ ଥାଏ ଯାହା ଆନ୍ତ୍ର, ଯକୃତ ଓ ହୃଦୟ ପାଇଁ ଭଲ।",
  ),

  WellnessContentModel(
    id: 'indian_vegetables_tip_mixcolors_493',
    type: ContentType.tip,
    tags: ['indian_vegetables', 'diet'],
    title: "Eat a Mix of Colors Daily",
    body:
        "Different colored vegetables supply different vitamins and antioxidants for immunity and energy.",
    bodyHi:
        "रंग-बिरंगी सब्जियाँ रोज़ खाने से अलग-अलग विटामिन और एंटीऑक्सीडेंट मिलते हैं, जिससे ऊर्जा और प्रतिरक्षा बढ़ती है।",
    bodyOd:
        "ବିଭିନ୍ନ ରଙ୍ଗର ସବ୍ଜି ରୋଜ୍ ଖାଇଲେ ଅନେକ ଭିଟାମିନ୍ ଓ ଆଣ୍ଟିଅକ୍ସିଡେଣ୍ଟ ମିଳେ, ଯାହା ଇମ୍ୟୁନିଟି ଓ ଏନର୍ଜିକୁ ବଢ଼ାଏ।",
  ),

  WellnessContentModel(
    id: 'indian_vegetables_advice_foodsynergy_494',
    type: ContentType.advice,
    tags: ['indian_vegetables', 'nutrition'],
    title: "Pair Vegetables With Healthy Fats",
    body:
        "Cooking vegetables with small amounts of ghee or oil improves absorption of fat-soluble vitamins.",
    bodyHi:
        "सब्जियों को थोड़ी मात्रा में घी या तेल के साथ पकाने से वसा-घुलनशील विटामिनों का अवशोषण बढ़ता है।",
    bodyOd:
        "ସବ୍ଜିକୁ ଥୋଡ଼ା ଘିଅ କିମ୍ବା ତେଲରେ ରାନ୍ଧିଲେ ଫ୍ୟାଟ୍-ସଲ୍ୟୁବଲ୍ ଭିଟାମିନ୍ ଶୋଷଣ ଭଲ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'pulses_fact_completeprotein_combo_495',
    type: ContentType.fact,
    tags: ['pulses', 'protein'],
    title: "Pulses Make a Complete Protein When Combined With Grains",
    body:
        "Dal-rice and khichdi offer all essential amino acids needed for muscle repair.",
    bodyHi:
        "दाल-चावल और खिचड़ी मिलकर पूर्ण प्रोटीन प्रदान करते हैं, जो मांसपेशियों की मरम्मत के लिए आवश्यक होते हैं।",
    bodyOd:
        "ଡାଲି-ଭାତ ଓ ଖିଚୁଡ଼ି ଏକାସାଥି ଖାଇଲେ ପୂର୍ଣ୍ଣ ପ୍ରୋଟିନ୍ ମିଳେ ଯାହା ମାଂସପେଶୀ ପୁନର୍ନିର୍ମାଣ ପାଇଁ ଆବଶ୍ୟକ।",
  ),

  WellnessContentModel(
    id: 'pulses_tip_soaking_496',
    type: ContentType.tip,
    tags: ['pulses', 'digestion'],
    title: "Soak Pulses for Better Digestion",
    body:
        "Soaking reduces cooking time and makes pulses gentler on the stomach.",
    bodyHi:
        "दालों को भिगोने से वे जल्दी पकती हैं और पाचन में भी आसान होती हैं।",
    bodyOd: "ଡାଲି ଭିଜାଇଲେ ସେଗୁଡିକ ଶୀଘ୍ର ପକେ ଏବଂ ଜୀର୍ଣ୍ଣ କରିବା ହେଉଛି ସହଜ।",
  ),

  WellnessContentModel(
    id: 'pulses_myth_gastric_497',
    type: ContentType.myth,
    tags: ['pulses', 'bloating'],
    title: "Myth: Pulses Always Cause Gas",
    body: "Proper soaking and cooking minimize gas and improve digestibility.",
    bodyHi:
        "मिथक: दाल हमेशा गैस बनाती है। तथ्य: सही तरह से भिगोना और पकाना गैस की समस्या को काफी कम करता है।",
    bodyOd:
        "ମିଥ୍: ଡାଲି ସଦା ଗ୍ୟାସ୍ କରେ। ସତ୍ୟ: ଭଲଭାବେ ଭିଜାଇ ଓ ପକାଇଲେ ଗ୍ୟାସ୍ ସମସ୍ୟା କମେ।",
  ),

  WellnessContentModel(
    id: 'food_grains_fact_fiberbenefit_498',
    type: ContentType.fact,
    tags: ['food_grains', 'fiber'],
    title: "Whole Grains Improve Gut Health",
    body:
        "Rotis made from whole wheat, jowar, or bajra improve bowel movement and satiety.",
    bodyHi:
        "गेहूँ, ज्वार या बाजरे के आटे से बनी रोटियाँ पाचन में सुधार करती हैं और पेट भरा हुआ महसूस कराती हैं।",
    bodyOd:
        "ଗହମ୍, ଝୋଡ଼ ଓ ମିଲେଟ୍ ରୋଟି ଆନ୍ତ୍ର ସ୍ୱାସ୍ଥ୍ୟ ସୁଧାରେ ଏବଂ ପେଟ ଭରା ଅନୁଭବ ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'food_grains_tip_halfswap_499',
    type: ContentType.tip,
    tags: ['food_grains', 'diet'],
    title: "Swap Half Your Grains for Whole Grains",
    body:
        "Replacing 50% refined grains with whole grains boosts fiber and supports weight control.",
    bodyHi:
        "अपने आहार में 50% रिफाइंड अनाज की जगह साबुत अनाज शामिल करने से फाइबर बढ़ता है और वजन नियंत्रित रहता है।",
    bodyOd:
        "ଆହାରରେ 50% ରିଫାଇନ୍ ଗ୍ରେନ୍ ପରିବର୍ତ୍ତେ ସାବୁତ ଗ୍ରେନ୍ ଯୋଡିଲେ ଫାଇବର ବଢ଼େ ଏବଂ ୱେଟ୍ କଣ୍ଟ୍ରୋଲ ହୁଏ।",
  ),

  WellnessContentModel(
    id: 'food_grains_advice_balancedplate_500',
    type: ContentType.advice,
    tags: ['food_grains', 'balanced_diet'],
    title: "Keep Grains to One-Quarter of Your Plate",
    body:
        "Balancing grains with vegetables and protein ensures steady energy and prevents overeating.",
    bodyHi:
        "अपने भोजन में अनाज को प्लेट के केवल एक-चौथाई हिस्से तक सीमित रखें ताकि ऊर्जा संतुलित रहे और ओवरईटिंग न हो।",
    bodyOd:
        "ପ୍ଲେଟର ଚତୁର୍ଥାଂଶ ଭାଗକୁ ମାତ୍ର ଅନାଜ ଦିଅନ୍ତୁ, ବାକିଟାକୁ ସବ୍ଜି ଓ ପ୍ରୋଟିନ୍ ରଖନ୍ତୁ। ଏଥିରେ ଏନର୍ଜି ସମନ୍ୱୟ ରହିଥାଏ ଓ ଅଧିକ ଖାଇବା ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'general_fact_dailywalk_501',
    type: ContentType.fact,
    tags: ['general', 'lifestyle'],
    title: "Walking Improves Longevity",
    body:
        "A daily 30-minute walk can reduce your risk of chronic diseases and improve overall lifespan.",
    bodyHi:
        "रोजाना 30 मिनट की वॉक आपके क्रॉनिक बीमारियों के जोखिम को कम करती है और जीवनकाल बढ़ाने में मदद करती है।",
    bodyOd:
        "ପ୍ରତିଦିନ 30 ମିନିଟ୍ ହାଟିବା ଦୀର୍ଘକାଳୀନ ରୋଗର ଜୋଖିମ କମାଇ ଆୟୁବର୍ଦ୍ଧନରେ ସହାୟକ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'lifestyle_tip_sleepcycle_502',
    type: ContentType.tip,
    tags: ['lifestyle', 'general'],
    title: "Maintain a Steady Sleep Cycle",
    body:
        "Sleeping and waking at the same time daily helps regulate hormones and reduces fatigue.",
    bodyHi:
        "हर दिन एक ही समय पर सोना और उठना हार्मोन संतुलन में मदद करता है और थकान कम करता है।",
    bodyOd:
        "প্ৰତିଦିନ ସମାନ ସମୟରେ ଶୋଇବା ଓ ଉଠିବା ହର୍ମୋନ ସଂତୁଳନରେ ସାହାଯ୍ୟ କରେ ଏବଂ କ୍ଲାନ୍ତି କମାଏ।",
  ),
  WellnessContentModel(
    id: 'immunity_fact_vitc_503',
    type: ContentType.fact,
    tags: ['immunity', 'general'],
    title: "Vitamin C Supports Immunity",
    body:
        "Foods rich in vitamin C like oranges, amla, and guava help strengthen immune defenses.",
    bodyHi:
        "संतरा, आंवला और अमरूद जैसे विटामिन C से भरपूर खाद्य पदार्थ इम्यूनिटी को मजबूत करते हैं।",
    bodyOd:
        "କମଳା, ଆଁଳା ଓ ପେରା ପରି ଭିଟାମିନ C ଧନାତ୍ମକ ଖାଦ୍ୟ ରୋଗ ପ୍ରତିରୋଧକ ଶକ୍ତିକୁ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'digestion_tip_water_504',
    type: ContentType.tip,
    tags: ['digestion', 'lifestyle'],
    title: "Drink Water Before Meals",
    body:
        "Drinking a glass of water before meals helps digestion and prevents overeating.",
    bodyHi:
        "भोजन से पहले एक गिलास पानी पीना पाचन में मदद करता है और ज्यादा खाने से रोकता है।",
    bodyOd:
        "ଖାଦ୍ୟ ପୂର୍ବରୁ ଗୋଟିଏ ଗିଲାସ୍ ପାଣି ପିଇବା ପାଚନ ଉନ୍ନତ କରେ ଏବଂ ଅଧିକ ଖାଇବାରୁ ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'gut_health_fact_probiotics_505',
    type: ContentType.fact,
    tags: ['gut_health', 'digestion'],
    title: "Probiotics Boost Gut Balance",
    body:
        "Curd, buttermilk, and fermented foods support gut-friendly bacteria.",
    bodyHi:
        "दही, छाछ और किण्वित खाद्य पदार्थ आंतों के लिए लाभदायक बैक्टीरिया को बढ़ाते हैं।",
    bodyOd: "ଦହି, ଛାସ ଓ ଖମିରୀକୃତ ଖାଦ୍ୟ ଗଟ୍-ଫ୍ରେଣ୍ଡଲି ବ୍ୟାକ୍ଟେରିଆ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'heart_health_advice_salt_506',
    type: ContentType.advice,
    tags: ['heart_health', 'lifestyle'],
    title: "Limit Excess Salt",
    body:
        "Reducing high-sodium foods helps maintain blood pressure and protects the heart.",
    bodyHi:
        "अधिक नमक कम करने से ब्लड प्रेशर नियंत्रित रहता है और हृदय की सुरक्षा होती है।",
    bodyOd: "ଅଧିକ ଲୁଣ କମାଇବା ରକ୍ତଚାପ ନିୟନ୍ତ୍ରଣ ରଖେ ଏବଂ ହୃଦୟକୁ ସୁରକ୍ଷା କରେ।",
  ),
  WellnessContentModel(
    id: 'liver_health_fact_antioxidants_507',
    type: ContentType.fact,
    tags: ['liver_health', 'general'],
    title: "Antioxidants Protect the Liver",
    body: "Green tea, berries, and leafy greens reduce liver inflammation.",
    bodyHi:
        "ग्रीन टी, बेरीज़ और हरी सब्जियाँ लिवर की सूजन कम करने में मदद करती हैं।",
    bodyOd: "ଗ୍ରିନ୍ ଟି, ବେରି ଓ ପତ୍ରଶାକ ଲିଭର ସୁଜିବା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'bone_health_myth_milkonly_508',
    type: ContentType.myth,
    tags: ['bone_health', 'general'],
    title: "Myth: Only Milk Builds Bones",
    body:
        "Fact: Nuts, millets, leafy greens, and sunlight are equally important for strong bones.",
    bodyHi:
        "सच: केवल दूध ही नहीं, बल्कि मेवे, मिलेट्स, हरी सब्जियाँ और धूप भी हड्डियों को मजबूत बनाते हैं।",
    bodyOd:
        "ସତ୍ୟ: କେବଳ ଦୁଧ ନୁହେଁ, ନଟ୍ସ, ମିଲେଟ୍ସ, ପତ୍ରଶାକ ଓ ଧୂପ ମଧ୍ୟ ହାଡକୁ ଶକ୍ତିଶାଳୀ କରେ।",
  ),
  WellnessContentModel(
    id: 'general_tip_moderation_509',
    type: ContentType.tip,
    tags: ['general', 'lifestyle'],
    title: "Practice Moderation",
    body:
        "Balanced eating and portion control help prevent overeating and weight gain.",
    bodyHi:
        "संतुलित आहार और नियंत्रित मात्रा ज्यादा खाने और वजन बढ़ने से बचाते हैं।",
    bodyOd: "ସମତୋଳ ଖାଦ୍ୟ ଓ ପୋର୍ସନ୍ ନିୟନ୍ତ୍ରଣ ଅଧିକ ଖାଇବା ଏବଂ ବଜନ ବୃଦ୍ଧି ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'immunity_advice_sleep_510',
    type: ContentType.advice,
    tags: ['immunity', 'sleep'],
    title: "Prioritize Rest for Immunity",
    body:
        "7–8 hours of deep sleep helps the immune system repair and strengthen.",
    bodyHi:
        "7–8 घंटे की अच्छी नींद इम्यून सिस्टम को मरम्मत और मजबूत करने में मदद करती है।",
    bodyOd: "7–8 ଘଣ୍ଟା ଗଭୀର ନିଦ୍ରା ରୋଗ ପ୍ରତିରୋଧକ୍ ତନ୍ତ୍ରକୁ ଶକ୍ତିଶାଳୀ କରେ।",
  ),

  // --- Continuing 511–525 ---
  WellnessContentModel(
    id: 'digestion_fact_chewing_511',
    type: ContentType.fact,
    tags: ['digestion', 'lifestyle'],
    title: "Chewing Aids Digestion",
    body:
        "Chewing food thoroughly helps enzymes break it down better and improves absorption.",
    bodyHi:
        "खाने को अच्छे से चबाना पाचन एंज़ाइम्स को बेहतर काम करने में मदद करता है और अवशोषण बढ़ाता है।",
    bodyOd:
        "ଖାଦ୍ୟକୁ ଭଲ ଭାବରେ ଚବାଇବା ପାଚନ ଏନଜାଇମ୍‌ର କାମ ଉନ୍ନତ କରେ ଏବଂ ଶୋଷଣ ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'gut_health_tip_fiber_512',
    type: ContentType.tip,
    tags: ['gut_health', 'digestion'],
    title: "Add Fiber for Happy Gut",
    body:
        "Fruits, vegetables, whole grains, and legumes support smooth digestion.",
    bodyHi: "फल, सब्जियाँ, साबुत अनाज और दालें पाचन को सहज बनाती हैं।",
    bodyOd: "ଫଳ, ସବ୍ଜି, ସାବୁତ ଅନ୍ନ ଓ ଡାଲିଆ ପାଚନକୁ ସୁଗମ କରେ।",
  ),
  WellnessContentModel(
    id: 'heart_health_fact_healthyfats_513',
    type: ContentType.fact,
    tags: ['heart_health', 'lifestyle'],
    title: "Healthy Fats Protect the Heart",
    body:
        "Omega-3 rich nuts, seeds, and fish reduce inflammation and support heart function.",
    bodyHi:
        "ओमेगा-3 से भरपूर मेवे, बीज और मछली सूजन कम करके हृदय को सुरक्षित रखते हैं।",
    bodyOd: "ଓମେଗା-3 ଧନାତ୍ମକ ନଟ୍ସ, ବୀଜ ଓ ମାଛ ହୃଦଯନ୍ତ୍ର ପାଇଁ ଉପକାରୀ।",
  ),
  WellnessContentModel(
    id: 'liver_health_tip_hydration_514',
    type: ContentType.tip,
    tags: ['liver_health', 'general'],
    title: "Hydration Supports Liver Detox",
    body: "Adequate water intake helps the liver flush toxins efficiently.",
    bodyHi:
        "पर्याप्त पानी पीना लिवर को विषाक्त पदार्थ बाहर निकालने में मदद करता है।",
    bodyOd:
        "ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିଇବା ଲିଭରକୁ ବିଷାକ୍ତ ପଦାର୍ଥ ବାହାର କରିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'bone_health_advice_vitd_515',
    type: ContentType.advice,
    tags: ['bone_health', 'vitamin_d'],
    title: "Get Sunlight for Vitamin D",
    body:
        "Morning sunlight helps your body naturally produce vitamin D for bone strength.",
    bodyHi:
        "सुबह की धूप विटामिन D बनाने में मदद करती है, जो हड्डियों को मजबूत बनाता है।",
    bodyOd: "ସକାଳ ବେଳର ଧୁପ ଭିଟାମିନ D ତିଆରି କରି ହାଡକୁ ଶକ୍ତିଶାଳୀ କରେ।",
  ),
  WellnessContentModel(
    id: 'general_fact_posture_516',
    type: ContentType.fact,
    tags: ['general', 'lifestyle'],
    title: "Good Posture Prevents Pain",
    body:
        "Maintaining good posture reduces back and neck strain throughout the day.",
    bodyHi: "अच्छी पोस्टure कमर और गर्दन के दर्द को कम करने में मदद करती है।",
    bodyOd: "ଭଲ ପୋଷ୍ଚର୍ ସାରା ଦିନ ପଛ ଓ ଗଲାର ବେଦନା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'immunity_tip_spices_517',
    type: ContentType.tip,
    tags: ['immunity', 'spices'],
    title: "Use Immunity-Boosting Spices",
    body:
        "Turmeric, ginger, and black pepper help reduce inflammation and strengthen immunity.",
    bodyHi: "हल्दी, अदरक और काली मिर्च सूजन कम कर इम्यूनिटी बढ़ाते हैं।",
    bodyOd: "ହଳଦୀ, ଅଦା ଓ ଗୋଲମରିଚ ରୋଗ ପ୍ରତିରୋଧକ୍ ଶକ୍ତି ବୃଦ୍ଧି କରେ।",
  ),
  WellnessContentModel(
    id: 'digestion_advice_mealregularity_518',
    type: ContentType.advice,
    tags: ['digestion', 'lifestyle'],
    title: "Maintain Regular Meal Times",
    body:
        "Eating at consistent times supports digestive rhythm and reduces bloating.",
    bodyHi:
        "नियमित समय पर भोजन करना पाचन को संतुलित रखता है और गैस की समस्या कम करता है।",
    bodyOd: "ନିୟମିତ ସମୟରେ ଖାଇବା ପାଚନ ସହଜ କରେ ଏବଂ ଫୁଲା ହେବା ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'gut_health_myth_spicyharm_519',
    type: ContentType.myth,
    tags: ['gut_health', 'digestion'],
    title: "Myth: All Spicy Foods Harm the Gut",
    body:
        "Fact: Moderate spices may improve digestion; only excessive spicy food causes discomfort.",
    bodyHi:
        "सच: सीमित मसाले पाचन में मदद कर सकते हैं; केवल अधिक मसाले नुकसान पहुंचाते हैं।",
    bodyOd:
        "ସତ୍ୟ: ମାପଯୋଗ୍ୟ ମସଲା ପାଚନରେ ସାହାଯ୍ୟ କରିପାରେ; ଅଧିକ ତୀକ୍ଷ୍ଣ ଖାଦ୍ୟ ଅସୁବିଧା ଦେଇଥାଏ।",
  ),
  WellnessContentModel(
    id: 'heart_health_tip_aerobic_520',
    type: ContentType.tip,
    tags: ['heart_health', 'lifestyle'],
    title: "Include Aerobic Exercise",
    body:
        "Brisk walking, cycling, or swimming strengthens the heart and improves circulation.",
    bodyHi:
        "तेज चलना, साइक्लिंग और तैराकी हृदय को मजबूत करती है और रक्त प्रवाह सुधारती है।",
    bodyOd: "ତୀବ୍ର ହାଟିବା, ସାଇକଲିଂ ଓ ପହଁରିବା ହୃଦୟକୁ ଶକ୍ତିଶାଳୀ କରେ।",
  ),
  WellnessContentModel(
    id: 'liver_health_fact_sugarlimit_521',
    type: ContentType.fact,
    tags: ['liver_health', 'general'],
    title: "Excess Sugar Burdens the Liver",
    body:
        "High sugar intake increases fat storage in the liver and contributes to fatty liver.",
    bodyHi:
        "अधिक शुगर लिवर में फैट जमा कर सकती है और फैटी लिवर का कारण बनती है।",
    bodyOd: "ଅଧିକ ଚିନି ଲିଭରରେ ଚର୍ବି ଜମାଇ ଫ୍ୟାଟି ଲିଭର ସୃଷ୍ଟି କରେ।",
  ),
  WellnessContentModel(
    id: 'bone_health_tip_strengthtrain_522',
    type: ContentType.tip,
    tags: ['bone_health', 'lifestyle'],
    title: "Do Strength Training",
    body:
        "Strength exercises improve bone density and prevent age-related bone loss.",
    bodyHi:
        "स्ट्रेंथ ट्रेनिंग हड्डियों की घनत्व बढ़ाती है और उम्र-संबंधी कमजोरी रोकती है।",
    bodyOd: "ଶକ୍ତି ଅଭ୍ୟାସ ହାଡର ଘନତା ବୃଦ୍ଧି କରେ ଏବଂ ବୟସ ଅନୁସାରେ ଅବନତି ରୋକେ।",
  ),
  WellnessContentModel(
    id: 'general_tip_breaksitting_523',
    type: ContentType.tip,
    tags: ['general', 'lifestyle'],
    title: "Break Long Sitting Hours",
    body:
        "Standing or walking for 2–3 minutes every 30 minutes improves energy and posture.",
    bodyHi:
        "हर 30 मिनट में 2–3 मिनट खड़े होना या टहलना ऊर्जा और पोस्टure सुधारता है।",
    bodyOd:
        "ପ୍ରତି 30 ମିନିଟ୍‌ରେ 2–3 ମିନିଟ୍ ଉଠିବା କିମ୍ବା ଚାଲିବା ଶକ୍ତି ଓ ପୋଷ୍ଚର୍ ଉନ୍ନତ କରେ।",
  ),
  WellnessContentModel(
    id: 'immunity_fact_zinc_524',
    type: ContentType.fact,
    tags: ['immunity', 'minerals'],
    title: "Zinc Supports Immune Cells",
    body:
        "Nuts, seeds, and legumes provide zinc that helps immune cells function properly.",
    bodyHi:
        "मेवे, बीज और दालें जिंक प्रदान करती हैं जो इम्यून कोशिकाओं के कार्य में मदद करता है।",
    bodyOd: "ନଟ୍ସ, ବିଆ ଓ ଡାଲିଆ ଜିଙ୍କ ଦିଇ ରୋଗ ପ୍ରତିରୋଧକ କୋଷକୁ ସହାଯ୍ୟ କରେ।",
  ),
  WellnessContentModel(
    id: 'digestion_advice_mindfuleating_525',
    type: ContentType.advice,
    tags: ['digestion', 'lifestyle'],
    title: "Practice Mindful Eating",
    body:
        "Eating slowly without distractions improves digestion and satisfaction.",
    bodyHi:
        "ध्यानपूर्वक और धीरे खाने से पाचन बेहतर होता है और भोजन का आनंद बढ़ता है।",
    bodyOd: "ଧ୍ୟାନ ଦେଇ ଧୀରେ ଖାଇବା ପାଚନ ଭଲ କରେ ଏବଂ ପୁରଣତା ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'general_fact_dailywalk_526',
    type: ContentType.fact,
    tags: ['general', 'lifestyle'],
    title: "Daily Walking Boosts Overall Health",
    body:
        "A simple 20–30 minute walk daily improves circulation, mood, and energy levels.",
    bodyHi: "रोज 20–30 मिनट चलना रक्त प्रवाह, मूड और ऊर्जा को बेहतर बनाता है।",
    bodyOd:
        "ଦିନକୁ 20–30 ମିନିଟ୍ ହାଟିବା ରକ୍ତସଞ୍ଚାଳନ, ମନୋଭାବ ଓ ଉର୍ଜାକୁ ଉନ୍ନତ କରେ।",
  ),

  WellnessContentModel(
    id: 'lifestyle_advice_consistent_sleep_527',
    type: ContentType.advice,
    tags: ['lifestyle', 'sleep'],
    title: "Maintain a Consistent Sleep Schedule",
    body:
        "Sleeping and waking at the same time daily stabilizes hormones and energy.",
    bodyHi:
        "हर दिन एक ही समय पर सोना और जागना हार्मोन और ऊर्जा को स्थिर रखता है।",
    bodyOd: "ପ୍ରତିଦିନ ସମାନ ସମୟରେ ସୁଇବା ଓ ଉଠିବା ହର୍ମୋନ ଏବଂ ଉର୍ଜାକୁ ସ୍ଥିର କରେ।",
  ),

  WellnessContentModel(
    id: 'immunity_fact_vitaminC_528',
    type: ContentType.fact,
    tags: ['immunity', 'vitamins'],
    title: "Vitamin C Strengthens Immunity",
    body:
        "Citrus fruits and amla provide Vitamin C that protects cells from infections.",
    bodyHi:
        "साइट्रस फल और आंवला विटामिन C देते हैं जो कोशिकाओं को संक्रमण से बचाता है।",
    bodyOd: "ଲେମ୍ବୁ ଫଳ ଓ ଆଁଲା ଭିଟାମିନ C ଦିଏ, ଯାହା କୋଷକୁ ସଂକ୍ରମଣରୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'digestion_advice_waterintake_529',
    type: ContentType.advice,
    tags: ['digestion', 'hydration'],
    title: "Drink Water Before Heavy Meals",
    body:
        "Hydration before meals supports smoother digestion and prevents overeating.",
    bodyHi:
        "भोजन से पहले पानी पीने से पाचन बेहतर होता है और अधिक खाने से बचाता है।",
    bodyOd: "ଭୋଜନ ପୂର୍ବରୁ ପାଣି ପିଲେ ପାଚନ ସହଜ ହୁଏ ଏବଂ ଅଧିକ ଖାଇବାକୁ ରୋକେ।",
  ),

  WellnessContentModel(
    id: 'gut_health_fact_prebiotics_530',
    type: ContentType.fact,
    tags: ['gut_health', 'fiber'],
    title: "Prebiotics Feed Healthy Gut Bacteria",
    body:
        "Foods like garlic, onions, and bananas help nourish good gut microbes.",
    bodyHi:
        "लहसुन, प्याज और केला जैसे खाद्य पदार्थ अच्छे आंत बैक्टीरिया को पोषण देते हैं।",
    bodyOd: "ରସୁଣ, ପିଆଜ ଓ କଦଳୀ ଭଲ ଗଟ୍ ବ୍ୟାକଟିରିଆକୁ ପୋଷଣ ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'heart_health_advice_reduce_salt_531',
    type: ContentType.advice,
    tags: ['heart_health', 'lifestyle'],
    title: "Limit Excess Salt Intake",
    body:
        "Reducing added salt lowers your blood pressure and protects heart health.",
    bodyHi: "नमक कम करने से रक्तचाप नियंत्रित रहता है और हृदय स्वस्थ रहता है।",
    bodyOd: "ଅତ୍ୟଧିକ ଲୁଣ କମେଇବାରେ BP ନିୟନ୍ତ୍ରଣ ରହେ ଏବଂ ହୃଦୟ ସୁରକ୍ଷିତ ଥାଏ।",
  ),

  WellnessContentModel(
    id: 'liver_health_fact_detoxnaturally_532',
    type: ContentType.fact,
    tags: ['liver_health', 'hydration'],
    title: "Your Liver Detoxes Naturally",
    body:
        "A hydrated body helps the liver flush out toxins without fancy detox diets.",
    bodyHi:
        "पर्याप्त पानी पीने से लीवर प्राकृतिक रूप से शरीर को डिटॉक्स करता है।",
    bodyOd: "ପରିପୂର୍ଣ୍ଣ ଜଳଯୋଗାଣି ଥିଲେ ଲିଭର ସ୍ୱଭାବିକ ଭାବେ ଦେହକୁ ଡିଟକ୍ସ କରେ।",
  ),

  WellnessContentModel(
    id: 'bone_health_advice_calciumfoods_533',
    type: ContentType.advice,
    tags: ['bone_health', 'minerals'],
    title: "Include Calcium-Rich Foods",
    body: "Curd, ragi, and sesame seeds help maintain strong bones.",
    bodyHi: "दही, रागी और तिल हड्डियों को मजबूत बनाए रखने में मदद करते हैं।",
    bodyOd: "ଦହି, ରାଗି ଓ ତିଳ ହାଡ଼କୁ ମଜୁବୁତ ରଖିବାରେ ସାହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'immunity_advice_sleepboosts_534',
    type: ContentType.advice,
    tags: ['immunity', 'sleep'],
    title: "Good Sleep Strengthens Immunity",
    body: "7–8 hours of restful sleep improves immune response and recovery.",
    bodyHi:
        "7–8 घंटे की पूरी नींद इम्यून प्रतिक्रिया और रिकवरी को बेहतर करती है।",
    bodyOd: "7–8 ଘଣ୍ଟାର ଭଲ ଘୁମ ରୋଗ ପ୍ରତିରୋଧକ କ୍ଷମତାକୁ ବଢ଼ାଏ।",
  ),

  WellnessContentModel(
    id: 'general_fact_stayactive_535',
    type: ContentType.fact,
    tags: ['general', 'lifestyle'],
    title: "Staying Active Reduces Disease Risk",
    body:
        "Light activity throughout the day improves metabolism and cellular health.",
    bodyHi:
        "दिनभर हल्की सक्रियता भी मेटाबॉलिज़्म और कोशिकाओं के स्वास्थ्य को बेहतर करती है।",
    bodyOd:
        "ଦିନଯୁଗୁ ହଲ୍କା କ୍ରିୟାଶୀଳତା ମେଟାବୋଲିଜମ୍ ଓ କୋଷ ସ୍ୱାସ୍ଥ୍ୟକୁ ଉନ୍ନତ କରେ।",
  ),

  WellnessContentModel(
    id: 'digestion_fact_fermentedfoods_536',
    type: ContentType.fact,
    tags: ['digestion', 'gut_health'],
    title: "Fermented Foods Support Digestion",
    body:
        "Curd, buttermilk, and fermented batters provide probiotics for gut balance.",
    bodyHi:
        "दही, छाछ और फ़र्मेंटेड बैटर आंतों के लिए प्रोबायोटिक्स प्रदान करते हैं।",
    bodyOd: "ଦହି, ଛାସ୍ ଓ ଫର୍ମେଣ୍ଟେଡ୍ ବ୍ୟାଟର ଗଟ୍ ପାଇଁ ପ୍ରୋବାଯୋଟିକ୍ ଦିଏ।",
  ),

  WellnessContentModel(
    id: 'heart_health_fact_goodfats_537',
    type: ContentType.fact,
    tags: ['heart_health', 'cholesterol'],
    title: "Good Fats Support Heart Function",
    body:
        "Nuts, seeds, and olive oil improve cholesterol and protect the heart.",
    bodyHi:
        "मेवे, बीज और ऑलिव ऑयल अच्छा कोलेस्ट्रॉल बढ़ाकर हृदय की रक्षा करते हैं।",
    bodyOd: "ନଟ୍ସ, ବିଆ ଓ ଅଲିଭ୍ ତେଲ କଲେଷ୍ଟରଲ୍ ସୁଧାରି ହୃଦୟକୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'liver_health_advice_limitfried_538',
    type: ContentType.advice,
    tags: ['liver_health', 'lifestyle'],
    title: "Limit Deep-Fried Foods",
    body: "Heavy fried meals strain the liver and slow down fat processing.",
    bodyHi:
        "बहुत तली हुई चीज़ें लीवर पर दबाव डालती हैं और वसा के पाचन को धीमा करती हैं।",
    bodyOd: "ଅତ୍ୟଧିକ ତଳା ଖାଦ୍ୟ ଲିଭରକୁ ଚାପ ଦିଏ ଏବଂ ଚର୍ବି ପାଚନ ଧୀର କରେ।",
  ),

  WellnessContentModel(
    id: 'bone_health_fact_vitaminD_539',
    type: ContentType.fact,
    tags: ['bone_health', 'vitamins'],
    title: "Sunlight Helps Vitamin D Production",
    body: "10–15 minutes of morning sunlight supports calcium absorption.",
    bodyHi:
        "10–15 मिनट की सुबह की धूप विटामिन D बनाती है और कैल्शियम अवशोषण में मदद करती है।",
    bodyOd:
        "ସକାଳ 10–15 ମିନିଟ୍ ଧୁପରେ ରହିବା ଭିଟାମିନ D ତିଆରି କରେ ଓ କ୍ୟାଲସିଆମ୍ ଶୋଷଣକୁ ସହାଯ୍ୟ କରେ।",
  ),

  WellnessContentModel(
    id: 'general_advice_stretchbreaks_540',
    type: ContentType.advice,
    tags: ['general', 'lifestyle'],
    title: "Take Stretch Breaks",
    body:
        "Short stretch breaks during long sitting hours prevent stiffness and fatigue.",
    bodyHi:
        "लंबे समय बैठने पर छोटे-छोटे स्ट्रेच ब्रेक लेने से अकड़न और थकान कम होती है।",
    bodyOd:
        "ଦୀର୍ଘସମୟ ବସିଥିବାବେଳେ ଛୋଟ ଷ୍ଟ୍ରେଚ୍ ବ୍ରେକ୍ ନେଲେ ଜଡ଼ାଣି ଓ କ୍ଲାନ୍ତି କମେ।",
  ),

  WellnessContentModel(
    id: 'gut_health_advice_avoidovereating_541',
    type: ContentType.advice,
    tags: ['gut_health', 'digestion'],
    title: "Avoid Overeating at Once",
    body:
        "Eating smaller, frequent meals keeps the gut comfortable and active.",
    bodyHi: "बार–बार कम मात्रा में खाने से आंतें आरामदायक और सक्रिय रहती हैं।",
    bodyOd: "ଛୋଟ ଛୋଟ ପରିମାଣରେ ବେଶିବାର ଖାଇଲେ ଗଟ୍ ସୁବିଧାଜନକ ଓ ସକ୍ରିୟ ରହେ।",
  ),

  WellnessContentModel(
    id: 'heart_health_advice_walkaftermeal_542',
    type: ContentType.advice,
    tags: ['heart_health', 'lifestyle'],
    title: "Take a Short Walk After Meals",
    body:
        "A 10-minute walk helps regulate blood sugar and reduces cardiac strain.",
    bodyHi:
        "भोजन के बाद 10 मिनट टहलना ब्लड शुगर को नियंत्रित करता है और दिल पर दबाव कम करता है।",
    bodyOd:
        "ଭୋଜନ ପରେ 10 ମିନିଟ୍ ହାଟିବା ବ୍ଲଡ୍ ସୁଗରକୁ ନିୟନ୍ତ୍ରଣ କରେ ଏବଂ ହୃଦୟର ଚାପ କମେ।",
  ),

  WellnessContentModel(
    id: 'liver_health_fact_antioxidants_543',
    type: ContentType.fact,
    tags: ['liver_health', 'general'],
    title: "Antioxidants Protect the Liver",
    body:
        "Colorful fruits and vegetables reduce inflammation and support liver function.",
    bodyHi:
        "रंग-बिरंगे फल और सब्ज़ियाँ सूजन घटाती हैं और लीवर की रक्षा करती हैं।",
    bodyOd: "ବିଭିନ୍ନ ରଙ୍ଗର ଫଳ ଓ ସବ୍ଜି ସୋଜା ହ୍ରାସ କରେ ଏବଂ ଲିଭରକୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'bone_health_advice_strengthtraining_544',
    type: ContentType.advice,
    tags: ['bone_health', 'general'],
    title: "Do Light Strength Training",
    body: "Weight-bearing exercises help improve bone density and balance.",
    bodyHi: "वेट-बेयरिंग व्यायाम हड्डियों की मजबूती और संतुलन बढ़ाते हैं।",
    bodyOd: "ଭାରପୂର୍ଣ୍ଣ ଅଭ୍ୟାସ ହାଡ଼ ଘନତା ଓ ସନ୍ତୁଳନ ଉନ୍ନତ କରେ।",
  ),

  WellnessContentModel(
    id: 'immunity_fact_greentea_545',
    type: ContentType.fact,
    tags: ['immunity', 'general'],
    title: "Green Tea Contains Immune-Supporting Antioxidants",
    body:
        "Green tea polyphenols strengthen the immune system and reduce inflammation.",
    bodyHi:
        "ग्रीन टी के पॉलीफेनॉल इम्यून सिस्टम को मजबूत करते हैं और सूजन कम करते हैं।",
    bodyOd: "ଗ୍ରିନ୍ ଟିର ପଲିଫେନଲ୍ ରୋଗ ପ୍ରତିରୋଧକତା ବଢ଼ାଏ ଏବଂ ସୋଜା କମାଏ।",
  ),

  WellnessContentModel(
    id: 'general_advice_stayhydrated_546',
    type: ContentType.advice,
    tags: ['general', 'hydration'],
    title: "Stay Hydrated Through the Day",
    body:
        "Regular water intake improves digestion, skin health, and overall energy.",
    bodyHi: "दिनभर पानी पीने से पाचन, त्वचा और ऊर्जा स्तर बेहतर रहते हैं।",
    bodyOd: "ଦିନଭର ପାଣି ପିଲେ ପାଚନ, ଚର୍ମ ଓ ଉର୍ଜା ସ୍ତର ଉନ୍ନତ ରହେ।",
  ),

  WellnessContentModel(
    id: 'digestion_advice_avoidlateeating_547',
    type: ContentType.advice,
    tags: ['digestion', 'lifestyle'],
    title: "Avoid Eating Very Late at Night",
    body: "Late-night meals slow digestion and disturb sleep quality.",
    bodyHi:
        "बहुत देर रात में खाना पाचन धीमा करता है और नींद की गुणवत्ता खराब करता है।",
    bodyOd: "ଅତ୍ୟଧିକ ରାତିରେ ଖାଇବା ପାଚନ କମେଇ ଘୁମର ଗୁଣତା ଖରାପ କରେ।",
  ),

  WellnessContentModel(
    id: 'gut_health_fact_fiberdiversity_548',
    type: ContentType.fact,
    tags: ['gut_health', 'fiber'],
    title: "A Variety of Fibers Supports Gut Microbiome",
    body:
        "Different plant fibers feed different gut bacteria, improving gut balance.",
    bodyHi:
        "विभिन्न प्रकार के फाइबर अलग-अलग आंत बैक्टीरिया को पोषण देते हैं और आंतों का संतुलन सुधारते हैं।",
    bodyOd:
        "ବିଭିନ୍ନ ପ୍ଲାଣ୍ଟ ଫାଇବର ଭିନ୍ନ ଗଟ୍ ବ୍ୟାକଟିରିଆକୁ ପୋଷଣ ଦେଇ ଗଟ୍ ସନ୍ତୁଳନ ଉନ୍ନତ କରେ।",
  ),

  WellnessContentModel(
    id: 'heart_health_fact_omega3_549',
    type: ContentType.fact,
    tags: ['heart_health', 'general'],
    title: "Omega-3 Fats Support Heart Function",
    body:
        "Walnuts and flaxseeds provide omega-3 fats that reduce inflammation and support the heart.",
    bodyHi:
        "अखरोट और अलसी ओमेगा-3 प्रदान करते हैं जो सूजन कम कर हृदय की रक्षा करते हैं।",
    bodyOd: "ଆଖରୋଟ ଓ ଅଲସୀ ଓମେଗା-3 ଦିଏ, ଯାହା ସୋଜା କମାଇ ହୃଦୟକୁ ସୁରକ୍ଷା କରେ।",
  ),

  WellnessContentModel(
    id: 'liver_health_advice_avoid_sugarydrinks_550',
    type: ContentType.advice,
    tags: ['liver_health', 'lifestyle'],
    title: "Avoid Sugary Drinks",
    body: "Sugary beverages increase liver fat and reduce metabolic health.",
    bodyHi:
        "मीठे पेय लीवर में वसा बढ़ाते हैं और मेटाबॉलिक स्वास्थ्य को नुकसान पहुँचाते हैं।",
    bodyOd:
        "ଚିନି ଭର୍ତ୍ତି ପାନୀୟ ଲିଭରରେ ଚର୍ବି ବଢ଼ାଏ ଏବଂ ମେଟାବୋଲିକ୍ ସ୍ୱାସ୍ଥ୍ୟ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'general_fact_hydration_526',
    type: ContentType.fact,
    tags: ['general', 'hydration'],
    title: "Water is Vital for Every Cell",
    body:
        "Drinking enough water aids in circulation, digestion, and detoxification.",
    bodyHi: "पर्याप्त पानी पीने से रक्तसंचार, पाचन और विषहरण में मदद मिलती है।",
    bodyOd: "ଯଥେଷ୍ଟ ପାଣି ପିବା ରକ୍ତସଞ୍ଚାର, ପାଚନ ଓ ବିଷହରଣରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'lifestyle_tip_activity_527',
    type: ContentType.tip,
    tags: ['lifestyle', 'general'],
    title: "Move Throughout the Day",
    body:
        "Short walks or stretching every hour boosts energy and reduces stiffness.",
    bodyHi:
        "हर घंटे थोड़ी देर की सैर या स्ट्रेचिंग ऊर्जा बढ़ाती है और जकड़न कम करती है।",
    bodyOd:
        "ପ୍ରତିଘଣ୍ଟା ଛୋଟ ହାଟିବା କିମ୍ବା ସ୍ଟ୍ରେଚିଂ ଶକ୍ତି ବଢ଼ାଏ ଏବଂ କଠିନତା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'immunity_fact_vitc_528',
    type: ContentType.fact,
    tags: ['immunity', 'vitamins'],
    title: "Vitamin C Supports Immunity",
    body:
        "Citrus fruits and guava provide vitamin C that helps fight infections.",
    bodyHi:
        "संतरे और अमरूद में विटामिन C होता है जो संक्रमण से लड़ने में मदद करता है।",
    bodyOd:
        "ସିଟ୍ରସ ଫଳ ଓ ଗୁଆବାରେ ଭିଟାମିନ C ରହିଛି ଯାହା ସଂକ୍ରମଣ ସହ ଲଡ଼ିବାରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'digestion_advice_mindfuleating_529',
    type: ContentType.advice,
    tags: ['digestion', 'lifestyle'],
    title: "Practice Mindful Eating",
    body:
        "Eating slowly without distractions improves digestion and satisfaction.",
    bodyHi:
        "ध्यानपूर्वक और धीरे खाने से पाचन बेहतर होता है और भोजन का आनंद बढ़ता है।",
    bodyOd: "ଧ୍ୟାନ ଦେଇ ଧୀରେ ଖାଇବା ପାଚନ ଭଲ କରେ ଏବଂ ପୁରଣତା ବଢ଼ାଏ।",
  ),
  WellnessContentModel(
    id: 'gut_health_tip_probiotics_530',
    type: ContentType.tip,
    tags: ['gut_health', 'general'],
    title: "Include Probiotics",
    body: "Yogurt and fermented foods support gut microbiome balance.",
    bodyHi:
        "दही और किण्वित खाद्य पदार्थ आंत के माइक्रोबायोम को संतुलित रखते हैं।",
    bodyOd: "ଦହି ଓ ଫର୍ମେଣ୍ଟ ଖାଦ୍ୟ ଆନ୍ତ ମାଇକ୍ରୋବାୟୋମ୍ ସମତୁଳିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'heart_health_fact_fiber_531',
    type: ContentType.fact,
    tags: ['heart_health', 'fiber'],
    title: "Fiber Protects Your Heart",
    body:
        "Whole grains, vegetables, and fruits reduce cholesterol and support heart health.",
    bodyHi:
        "साबुत अनाज, सब्जियां और फल कोलेस्ट्रॉल कम करते हैं और हृदय स्वास्थ्य को बढ़ावा देते हैं।",
    bodyOd:
        "ସାବୁତ ଅନାଜ, ସବୁଜ ସବ୍ଜୀ ଓ ଫଳ କୋଲେସ୍ଟେରଲ୍ କମାଏ ଏବଂ ହୃଦୟ ସ୍ୱାସ୍ଥ୍ୟକୁ ସହାୟତା କରେ।",
  ),
  WellnessContentModel(
    id: 'liver_health_tip_avoidalcohol_532',
    type: ContentType.tip,
    tags: ['liver_health', 'lifestyle'],
    title: "Limit Alcohol for Liver Health",
    body:
        "Excessive alcohol intake stresses the liver and can cause fatty liver disease.",
    bodyHi:
        "अत्यधिक शराब सेवन यकृत पर दबाव डालता है और फैटी लिवर का कारण बन सकता है।",
    bodyOd:
        "ଅତିରିକ୍ତ ମଦ୍ୟପାନ ଯକୃତକୁ ଚାପ ଦିଏ ଏବଂ ଫ୍ୟାଟି ଲିଭର ରୋଗ ସୃଷ୍ଟି କରିପାରେ।",
  ),
  WellnessContentModel(
    id: 'bone_health_fact_calcium_533',
    type: ContentType.fact,
    tags: ['bone_health', 'minerals'],
    title: "Calcium Strengthens Bones",
    body: "Milk, yogurt, and leafy greens provide calcium for strong bones.",
    bodyHi:
        "दूध, दही और पत्तेदार सब्जियां हड्डियों को मजबूत बनाने के लिए कैल्शियम देती हैं।",
    bodyOd:
        "ଦୁଧ, ଦହି ଓ ପତ୍ତାପାତୀ ସବ୍ଜୀ ହାଡ଼କୁ ଶକ୍ତିଶାଳୀ କରିବା ପାଇଁ କ୍ୟାଲସିୟମ୍ ଦିଏ।",
  ),
  WellnessContentModel(
    id: 'general_advice_sleep_534',
    type: ContentType.advice,
    tags: ['general', 'sleep'],
    title: "Prioritize Sleep",
    body:
        "Consistent 7–8 hours of sleep restores energy and supports overall health.",
    bodyHi:
        "लगातार 7–8 घंटे की नींद ऊर्जा बहाल करती है और संपूर्ण स्वास्थ्य का समर्थन करती है।",
    bodyOd:
        "ନିରନ୍ତର 7–8 ଘଣ୍ଟା ଘୁମ ଶକ୍ତି ପୁନରୁଦ୍ଧାର କରେ ଏବଂ ସମଗ୍ର ସ୍ୱାସ୍ଥ୍ୟକୁ ସହାୟତା କରେ।",
  ),
  WellnessContentModel(
    id: 'immunity_tip_sleep_535',
    type: ContentType.tip,
    tags: ['immunity', 'sleep'],
    title: "Sleep Boosts Immunity",
    body: "Quality sleep enhances immune response and reduces infection risk.",
    bodyHi:
        "गुणवत्तापूर्ण नींद इम्यून प्रतिक्रिया को बढ़ाती है और संक्रमण के जोखिम को कम करती है।",
    bodyOd:
        "ଗୁଣବତ୍ତାପୂର୍ଣ୍ଣ ଘୁମ ରୋଗ ପ୍ରତିରୋଧକ ପ୍ରତିକ୍ରିୟାକୁ ବଢ଼ାଏ ଏବଂ ସଂକ୍ରମଣର ସଂଭାବନା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_circadian_536',
    type: ContentType.fact,
    tags: ['sleep', 'general'],
    title: "Respect Your Circadian Rhythm",
    body:
        "Going to bed and waking up at consistent times helps regulate sleep quality.",
    bodyHi:
        "समान समय पर सोना और जागना नींद की गुणवत्ता को नियंत्रित करने में मदद करता है।",
    bodyOd:
        "ନିୟମିତ ସମୟରେ ଘୁମିବା ଓ ଉଠିବା ଘୁମର ଗୁଣବତ୍ତାକୁ ନିୟନ୍ତ୍ରଣ କରିବାରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'sleep_advice_nap_537',
    type: ContentType.advice,
    tags: ['sleep', 'lifestyle'],
    title: "Short Power Naps",
    body:
        "A 20-minute nap can refresh your mind without disturbing nighttime sleep.",
    bodyHi:
        "20 मिनट की झपकी दिमाग को ताज़ा करती है बिना रात की नींद को प्रभावित किए।",
    bodyOd: "20 ମିନିଟ୍ ନିଦ୍ରା ମନକୁ ତାଜା କରେ, ରାତିର ଘୁମକୁ ଭଙ୍ଗ କରିବା ଛାଡ଼ି।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_morningwater_538',
    type: ContentType.tip,
    tags: ['hydration', 'general'],
    title: "Start with Morning Water",
    body:
        "Drinking a glass of water after waking up jumpstarts metabolism and hydration.",
    bodyHi:
        "सुबह उठने के बाद एक गिलास पानी पीना मेटाबॉलिज़्म और हाइड्रेशन को बढ़ाता है।",
    bodyOd:
        "ସକାଳେ ଉଠିବା ପରେ ଗ୍ଲାସ ପାଣି ପିବା ମେଟାବଲିଜମ୍ ଏବଂ ଜଳସଂଚୟକୁ ସଚେତନ କରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_electrolytes_539',
    type: ContentType.fact,
    tags: ['hydration', 'minerals'],
    title: "Electrolytes Maintain Balance",
    body:
        "Sodium, potassium, and magnesium in fluids help maintain hydration and muscle function.",
    bodyHi:
        "तरल पदार्थों में सोडियम, पोटेशियम और मैग्नीशियम हाइड्रेशन और मांसपेशियों के कार्य को बनाए रखते हैं।",
    bodyOd:
        "ଦ୍ରବରେ ସୋଡିୟମ୍, ପୋଟାସିୟମ୍ ଓ ମ୍ୟାଗ୍ନେସିୟମ୍ ଜଳସଂଚୟ ଓ ସନ୍ଧି କାର୍ଯ୍ୟକୁ ସମତୁଳିତ କରେ।",
  ),
  WellnessContentModel(
    id: 'walk_tip_dailywalk_540',
    type: ContentType.tip,
    tags: ['walk', 'lifestyle'],
    title: "Daily Walks for Health",
    body: "A 30-minute walk daily improves cardiovascular health and mood.",
    bodyHi: "रोज़ाना 30 मिनट की सैर हृदय स्वास्थ्य और मूड को सुधारती है।",
    bodyOd: "ଦৈନନ୍ଦିନ 30 ମିନିଟ୍ ହାଟିବା ହୃଦୟ ସ୍ୱାସ୍ଥ୍ୟ ଏବଂ ମନୋଭାବକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'walk_fact_steps_541',
    type: ContentType.fact,
    tags: ['walk', 'general'],
    title: "Step Count Matters",
    body:
        "Walking 7,000–10,000 steps per day can reduce risk of chronic diseases.",
    bodyHi:
        "प्रतिदिन 7,000–10,000 कदम चलने से पुरानी बीमारियों का खतरा कम होता है।",
    bodyOd:
        "ପ୍ରତିଦିନ 7,000–10,000 ପଦକ୍ଷେପ ଚାଲିବାରେ ଦୀର୍ଘକାଳୀନ ରୋଗର ସଂଭାବନା କମେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_fact_breathing_542',
    type: ContentType.fact,
    tags: ['mental_health', 'anxiety'],
    title: "Deep Breathing Reduces Anxiety",
    body:
        "Practicing slow, deep breaths calms the nervous system and lowers stress.",
    bodyHi:
        "धीरे और गहरी सांसें लेने से तंत्रिका तंत्र शांत होता है और तनाव कम होता है।",
    bodyOd:
        "ଧୀରେ ଏବଂ ଗଭୀର ସ୍ୱାସ ନେବା ନର୍ବସ୍ ସିଷ୍ଟମ୍ କୁ ଶାନ୍ତ କରେ ଏବଂ ଚିନ୍ତା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'anxiety_advice_meditation_543',
    type: ContentType.advice,
    tags: ['mental_health', 'anxiety'],
    title: "Meditation for Calm",
    body:
        "Daily meditation helps manage anxiety and improve emotional regulation.",
    bodyHi:
        "रोज़ाना ध्यान करने से चिंता कम होती है और भावनात्मक नियंत्रण बेहतर होता है।",
    bodyOd:
        "ଦୈନନ୍ଦିନ ଧ୍ୟାନ ଚିନ୍ତା କୁ ନିୟନ୍ତ୍ରଣ କରିବାରେ ସହାୟକ ଏବଂ ଭାବନାତ୍ମକ ନିୟନ୍ତ୍ରଣକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_tip_screen_544',
    type: ContentType.tip,
    tags: ['sleep', 'lifestyle'],
    title: "Limit Screens Before Bed",
    body:
        "Reducing screen time 1 hour before sleep improves quality and duration.",
    bodyHi:
        "सोने से 1 घंटे पहले स्क्रीन समय कम करने से नींद की गुणवत्ता और अवधि बेहतर होती है।",
    bodyOd:
        "ଘୁମ ପୂର୍ବରୁ 1 ଘଣ୍ଟା ସ୍କ୍ରିନ୍ ସମୟ କମାଇବା ଘୁମର ଗୁଣବତ୍ତା ଏବଂ ଅବଧିକୁ ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_advice_coconutwater_545',
    type: ContentType.advice,
    tags: ['hydration', 'lifestyle'],
    title: "Coconut Water for Hydration",
    body:
        "Natural coconut water replenishes fluids and electrolytes efficiently.",
    bodyHi:
        "प्राकृतिक नारियल पानी शरीर में पानी और इलेक्ट्रोलाइट्स को प्रभावी रूप से भरता है।",
    bodyOd: "ପ୍ରାକୃତିକ ନାରିକେଳ ପାଣି ଦେହରେ ଜଳ ଏବଂ ଇଲେକ୍ଟ୍ରୋଲାଇଟ୍ ସଂପୁର୍ଣ୍ଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'walk_tip_stairs_546',
    type: ContentType.tip,
    tags: ['walk', 'lifestyle'],
    title: "Take the Stairs",
    body: "Using stairs instead of elevators adds simple cardio to your day.",
    bodyHi:
        "लिफ्ट के बजाय सीढ़ियां चढ़ने से दिन में सरल कार्डियो शामिल होता है।",
    bodyOd: "ଲିଫ୍ଟର ବଦଳରେ ସିଢ଼ି ଚଢ଼ିବା ଦିନରେ ସରଳ କାର୍ଡିଓ ସଂଯୋଜନ କରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_tip_journaling_547',
    type: ContentType.tip,
    tags: ['mental_health', 'anxiety'],
    title: "Journaling to Reduce Stress",
    body: "Writing thoughts daily helps process emotions and ease anxiety.",
    bodyHi:
        "रोज़ाना विचार लिखने से भावनाओं को समझने और चिंता कम करने में मदद मिलती है।",
    bodyOd:
        "ଦୈନନ୍ଦିନ ଚିନ୍ତା ଲେଖିବା ଭାବନା ପ୍ରକ୍ରିୟା କରିବା ଏବଂ ଚିନ୍ତା କମାଇବାରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_melatonin_548',
    type: ContentType.fact,
    tags: ['sleep', 'general'],
    title: "Melatonin Regulates Sleep",
    body: "Melatonin hormone helps signal your body when it’s time to sleep.",
    bodyHi: "मेलाटोनिन हार्मोन शरीर को संकेत देता है कि सोने का समय है।",
    bodyOd: "ମେଲାଟୋନିନ୍ ହର୍ମୋନ୍ ଦେହକୁ ସୂଚନା ଦିଏ କେବେ ଘୁମିବା ସମୟ।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_fruits_549',
    type: ContentType.fact,
    tags: ['hydration', 'food'],
    title: "Fruits Contribute to Hydration",
    body:
        "Water-rich fruits like watermelon and orange help maintain fluid balance.",
    bodyHi:
        "तरबूज और संतरे जैसे पानी युक्त फल शरीर में तरल संतुलन बनाए रखते हैं।",
    bodyOd: "ତରବୁଜ ଏବଂ କମଳା ଫଳ ପାଣିରେ ଧନ୍ୟ, ଯାହା ଦେହର ଜଳ ସମତୁଳନ କୁ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'walk_advice_evening_550',
    type: ContentType.advice,
    tags: ['walk', 'lifestyle'],
    title: "Evening Walks Calm Mind",
    body: "A 20-minute evening walk reduces stress and improves sleep quality.",
    bodyHi:
        "20 मिनट की शाम की सैर तनाव कम करती है और नींद की गुणवत्ता सुधारती है।",
    bodyOd: "20 ମିନିଟ୍ ସନ୍ଧ୍ୟା ହାଟିବା ଚିନ୍ତା କମାଏ ଏବଂ ଘୁମର ଗୁଣବତ୍ତାକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_fact_exercise_551',
    type: ContentType.fact,
    tags: ['mental_health', 'anxiety'],
    title: "Exercise Reduces Anxiety",
    body:
        "Physical activity releases endorphins, improving mood and reducing anxiety.",
    bodyHi:
        "शारीरिक गतिविधि एंडोर्फिन छोड़ती है, मूड सुधारती है और चिंता कम करती है।",
    bodyOd:
        "ଶାରୀରିକ କାର୍ଯ୍ୟକଳାପ ଏଣ୍ଡୋର୍ଫିନ୍ ମୁକ୍ତ କରେ, ମନୋଭାବ ସୁଧାରେ ଏବଂ ଚିନ୍ତା କମାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_advice_darkroom_552',
    type: ContentType.advice,
    tags: ['sleep', 'lifestyle'],
    title: "Sleep in Darkness",
    body:
        "A dark sleeping environment supports melatonin production and quality sleep.",
    bodyHi: "अंधेरा कमरा मेलाटोनिन उत्पादन और अच्छी नींद को बढ़ावा देता है।",
    bodyOd: "ଅନ୍ଧା କକ୍ଷ ମେଲାଟୋନିନ୍ ଉତ୍ପାଦନ ଏବଂ ଭଲ ଘୁମକୁ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_herbaltea_553',
    type: ContentType.tip,
    tags: ['hydration', 'lifestyle'],
    title: "Herbal Teas Aid Hydration",
    body: "Caffeine-free herbal teas can contribute to daily fluid intake.",
    bodyHi: "कैफीन-रहित हर्बल चाय दैनिक तरल सेवन में योगदान कर सकती है।",
    bodyOd: "କ୍ୟାଫିନ୍-ମୁକ୍ତ ହର୍ବାଲ୍ ଟି ଦୈନନ୍ଦିନ ଜଳ ଉପଭୋଗରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'walk_fact_posture_554',
    type: ContentType.fact,
    tags: ['walk', 'general'],
    title: "Good Posture While Walking",
    body:
        "Maintaining upright posture during walks reduces strain and improves breathing.",
    bodyHi:
        "चलते समय सही स्थिति बनाए रखने से तनाव कम होता है और सांस बेहतर होती है।",
    bodyOd: "ଚାଲିବା ସମୟରେ ସଠିକ୍ ଭଙ୍ଗୀ ରଖିବା ଚାପ କମାଏ ଏବଂ ସ୍ଵାସ ଭଲ କରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_advice_progressive_555',
    type: ContentType.advice,
    tags: ['mental_health', 'anxiety'],
    title: "Try Progressive Muscle Relaxation",
    body:
        "Tensing and relaxing muscles sequentially reduces anxiety and tension.",
    bodyHi:
        "मांसपेशियों को क्रमिक रूप से तनाव और शिथिल करने से चिंता और तनाव कम होता है।",
    bodyOd: "ପେଶୀଗୁଡିକୁ କ୍ରମବଦ୍ଧ ଭାବରେ ତଣାଇ ଏବଂ ଶିଥିଳ କରିବା ଚିନ୍ତା ଓ ଚାପ କମାଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_temperature_556',
    type: ContentType.fact,
    tags: ['sleep', 'general'],
    title: "Cool Room Improves Sleep",
    body:
        "Lowering bedroom temperature supports faster sleep onset and deeper rest.",
    bodyHi: "कमरा ठंडा रखने से नींद जल्दी आती है और गहरी नींद मिलती है।",
    bodyOd: "ଘର ତାପମାତ୍ରା କମାଇବା ଘୁମ ଶୀଘ୍ର ଆସିବାରେ ଏବଂ ଗଭୀର ଆରାମ ପାଇଁ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'hydration_tip_fruits_557',
    type: ContentType.tip,
    tags: ['hydration', 'food'],
    title: "Eat Hydrating Fruits",
    body:
        "Melons, cucumber, and oranges provide fluids and essential vitamins.",
    bodyHi:
        "तरबूज, खीरा और संतरे शरीर में पानी और आवश्यक विटामिन प्रदान करते हैं।",
    bodyOd: "ତରବୁଜ, କାକୁଡ଼ି ଏବଂ କମଳା ଦେହକୁ ଜଳ ଏବଂ ଆବଶ୍ୟକ ଭିଟାମିନ ଯୋଗାଏ।",
  ),
  WellnessContentModel(
    id: 'walk_tip_pace_558',
    type: ContentType.tip,
    tags: ['walk', 'lifestyle'],
    title: "Maintain a Brisk Pace",
    body:
        "Walking at a brisk pace boosts heart rate and enhances calorie burn.",
    bodyHi: "तेज़ गति से चलने से हृदय गति बढ़ती है और कैलोरी बर्न होती है।",
    bodyOd: "ଦୃତ ଗତିରେ ଚାଲିବା ହୃଦୟ ହାର ବଢ଼ାଏ ଏବଂ କ୍ୟାଲୋରି ବର୍ଣ୍ଣ କରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_fact_music_559',
    type: ContentType.fact,
    tags: ['mental_health', 'anxiety'],
    title: "Music Reduces Anxiety",
    body:
        "Listening to calming music lowers stress hormones and soothes the mind.",
    bodyHi: "शांत संगीत सुनने से तनाव हार्मोन कम होते हैं और मन शांत होता है।",
    bodyOd: "ଶାନ୍ତିପୂର୍ଣ୍ଣ ସଙ୍ଗୀତ ଶୁଣିବା ଚାପ ହର୍ମୋନ୍ କମାଏ ଏବଂ ମନକୁ ଶାନ୍ତ କରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_advice_consistency_560',
    type: ContentType.advice,
    tags: ['sleep', 'lifestyle'],
    title: "Keep a Sleep Schedule",
    body:
        "Going to bed and waking up at the same time daily strengthens circadian rhythm.",
    bodyHi: "रोज़ाना समान समय पर सोना और जागना जैविक घड़ी को मजबूत करता है।",
    bodyOd: "ପ୍ରତିଦିନ ସମାନ ସମୟରେ ଘୁମିବା ଓ ଉଠିବା ଜୀବନ୍ତ ଘଡ଼ିକୁ ଶକ୍ତିଶାଳୀ କରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_tea_561',
    type: ContentType.fact,
    tags: ['hydration', 'beverages'],
    title: "Herbal Tea Supports Hydration",
    body:
        "Caffeine-free herbal teas add to daily fluid intake without dehydrating.",
    bodyHi: "कैफीन-रहित हर्बल चाय दैनिक तरल सेवन में योगदान करती है।",
    bodyOd: "କ୍ୟାଫିନ୍-ମୁକ୍ତ ହର୍ବାଲ୍ ଟି ଦୈନନ୍ଦିନ ଜଳ ସଂଚୟରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'walk_fact_outdoors_562',
    type: ContentType.fact,
    tags: ['walk', 'general'],
    title: "Walking Outdoors Boosts Mood",
    body:
        "Exposure to natural light during walks improves vitamin D levels and mood.",
    bodyHi: "सैर के दौरान प्राकृतिक रोशनी मूड और विटामिन D स्तर को सुधारती है।",
    bodyOd: "ଚାଲିବା ସମୟରେ ପ୍ରାକୃତିକ ଆଲୋକ ମୁଡ୍ ଏବଂ ଭିଟାମିନ D ସ୍ତରକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_advice_yoga_563',
    type: ContentType.advice,
    tags: ['mental_health', 'anxiety'],
    title: "Yoga for Anxiety Relief",
    body:
        "Practicing yoga daily reduces stress and improves emotional regulation.",
    bodyHi:
        "रोज़ाना योग करने से तनाव कम होता है और भावनात्मक नियंत्रण बेहतर होता है।",
    bodyOd: "ଦୈନନ୍ଦିନ ଯୋଗାଭ୍ୟାସ ଚାପ କମାଏ ଏବଂ ଭାବନାତ୍ମକ ନିୟନ୍ତ୍ରଣକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'sleep_tip_meditation_564',
    type: ContentType.tip,
    tags: ['sleep', 'mental_health'],
    title: "Meditation Before Bed",
    body:
        "A short meditation session calms the mind and promotes better sleep.",
    bodyHi:
        "सोने से पहले छोटा ध्यान सत्र मन को शांत करता है और नींद सुधारता है।",
    bodyOd: "ଘୁମ ପୂର୍ବରୁ ଛୋଟ ଧ୍ୟାନ ସତ୍ର ମନକୁ ଶାନ୍ତ କରେ ଏବଂ ଘୁମକୁ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_advice_morningwater_565',
    type: ContentType.advice,
    tags: ['hydration', 'lifestyle'],
    title: "Start Your Day with Water",
    body:
        "Drinking a glass of water first thing in the morning aids digestion and hydration.",
    bodyHi:
        "सुबह उठते ही एक गिलास पानी पीना पाचन और हाइड्रेशन में मदद करता है।",
    bodyOd: "ସକାଳେ ଉଠିବା ସମୟରେ ଗ୍ଲାସ ପାଣି ପିବା ପାଚନ ଏବଂ ଜଳସଂଚୟରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'walk_tip_lunchbreak_566',
    type: ContentType.tip,
    tags: ['walk', 'lifestyle'],
    title: "Walk During Lunch Break",
    body:
        "A short walk after meals helps digestion and keeps energy levels steady.",
    bodyHi: "भोजन के बाद थोड़ी सैर पाचन में मदद करती है और ऊर्जा बनाए रखती है।",
    bodyOd: "ଖାଦ୍ୟ ପରେ ଛୋଟ ହାଟିବା ପାଚନରେ ସହାୟକ ଏବଂ ଶକ୍ତି ସ୍ତରକୁ ସ୍ଥିର ରଖେ।",
  ),
  WellnessContentModel(
    id: 'sleep_fact_earlybed_567',
    type: ContentType.fact,
    tags: ['sleep', 'lifestyle'],
    title: "Early Bedtime Improves Sleep",
    body:
        "Going to bed before 11 PM supports circadian rhythm and restorative sleep.",
    bodyHi:
        "11 बजे से पहले सोना जैविक घड़ी और सुधारात्मक नींद को बढ़ावा देता है।",
    bodyOd:
        "ରାତି 11 ଟା ପୂର୍ବରୁ ଘୁମିବା ଜୀବନ୍ତ ଘଡ଼ିକୁ ସମର୍ଥନ କରେ ଏବଂ ପୁନଃସ୍ଥାପନା ଘୁମ ପ୍ରଦାନ କରେ।",
  ),
  WellnessContentModel(
    id: 'anxiety_tip_breathwork_568',
    type: ContentType.tip,
    tags: ['mental_health', 'anxiety'],
    title: "Practice Breathwork",
    body:
        "Slow, deep breathing exercises reduce cortisol and help calm the mind.",
    bodyHi:
        "धीरे और गहरी सांस लेने के व्यायाम कोर्टिसोल कम करते हैं और मन को शांत करते हैं।",
    bodyOd: "ଧୀରେ ଏବଂ ଗଭୀର ସ୍ୱାସ ଅଭ୍ୟାସ କର୍ଟିସୋଲ୍ କମାଏ ଏବଂ ମନକୁ ଶାନ୍ତ କରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_fact_soups_569',
    type: ContentType.fact,
    tags: ['hydration', 'food'],
    title: "Soups Contribute to Fluids",
    body:
        "Clear soups add fluids and nutrients, supporting hydration throughout the day.",
    bodyHi:
        "साफ़ सूप तरल और पोषक तत्व प्रदान करते हैं, जो पूरे दिन हाइड्रेशन में मदद करते हैं।",
    bodyOd: "ସ୍ପଷ୍ଟ ସୁପ୍ ଦିନଭରରେ ଜଳ ଏବଂ ପୋଷକ ଯୋଗାଏ, ଜଳସଂଚୟ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'walk_fact_posture_570',
    type: ContentType.fact,
    tags: ['walk', 'general'],
    title: "Maintain Proper Walking Posture",
    body:
        "Keep shoulders relaxed and back straight to prevent strain and improve breathing.",
    bodyHi:
        "कंधों को आरामदायक और पीठ को सीधा रखकर चलें, तनाव कम होता है और सांस बेहतर होती है।",
    bodyOd: "ପାଖ ଶିଥିଳ ରଖି ଓ ପିଛୁ ସିଧା ରଖି ଚାଲନ୍ତୁ, ଚାପ କମେ ଏବଂ ସ୍ଵାସ ଭଲ ହୁଏ।",
  ),
  WellnessContentModel(
    id: 'sleep_tip_light_571',
    type: ContentType.tip,
    tags: ['sleep', 'lifestyle'],
    title: "Dim the Lights Before Bed",
    body:
        "Lower light exposure 1 hour before sleep helps melatonin production.",
    bodyHi:
        "सोने से 1 घंटे पहले रोशनी कम करने से मेलाटोनिन उत्पादन में मदद मिलती है।",
    bodyOd: "ଘୁମ ପୂର୍ବରୁ 1 ଘଣ୍ଟା ଆଲୋକ କମାଇବା ମେଲାଟୋନିନ୍ ଉତ୍ପାଦନରେ ସହାୟକ।",
  ),
  WellnessContentModel(
    id: 'anxiety_fact_nature_572',
    type: ContentType.fact,
    tags: ['mental_health', 'anxiety'],
    title: "Time in Nature Reduces Anxiety",
    body:
        "Spending time in natural environments lowers stress and improves mood.",
    bodyHi:
        "प्राकृतिक वातावरण में समय बिताने से तनाव कम होता है और मूड बेहतर होता है।",
    bodyOd: "ପ୍ରାକୃତିକ ପରିବେଶରେ ସମୟ ବିତାଇବା ଚାପ କମାଏ ଏବଂ ମନୋଭାବ ସୁଧାରେ।",
  ),
  WellnessContentModel(
    id: 'hydration_advice_fruits_573',
    type: ContentType.advice,
    tags: ['hydration', 'food'],
    title: "Snack on Hydrating Fruits",
    body:
        "Watermelon, cucumber, and berries provide fluids and essential vitamins.",
    bodyHi:
        "तरबूज, खीरा और बेरीज शरीर में पानी और आवश्यक विटामिन प्रदान करते हैं।",
    bodyOd: "ତରବୁଜ, କାକୁଡ଼ି ଏବଂ ବେରି ଦେହକୁ ଜଳ ଏବଂ ଆବଶ୍ୟକ ଭିଟାମିନ ଯୋଗାଏ।",
  ),
  WellnessContentModel(
    id: 'walk_tip_group_574',
    type: ContentType.tip,
    tags: ['walk', 'lifestyle'],
    title: "Walk with Friends",
    body:
        "Walking with friends increases motivation and makes exercise enjoyable.",
    bodyHi:
        "दोस्तों के साथ चलने से प्रेरणा बढ़ती है और व्यायाम मज़ेदार बनता है।",
    bodyOd: "ମିତ୍ରମାନଙ୍କ ସହିତ ଚାଲିବା ପ୍ରେରଣା ବଢ଼ାଏ ଏବଂ ଅଭ୍ୟାସକୁ ଆନନ୍ଦଦାୟକ କରେ।",
  ),
];
