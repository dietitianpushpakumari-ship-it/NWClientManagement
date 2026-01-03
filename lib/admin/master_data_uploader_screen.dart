// lib/admin/master_data_uploader_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for complex saves
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // Assuming provider for Firestore

// Define a type for localized item map
typedef LocalizedItem = Map<String, String>;

// --- 1. DEFAULT MASTER DATA DEFINITIONS (ALL 21 ENTITIES WITH TRANSLATIONS) ---
// This list covers ALL master entities, simple (14) and complex (7).
final Map<String, List<LocalizedItem>> _defaultMasterData = {

  // ---------- A. SIMPLE / GENERIC MASTERS (14) ----------

  MasterEntity.entity_Complaint: const [
    {'en': 'Fever', 'hi': 'बुखार', 'or': 'ଜ୍ୱର'},
    {'en': 'Fatigue', 'hi': 'थकान', 'or': 'କ୍ଲାନ୍ତି'},
    {'en': 'Weakness', 'hi': 'कमजोरी', 'or': 'ଦୁର୍ବଳତା'},
    {'en': 'Headache', 'hi': 'सिरदर्द', 'or': 'ମୁଣ୍ଡବ୍ୟଥା'},
    {'en': 'Dizziness', 'hi': 'चक्कर', 'or': 'ମୁଣ୍ଡ ଘୁରାଣ'},
    {'en': 'Body Pain', 'hi': 'शरीर दर्द', 'or': 'ଶରୀର ଯନ୍ତ୍ରଣା'},
    {'en': 'Joint Pain', 'hi': 'जोड़ों का दर्द', 'or': 'ଗଣ୍ଠି ଯନ୍ତ୍ରଣା'},
    {'en': 'Back Pain', 'hi': 'पीठ दर्द', 'or': 'ପିଠି ଯନ୍ତ୍ରଣା'},
    {'en': 'Chest Pain', 'hi': 'सीने में दर्द', 'or': 'ଛାତି ଯନ୍ତ୍ରଣା'},
    {'en': 'Breathlessness', 'hi': 'सांस फूलना', 'or': 'ଶ୍ୱାସକଷ୍ଟ'},
    {'en': 'Palpitations', 'hi': 'दिल की धड़कन तेज', 'or': 'ହୃଦୟ ଧଡ଼କଣ'},
    {'en': 'Swelling (Edema)', 'hi': 'सूजन', 'or': 'ସ୍ଫୀତି'},
    {'en': 'Loss of Appetite', 'hi': 'भूख न लगना', 'or': 'ଭୋକ ନ ଲାଗିବା'},
    {'en': 'Weight Loss', 'hi': 'वजन घटना', 'or': 'ଓଜନ କମିବା'},
    {'en': 'Weight Gain', 'hi': 'वजन बढ़ना', 'or': 'ଓଜନ ବଢ଼ିବା'},
    {'en': 'Sleep Disturbance', 'hi': 'नींद में परेशानी', 'or': 'ନିଦ୍ରା ସମସ୍ୟା'},
  ],

  MasterEntity.entity_giSymptom: const [
    {'en': 'Poor Appetite', 'hi': 'भूख कम', 'or': 'ଭୋକ କମ୍'},
    {'en': 'Nausea', 'hi': 'मतली', 'or': 'ମନ୍ଦିଆ'},
    {'en': 'Vomiting', 'hi': 'उल्टी', 'or': 'ବାନ୍ତି'},
    {'en': 'Acidity', 'hi': 'एसिडिटी', 'or': 'ଆମ୍ଲତା'},
    {'en': 'Heartburn', 'hi': 'सीने में जलन', 'or': 'ଛାତି ଜଳନ'},
    {'en': 'Gas', 'hi': 'गैस', 'or': 'ଗ୍ୟାସ୍'},
    {'en': 'Bloating', 'hi': 'पेट फूलना', 'or': 'ପେଟ ଫୁଲିବା'},
    {'en': 'Abdominal Pain', 'hi': 'पेट दर्द', 'or': 'ପେଟ ଯନ୍ତ୍ରଣା'},
    {'en': 'Indigestion', 'hi': 'अपच', 'or': 'ଅଜୀର୍ଣ୍ଣ'},
    {'en': 'Constipation', 'hi': 'कब्ज', 'or': 'କୋଷ୍ଠକାଠିନ୍ୟ'},
    {'en': 'Diarrhea', 'hi': 'दस्त', 'or': 'ଝାଡ଼ା'},
    {'en': 'Blood in Stool', 'hi': 'मल में खून', 'or': 'ମଳରେ ରକ୍ତ'},
  ],

  MasterEntity.entity_waterIntake: const [
    {'en': '<1 Litre/Day', 'hi': '1 लीटर से कम', 'or': '1 ଲିଟରରୁ କମ୍'},
    {'en': '1–1.5 Litres/Day', 'hi': '1–1.5 लीटर', 'or': '1–1.5 ଲିଟର'},
    {'en': '2 Litres/Day', 'hi': '2 लीटर', 'or': '2 ଲିଟର'},
    {'en': '3–4 Litres/Day', 'hi': '3–4 लीटर', 'or': '3–4 ଲିଟର'},
    {'en': '5+ Litres/Day', 'hi': '5+ लीटर', 'or': '5+ ଲିଟର'},
  ],

  MasterEntity.entity_caffeineSource: const [
    {'en': 'None', 'hi': 'कोई नहीं', 'or': 'ନାହିଁ'},
    {'en': 'Tea', 'hi': 'चाय', 'or': 'ଚା'},
    {'en': 'Coffee', 'hi': 'कॉफी', 'or': 'କଫି'},
    {'en': 'Green Tea', 'hi': 'ग्रीन टी', 'or': 'ସବୁଜ ଚା'},
    {'en': 'Energy Drinks', 'hi': 'एनर्जी ड्रिंक', 'or': 'ଶକ୍ତି ପାନୀୟ'},
    {'en': 'Soft Drinks', 'hi': 'शीतल पेय', 'or': 'ଶୀତଳ ପାନୀୟ'},
  ],

  MasterEntity.entity_allergy: const [
    {'en': 'None', 'hi': 'कोई नहीं', 'or': 'ନାହିଁ'},
    {'en': 'Milk/Dairy', 'hi': 'दूध/डेयरी', 'or': 'କ୍ଷୀରଜାତ'},
    {'en': 'Egg', 'hi': 'अंडा', 'or': 'ଅଣ୍ଡା'},
    {'en': 'Peanuts', 'hi': 'मूंगफली', 'or': 'ବାଦାମ'},
    {'en': 'Tree Nuts', 'hi': 'मेवे', 'or': 'ଗୁଡ଼ି'},
    {'en': 'Gluten/Wheat', 'hi': 'गेहूं/ग्लूटेन', 'or': 'ଗହମ/ଗ୍ଲୁଟେନ୍'},
    {'en': 'Soy', 'hi': 'सोया', 'or': 'ସୋୟା'},
    {'en': 'Shellfish', 'hi': 'सीफूड', 'or': 'ସାମୁଦ୍ରିକ ଖାଦ୍ୟ'},
  ],

  MasterEntity.entity_Clinicalnotes: const [
    {'en': 'Subjective', 'hi': 'व्यक्तिपरक', 'or': 'ବ୍ୟକ୍ତିଗତ'},
    {'en': 'Objective', 'hi': 'उद्देश्य', 'or': 'ଉଦ୍ଦେଶ୍ୟମୂଳକ'},
    {'en': 'Assessment', 'hi': 'मूल्यांकन', 'or': 'ମୂଲ୍ୟାଙ୍କନ'},
    {'en': 'Diagnosis', 'hi': 'निदान', 'or': 'ରୋଗନିର୍ଣ୍ଣୟ'},
    {'en': 'Plan', 'hi': 'योजना', 'or': 'ଯୋଜନା'},
    {'en': 'Follow-up', 'hi': 'फॉलो-अप', 'or': 'ଅନୁସରଣ'},
  ],

  MasterEntity.entity_ActivityLevels: const [
    {'en': 'Bedridden', 'hi': 'बिस्तर पर', 'or': 'ଶଯ୍ୟାଶାୟୀ'},
    {'en': 'Sedentary', 'hi': 'गतिहीन', 'or': 'ବସି ରହିବା'},
    {'en': 'Lightly Active', 'hi': 'हल्का सक्रिय', 'or': 'ହାଲୁକା ସକ୍ରିୟ'},
    {'en': 'Moderately Active', 'hi': 'मध्यम सक्रिय', 'or': 'ମଧ୍ୟମ ସକ୍ରିୟ'},
    {'en': 'Very Active', 'hi': 'बहुत सक्रिय', 'or': 'ବହୁତ ସକ୍ରିୟ'},
    {'en': 'Athlete/Heavy Work', 'hi': 'भारी श्रम', 'or': 'ଭାରି କାମ'},
  ],

  MasterEntity.entity_SleepQuality: const [
    {'en': 'Very Poor (<4 hours)', 'hi': 'बहुत खराब', 'or': 'ଅତ୍ୟନ୍ତ ଖରାପ'},
    {'en': 'Poor (4–5 hours)', 'hi': 'खराब', 'or': 'ଖରାପ'},
    {'en': 'Average (5–7 hours)', 'hi': 'औसत', 'or': 'ସାଧାରଣ'},
    {'en': 'Good (7–9 hours)', 'hi': 'अच्छा', 'or': 'ଭଲ'},
    {'en': 'Excessive Daytime Sleepiness', 'hi': 'दिन में नींद', 'or': 'ଦିନେ ଘୁମ'},
  ],

  MasterEntity.entity_MenstrualStatus: const [
    {'en': 'Regular Cycle', 'hi': 'नियमित चक्र', 'or': 'ନିୟମିତ ଚକ୍ର'},
    {'en': 'Irregular Cycle', 'hi': 'अनियमित चक्र', 'or': 'ଅନିୟମିତ ଚକ୍ର'},
    {'en': 'Pregnant', 'hi': 'गर्भवती', 'or': 'ଗର୍ଭବତୀ'},
    {'en': 'Lactating', 'hi': 'स्तनपान', 'or': 'ଦୁଧ ପାନ'},
    {'en': 'Post-partum', 'hi': 'प्रसव के बाद', 'or': 'ପ୍ରସବ ପରେ'},
    {'en': 'Menopausal', 'hi': 'रजोनिवृत्त', 'or': 'ଋତୁବନ୍ଦ'},
  ],
  MasterEntity.entity_Guidelines: const [
    {'en': 'Eat meals at regular intervals', 'hi': 'नियमित समय पर भोजन करें', 'or': 'ନିୟମିତ ସମୟରେ ଭୋଜନ'},
    {'en': 'Do not skip breakfast', 'hi': 'नाश्ता न छोड़ें', 'or': 'ଜଳଖିଆ ଛାଡ଼ନ୍ତୁ ନାହିଁ'},
    {'en': 'Avoid sugar-sweetened beverages', 'hi': 'मीठे पेय से बचें', 'or': 'ମିଠା ପାନୀୟ ଏଡ଼ାନ୍ତୁ'},
    {'en': 'Limit fried and junk foods', 'hi': 'तला-भुना और जंक फूड कम करें', 'or': 'ଭଜା ଓ ଜଙ୍କ ଫୁଡ୍ କମାନ୍ତୁ'},
    {'en': 'Increase intake of fruits and vegetables', 'hi': 'फल और सब्ज़ियों का सेवन बढ़ाएं', 'or': 'ଫଳ ଓ ସବ୍ଜି ବଢ଼ାନ୍ତୁ'},
    {'en': 'Prefer whole grains over refined grains', 'hi': 'साबुत अनाज का चयन करें', 'or': 'ସମ୍ପୂର୍ଣ୍ଣ ଶସ୍ୟ ବାଛନ୍ତୁ'},
    {'en': 'Ensure adequate hydration throughout the day', 'hi': 'दिन भर पर्याप्त पानी पिएं', 'or': 'ସାରାଦିନ ପାଣି ପିଅନ୍ତୁ'},
    {'en': 'Limit salt intake', 'hi': 'नमक का सेवन सीमित करें', 'or': 'ଲୁଣ କମାନ୍ତୁ'},
    {'en': 'Avoid late-night eating', 'hi': 'देर रात भोजन न करें', 'or': 'ରାତିରେ ଦେରିରେ ଭୋଜନ ନକରନ୍ତୁ'},
    {'en': 'Chew food slowly and mindfully', 'hi': 'भोजन को धीरे-धीरे चबाएं', 'or': 'ଧୀରେ ଧୀରେ ଚବାନ୍ତୁ'},
    {'en': 'Maintain regular physical activity', 'hi': 'नियमित शारीरिक गतिविधि करें', 'or': 'ନିୟମିତ ଶାରୀରିକ କ୍ରିୟା'},
    {'en': 'Aim for at least 30 minutes of exercise daily', 'hi': 'रोज़ कम से कम 30 मिनट व्यायाम करें', 'or': 'ପ୍ରତିଦିନ 30 ମିନିଟ୍ ବ୍ୟାୟାମ'},
    {'en': 'Ensure adequate sleep every night', 'hi': 'हर रात पर्याप्त नींद लें', 'or': 'ପ୍ରତିରାତି ପର୍ଯ୍ୟାପ୍ତ ନିଦ୍ରା'},
    {'en': 'Avoid smoking and tobacco use', 'hi': 'धूम्रपान और तंबाकू से बचें', 'or': 'ଧୂମପାନ ଏଡ଼ାନ୍ତୁ'},
    {'en': 'Limit alcohol consumption', 'hi': 'शराब का सेवन सीमित करें', 'or': 'ମଦ୍ୟପାନ କମାନ୍ତୁ'},
    {'en': 'Monitor portion sizes', 'hi': 'भोजन की मात्रा पर ध्यान दें', 'or': 'ଖାଦ୍ୟ ପରିମାଣ ନିୟନ୍ତ୍ରଣ'},
    {'en': 'Prefer home-cooked meals', 'hi': 'घर का बना भोजन करें', 'or': 'ଘରେ ପକା ଖାଦ୍ୟ'},
    {'en': 'Include adequate protein in every meal', 'hi': 'हर भोजन में प्रोटीन शामिल करें', 'or': 'ପ୍ରତି ଭୋଜନରେ ପ୍ରୋଟିନ୍'},
    {'en': 'Manage stress through relaxation techniques', 'hi': 'तनाव प्रबंधन करें', 'or': 'ଚାପ ନିୟନ୍ତ୍ରଣ'},
    {'en': 'Follow prescribed diet and medications strictly', 'hi': 'निर्धारित आहार व दवा का पालन करें', 'or': 'ନିର୍ଦ୍ଦିଷ୍ଟ ଆହାର ଓ ଔଷଧ'},
    {'en': 'Monitor blood sugar and blood pressure regularly', 'hi': 'ब्लड शुगर व बीपी की नियमित जांच करें', 'or': 'ସୁଗର ଓ ବିପି ଯାଞ୍ଚ'},
    {'en': 'Avoid overeating during social gatherings', 'hi': 'समारोहों में अधिक न खाएं', 'or': 'ସମାରୋହରେ ଅଧିକ ନ ଖାଆନ୍ତୁ'},
    {'en': 'Consult doctor or dietitian before supplements', 'hi': 'सप्लीमेंट से पहले सलाह लें', 'or': 'ସପ୍ଲିମେଣ୍ଟ ପୂର୍ବରୁ ପରାମର୍ଶ'},
    {'en': 'Maintain consistency in diet and lifestyle', 'hi': 'आहार व जीवनशैली में निरंतरता रखें', 'or': 'ନିୟମିତ ଆଚରଣ'},
  ],


MasterEntity.entity_MealNames: const [
    {'en': 'Early Morning', 'hi': 'सुबह जल्दी', 'or': 'ପ୍ରଭାତ'},
    {'en': 'Breakfast', 'hi': 'नाश्ता', 'or': 'ଜଳଖିଆ'},
    {'en': 'Mid-Morning', 'hi': 'मध्य सुबह', 'or': 'ମଧ୍ୟ ପ୍ରଭାତ'},
    {'en': 'Lunch', 'hi': 'दोपहर का भोजन', 'or': 'ମଧ୍ୟାହ୍ନ ଭୋଜନ'},
    {'en': 'Evening Snack', 'hi': 'शाम का नाश्ता', 'or': 'ସନ୍ଧ୍ୟା ସ୍ନାକ୍ସ'},
    {'en': 'Dinner', 'hi': 'रात का खाना', 'or': 'ରାତ୍ରି ଭୋଜନ'},
    {'en': 'Bedtime', 'hi': 'सोने से पहले', 'or': 'ଶୋଇବା ପୂର୍ବରୁ'},
  ],

  MasterEntity.entity_ServingUnits: const [
    {'en': 'Gram (g)', 'hi': 'ग्राम', 'or': 'ଗ୍ରାମ'},
    {'en': 'Kilogram (kg)', 'hi': 'किलोग्राम', 'or': 'କିଲୋଗ୍ରାମ'},
    {'en': 'Millilitre (ml)', 'hi': 'मिलीलीटर', 'or': 'ମିଲିଲିଟର'},
    {'en': 'Litre (L)', 'hi': 'लीटर', 'or': 'ଲିଟର'},
    {'en': 'Cup', 'hi': 'कप', 'or': 'କପ୍'},
    {'en': 'Bowl', 'hi': 'कटोरा', 'or': 'ବାଟି'},
    {'en': 'Piece', 'hi': 'टुकड़ा', 'or': 'ଖଣ୍ଡ'},
    {'en': 'Teaspoon', 'hi': 'छोटी चम्मच', 'or': 'ଛୋଟ ଚାମଚ'},
    {'en': 'Tablespoon', 'hi': 'बड़ी चम्मच', 'or': 'ବଡ଼ ଚାମଚ'},
  ],

  // ---------- B. COMPLEX / CLINICAL MASTERS (7) ----------

  MasterEntity.entity_DietPlanCategories: const [
    {'en': 'Weight Loss', 'hi': 'वजन घटाना', 'or': 'ଓଜନ କମା'},
    {'en': 'Weight Gain', 'hi': 'वजन बढ़ाना', 'or': 'ଓଜନ ବଢ଼ା'},
    {'en': 'Diabetes Management', 'hi': 'मधुमेह प्रबंधन', 'or': 'ମଧୁମେହ ପରିଚାଳନା'},
    {'en': 'Prediabetes Diet', 'hi': 'प्रीडायबिटीज आहार', 'or': 'ପ୍ରିଡାୟାବେଟିସ୍ ଆହାର'},
    {'en': 'Hypertension Diet', 'hi': 'उच्च रक्तचाप आहार', 'or': 'ଉଚ୍ଚ ରକ୍ତଚାପ ଆହାର'},
    {'en': 'Cardiac Diet', 'hi': 'हृदय आहार', 'or': 'ହୃଦୟ ଆହାର'},
    {'en': 'Renal Diet (CKD)', 'hi': 'किडनी आहार', 'or': 'କିଡନି ଆହାର'},
    {'en': 'Liver Disorder Diet', 'hi': 'लिवर आहार', 'or': 'ଲିଭର ଆହାର'},
    {'en': 'PCOS / PCOD Diet', 'hi': 'पीसीओएस आहार', 'or': 'PCOS ଆହାର'},
    {'en': 'Thyroid Diet', 'hi': 'थायरॉइड आहार', 'or': 'ଥାଇରଏଡ୍ ଆହାର'},
    {'en': 'Anemia Correction Diet', 'hi': 'एनीमिया आहार', 'or': 'ରକ୍ତାଲ୍ପତା ଆହାର'},
    {'en': 'Pregnancy Diet', 'hi': 'गर्भावस्था आहार', 'or': 'ଗର୍ଭାବସ୍ଥା ଆହାର'},
    {'en': 'Lactation Diet', 'hi': 'स्तनपान आहार', 'or': 'ସ୍ତନ୍ୟପାନ ଆହାର'},
    {'en': 'Geriatric Diet', 'hi': 'वृद्ध आहार', 'or': 'ବୃଦ୍ଧ ଆହାର'},
    {'en': 'Gut Health / IBS Diet', 'hi': 'पाचन आहार', 'or': 'ପାଚନ ଆହାର'},
  ],

  MasterEntity.entity_FoodItem: const [
    {'en': 'Rice (White)', 'hi': 'सफेद चावल', 'or': 'ଧଳା ଚାଉଳ'},
    {'en': 'Brown Rice', 'hi': 'ब्राउन राइस', 'or': 'ବାଦାମୀ ଚାଉଳ'},
    {'en': 'Wheat Roti', 'hi': 'गेहूं रोटी', 'or': 'ଗହମ ରୁଟି'},
    {'en': 'Millets (Ragi/Jowar/Bajra)', 'hi': 'मोटे अनाज', 'or': 'ମିଲେଟ୍ସ'},
    {'en': 'Dal (Any)', 'hi': 'दाल', 'or': 'ଡାଲି'},
    {'en': 'Chickpeas', 'hi': 'चना', 'or': 'ଚଣା'},
    {'en': 'Rajma', 'hi': 'राजमा', 'or': 'ରାଜମା'},
    {'en': 'Milk', 'hi': 'दूध', 'or': 'ଦୁଧ'},
    {'en': 'Curd', 'hi': 'दही', 'or': 'ଦହି'},
    {'en': 'Paneer', 'hi': 'पनीर', 'or': 'ପନୀର'},
    {'en': 'Egg (Boiled)', 'hi': 'उबला अंडा', 'or': 'ସିଜା ଅଣ୍ଡା'},
    {'en': 'Chicken', 'hi': 'चिकन', 'or': 'ମୁର୍ଗୀ'},
    {'en': 'Fish', 'hi': 'मछली', 'or': 'ମାଛ'},
    {'en': 'Green Leafy Vegetables', 'hi': 'हरी पत्तेदार सब्ज़ी', 'or': 'ଶାଗ'},
    {'en': 'Root Vegetables', 'hi': 'जड़ वाली सब्ज़ी', 'or': 'ମୂଳ ସବ୍ଜି'},
    {'en': 'Seasonal Fruits', 'hi': 'मौसमी फल', 'or': 'ମୌସୁମୀ ଫଳ'},
    {'en': 'Nuts & Seeds', 'hi': 'मेवे और बीज', 'or': 'ଗୁଡ଼ି ଓ ବୀଜ'},
    {'en': 'Cooking Oil', 'hi': 'खाना पकाने का तेल', 'or': 'ତେଲ'},
  ],

  MasterEntity.entity_disease: const [
    {'en': 'Type 2 Diabetes Mellitus', 'hi': 'टाइप 2 मधुमेह', 'or': 'ଟାଇପ୍ 2 ମଧୁମେହ'},
    {'en': 'Prediabetes', 'hi': 'प्रीडायबिटीज', 'or': 'ପ୍ରିଡାୟାବେଟିସ୍'},
    {'en': 'Hypertension', 'hi': 'उच्च रक्तचाप', 'or': 'ଉଚ୍ଚ ରକ୍ତଚାପ'},
    {'en': 'Coronary Artery Disease', 'hi': 'हृदय धमनी रोग', 'or': 'ହୃଦୟ ଧମନୀ ରୋଗ'},
    {'en': 'Chronic Kidney Disease', 'hi': 'किडनी रोग', 'or': 'ଦୀର୍ଘ କିଡନି ରୋଗ'},
    {'en': 'Fatty Liver Disease', 'hi': 'फैटी लिवर', 'or': 'ଫ୍ୟାଟି ଲିଭର'},
    {'en': 'Cirrhosis of Liver', 'hi': 'लिवर सिरोसिस', 'or': 'ଲିଭର ସିରୋସିସ୍'},
    {'en': 'Hypothyroidism', 'hi': 'हाइपोथायरॉयड', 'or': 'ହାଇପୋଥାଇରଏଡ୍'},
    {'en': 'Hyperthyroidism', 'hi': 'हाइपरथायरॉयड', 'or': 'ହାଇପରଥାଇରଏଡ୍'},
    {'en': 'PCOS / PCOD', 'hi': 'पीसीओएस', 'or': 'PCOS'},
    {'en': 'Iron Deficiency Anemia', 'hi': 'आयरन एनीमिया', 'or': 'ଲୋହ ଅଭାବ'},
    {'en': 'Vitamin D Deficiency', 'hi': 'विटामिन डी की कमी', 'or': 'ଭିଟାମିନ୍ D ଅଭାବ'},
    {'en': 'Osteoporosis', 'hi': 'ऑस्टियोपोरोसिस', 'or': 'ହାଡ଼ କମଜୋର'},
    {'en': 'Gout', 'hi': 'गठिया', 'or': 'ଗାଉଟ୍'},
    {'en': 'IBS', 'hi': 'आईबीएस', 'or': 'IBS'},
    {'en': 'GERD', 'hi': 'जीईआरडी', 'or': 'GERD'},
  ],

  MasterEntity.entity_Investigation: const [
    {'en': 'Hemoglobin', 'hi': 'हीमोग्लोबिन', 'or': 'ହିମୋଗ୍ଲୋବିନ'},
    {'en': 'Complete Blood Count', 'hi': 'पूर्ण रक्त जांच', 'or': 'CBC'},
    {'en': 'Fasting Blood Sugar', 'hi': 'फास्टिंग शुगर', 'or': 'ଉପବାସ ସୁଗର'},
    {'en': 'Post Prandial Blood Sugar', 'hi': 'पीपी शुगर', 'or': 'ଭୋଜନ ପରେ ସୁଗର'},
    {'en': 'HbA1c', 'hi': 'एचबीए1सी', 'or': 'HbA1c'},
    {'en': 'Lipid Profile', 'hi': 'लिपिड प्रोफाइल', 'or': 'ଲିପିଡ ପ୍ରୋଫାଇଲ'},
    {'en': 'Serum Creatinine', 'hi': 'सीरम क्रिएटिनिन', 'or': 'ସିରମ୍ କ୍ରିଏଟିନିନ'},
    {'en': 'Blood Urea', 'hi': 'ब्लड यूरिया', 'or': 'ବ୍ଲଡ୍ ଇଉରିଆ'},
    {'en': 'SGPT (ALT)', 'hi': 'एसजीपीटी', 'or': 'SGPT'},
    {'en': 'SGOT (AST)', 'hi': 'एसजीଓଟି', 'or': 'SGOT'},
    {'en': 'TSH', 'hi': 'टीएसएच', 'or': 'TSH'},
    {'en': 'Vitamin D', 'hi': 'विटामिन डी', 'or': 'ଭିଟାମିନ୍ D'},
    {'en': 'Vitamin B12', 'hi': 'विटामिन बी12', 'or': 'ଭିଟାମିନ୍ B12'},
    {'en': 'Urine Routine', 'hi': 'मूत्र जांच', 'or': 'ମୁତ୍ର ପରୀକ୍ଷା'},
  ],

  MasterEntity.entity_LifestyleHabit: const [
    {'en': 'Smoking', 'hi': 'धूम्रपान', 'or': 'ଧୂମପାନ'},
    {'en': 'Alcohol Use', 'hi': 'शराब सेवन', 'or': 'ମଦ୍ୟପାନ'},
    {'en': 'Tobacco Chewing', 'hi': 'तंबाकू', 'or': 'ତମାଖୁ'},
    {'en': 'Late Night Eating', 'hi': 'देर रात भोजन', 'or': 'ରାତିରେ ଦେରି'},
    {'en': 'Physical Inactivity', 'hi': 'शारीरिक निष्क्रियता', 'or': 'ଶାରୀରିକ ଅକ୍ରିୟତା'},
  ],

  MasterEntity.entity_FoodCategory: const [
    {'en': 'Cereals & Millets', 'hi': 'अनाज', 'or': 'ଶସ୍ୟ'},
    {'en': 'Pulses & Legumes', 'hi': 'दालें', 'or': 'ଡାଲି'},
    {'en': 'Green Leafy Vegetables', 'hi': 'हरी पत्तेदार सब्ज़ी', 'or': 'ଶାଗ'},
    {'en': 'Other Vegetables', 'hi': 'अन्य सब्ज़ी', 'or': 'ଅନ୍ୟ ସବ୍ଜି'},
    {'en': 'Fruits', 'hi': 'फल', 'or': 'ଫଳ'},
    {'en': 'Milk & Milk Products', 'hi': 'दूध उत्पाद', 'or': 'କ୍ଷୀରଜାତ'},
    {'en': 'Egg / Meat / Fish', 'hi': 'अंडा/मांस/मछली', 'or': 'ମାଂସ ଓ ମାଛ'},
    {'en': 'Fats & Oils', 'hi': 'वसा व तेल', 'or': 'ଚର୍ବି ଓ ତେଲ'},
    {'en': 'Sugar & Sweets', 'hi': 'चीनी व मिठाई', 'or': 'ଚିନି'},
  ],

  MasterEntity.entity_Diagnosis: const [
    {'en': 'Overweight', 'hi': 'अधिक वजन', 'or': 'ଅଧିକ ଓଜନ'},
    {'en': 'Obesity', 'hi': 'मोटापा', 'or': 'ଅତିସ୍ଥୂଳତା'},
    {'en': 'Excessive Energy Intake', 'hi': 'अत्यधिक ऊर्जा सेवन', 'or': 'ଅତ୍ୟଧିକ ଶକ୍ତି'},
    {'en': 'Inadequate Energy Intake', 'hi': 'अपर्याप्त ऊर्जा', 'or': 'ଅପର୍ଯ୍ୟାପ୍ତ ଶକ୍ତି'},
    {'en': 'Inadequate Protein Intake', 'hi': 'अपर्याप्त प्रोटीन', 'or': 'ଅପର୍ଯ୍ୟାପ୍ତ ପ୍ରୋଟିନ୍'},
    {'en': 'Iron Deficiency', 'hi': 'आयरन की कमी', 'or': 'ଲୋହ ଅଭାବ'},
    {'en': 'Vitamin D Deficiency', 'hi': 'विटामिन डी की कमी', 'or': 'ଭିଟାମିନ୍ D ଅଭାବ'},
    {'en': 'Poor Glycemic Control', 'hi': 'खराब शुगर नियंत्रण', 'or': 'ଖରାପ ସୁଗର'},
    {'en': 'Dyslipidemia', 'hi': 'डिस्लिपिडेमिया', 'or': 'ଡିସ୍ଲିପିଡେମିଆ'},
  ],
  MasterEntity.entity_supplement: const [
    {'en': 'Multivitamin', 'hi': 'मल्टीविटामिन', 'or': 'ମଲ୍ଟିଭିଟାମିନ୍'},
    {'en': 'Iron Supplement', 'hi': 'आयरन सप्लीमेंट', 'or': 'ଲୋହ ସପ୍ଲିମେଣ୍ଟ'},
    {'en': 'Folic Acid', 'hi': 'फोलिक एसिड', 'or': 'ଫୋଲିକ୍ ଆସିଡ୍'},
    {'en': 'Vitamin B12', 'hi': 'विटामिन बी12', 'or': 'ଭିଟାମିନ୍ B12'},
    {'en': 'Vitamin D3', 'hi': 'विटामिन डी3', 'or': 'ଭିଟାମିନ୍ D3'},
    {'en': 'Calcium', 'hi': 'कैल्शियम', 'or': 'କ୍ୟାଲସିୟମ୍'},
    {'en': 'Calcium + Vitamin D', 'hi': 'कैल्शियम + विटामिन डी', 'or': 'କ୍ୟାଲସିୟମ୍ + D'},
    {'en': 'Omega 3 Fatty Acids', 'hi': 'ओमेगा 3 फैटी एसिड', 'or': 'ଓମେଗା 3'},
    {'en': 'Protein Powder (Whey)', 'hi': 'व्हे प्रोटीन', 'or': 'ହ୍ୱେ ପ୍ରୋଟିନ୍'},
    {'en': 'Protein Powder (Plant)', 'hi': 'प्लांट प्रोटीन', 'or': 'ପ୍ଲାଣ୍ଟ ପ୍ରୋଟିନ୍'},
    {'en': 'Probiotics', 'hi': 'प्रोबायोटिक्स', 'or': 'ପ୍ରୋବାୟୋଟିକ୍ସ'},
    {'en': 'Prebiotics', 'hi': 'प्रीबायोटिक्स', 'or': 'ପ୍ରିବାୟୋଟିକ୍ସ'},
    {'en': 'Digestive Enzymes', 'hi': 'पाचक एंजाइम', 'or': 'ପାଚକ ଏନଜାଇମ୍'},
    {'en': 'Fiber Supplement (Psyllium)', 'hi': 'फाइबर सप्लीमेंट', 'or': 'ଫାଇବର ସପ୍ଲିମେଣ୍ଟ'},
    {'en': 'Magnesium', 'hi': 'मैग्नीशियम', 'or': 'ମ୍ୟାଗ୍ନେସିୟମ୍'},
    {'en': 'Zinc', 'hi': 'जिंक', 'or': 'ଜିଙ୍କ୍'},
    {'en': 'Vitamin C', 'hi': 'विटामिन सी', 'or': 'ଭିଟାମିନ୍ C'},
    {'en': 'Electrolyte Powder', 'hi': 'इलेक्ट्रोलाइट पाउडर', 'or': 'ଇଲେକ୍ଟ୍ରୋଲାଇଟ୍'},
    {'en': 'Oral Nutrition Supplement (ONS)', 'hi': 'ओरल न्यूट्रिशन सप्लीमेंट', 'or': 'ମୁଖ ଆହାର ସପ୍ଲିମେଣ୍ଟ'},
    {'en': 'Medical Nutrition Formula', 'hi': 'चिकित्सीय पोषण फार्मूला', 'or': 'ମେଡିକାଲ୍ ପୋଷଣ ଫର୍ମୁଲା'},
  ],
  MasterEntity.entity_foodHabitsOptions: const [
    {'en': 'Vegetarian', 'hi': 'शाकाहारी', 'or': 'ନିରାମିଷ'},
    {'en': 'Eggetarian', 'hi': 'अंडा खाने वाला', 'or': 'ଅଣ୍ଡା ଭୋକ୍ତା'},
    {'en': 'Non-Vegetarian', 'hi': 'मांसाहारी', 'or': 'ମାଂସାହାରୀ'},
    {'en': 'Vegan', 'hi': 'वीगन', 'or': 'ଭେଗାନ୍'},
    {'en': 'Pure Vegetarian (No Onion/Garlic)', 'hi': 'शुद्ध शाकाहारी', 'or': 'ଶୁଦ୍ଧ ନିରାମିଷ'},
    {'en': 'Jain Diet', 'hi': 'जैन आहार', 'or': 'ଜୈନ ଆହାର'},
    {'en': 'Mixed Diet', 'hi': 'मिश्रित आहार', 'or': 'ମିଶ୍ରିତ ଆହାର'},
    {'en': 'Occasional Non-Vegetarian', 'hi': 'कभी-कभी मांसाहार', 'or': 'କେବେ କେବେ ମାଂସ'},
    {'en': 'High Protein Diet', 'hi': 'उच्च प्रोटीन आहार', 'or': 'ଉଚ୍ଚ ପ୍ରୋଟିନ୍ ଆହାର'},
    {'en': 'Low Carb Diet', 'hi': 'कम कार्बोहाइड्रेट आहार', 'or': 'କମ୍ କାର୍ବୋହାଇଡ୍ରେଟ୍'},
    {'en': 'Low Fat Diet', 'hi': 'कम वसा आहार', 'or': 'କମ୍ ଚର୍ବି ଆହାର'},
    {'en': 'High Fiber Diet', 'hi': 'उच्च फाइबर आहार', 'or': 'ଉଚ୍ଚ ଫାଇବର ଆହାର'},
    {'en': 'Soft Diet', 'hi': 'नरम आहार', 'or': 'ନରମ ଆହାର'},
    {'en': 'Liquid Diet', 'hi': 'तरल आहार', 'or': 'ତରଳ ଆହାର'},
    {'en': 'Semi-Solid Diet', 'hi': 'अर्ध-ठोस आहार', 'or': 'ଅର୍ଧଠୋସ ଆହାର'},
    {'en': 'Therapeutic Diet', 'hi': 'चिकित्सीय आहार', 'or': 'ଚିକିତ୍ସାମୂଳକ ଆହାର'},
    {'en': 'Culturally Restricted Diet', 'hi': 'सांस्कृतिक प्रतिबंधित आहार', 'or': 'ସାଂସ୍କୃତିକ ନିୟମିତ ଆହାର'},
    {'en': 'Fasting Pattern (Religious)', 'hi': 'उपवास आधारित आहार', 'or': 'ଉପବାସ ଆଧାରିତ'},
  ],
  MasterEntity.entity_develop_habits: const [
    {'en': 'Regular Meal Timing', 'hi': 'नियमित समय पर भोजन', 'or': 'ନିୟମିତ ସମୟରେ ଭୋଜନ'},
    {'en': 'Daily Physical Activity', 'hi': 'दैनिक शारीरिक गतिविधि', 'or': 'ଦୈନିକ ଶାରୀରିକ କ୍ରିୟା'},
    {'en': 'Morning Walk', 'hi': 'सुबह की सैर', 'or': 'ସକାଳ ହାଟିବା'},
    {'en': 'Regular Exercise Routine', 'hi': 'नियमित व्यायाम', 'or': 'ନିୟମିତ ବ୍ୟାୟାମ'},
    {'en': 'Adequate Water Intake', 'hi': 'पर्याप्त पानी पीना', 'or': 'ପର୍ଯ୍ୟାପ୍ତ ପାଣି ପିବା'},
    {'en': 'Mindful Eating', 'hi': 'सचेत भोजन', 'or': 'ସଚେତନ ଭୋଜନ'},
    {'en': 'Eating Home-Cooked Food', 'hi': 'घर का बना भोजन', 'or': 'ଘରେ ପକା ଖାଦ୍ୟ'},
    {'en': 'Including Fruits Daily', 'hi': 'प्रतिदिन फल शामिल करना', 'or': 'ଦୈନିକ ଫଳ ଖାଇବା'},
    {'en': 'Including Vegetables Daily', 'hi': 'प्रतिदिन सब्ज़ी शामिल करना', 'or': 'ଦୈନିକ ସବ୍ଜି ଖାଇବା'},
    {'en': 'Adequate Protein Intake', 'hi': 'पर्याप्त प्रोटीन सेवन', 'or': 'ପର୍ଯ୍ୟାପ୍ତ ପ୍ରୋଟିନ୍'},
    {'en': 'Limiting Sugar Intake', 'hi': 'चीनी का सेवन सीमित करना', 'or': 'ଚିନି କମାଇବା'},
    {'en': 'Limiting Salt Intake', 'hi': 'नमक का सेवन सीमित करना', 'or': 'ଲୁଣ କମାଇବା'},
    {'en': 'Avoiding Junk Food', 'hi': 'जंक फूड से बचाव', 'or': 'ଜଙ୍କ ଫୁଡ୍ ଏଡ଼ାଇବା'},
    {'en': 'Avoiding Late Night Eating', 'hi': 'देर रात भोजन से बचना', 'or': 'ରାତିରେ ଦେରି ଭୋଜନ ଏଡ଼ାଇବା'},
    {'en': 'Adequate Sleep Routine', 'hi': 'पर्याप्त नींद की दिनचर्या', 'or': 'ପର୍ଯ୍ୟାପ୍ତ ନିଦ୍ରା ଅଭ୍ୟାସ'},
    {'en': 'Stress Management Practice', 'hi': 'तनाव प्रबंधन अभ्यास', 'or': 'ଚାପ ନିୟନ୍ତ୍ରଣ ଅଭ୍ୟାସ'},
    {'en': 'Regular Health Check-ups', 'hi': 'नियमित स्वास्थ्य जांच', 'or': 'ନିୟମିତ ସ୍ୱାସ୍ଥ୍ୟ ଯାଞ୍ଚ'},
    {'en': 'Medication Adherence', 'hi': 'दवा का नियमित पालन', 'or': 'ଔଷଧ ନିୟମିତ ନେବା'},
    {'en': 'Monitoring Weight Regularly', 'hi': 'नियमित वजन निगरानी', 'or': 'ନିୟମିତ ଓଜନ ଯାଞ୍ଚ'},
    {'en': 'Monitoring Blood Sugar/BP', 'hi': 'शुगर/बीपी की निगरानी', 'or': 'ସୁଗର/ବିପି ଯାଞ୍ଚ'},
    {'en': 'Positive Lifestyle Changes', 'hi': 'सकारात्मक जीवनशैली परिवर्तन', 'or': 'ସକାରାତ୍ମକ ଜୀବନଶୈଳୀ'},
    {'en': 'Consistency in Diet Plan', 'hi': 'आहार योजना में निरंतरता', 'or': 'ଆହାରରେ ନିୟମିତତା'},
  ],
  MasterEntity.entity_packagefeature: const [
    {'en': 'Personalized Diet Plan', 'hi': 'व्यक्तिगत आहार योजना', 'or': 'ବ୍ୟକ୍ତିଗତ ଆହାର ଯୋଜନା'},
    {'en': 'Doctor Consultation', 'hi': 'डॉक्टर परामर्श', 'or': 'ଡାକ୍ତର ପରାମର୍ଶ'},
    {'en': 'Dietitian Consultation', 'hi': 'डायटीशियन परामर्श', 'or': 'ଡାଇଟିସିଆନ୍ ପରାମର୍ଶ'},
    {'en': 'Weekly Follow-up', 'hi': 'साप्ताहिक फॉलो-अप', 'or': 'ସାପ୍ତାହିକ ଅନୁସରଣ'},
    {'en': 'Monthly Review', 'hi': 'मासिक समीक्षा', 'or': 'ମାସିକ ସମୀକ୍ଷା'},
    {'en': 'WhatsApp / Chat Support', 'hi': 'व्हाट्सएप सहायता', 'or': 'ହ୍ୱାଟସ୍ଆପ୍ ସହାୟତା'},
    {'en': 'Progress Tracking', 'hi': 'प्रगति ट्रैकिंग', 'or': 'ପ୍ରଗତି ଟ୍ରାକିଂ'},
    {'en': 'Weight Monitoring', 'hi': 'वजन निगरानी', 'or': 'ଓଜନ ନିରୀକ୍ଷଣ'},
    {'en': 'Lifestyle Counselling', 'hi': 'जीवनशैली परामर्श', 'or': 'ଜୀବନଶୈଳୀ ପରାମର୍ଶ'},
    {'en': 'Exercise Guidance', 'hi': 'व्यायाम मार्गदर्शन', 'or': 'ବ୍ୟାୟାମ ମାର୍ଗଦର୍ଶନ'},
    {'en': 'Recipe Suggestions', 'hi': 'रेसिपी सुझाव', 'or': 'ରେସିପି ପରାମର୍ଶ'},
    {'en': 'Lab Report Review', 'hi': 'लैब रिपोर्ट समीक्षा', 'or': 'ଲ୍ୟାବ୍ ରିପୋର୍ଟ ସମୀକ୍ଷା'},
    {'en': 'Goal Setting & Monitoring', 'hi': 'लक्ष्य निर्धारण', 'or': 'ଲକ୍ଷ୍ୟ ନିର୍ଦ୍ଧାରଣ'},
  ],
  MasterEntity.entity_packageInclusion: [
    {'en': 'Initial Assessment', 'hi': 'प्रारंभिक मूल्यांकन', 'or': 'ପ୍ରାରମ୍ଭିକ ମୂଲ୍ୟାଙ୍କନ'},
    {'en': 'Detailed Case History', 'hi': 'विस्तृत केस हिस्ट्री', 'or': 'ବିସ୍ତୃତ କେସ୍ ଇତିହାସ'},
    {'en': 'Anthropometric Measurements', 'hi': 'शारीरिक माप', 'or': 'ଶାରୀରିକ ମାପ'},
    {'en': 'Diet Recall Analysis', 'hi': 'डाइट रिकॉल विश्लेषण', 'or': 'ଆହାର ବିଶ୍ଳେଷଣ'},
    {'en': 'Customized Meal Plan', 'hi': 'अनुकूलित भोजन योजना', 'or': 'କଷ୍ଟମାଇଜ୍ ଭୋଜନ'},
    {'en': 'Supplement Guidance', 'hi': 'सप्लीमेंट मार्गदर्शन', 'or': 'ସପ୍ଲିମେଣ୍ଟ ମାର୍ଗଦର୍ଶନ'},
    {'en': 'Lifestyle Modification Plan', 'hi': 'जीवनशैली सुधार योजना', 'or': 'ଜୀବନଶୈଳୀ ଯୋଜନା'},
    {'en': 'Follow-up Consultations', 'hi': 'फॉलो-अप परामर्श', 'or': 'ଅନୁସରଣ ପରାମର୍ଶ'},
    {'en': 'Progress Reports', 'hi': 'प्रगति रिपोर्ट', 'or': 'ପ୍ରଗତି ରିପୋର୍ଟ'},
    {'en': 'Educational Material', 'hi': 'शैक्षिक सामग्री', 'or': 'ଶିକ୍ଷାମୂଳକ ସାମଗ୍ରୀ'},
    {'en': 'Tele-consultation Access', 'hi': 'टेली परामर्श सुविधा', 'or': 'ଟେଲି ପରାମର୍ଶ'},
    {'en': 'Emergency Query Support', 'hi': 'आपात प्रश्न सहायता', 'or': 'ଆପାତକାଳୀନ ସହାୟତା'},
  ],
  MasterEntity.entity_packageType: [
    {'en': 'Basic Care Package', 'hi': 'बेसिक केयर पैकेज', 'or': 'ବେସିକ୍ କେୟାର୍ ପ୍ୟାକେଜ୍'},
    {'en': 'Standard Wellness Package', 'hi': 'स्टैंडर्ड वेलनेस पैकेज', 'or': 'ଷ୍ଟାଣ୍ଡାର୍ଡ୍ ୱେଲନେସ୍'},
    {'en': 'Advanced Clinical Package', 'hi': 'एडवांस क्लिनिकल पैकेज', 'or': 'ଏଡଭାନ୍ସ୍ କ୍ଲିନିକାଲ୍'},
    {'en': 'Chronic Disease Management Package', 'hi': 'दीर्घकालिक रोग पैकेज', 'or': 'ଦୀର୍ଘ ରୋଗ ପ୍ୟାକେଜ୍'},
    {'en': 'Weight Management Package', 'hi': 'वजन प्रबंधन पैकेज', 'or': 'ଓଜନ ପରିଚାଳନା'},
    {'en': 'Corporate Wellness Package', 'hi': 'कॉर्पोरेट वेलनेस पैकेज', 'or': 'କର୍ପୋରେଟ୍ ୱେଲନେସ୍'},
    {'en': 'Pregnancy & Maternal Package', 'hi': 'गर्भावस्था पैकेज', 'or': 'ଗର୍ଭାବସ୍ଥା ପ୍ୟାକେଜ୍'},
    {'en': 'Senior Citizen Care Package', 'hi': 'वरिष्ठ नागरिक पैकेज', 'or': 'ବୃଦ୍ଧ ସେବା ପ୍ୟାକେଜ୍'},
  ],
  MasterEntity.entity_packageTargetCondition: [
    {'en': 'Weight Loss', 'hi': 'वजन घटाना', 'or': 'ଓଜନ କମା'},
    {'en': 'Weight Gain', 'hi': 'वजन बढ़ाना', 'or': 'ଓଜନ ବଢ଼ା'},
    {'en': 'Diabetes Mellitus', 'hi': 'मधुमेह', 'or': 'ମଧୁମେହ'},
    {'en': 'Prediabetes', 'hi': 'प्रीडायबिटीज', 'or': 'ପ୍ରିଡାୟାବେଟିସ୍'},
    {'en': 'Hypertension', 'hi': 'उच्च रक्तचाप', 'or': 'ଉଚ୍ଚ ରକ୍ତଚାପ'},
    {'en': 'Heart Disease', 'hi': 'हृदय रोग', 'or': 'ହୃଦୟ ରୋଗ'},
    {'en': 'PCOS / PCOD', 'hi': 'पीसीओएस', 'or': 'PCOS'},
    {'en': 'Thyroid Disorders', 'hi': 'थायरॉइड विकार', 'or': 'ଥାଇରଏଡ୍ ସମସ୍ୟା'},
    {'en': 'Anemia', 'hi': 'एनीमिया', 'or': 'ରକ୍ତାଲ୍ପତା'},
    {'en': 'Fatty Liver Disease', 'hi': 'फैटी लिवर', 'or': 'ଫ୍ୟାଟି ଲିଭର'},
    {'en': 'Chronic Kidney Disease', 'hi': 'किडनी रोग', 'or': 'କିଡନି ରୋଗ'},
    {'en': 'Digestive Disorders', 'hi': 'पाचन विकार', 'or': 'ପାଚନ ସମସ୍ୟା'},
    {'en': 'Pregnancy Nutrition', 'hi': 'गर्भावस्था पोषण', 'or': 'ଗର୍ଭ ପୋଷଣ'},
    {'en': 'Geriatric Nutrition', 'hi': 'वृद्ध पोषण', 'or': 'ବୃଦ୍ଧ ପୋଷଣ'},
    {'en': 'General Wellness', 'hi': 'सामान्य स्वास्थ्य', 'or': 'ସାଧାରଣ ସ୍ୱାସ୍ଥ୍ୟ'},
  ],







};

// --- 2. UPLOADER LOGIC (Handles 14 Simple and 7 Complex Entities) ---
class BulkMasterUploaderService {
  final WidgetRef ref;
  final ClinicalMasterService clinicalMasterService;
  final FirebaseFirestore _firestore;

  BulkMasterUploaderService(this.ref)
      : clinicalMasterService = ref.read(clinicalMasterServiceProvider),
        _firestore = ref.read(firestoreProvider); // Assume firestoreProvider gives FirebaseFirestore instance

  Future<Map<String, int>> uploadAllMasters() async {
    final Map<String, int> results = {};
    final mapper = MasterCollectionMapper.getPath;

    final complexEntities = [
      MasterEntity.entity_FoodItem, MasterEntity.entity_supplement,
      MasterEntity.entity_disease, MasterEntity.entity_Investigation,
      MasterEntity.entity_develop_habits, MasterEntity.entity_FoodCategory,
      MasterEntity.entity_Diagnosis,MasterEntity.entity_MealNames
    ];

    for (final entry in _defaultMasterData.entries) {
      final entityName = entry.key;
      final defaultItems = entry.value;

      final collectionPath = mapper(entityName);
      int itemsInserted = 0;

      for (final itemMap in defaultItems) {
        final englishName = itemMap['en'] as String;
        final nameLocalized = {
          'hi': itemMap['hi'] as String,
          'or': itemMap['or'] as String,
        };

        if (complexEntities.contains(entityName)) {
          // --- COMPLEX ENTITY SAVE (Placeholder logic for the 7 Complex Entities) ---

          // Check for duplicate manually before inserting placeholder
          final existing = await _firestore.collection(collectionPath)
              .where('name', isEqualTo: englishName)
              .where('isDeleted', isEqualTo: false)
              .limit(1)
              .get();

          if (existing.docs.isEmpty) {
            // Minimal data structure for complex models (must be manually extended later)
            final complexData = {
              'name': englishName,
              'nameLocalized': nameLocalized,
              'isDeleted': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
         //    'isMasterTemplate': true, // Essential field for some complex masters
              // Note: Other required fields (e.g., calories, ICDCode) are intentionally missing here
            };
            await _firestore.collection(collectionPath).add(complexData);
            itemsInserted++;
          }
        } else {
          // --- SIMPLE ENTITY SAVE (Uses generic ClinicalMasterService which has built-in duplicate check) ---
          final item = ClinicalItemModel(
            id: '',
            name: englishName,
            nameLocalized: nameLocalized,
          );
          try {
            await clinicalMasterService.saveItem(collectionPath, item);
            itemsInserted++;
          } on Exception catch (e) {
            if (!e.toString().contains('already exists')) {
              rethrow;
            }
          }
        }
      }
      results[entityName] = itemsInserted;
    }
    return results;
  }
}


// --- 3. UI SCREEN (Updated text description) ---
class MasterDataUploaderScreen extends ConsumerStatefulWidget {
  const MasterDataUploaderScreen({super.key});

  @override
  ConsumerState<MasterDataUploaderScreen> createState() => _MasterDataUploaderScreenState();
}

class _MasterDataUploaderScreenState extends ConsumerState<MasterDataUploaderScreen> {
  bool _isLoading = false;
  Map<String, int> _uploadResults = {};

  Future<void> _startUpload() async {
    setState(() {
      _isLoading = true;
      _uploadResults = {};
    });

    try {
      final uploader = BulkMasterUploaderService(ref);
      final results = await uploader.uploadAllMasters();
      setState(() {
        _uploadResults = results;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Master data upload complete!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error during upload: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Uploader'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Initial Master Data Setup",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This tool will upload essential default items for ALL 21 master entities, including Hindi and Oriya translations. Complex masters (7 entities) are created as basic placeholders and must be completed via their dedicated entry screens.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startUpload,
                icon: Icon(_isLoading ? Icons.cloud_upload : Icons.start, color: Colors.white),
                label: Text(
                  _isLoading ? "Uploading..." : "Run Initial Master Upload (21 Entities)",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.deepPurple.shade300 : Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Center(child: LinearProgressIndicator()),
              ),

            // Results Display
            if (_uploadResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload Results (21 entities covered):",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _uploadResults.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('${entry.value} inserted', style: TextStyle(color: entry.value > 0 ? Colors.green.shade800 : Colors.grey.shade600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "*Items that previously existed were skipped to avoid duplicates.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}