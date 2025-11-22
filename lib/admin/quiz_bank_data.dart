import 'package:nutricare_client_management/admin/quiz_model.dart';

// 🎯 THE MASTER LIST
final List<QuizQuestion> masterQuizBank = [
  // =================================================================
  // 🇮🇳 INDIAN FOOD & SPICES
  // =================================================================
  QuizQuestion(
    id: 'ind_spice_01',
    category: 'Indian Spices',
    question: "Eating Turmeric (Haldi) raw is the best way to absorb Curcumin.",
    isFact: false,
    explanation:
        "Myth! Curcumin is poorly absorbed on its own. It needs Black Pepper (Piperine) and a fat source (like Ghee/Milk) for maximum absorption.",
  ),
  QuizQuestion(
    id: 'ind_spice_02',
    category: 'Indian Spices',
    question: "Cinnamon (Dalchini) can help lower blood sugar levels.",
    isFact: true,
    explanation:
        "Fact. Studies show that Cinnamon helps improve insulin sensitivity and lower blood sugar levels in Type 2 Diabetes.",
  ),
  QuizQuestion(
    id: 'ind_food_03',
    category: 'Indian Food',
    question: "Ghee is pure fat and causes heart attacks.",
    isFact: false,
    explanation:
        "Myth. Ghee contains healthy fats (CLA) and vitamins A, D, E, K. In moderation (1 tsp/meal), it is heart-healthy and good for digestion.",
  ),
  QuizQuestion(
    id: 'ind_food_04',
    category: 'Indian Food',
    question: "Pickles (Achar) are good for gut health.",
    isFact: true,
    explanation:
        "Fact. Traditionally fermented pickles act as probiotics, aiding gut bacteria. However, watch the oil and salt content!",
  ),
  QuizQuestion(
    id: 'ind_spice_05',
    category: 'Indian Spices',
    question: "Cumin (Jeera) water helps with digestion.",
    isFact: true,
    explanation:
        "Fact. Jeera stimulates the secretion of digestive enzymes and accelerates the digestion process, reducing bloating.",
  ),
  QuizQuestion(
    id: 'ind_food_06',
    category: 'Indian Food',
    question: "Rice is the main reason for obesity in India.",
    isFact: false,
    explanation:
        "Myth. Rice isn't the enemy; portion size and lack of activity are. Eating rice with plenty of dal/sabzi (fiber & protein) balances the meal.",
  ),
  QuizQuestion(
    id: 'ind_spice_07',
    category: 'Indian Spices',
    question: "Fenugreek (Methi) seeds are useless for hair health.",
    isFact: false,
    explanation:
        "Myth. Methi is rich in protein and nicotinic acid, which are renowned for treating hair fall and dandruff.",
  ),

  // =================================================================
  // 🩸 CHRONIC DISEASES (Diabetes, BP, Thyroid)
  // =================================================================
  QuizQuestion(
    id: 'dia_01',
    category: 'Diabetes',
    question: "Diabetics should completely stop eating fruits.",
    isFact: false,
    explanation:
        "Myth. Whole fruits have fiber. Low GI fruits like Guava, Apple, and Berries are excellent for diabetics in moderation.",
  ),
  QuizQuestion(
    id: 'dia_02',
    category: 'Diabetes',
    question: "Karela (Bitter Gourd) juice can cure diabetes permanently.",
    isFact: false,
    explanation:
        "Myth. While Karela contains compounds that lower blood sugar, it manages the condition but does not 'cure' it permanently. Meds are still needed.",
  ),
  QuizQuestion(
    id: 'bp_03',
    category: 'Hypertension',
    question: "Pink Salt (Sendha Namak) is safe to eat in unlimited amounts.",
    isFact: false,
    explanation:
        "Myth. While it has more minerals, it is still mostly Sodium Chloride. Excess intake will still raise blood pressure.",
  ),
  QuizQuestion(
    id: 'thy_04',
    category: 'Thyroid',
    question: "Soy products are dangerous for everyone with Thyroid issues.",
    isFact: false,
    explanation:
        "Myth. Soy acts as a goitrogen only if you are Iodine deficient. If your iodine levels are normal, moderate soy is usually fine.",
  ),
  QuizQuestion(
    id: 'dia_05',
    category: 'Diabetes',
    question: "Stress can raise your blood sugar levels.",
    isFact: true,
    explanation:
        "Fact. Stress releases cortisol and adrenaline, which signal your liver to release glucose, spiking blood sugar.",
  ),

  // =================================================================
  // ⚖️ WEIGHT MANAGEMENT
  // =================================================================
  QuizQuestion(
    id: 'wt_01',
    category: 'Weight Loss',
    question: "Skipping dinner is the fastest way to lose weight.",
    isFact: false,
    explanation:
        "Myth. Skipping meals slows down metabolism and often leads to binge eating the next morning. A light dinner is better than no dinner.",
  ),
  QuizQuestion(
    id: 'wt_02',
    category: 'Weight Loss',
    question: "Drinking hot water melts body fat.",
    isFact: false,
    explanation:
        "Myth. Water temperature doesn't burn fat. Fat loss happens only when you are in a calorie deficit.",
  ),
  QuizQuestion(
    id: 'wt_03',
    category: 'Weight Loss',
    question: "Protein is essential for weight loss.",
    isFact: true,
    explanation:
        "Fact. Protein increases satiety (fullness) and has a higher thermic effect, meaning your body burns more calories digesting it.",
  ),
  QuizQuestion(
    id: 'wt_04',
    category: 'Weight Loss',
    question: "You can target belly fat by doing crunches.",
    isFact: false,
    explanation:
        "Myth (Spot Reduction). You cannot decide where you lose fat. Crunches build muscle, but a calorie deficit is needed to reveal them.",
  ),
  QuizQuestion(
    id: 'wt_05',
    category: 'Weight Loss',
    question: "Eating late at night makes you gain weight.",
    isFact: false,
    explanation:
        "Myth. It's not the *time* that causes gain, it's the *amount*. However, late eating often leads to mindless snacking.",
  ),

  // =================================================================
  // 🍎 NUTRIENTS & GENERAL
  // =================================================================
  QuizQuestion(
    id: 'nut_01',
    category: 'Nutrients',
    question: "Vitamin D is actually a hormone.",
    isFact: true,
    explanation:
        "Fact. Unlike other vitamins, your body makes Vitamin D from sunlight, and it acts like a hormone to regulate calcium.",
  ),
  QuizQuestion(
    id: 'nut_02',
    category: 'Nutrients',
    question: "Spinach is the best source of Iron.",
    isFact: false,
    explanation:
        "Myth. While it has iron, it also has oxalates that block absorption. Lentils and meat are often better absorbed sources.",
  ),
  QuizQuestion(
    id: 'nut_03',
    category: 'Nutrients',
    question: "Carbohydrates are essential for brain function.",
    isFact: true,
    explanation:
        "Fact. Glucose (from carbs) is the brain's primary fuel source. Cutting carbs too low can cause brain fog.",
  ),
  QuizQuestion(
    id: 'nut_04',
    category: 'Nutrients',
    question: "Multivitamins can replace a healthy diet.",
    isFact: false,
    explanation:
        "Myth. Supplements cannot replicate the complex mix of fiber and phytochemicals found in whole foods.",
  ),
  QuizQuestion(
    id: 'nut_05',
    category: 'Nutrients',
    question: "Omega-3 fatty acids help reduce inflammation.",
    isFact: true,
    explanation:
        "Fact. Found in fish, walnuts, and flaxseeds, Omega-3s are powerful anti-inflammatory agents.",
  ),

  QuizQuestion(
    id: 'ind_life_01',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Starting your day with poha, upma, or idli helps maintain energy without spiking blood sugar.",
    isFact: true,
    explanation:
        "These foods have complex carbs and fiber that release energy slowly, supporting stable blood sugar and focus.",
  ),
  QuizQuestion(
    id: 'ind_life_02',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Skipping breakfast helps reduce overall calorie intake and is always beneficial.",
    isFact: false,
    explanation:
        "Skipping breakfast can increase hunger later and lead to overeating, causing energy crashes and poor metabolic control.",
  ),
  QuizQuestion(
    id: 'ind_life_03',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Adding a pinch of turmeric to daily meals can support inflammation reduction.",
    isFact: true,
    explanation:
        "Curcumin in turmeric has anti-inflammatory properties and supports joint and gut health.",
  ),
  QuizQuestion(
    id: 'ind_life_04',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Ghee should be completely avoided for heart health in all Indian diets.",
    isFact: false,
    explanation:
        "Moderate ghee provides healthy fats and fat-soluble vitamins, especially in traditional Indian cooking.",
  ),
  QuizQuestion(
    id: 'ind_life_05',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking chai with sugar multiple times a day can impact blood sugar and energy levels.",
    isFact: true,
    explanation:
        "Excess sugar in tea increases calorie intake and causes energy swings, contributing to insulin resistance over time.",
  ),
  QuizQuestion(
    id: 'ind_life_06',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating fried samosas and pakoras occasionally has no effect on heart or liver health.",
    isFact: false,
    explanation:
        "Frequent fried snacks increase trans fats and metabolic risk; moderation is important.",
  ),
  QuizQuestion(
    id: 'ind_life_07',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including seasonal fruits like guava, papaya, and orange provides vitamin C and antioxidants.",
    isFact: true,
    explanation:
        "Seasonal fruits strengthen immunity and support skin, gut, and overall health.",
  ),
  QuizQuestion(
    id: 'ind_life_08',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking buttermilk after lunch can aid digestion in Indian meals.",
    isFact: true,
    explanation:
        "Probiotics in buttermilk support gut microbiota and improve digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_09',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating only fruits or juice for dinner helps in detoxification and weight loss.",
    isFact: false,
    explanation:
        "This can cause nutrient deficiencies, energy loss, and disrupt sleep; balanced meals are better.",
  ),
  QuizQuestion(
    id: 'ind_life_10',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Walking for 20-30 minutes after meals can aid digestion and blood sugar control.",
    isFact: true,
    explanation:
        "Post-meal activity improves insulin sensitivity and prevents spikes in blood sugar.",
  ),
  QuizQuestion(
    id: 'ind_life_11',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Using jaggery instead of refined sugar makes desserts completely healthy.",
    isFact: false,
    explanation:
        "Jaggery has slightly more micronutrients but still adds sugar and calories; moderation is key.",
  ),
  QuizQuestion(
    id: 'ind_life_12',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including lentils (dal) in daily meals provides protein, fiber, and supports gut health.",
    isFact: true,
    explanation:
        "Dal contains essential amino acids and soluble fiber, aiding satiety, blood sugar control, and digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_13',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking warm water first thing in the morning helps in digestion and hydration.",
    isFact: true,
    explanation:
        "Warm water stimulates the digestive tract and helps maintain hydration after sleep.",
  ),
  QuizQuestion(
    id: 'ind_life_14',
    category: 'Indian Lifestyle Nutrition',
    question: "Eating late-night snacks has no impact on metabolism or weight.",
    isFact: false,
    explanation:
        "Late eating can disrupt circadian rhythm, affect metabolism, and contribute to weight gain.",
  ),
  QuizQuestion(
    id: 'ind_life_15',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Chewing food slowly and mindfully improves digestion and prevents overeating.",
    isFact: true,
    explanation:
        "Mindful eating increases satiety, reduces digestive stress, and supports better nutrient absorption.",
  ),
  QuizQuestion(
    id: 'ind_life_16',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating breakfast with protein like eggs, paneer, or dal improves satiety and concentration.",
    isFact: true,
    explanation:
        "Protein stabilizes blood sugar and keeps you full longer, reducing mid-morning cravings.",
  ),
  QuizQuestion(
    id: 'ind_life_17',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Having fried snacks with chai every day has no long-term effect on health.",
    isFact: false,
    explanation:
        "Regular fried foods increase saturated fat intake, contributing to obesity, cholesterol, and heart disease.",
  ),
  QuizQuestion(
    id: 'ind_life_18',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including turmeric in daily cooking may reduce inflammation and support joint health.",
    isFact: true,
    explanation:
        "Curcumin in turmeric has anti-inflammatory properties beneficial for chronic conditions.",
  ),
  QuizQuestion(
    id: 'ind_life_19',
    category: 'Indian Lifestyle Nutrition',
    question: "Skipping meals improves metabolism and helps burn fat faster.",
    isFact: false,
    explanation:
        "Skipping meals often leads to overeating later and disrupts metabolic balance.",
  ),
  QuizQuestion(
    id: 'ind_life_20',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating fiber-rich foods like whole wheat roti, brown rice, and vegetables supports blood sugar control.",
    isFact: true,
    explanation:
        "Fiber slows glucose absorption, prevents spikes, and promotes gut health.",
  ),
  QuizQuestion(
    id: 'ind_life_21',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Ghee in moderation can improve taste and provide fat-soluble vitamins.",
    isFact: true,
    explanation:
        "Moderate ghee intake supports vitamin absorption and provides healthy fats for energy.",
  ),
  QuizQuestion(
    id: 'ind_life_22',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating street food occasionally has no effect on gut health or immunity.",
    isFact: false,
    explanation:
        "Street food may carry bacteria or excess oil, impacting digestion and metabolic health.",
  ),
  QuizQuestion(
    id: 'ind_life_23',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking water before meals can reduce overeating and support digestion.",
    isFact: true,
    explanation:
        "Water helps create a sense of fullness and supports proper digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_24',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming jaggery instead of sugar makes sweets completely healthy.",
    isFact: false,
    explanation:
        "Jaggery has minor nutrients but still contributes sugar and calories; moderation is key.",
  ),
  QuizQuestion(
    id: 'ind_life_25',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including seasonal fruits like mangoes, guavas, or papaya provides essential vitamins and antioxidants.",
    isFact: true,
    explanation:
        "Seasonal fruits strengthen immunity and support skin, energy, and digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_26',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking warm water first thing in the morning supports liver detoxification and metabolism.",
    isFact: true,
    explanation:
        "Warm water stimulates digestion and helps hydrate after a night of fasting.",
  ),
  QuizQuestion(
    id: 'ind_life_27',
    category: 'Indian Lifestyle Nutrition',
    question: "Late-night snacking has no impact on weight or metabolism.",
    isFact: false,
    explanation:
        "Eating late can disrupt circadian rhythm and increase fat storage, affecting weight.",
  ),
  QuizQuestion(
    id: 'ind_life_28',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Chewing food slowly and mindfully aids digestion and prevents overeating.",
    isFact: true,
    explanation:
        "Mindful eating increases satiety and helps the digestive system process food efficiently.",
  ),
  QuizQuestion(
    id: 'ind_life_29',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Skipping vegetables in your daily diet does not affect overall health.",
    isFact: false,
    explanation:
        "Vegetables provide essential fiber, vitamins, and antioxidants necessary for immunity and metabolism.",
  ),
  QuizQuestion(
    id: 'ind_life_30',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Walking for 20 minutes after lunch or dinner helps control blood sugar.",
    isFact: true,
    explanation:
        "Post-meal activity improves insulin sensitivity and prevents glucose spikes.",
  ),
  QuizQuestion(
    id: 'ind_life_31',
    category: 'Indian Lifestyle Nutrition',
    question:
        "High-sugar Indian sweets like laddoo and jalebi have no impact if eaten daily.",
    isFact: false,
    explanation:
        "Excess sugar increases risk of diabetes, fatty liver, and weight gain.",
  ),
  QuizQuestion(
    id: 'ind_life_32',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including lentils, beans, and dals in meals provides protein, fiber, and micronutrients.",
    isFact: true,
    explanation:
        "Legumes are essential for vegetarians, supporting muscle, gut, and metabolic health.",
  ),
  QuizQuestion(
    id: 'ind_life_33',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking sweetened chai multiple times a day has no effect on energy levels or metabolism.",
    isFact: false,
    explanation:
        "Excess sugar leads to energy crashes and can worsen insulin resistance.",
  ),
  QuizQuestion(
    id: 'ind_life_34',
    category: 'Indian Lifestyle Nutrition',
    question: "Using homemade yogurt or curd daily supports gut and immunity.",
    isFact: true,
    explanation:
        "Probiotics in curd promote beneficial gut bacteria and improve digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_35',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Fasting for long hours without planning is always beneficial for weight loss.",
    isFact: false,
    explanation:
        "Improper fasting can cause nutrient deficiencies, energy dips, and overeating later.",
  ),
  QuizQuestion(
    id: 'ind_life_36',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Adding fenugreek, cinnamon, and cumin to Indian dishes may help in blood sugar control.",
    isFact: true,
    explanation:
        "Certain Indian spices improve insulin sensitivity and have antioxidant properties.",
  ),
  QuizQuestion(
    id: 'ind_life_37',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating polished white rice in every meal has no effect on blood sugar.",
    isFact: false,
    explanation:
        "Refined rice causes rapid glucose spikes; whole grains are preferable for metabolic health.",
  ),
  QuizQuestion(
    id: 'ind_life_38',
    category: 'Indian Lifestyle Nutrition',
    question: "Hydration is important even if your diet is healthy.",
    isFact: true,
    explanation:
        "Water supports digestion, metabolism, detoxification, and overall energy levels.",
  ),
  QuizQuestion(
    id: 'ind_life_39',
    category: 'Indian Lifestyle Nutrition',
    question:
        "All packaged and labeled 'low-fat' Indian foods are healthy options.",
    isFact: false,
    explanation:
        "Many low-fat products contain hidden sugar or refined carbs; whole foods are safer and more nutritious.",
  ),
  QuizQuestion(
    id: 'ind_life_40',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating seasonal vegetables like bottle gourd, spinach, and carrots boosts immunity.",
    isFact: true,
    explanation:
        "Seasonal vegetables provide vitamins, minerals, and antioxidants supporting health.",
  ),
  QuizQuestion(
    id: 'ind_life_41',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Frequent consumption of pakoras, bhujias, and fried snacks has no health risks.",
    isFact: false,
    explanation:
        "Excess fried foods increase trans fats, cholesterol, and metabolic risk.",
  ),
  QuizQuestion(
    id: 'ind_life_42',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating small frequent meals can help stabilize blood sugar and prevent overeating.",
    isFact: true,
    explanation:
        "Regular balanced meals support energy, insulin control, and satiety.",
  ),
  QuizQuestion(
    id: 'ind_life_43',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Skipping roti or rice completely is the only way to lose weight effectively.",
    isFact: false,
    explanation:
        "Balanced portion-controlled meals with whole grains support weight loss safely.",
  ),
  QuizQuestion(
    id: 'ind_life_44',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including nuts like almonds, walnuts, and seeds supports heart and brain health.",
    isFact: true,
    explanation:
        "Nuts provide healthy fats, fiber, protein, and antioxidants beneficial for chronic disease prevention.",
  ),
  QuizQuestion(
    id: 'ind_life_45',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating spicy Indian food always causes ulcers or digestive problems.",
    isFact: false,
    explanation:
        "Spices in moderation are safe; ulcers are usually caused by H. pylori infection or other conditions.",
  ),
  QuizQuestion(
    id: 'ind_life_46',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including fermented foods like idli, dosa, and curd supports gut health.",
    isFact: true,
    explanation:
        "Fermented foods contain probiotics that improve digestion and immunity.",
  ),
  QuizQuestion(
    id: 'ind_life_47',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking sugary drinks like aerated sodas or sweet lassi daily has no impact on liver or blood sugar.",
    isFact: false,
    explanation:
        "Excess sugar contributes to fatty liver, obesity, and insulin resistance.",
  ),
  QuizQuestion(
    id: 'ind_life_48',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Mindful eating, focusing on taste and satiety, helps prevent overeating.",
    isFact: true,
    explanation:
        "Awareness of hunger and fullness cues prevents mindless eating and supports weight management.",
  ),
  QuizQuestion(
    id: 'ind_life_49',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming nuts and jaggery together helps in blood sugar control.",
    isFact: false,
    explanation:
        "Jaggery spikes blood sugar; pairing it with nuts reduces but does not eliminate the sugar impact.",
  ),
  QuizQuestion(
    id: 'ind_life_50',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating seasonal pulses like moong, chana, and urad daily provides protein and fiber for energy.",
    isFact: true,
    explanation:
        "Pulses support satiety, gut health, and stable energy throughout the day.",
  ),

  QuizQuestion(
    id: 'nut_vs_med_01',
    category: 'Nutrition vs Medicine',
    question:
        "A balanced diet can reduce the need for high-dose supplements over time.",
    isFact: true,
    explanation:
        "Whole foods provide vitamins, minerals, and bioactive compounds that supplements alone cannot replicate.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_02',
    category: 'Nutrition vs Medicine',
    question:
        "Medicines alone are sufficient to manage chronic diseases without dietary changes.",
    isFact: false,
    explanation:
        "Dietary habits and lifestyle modifications significantly influence disease outcomes alongside medicine.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_03',
    category: 'Nutrition vs Medicine',
    question:
        "Long-term vitamin or mineral supplementation is always better than improving diet.",
    isFact: false,
    explanation:
        "Excess supplementation may cause toxicity, whereas a nutrient-rich diet provides safe, balanced intake.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_04',
    category: 'Nutrition vs Medicine',
    question:
        "Nutritional therapy can complement medicine in managing diabetes and hypertension.",
    isFact: true,
    explanation:
        "A diet rich in fiber, healthy fats, and antioxidants improves glucose and blood pressure control.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_05',
    category: 'Nutrition vs Medicine',
    question:
        "Medicinal therapy focuses on symptoms, while nutrition therapy targets root causes and prevention.",
    isFact: true,
    explanation:
        "Nutritional interventions modulate metabolism, inflammation, and hormonal balance for long-term benefits.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_06',
    category: 'Nutrition vs Medicine',
    question:
        "High-dose supplementation is harmless if taken without medical supervision.",
    isFact: false,
    explanation:
        "Excess iron, vitamin A, or calcium can lead to toxicity or organ damage; supervised use is essential.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_07',
    category: 'Nutrition vs Medicine',
    question:
        "Eating a variety of seasonal Indian foods supports chronic disease management better than taking multiple supplements.",
    isFact: true,
    explanation:
        "Whole foods provide synergistic nutrients and bioactive compounds that supplements cannot match.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_08',
    category: 'Nutrition vs Medicine',
    question: "Nutrition therapy is only necessary when medicines fail.",
    isFact: false,
    explanation:
        "Nutrition therapy works preventively and alongside medicines to improve efficacy and reduce complications.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_09',
    category: 'Nutrition vs Medicine',
    question:
        "Including legumes, whole grains, and vegetables can reduce dependency on certain medicines over time.",
    isFact: true,
    explanation:
        "These foods help regulate blood sugar, cholesterol, and blood pressure naturally, complementing medicines.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_10',
    category: 'Nutrition vs Medicine',
    question: "Supplements can replace all benefits of a healthy diet.",
    isFact: false,
    explanation:
        "Supplements provide single nutrients but lack fiber, antioxidants, and complex nutrient interactions of whole foods.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_11',
    category: 'Nutrition vs Medicine',
    question:
        "Mindful nutrition can improve liver, gut, and heart health alongside prescribed medications.",
    isFact: true,
    explanation:
        "Dietary patterns influence metabolic pathways and organ health, supporting pharmacological therapy.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_12',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy can manage PCOS symptoms without any medication in all cases.",
    isFact: false,
    explanation:
        "While diet improves insulin and hormone balance, medications may be required for ovulation or severe symptoms.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_13',
    category: 'Nutrition vs Medicine',
    question:
        "Over-reliance on supplements may mask the need for a proper diet.",
    isFact: true,
    explanation:
        "Supplements cannot replace balanced meals and can create a false sense of nutritional security.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_14',
    category: 'Nutrition vs Medicine',
    question:
        "A diet rich in iron, folate, and B12 can prevent anemia more effectively than supplements alone.",
    isFact: true,
    explanation:
        "Whole foods improve absorption and provide co-factors that enhance red blood cell production.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_15',
    category: 'Nutrition vs Medicine',
    question:
        "Medicine therapy addresses root causes of fatty liver more effectively than dietary changes.",
    isFact: false,
    explanation:
        "Lifestyle and dietary changes are primary interventions; medicines may assist only in advanced cases.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_16',
    category: 'Nutrition vs Medicine',
    question:
        "Consuming antioxidants from Indian spices like turmeric, cinnamon, and fenugreek complements medicinal therapy.",
    isFact: true,
    explanation:
        "Spices reduce oxidative stress and inflammation, enhancing the effect of medications.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_17',
    category: 'Nutrition vs Medicine',
    question:
        "All chronic diseases can be treated effectively with supplements alone.",
    isFact: false,
    explanation:
        "Supplements cannot replace lifestyle, dietary patterns, and medical treatment for chronic diseases.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_18',
    category: 'Nutrition vs Medicine',
    question:
        "Personalized nutritional therapy reduces the risk of long-term medication side effects.",
    isFact: true,
    explanation:
        "Optimized diet can improve disease control and reduce reliance on high-dose drugs, minimizing adverse effects.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_19',
    category: 'Nutrition vs Medicine',
    question:
        "Eating a traditional Indian diet with millets, legumes, and spices supports metabolic health better than multiple supplements.",
    isFact: true,
    explanation:
        "Traditional diets provide fiber, micronutrients, and bioactive compounds essential for long-term health.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_20',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy is less effective than taking vitamins and minerals as pills for chronic disease prevention.",
    isFact: false,
    explanation:
        "Whole-food nutrition addresses multiple pathways, while pills provide only isolated nutrients.",
  ),
  QuizQuestion(
    id: 'ind_life_51',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including turmeric, cumin, and coriander in daily cooking supports digestion and immunity.",
    isFact: true,
    explanation:
        "These spices contain antioxidants and anti-inflammatory compounds that aid gut health and immune function.",
  ),
  QuizQuestion(
    id: 'ind_life_52',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming fried snacks daily has no long-term effect on heart health.",
    isFact: false,
    explanation:
        "Excess fried foods increase cholesterol and risk of cardiovascular disease.",
  ),
  QuizQuestion(
    id: 'ind_life_53',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking warm water with lemon in the morning aids detoxification and hydration.",
    isFact: true,
    explanation:
        "Warm water supports digestion and hydration, while lemon provides vitamin C.",
  ),
  QuizQuestion(
    id: 'ind_life_54',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating only fruit for breakfast provides enough protein and energy for the day.",
    isFact: false,
    explanation:
        "Fruits are low in protein; a balanced breakfast with protein and complex carbs is essential for sustained energy.",
  ),
  QuizQuestion(
    id: 'ind_life_55',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating slow-digesting foods like whole grains and legumes prevents sugar spikes and improves energy.",
    isFact: true,
    explanation:
        "Complex carbs and fiber slow glucose absorption, stabilizing blood sugar and energy.",
  ),
  QuizQuestion(
    id: 'ind_life_56',
    category: 'Indian Lifestyle Nutrition',
    question: "Skipping meals helps in weight management effectively.",
    isFact: false,
    explanation:
        "Skipping meals can lead to overeating later and disrupt metabolism.",
  ),
  QuizQuestion(
    id: 'ind_life_57',
    category: 'Indian Lifestyle Nutrition',
    question: "Drinking buttermilk or lassi after meals aids digestion.",
    isFact: true,
    explanation:
        "Probiotics in fermented dairy improve gut microbiota and digestive health.",
  ),
  QuizQuestion(
    id: 'ind_life_58',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Frequent consumption of sweets like laddoo and jalebi has no effect on blood sugar.",
    isFact: false,
    explanation:
        "High sugar intake leads to glucose spikes, insulin resistance, and long-term metabolic risk.",
  ),
  QuizQuestion(
    id: 'ind_life_59',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including leafy greens like spinach, methi, and fenugreek in meals supports iron and vitamin intake.",
    isFact: true,
    explanation:
        "Leafy greens are rich in iron, calcium, and antioxidants important for energy and immunity.",
  ),
  QuizQuestion(
    id: 'ind_life_60',
    category: 'Indian Lifestyle Nutrition',
    question: "Drinking sweetened chai multiple times a day is harmless.",
    isFact: false,
    explanation:
        "Excess sugar contributes to weight gain, insulin resistance, and energy crashes.",
  ),
  QuizQuestion(
    id: 'ind_life_61',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Walking for 20-30 minutes after lunch improves digestion and blood sugar control.",
    isFact: true,
    explanation:
        "Post-meal activity increases insulin sensitivity and prevents glucose spikes.",
  ),
  QuizQuestion(
    id: 'ind_life_62',
    category: 'Indian Lifestyle Nutrition',
    question: "All fried Indian snacks are healthy if eaten with tea.",
    isFact: false,
    explanation:
        "Fried snacks contain trans fats and excess calories; moderation is essential.",
  ),
  QuizQuestion(
    id: 'ind_life_63',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating small, frequent meals helps in maintaining stable energy and blood sugar levels.",
    isFact: true,
    explanation:
        "Balanced meal timing prevents overeating and supports metabolism.",
  ),
  QuizQuestion(
    id: 'ind_life_64',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Skipping roti or rice completely is the only way to lose weight.",
    isFact: false,
    explanation:
        "Balanced portion-controlled meals with whole grains are healthier and sustainable.",
  ),
  QuizQuestion(
    id: 'ind_life_65',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including nuts like almonds, walnuts, and seeds provides healthy fats and antioxidants.",
    isFact: true,
    explanation:
        "Nuts support heart, brain, and metabolic health through unsaturated fats and micronutrients.",
  ),
  QuizQuestion(
    id: 'ind_life_66',
    category: 'Indian Lifestyle Nutrition',
    question: "Spicy food always causes ulcers or digestive issues.",
    isFact: false,
    explanation:
        "Moderate spices are safe; ulcers are usually caused by H. pylori or other medical conditions.",
  ),
  QuizQuestion(
    id: 'ind_life_67',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including fermented foods like idli, dosa, and curd supports gut health.",
    isFact: true,
    explanation:
        "Probiotics improve digestion, immunity, and nutrient absorption.",
  ),
  QuizQuestion(
    id: 'ind_life_68',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking sugary drinks like sodas or sweet lassi daily has no impact on liver or blood sugar.",
    isFact: false,
    explanation:
        "High sugar intake increases risk of fatty liver, obesity, and insulin resistance.",
  ),
  QuizQuestion(
    id: 'ind_life_69',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Mindful eating, focusing on taste and fullness, prevents overeating.",
    isFact: true,
    explanation:
        "Being aware of hunger and satiety cues helps manage calorie intake and digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_70',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming jaggery with nuts helps control blood sugar spikes completely.",
    isFact: false,
    explanation:
        "Jaggery still raises blood sugar; pairing with nuts slows but does not eliminate the impact.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_21',
    category: 'Nutrition vs Medicine',
    question:
        "Personalized diet plans can reduce reliance on high-dose medicines in chronic conditions.",
    isFact: true,
    explanation:
        "Optimized nutrition improves disease management, supporting lower medication doses safely.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_22',
    category: 'Nutrition vs Medicine',
    question: "Supplements can replace all benefits of balanced nutrition.",
    isFact: false,
    explanation:
        "Whole foods provide fiber, phytonutrients, and nutrient synergy that supplements alone cannot replicate.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_23',
    category: 'Nutrition vs Medicine',
    question:
        "Omega-3 rich foods like flaxseeds and walnuts complement medicines for heart health.",
    isFact: true,
    explanation:
        "Omega-3 fatty acids reduce inflammation and support cardiovascular outcomes alongside medication.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_24',
    category: 'Nutrition vs Medicine',
    question: "Nutrition therapy is only effective if medicines fail.",
    isFact: false,
    explanation:
        "Dietary intervention works preventively and alongside medicines to improve outcomes and reduce complications.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_25',
    category: 'Nutrition vs Medicine',
    question:
        "Balanced Indian diets with legumes, vegetables, and spices can prevent deficiencies better than supplements alone.",
    isFact: true,
    explanation:
        "Whole foods provide multiple nutrients and improve absorption compared to isolated supplements.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_26',
    category: 'Nutrition vs Medicine',
    question:
        "High-dose supplements are always safe without medical supervision.",
    isFact: false,
    explanation:
        "Excess iron, vitamin A, or calcium can cause toxicity; proper guidance is essential.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_27',
    category: 'Nutrition vs Medicine',
    question:
        "Eating seasonal Indian vegetables reduces the need for supplementation.",
    isFact: true,
    explanation:
        "Seasonal vegetables provide vitamins and minerals that prevent deficiencies naturally.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_28',
    category: 'Nutrition vs Medicine',
    question: "Supplements can completely replace meals and diet quality.",
    isFact: false,
    explanation:
        "Meals provide energy, fiber, and multiple nutrients that cannot be fully replaced by supplements.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_29',
    category: 'Nutrition vs Medicine',
    question:
        "Including spices like cinnamon, fenugreek, and turmeric in diet complements medication for blood sugar control.",
    isFact: true,
    explanation:
        "These spices improve insulin sensitivity and provide antioxidant support alongside medicines.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_30',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy can help prevent fatty liver and PCOS complications, not just medicines.",
    isFact: true,
    explanation:
        "Dietary management regulates insulin, reduces liver fat, and improves hormonal balance effectively.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_31',
    category: 'Nutrition vs Medicine',
    question: "All types of anemia can be corrected with iron tablets alone.",
    isFact: false,
    explanation:
        "Some anemias require B12, folate, or treatment of underlying chronic disease; iron alone is insufficient.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_32',
    category: 'Nutrition vs Medicine',
    question:
        "Balanced meals and nutrient-dense foods improve long-term outcomes in chronic diseases more sustainably than supplements.",
    isFact: true,
    explanation:
        "Whole foods address multiple metabolic pathways and prevent nutrient gaps, unlike isolated supplements.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_33',
    category: 'Nutrition vs Medicine',
    question:
        "Relying solely on supplements without dietary changes is enough to manage hypertension.",
    isFact: false,
    explanation:
        "Lifestyle, sodium restriction, and balanced diet are critical to blood pressure control along with medications.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_34',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy reduces side effects of long-term medications.",
    isFact: true,
    explanation:
        "Adequate nutrients support organ health and prevent complications from prolonged medication use.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_35',
    category: 'Nutrition vs Medicine',
    question:
        "Traditional Indian diets with whole grains, legumes, and spices support metabolic health better than taking multiple pills.",
    isFact: true,
    explanation:
        "Whole foods provide fiber, micronutrients, and bioactive compounds essential for disease prevention and wellness.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_36',
    category: 'Nutrition vs Medicine',
    question:
        "Taking multiple vitamin tablets is safer than improving diet quality.",
    isFact: false,
    explanation:
        "High doses of vitamins can be toxic; a nutrient-rich diet is safer and more effective.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_37',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy can improve energy, digestion, and immunity along with prescribed medicines.",
    isFact: true,
    explanation:
        "Balanced meals and nutrient-rich foods optimize health outcomes alongside medical treatment.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_38',
    category: 'Nutrition vs Medicine',
    question:
        "Supplements are sufficient to manage PCOS symptoms without diet and lifestyle changes.",
    isFact: false,
    explanation:
        "Diet, exercise, and weight management are essential components; supplements alone are insufficient.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_39',
    category: 'Nutrition vs Medicine',
    question:
        "Indian spices like cumin and coriander help digestion and complement medical therapy.",
    isFact: true,
    explanation:
        "Spices support enzymatic activity, reduce bloating, and improve nutrient absorption.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_40',
    category: 'Nutrition vs Medicine',
    question:
        "Relying only on supplements for chronic disease prevention is as effective as dietary therapy.",
    isFact: false,
    explanation:
        "Whole foods provide multiple synergistic nutrients that supplements cannot replicate.",
  ),
  QuizQuestion(
    id: 'ind_life_101',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating dal, vegetables, and roti daily supports sustained energy and gut health.",
    isFact: true,
    explanation:
        "Balanced meals provide fiber, protein, and complex carbs that improve metabolism and digestion.",
  ),
  QuizQuestion(
    id: 'ind_life_102',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Frequent consumption of fried snacks like pakoras has no impact on cholesterol.",
    isFact: false,
    explanation:
        "Fried foods contain trans fats, raising LDL cholesterol and cardiovascular risk.",
  ),
  QuizQuestion(
    id: 'ind_life_103',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Adding a pinch of turmeric to milk or curries can support joint health and reduce inflammation.",
    isFact: true,
    explanation:
        "Curcumin in turmeric has anti-inflammatory properties beneficial for chronic disease management.",
  ),
  QuizQuestion(
    id: 'ind_life_104',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Skipping breakfast regularly is a healthy way to reduce calorie intake.",
    isFact: false,
    explanation:
        "Skipping breakfast can increase hunger later, leading to overeating and metabolic disruption.",
  ),
  QuizQuestion(
    id: 'ind_life_105',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including fiber-rich foods like whole grains, legumes, and vegetables stabilizes blood sugar.",
    isFact: true,
    explanation:
        "Fiber slows glucose absorption, preventing spikes and improving gut health.",
  ),
  QuizQuestion(
    id: 'ind_life_106',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking chai with sugar multiple times a day has no effect on energy or metabolism.",
    isFact: false,
    explanation:
        "High sugar intake causes energy crashes, weight gain, and insulin resistance.",
  ),
  QuizQuestion(
    id: 'ind_life_107',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating slowly and mindfully improves digestion and prevents overeating.",
    isFact: true,
    explanation:
        "Mindful eating increases satiety, allowing better nutrient absorption and calorie control.",
  ),
  QuizQuestion(
    id: 'ind_life_108',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming jaggery instead of refined sugar makes desserts completely healthy.",
    isFact: false,
    explanation:
        "Jaggery has minor nutrients but still adds sugar and calories; moderation is key.",
  ),
  QuizQuestion(
    id: 'ind_life_109',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Walking for 20–30 minutes after meals supports digestion and blood sugar control.",
    isFact: true,
    explanation:
        "Post-meal activity improves insulin sensitivity and prevents glucose spikes.",
  ),
  QuizQuestion(
    id: 'ind_life_110',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating only fruit for dinner provides adequate protein and prevents nutrient deficiencies.",
    isFact: false,
    explanation:
        "Fruits are low in protein and essential nutrients; a balanced meal is necessary.",
  ),
  QuizQuestion(
    id: 'ind_life_111',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming fermented foods like idli, dosa, and curd supports gut health.",
    isFact: true,
    explanation:
        "Probiotics in fermented foods enhance digestion, immunity, and nutrient absorption.",
  ),
  QuizQuestion(
    id: 'ind_life_112',
    category: 'Indian Lifestyle Nutrition',
    question: "Eating late-night snacks has no effect on metabolism or weight.",
    isFact: false,
    explanation:
        "Late eating can disrupt circadian rhythm and contribute to fat accumulation.",
  ),
  QuizQuestion(
    id: 'ind_life_113',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Including nuts and seeds in daily diet supports heart, brain, and metabolic health.",
    isFact: true,
    explanation:
        "Nuts and seeds provide healthy fats, fiber, and antioxidants beneficial for chronic disease prevention.",
  ),
  QuizQuestion(
    id: 'ind_life_114',
    category: 'Indian Lifestyle Nutrition',
    question: "Spicy foods always cause ulcers or digestive problems.",
    isFact: false,
    explanation:
        "Moderate spices are generally safe; ulcers are usually caused by H. pylori or other conditions.",
  ),
  QuizQuestion(
    id: 'ind_life_115',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking warm water with lemon in the morning aids hydration and digestion.",
    isFact: true,
    explanation:
        "Warm water supports digestion, and lemon provides vitamin C for immunity.",
  ),
  QuizQuestion(
    id: 'ind_life_116',
    category: 'Indian Lifestyle Nutrition',
    question: "Skipping vegetables in meals has no impact on overall health.",
    isFact: false,
    explanation:
        "Vegetables provide fiber, vitamins, and antioxidants essential for immunity and metabolic health.",
  ),
  QuizQuestion(
    id: 'ind_life_117',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Eating small, frequent meals helps stabilize blood sugar and prevents overeating.",
    isFact: true,
    explanation:
        "Regular balanced meals maintain energy levels and improve metabolism.",
  ),
  QuizQuestion(
    id: 'ind_life_118',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Consuming refined white rice in every meal does not affect blood sugar.",
    isFact: false,
    explanation:
        "Refined rice causes rapid glucose spikes; whole grains are preferable.",
  ),
  QuizQuestion(
    id: 'ind_life_119',
    category: 'Indian Lifestyle Nutrition',
    question: "Hydration is important even with a healthy diet.",
    isFact: true,
    explanation:
        "Water supports digestion, metabolism, detoxification, and energy balance.",
  ),
  QuizQuestion(
    id: 'ind_life_120',
    category: 'Indian Lifestyle Nutrition',
    question: "All low-fat packaged Indian foods are healthy choices.",
    isFact: false,
    explanation:
        "Many low-fat foods contain hidden sugar or refined carbs; whole foods are safer.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_41',
    category: 'Nutrition vs Medicine',
    question:
        "Balanced diet can reduce reliance on high-dose supplements over time.",
    isFact: true,
    explanation:
        "Whole foods provide multiple nutrients and bioactive compounds that supplements alone cannot replicate.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_42',
    category: 'Nutrition vs Medicine',
    question:
        "Medicines alone are sufficient to manage chronic diseases without dietary changes.",
    isFact: false,
    explanation:
        "Dietary and lifestyle modifications are essential alongside medicine for effective management.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_43',
    category: 'Nutrition vs Medicine',
    question:
        "Long-term high-dose supplementation is always better than improving diet quality.",
    isFact: false,
    explanation:
        "Excess supplementation can be harmful; nutrient-rich foods provide balanced intake safely.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_44',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy complements medicines in diabetes and hypertension management.",
    isFact: true,
    explanation:
        "High-fiber, nutrient-rich diets improve blood sugar and blood pressure alongside medications.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_45',
    category: 'Nutrition vs Medicine',
    question:
        "Medicines address symptoms, while nutrition therapy targets root causes and prevention.",
    isFact: true,
    explanation:
        "Dietary interventions modulate metabolism, inflammation, and hormones for long-term benefits.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_46',
    category: 'Nutrition vs Medicine',
    question:
        "High-dose vitamin supplements are always harmless without medical supervision.",
    isFact: false,
    explanation:
        "Excess vitamins can lead to toxicity; supervised intake is essential.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_47',
    category: 'Nutrition vs Medicine',
    question:
        "Eating a variety of seasonal Indian foods supports chronic disease management better than multiple supplements.",
    isFact: true,
    explanation:
        "Whole foods provide synergistic nutrients and bioactive compounds that supplements cannot replicate.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_48',
    category: 'Nutrition vs Medicine',
    question: "Nutrition therapy is only necessary if medicines fail.",
    isFact: false,
    explanation:
        "Dietary therapy works preventively and alongside medicines to improve outcomes.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_49',
    category: 'Nutrition vs Medicine',
    question:
        "Including legumes and whole grains daily can reduce dependency on certain medicines over time.",
    isFact: true,
    explanation:
        "Fiber-rich foods help regulate blood sugar, cholesterol, and blood pressure naturally.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_50',
    category: 'Nutrition vs Medicine',
    question: "Supplements can replace all benefits of a healthy diet.",
    isFact: false,
    explanation:
        "Supplements provide isolated nutrients, whereas whole foods offer fiber, phytonutrients, and nutrient synergy.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_51',
    category: 'Nutrition vs Medicine',
    question:
        "Mindful nutrition improves liver, gut, and heart health alongside prescribed medications.",
    isFact: true,
    explanation:
        "Balanced meals optimize organ function and enhance pharmacological therapy.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_52',
    category: 'Nutrition vs Medicine',
    question:
        "Nutrition therapy can manage PCOS symptoms without any medication in all cases.",
    isFact: false,
    explanation:
        "Diet improves hormone balance, but medications may be needed for ovulation or severe symptoms.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_53',
    category: 'Nutrition vs Medicine',
    question:
        "Over-reliance on supplements may mask the need for a proper diet.",
    isFact: true,
    explanation:
        "Supplements cannot replace the benefits of balanced meals and nutrient-rich foods.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_54',
    category: 'Nutrition vs Medicine',
    question:
        "A diet rich in iron, folate, and B12 prevents anemia more effectively than supplements alone.",
    isFact: true,
    explanation:
        "Whole foods improve absorption and provide co-factors that enhance red blood cell production.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_55',
    category: 'Nutrition vs Medicine',
    question:
        "Medicinal therapy alone is more effective than dietary changes in managing fatty liver.",
    isFact: false,
    explanation:
        "Lifestyle and dietary changes are primary interventions; medicines assist only in advanced cases.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_56',
    category: 'Nutrition vs Medicine',
    question:
        "Consuming antioxidants from Indian spices complements medicinal therapy.",
    isFact: true,
    explanation:
        "Spices reduce oxidative stress and inflammation, enhancing medicine effectiveness.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_57',
    category: 'Nutrition vs Medicine',
    question:
        "All chronic diseases can be treated effectively with supplements alone.",
    isFact: false,
    explanation:
        "Supplements cannot replace lifestyle, dietary patterns, and medical treatment.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_58',
    category: 'Nutrition vs Medicine',
    question:
        "Personalized nutrition reduces risk of long-term medication side effects.",
    isFact: true,
    explanation:
        "Optimized diet supports disease control and minimizes adverse effects from drugs.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_59',
    category: 'Nutrition vs Medicine',
    question:
        "Traditional Indian diets with whole grains, legumes, and spices support metabolic health better than multiple supplements.",
    isFact: true,
    explanation:
        "Whole foods provide fiber, micronutrients, and bioactive compounds essential for long-term health.",
  ),
  QuizQuestion(
    id: 'nut_vs_med_60',
    category: 'Nutrition vs Medicine',
    question:
        "High-dose vitamin tablets are safer than improving diet quality.",
    isFact: false,
    explanation:
        "Excess vitamins can be toxic; a nutrient-rich diet is safer and more effective.",
  ),
  QuizQuestion(
    id: 'chronic_nut_01',
    category: 'Chronic Disease & Nutrition',
    question:
        "Diabetes can be managed effectively with a diet rich in fiber, whole grains, and spices alongside medications.",
    isFact: true,
    explanation:
        "High-fiber foods slow glucose absorption and spices like cinnamon improve insulin sensitivity.",
  ),
  QuizQuestion(
    id: 'chronic_nut_02',
    category: 'Chronic Disease & Nutrition',
    question:
        "Taking diabetes medication alone is enough to maintain energy and prevent complications.",
    isFact: false,
    explanation:
        "Without dietary control, blood sugar spikes still occur, reducing energy and increasing long-term risks.",
  ),
  QuizQuestion(
    id: 'chronic_nut_03',
    category: 'Chronic Disease & Nutrition',
    question:
        "Including leafy greens, legumes, and nuts in daily meals supports heart health and prevents hypertension complications.",
    isFact: true,
    explanation:
        "These foods provide potassium, magnesium, and fiber that help regulate blood pressure naturally.",
  ),
  QuizQuestion(
    id: 'chronic_nut_04',
    category: 'Chronic Disease & Nutrition',
    question:
        "High-salt Indian snacks do not affect blood pressure if you take medication.",
    isFact: false,
    explanation:
        "Excess sodium worsens hypertension; diet management is crucial alongside medications.",
  ),
  QuizQuestion(
    id: 'chronic_nut_05',
    category: 'Chronic Disease & Nutrition',
    question:
        "Fatty liver can improve with lifestyle and diet changes without relying solely on medicine.",
    isFact: true,
    explanation:
        "Reducing refined carbs, sugar, and unhealthy fats while including fiber and protein supports liver health.",
  ),
  QuizQuestion(
    id: 'chronic_nut_06',
    category: 'Chronic Disease & Nutrition',
    question:
        "Eating fried foods and sweets is harmless if you are taking liver-protective medicine.",
    isFact: false,
    explanation:
        "Dietary habits directly impact liver fat accumulation; medicine alone cannot reverse poor nutrition effects.",
  ),
  QuizQuestion(
    id: 'chronic_nut_07',
    category: 'Chronic Disease & Nutrition',
    question:
        "PCOS symptoms like insulin resistance and hormonal imbalance can improve with proper nutrition therapy.",
    isFact: true,
    explanation:
        "Balanced diet, fiber, healthy fats, and regular meals improve insulin sensitivity and hormonal health.",
  ),
  QuizQuestion(
    id: 'chronic_nut_08',
    category: 'Chronic Disease & Nutrition',
    question:
        "Taking supplements alone can fully manage PCOS without dietary changes.",
    isFact: false,
    explanation:
        "Supplements help only partially; diet and lifestyle are the main interventions for long-term improvement.",
  ),
  QuizQuestion(
    id: 'chronic_nut_09',
    category: 'Chronic Disease & Nutrition',
    question:
        "Anemia can be prevented with iron-rich foods, B12, and folate rather than relying solely on tablets.",
    isFact: true,
    explanation:
        "Whole foods improve absorption and provide essential co-factors for red blood cell production.",
  ),
  QuizQuestion(
    id: 'chronic_nut_10',
    category: 'Chronic Disease & Nutrition',
    question:
        "Iron tablets alone are enough to maintain energy and prevent anemia symptoms.",
    isFact: false,
    explanation:
        "Without dietary support, anemia may persist and energy levels remain low.",
  ),
  QuizQuestion(
    id: 'chronic_nut_11',
    category: 'Chronic Disease & Nutrition',
    question:
        "Including Indian spices like turmeric, fenugreek, and cumin regularly helps reduce inflammation in chronic diseases.",
    isFact: true,
    explanation:
        "Spices have bioactive compounds that modulate inflammatory pathways and oxidative stress.",
  ),
  QuizQuestion(
    id: 'chronic_nut_12',
    category: 'Chronic Disease & Nutrition',
    question: "Spices alone can replace all medicines for chronic diseases.",
    isFact: false,
    explanation:
        "While beneficial, spices complement medicine and lifestyle, they cannot replace pharmacotherapy entirely.",
  ),
  QuizQuestion(
    id: 'chronic_nut_13',
    category: 'Chronic Disease & Nutrition',
    question:
        "Switching to a nutrition-focused lifestyle improves long-term energy, mood, and disease outcomes.",
    isFact: true,
    explanation:
        "Balanced diets regulate blood sugar, reduce inflammation, and provide sustained energy.",
  ),
  QuizQuestion(
    id: 'chronic_nut_14',
    category: 'Chronic Disease & Nutrition',
    question:
        "Chronic disease management does not require lifestyle changes if medication is taken regularly.",
    isFact: false,
    explanation:
        "Lifestyle interventions are essential for symptom control, reducing complications, and improving energy.",
  ),
  QuizQuestion(
    id: 'chronic_nut_15',
    category: 'Chronic Disease & Nutrition',
    question:
        "Daily walking or physical activity combined with proper diet enhances medication efficacy in chronic disease management.",
    isFact: true,
    explanation:
        "Exercise improves insulin sensitivity, heart health, and energy levels, supporting pharmacological therapy.",
  ),
  QuizQuestion(
    id: 'chronic_nut_16',
    category: 'Chronic Disease & Nutrition',
    question:
        "Chronic fatigue and low energy are unavoidable even with dietary improvements if you have chronic disease.",
    isFact: false,
    explanation:
        "Proper nutrition and lifestyle changes can restore energy and reduce fatigue over time.",
  ),
  QuizQuestion(
    id: 'chronic_nut_17',
    category: 'Chronic Disease & Nutrition',
    question:
        "Whole grains, legumes, vegetables, and nuts provide more sustainable benefits than long-term high-dose supplementation.",
    isFact: true,
    explanation:
        "Whole foods offer fiber, antioxidants, and multiple micronutrients in synergy, supporting long-term health.",
  ),
  QuizQuestion(
    id: 'chronic_nut_18',
    category: 'Chronic Disease & Nutrition',
    question:
        "Supplements alone can provide the same long-lasting energy and metabolic benefits as a nutrient-rich diet.",
    isFact: false,
    explanation:
        "Supplements provide isolated nutrients, while whole foods support energy, digestion, and chronic disease prevention.",
  ),
  QuizQuestion(
    id: 'chronic_nut_19',
    category: 'Chronic Disease & Nutrition',
    question:
        "Adopting an Indian lifestyle diet rich in spices, whole grains, and legumes reduces dependency on medications over time.",
    isFact: true,
    explanation:
        "Dietary patterns improve metabolic health, hormone balance, and cardiovascular outcomes sustainably.",
  ),
  QuizQuestion(
    id: 'chronic_nut_20',
    category: 'Chronic Disease & Nutrition',
    question:
        "Switching to nutrition therapy has no impact on long-term wellness if chronic disease medicines are taken.",
    isFact: false,
    explanation:
        "Nutrition therapy addresses root causes and provides energy, immunity, and metabolic benefits beyond medicines.",
  ),
  QuizQuestion(
    id: 'ind_chronic_151',
    category: 'Chronic Disease & Indian Food',
    question:
        "Including fenugreek seeds in meals can help control blood sugar levels in diabetes.",
    isFact: true,
    explanation:
        "Fenugreek contains soluble fiber that slows glucose absorption, improving glycemic control.",
  ),
  QuizQuestion(
    id: 'ind_chronic_152',
    category: 'Chronic Disease & Indian Food',
    question:
        "Skipping whole grains like millets and roti has no effect on chronic disease management.",
    isFact: false,
    explanation:
        "Whole grains provide fiber and micronutrients essential for controlling blood sugar, cholesterol, and weight.",
  ),
  QuizQuestion(
    id: 'ind_chronic_153',
    category: 'Chronic Disease & Indian Food',
    question:
        "Turmeric in daily cooking can reduce inflammation and support liver and heart health.",
    isFact: true,
    explanation:
        "Curcumin in turmeric modulates inflammatory pathways and antioxidant activity, aiding chronic disease management.",
  ),
  QuizQuestion(
    id: 'ind_chronic_154',
    category: 'Chronic Disease & Indian Food',
    question:
        "Adding extra ghee or butter in meals does not affect cholesterol levels if you take medication.",
    isFact: false,
    explanation:
        "Excess saturated fat can raise LDL cholesterol; diet management complements medication.",
  ),
  QuizQuestion(
    id: 'ind_chronic_155',
    category: 'Chronic Disease & Indian Food',
    question:
        "Eating more fiber-rich legumes and vegetables improves gut health and energy in chronic disease patients.",
    isFact: true,
    explanation:
        "Fiber supports healthy microbiota, stabilizes blood sugar, and prevents energy crashes.",
  ),
  QuizQuestion(
    id: 'ind_chronic_156',
    category: 'Chronic Disease & Indian Food',
    question:
        "Frequent consumption of sweet Indian desserts like gulab jamun has no impact on metabolic health.",
    isFact: false,
    explanation:
        "High sugar intake contributes to diabetes, obesity, and fatty liver risk.",
  ),
  QuizQuestion(
    id: 'ind_chronic_157',
    category: 'Chronic Disease & Indian Food',
    question:
        "Drinking buttermilk or lassi daily aids digestion and provides probiotics for gut health.",
    isFact: true,
    explanation:
        "Fermented dairy improves microbiome health, nutrient absorption, and digestion.",
  ),
  QuizQuestion(
    id: 'ind_chronic_158',
    category: 'Chronic Disease & Indian Food',
    question:
        "Eating late-night meals has no effect on weight or energy levels.",
    isFact: false,
    explanation:
        "Late meals disrupt circadian rhythm, affect metabolism, and can worsen insulin resistance.",
  ),
  QuizQuestion(
    id: 'ind_chronic_159',
    category: 'Chronic Disease & Indian Food',
    question:
        "Including nuts like almonds and walnuts in snacks boosts energy and supports heart health.",
    isFact: true,
    explanation:
        "Nuts provide healthy fats, protein, and antioxidants that improve cardiovascular and metabolic health.",
  ),
  QuizQuestion(
    id: 'ind_chronic_160',
    category: 'Chronic Disease & Indian Food',
    question: "Spicy foods always cause ulcers or digestive issues.",
    isFact: false,
    explanation:
        "Moderate spices are generally safe; ulcers are usually caused by H. pylori or other medical conditions.",
  ),
  QuizQuestion(
    id: 'ind_chronic_161',
    category: 'Chronic Disease & Indian Food',
    question:
        "Walking 20–30 minutes after lunch or dinner improves digestion and blood sugar control.",
    isFact: true,
    explanation:
        "Post-meal activity enhances insulin sensitivity and prevents glucose spikes.",
  ),
  QuizQuestion(
    id: 'ind_chronic_162',
    category: 'Chronic Disease & Indian Food',
    question:
        "Refined white rice can be eaten freely without affecting blood sugar in diabetic patients.",
    isFact: false,
    explanation:
        "Refined rice causes rapid glucose spikes; whole grains or millets are better choices.",
  ),
  QuizQuestion(
    id: 'ind_chronic_163',
    category: 'Chronic Disease & Indian Food',
    question:
        "Mindful eating, focusing on hunger and fullness cues, helps prevent overeating.",
    isFact: true,
    explanation:
        "Being aware of satiety and eating slowly improves digestion and reduces calorie excess.",
  ),
  QuizQuestion(
    id: 'ind_chronic_164',
    category: 'Chronic Disease & Indian Food',
    question:
        "Supplements alone are enough to manage chronic fatigue in diabetes and hypertension.",
    isFact: false,
    explanation:
        "Dietary patterns, meal timing, and lifestyle changes are essential for sustained energy and health.",
  ),
  QuizQuestion(
    id: 'ind_chronic_165',
    category: 'Chronic Disease & Indian Food',
    question:
        "Including seasonal fruits in meals improves vitamin intake and energy levels.",
    isFact: true,
    explanation:
        "Seasonal fruits provide antioxidants, vitamins, and hydration that support metabolism and immunity.",
  ),
  QuizQuestion(
    id: 'ind_chronic_166',
    category: 'Chronic Disease & Indian Food',
    question:
        "Eating excessive fried snacks and sweets has no long-term effect if you take multivitamins.",
    isFact: false,
    explanation:
        "Supplements cannot counteract excess calories, trans fats, or sugar; balanced diet is critical.",
  ),
  QuizQuestion(
    id: 'ind_chronic_167',
    category: 'Chronic Disease & Indian Food',
    question:
        "Legumes like chana, moong, and masoor improve blood sugar control and provide sustained energy.",
    isFact: true,
    explanation:
        "Legumes have low glycemic index and are rich in protein and fiber, stabilizing glucose and energy.",
  ),
  QuizQuestion(
    id: 'ind_chronic_168',
    category: 'Chronic Disease & Indian Food',
    question:
        "Eating processed snacks frequently does not affect long-term metabolic health.",
    isFact: false,
    explanation:
        "Processed foods increase inflammation, obesity, and risk of chronic diseases.",
  ),
  QuizQuestion(
    id: 'ind_chronic_169',
    category: 'Chronic Disease & Indian Food',
    question:
        "Nutrition therapy can help reduce dependency on long-term medications in chronic disease management.",
    isFact: true,
    explanation:
        "Optimized diet and lifestyle improve metabolic control, reducing the need for higher medication doses.",
  ),
  QuizQuestion(
    id: 'ind_chronic_170',
    category: 'Chronic Disease & Indian Food',
    question:
        "Taking supplements is sufficient to prevent fatty liver without dietary changes.",
    isFact: false,
    explanation:
        "Lifestyle and diet, including reduced sugar and refined carbs, are primary interventions for fatty liver.",
  ),
  QuizQuestion(
    id: 'ind_chronic_171',
    category: 'Chronic Disease & Indian Food',
    question:
        "Turmeric, cinnamon, and fenugreek as part of daily diet complement medicines in diabetes and cholesterol management.",
    isFact: true,
    explanation:
        "These spices improve glucose and lipid metabolism and reduce inflammation.",
  ),
  QuizQuestion(
    id: 'ind_chronic_172',
    category: 'Chronic Disease & Indian Food',
    question:
        "Spices alone can replace medicines for chronic disease management.",
    isFact: false,
    explanation:
        "While helpful, spices cannot replace pharmacotherapy; they are complementary.",
  ),
  QuizQuestion(
    id: 'ind_chronic_173',
    category: 'Chronic Disease & Indian Food',
    question:
        "Adopting an Indian diet rich in whole grains, legumes, vegetables, and spices enhances energy and long-term wellness.",
    isFact: true,
    explanation:
        "Balanced nutrition regulates metabolism, hormone balance, and immune function sustainably.",
  ),
  QuizQuestion(
    id: 'ind_chronic_174',
    category: 'Chronic Disease & Indian Food',
    question:
        "Chronic disease medicines alone can provide sustained energy and overall wellness.",
    isFact: false,
    explanation:
        "Medications manage symptoms, but diet and lifestyle changes are essential for energy, immunity, and prevention.",
  ),
  QuizQuestion(
    id: 'ind_chronic_175',
    category: 'Chronic Disease & Indian Food',
    question:
        "Fiber-rich Indian foods like bajra, jowar, and lentils improve gut health and reduce sugar spikes.",
    isFact: true,
    explanation:
        "Fiber slows carbohydrate absorption and supports healthy gut microbiota.",
  ),
  QuizQuestion(
    id: 'ind_chronic_176',
    category: 'Chronic Disease & Indian Food',
    question:
        "Eating high-sugar desserts daily has no impact on fatty liver risk if medicines are taken.",
    isFact: false,
    explanation:
        "High sugar promotes liver fat accumulation; diet management is critical for fatty liver prevention.",
  ),
  QuizQuestion(
    id: 'ind_chronic_177',
    category: 'Chronic Disease & Indian Food',
    question:
        "Nuts, seeds, and healthy oils provide essential fats that support brain, heart, and hormone health in chronic diseases.",
    isFact: true,
    explanation:
        "Unsaturated fats improve cardiovascular health, hormone regulation, and energy balance.",
  ),
  QuizQuestion(
    id: 'ind_chronic_178',
    category: 'Chronic Disease & Indian Food',
    question:
        "Supplements alone can fully restore energy and metabolic health without dietary changes.",
    isFact: false,
    explanation:
        "Whole foods provide synergistic nutrients, fiber, and phytonutrients that supplements cannot replicate.",
  ),
  QuizQuestion(
    id: 'ind_chronic_179',
    category: 'Chronic Disease & Indian Food',
    question:
        "Switching to nutrition therapy can reduce long-term complications of chronic diseases like diabetes and PCOS.",
    isFact: true,
    explanation:
        "Dietary interventions regulate glucose, hormones, and inflammation, preventing progression and complications.",
  ),
  QuizQuestion(
    id: 'ind_chronic_180',
    category: 'Chronic Disease & Indian Food',
    question:
        "Chronic disease management does not benefit from Indian lifestyle dietary changes if medications are taken.",
    isFact: false,
    explanation:
        "Lifestyle and diet modifications improve metabolic control, energy, and quality of life beyond medicines alone.",
  ),
  QuizQuestion(
    id: 'fun_nut_201',
    category: 'Indian Spices & Nutrition',
    question:
        "Adding black pepper to turmeric enhances its absorption in the body.",
    isFact: true,
    explanation:
        "Piperine in black pepper increases curcumin absorption, making turmeric more effective.",
  ),
  QuizQuestion(
    id: 'fun_nut_202',
    category: 'Indian Spices & Nutrition',
    question:
        "Cumin in Indian cooking has no effect on digestion or metabolism.",
    isFact: false,
    explanation:
        "Cumin stimulates digestive enzymes and improves nutrient absorption.",
  ),
  QuizQuestion(
    id: 'fun_nut_203',
    category: 'Indian Food Myths',
    question:
        "Eating ghee in moderation can be beneficial for energy and hormone balance.",
    isFact: true,
    explanation:
        "Healthy fats in ghee support brain function, energy, and hormone synthesis.",
  ),
  QuizQuestion(
    id: 'fun_nut_204',
    category: 'Indian Food Myths',
    question:
        "Consuming ghee daily will always cause weight gain regardless of diet.",
    isFact: false,
    explanation:
        "Moderation is key; balanced diet and physical activity prevent weight gain.",
  ),
  QuizQuestion(
    id: 'fun_nut_205',
    category: 'Diabetes & Lifestyle',
    question:
        "Drinking water before meals can help control hunger and support blood sugar management.",
    isFact: true,
    explanation:
        "Water intake can reduce calorie intake and stabilize post-meal glucose levels.",
  ),
  QuizQuestion(
    id: 'fun_nut_206',
    category: 'Diabetes & Lifestyle',
    question:
        "Fruit juices are always safe for diabetics because they are natural.",
    isFact: false,
    explanation:
        "Juices have high glycemic load and can spike blood sugar levels.",
  ),
  QuizQuestion(
    id: 'fun_nut_207',
    category: 'Gut Health',
    question:
        "Eating fermented foods like idli, dosa, and curd daily supports a healthy gut microbiome.",
    isFact: true,
    explanation:
        "Probiotics from fermentation improve digestion, immunity, and nutrient absorption.",
  ),
  QuizQuestion(
    id: 'fun_nut_208',
    category: 'Gut Health',
    question: "Spicy and tangy Indian foods always harm gut health.",
    isFact: false,
    explanation:
        "Moderate spices are generally safe and can even stimulate digestion and enzyme activity.",
  ),
  QuizQuestion(
    id: 'fun_nut_209',
    category: 'Weight Loss Myths',
    question:
        "Eating late at night does not automatically cause weight gain; overall diet quality matters more.",
    isFact: true,
    explanation:
        "Calorie balance and nutrient quality are more important than timing alone.",
  ),
  QuizQuestion(
    id: 'fun_nut_210',
    category: 'Weight Loss Myths',
    question: "Skipping meals is a good strategy to lose weight quickly.",
    isFact: false,
    explanation:
        "Skipping meals can slow metabolism, increase hunger, and promote overeating later.",
  ),
  QuizQuestion(
    id: 'fun_nut_211',
    category: 'Hypertension',
    question:
        "Including potassium-rich foods like bananas, spinach, and beans helps control blood pressure naturally.",
    isFact: true,
    explanation:
        "Potassium balances sodium and relaxes blood vessels, reducing hypertension risk.",
  ),
  QuizQuestion(
    id: 'fun_nut_212',
    category: 'Hypertension',
    question:
        "Low-salt packaged Indian foods are always healthy choices for blood pressure control.",
    isFact: false,
    explanation:
        "Many processed foods contain hidden sugars or refined carbs that affect blood pressure and metabolism.",
  ),
  QuizQuestion(
    id: 'fun_nut_213',
    category: 'Cholesterol & Fatty Liver',
    question:
        "Nuts, seeds, and whole grains help reduce LDL cholesterol and support liver health.",
    isFact: true,
    explanation:
        "Fiber and healthy fats lower bad cholesterol and prevent fat accumulation in the liver.",
  ),
  QuizQuestion(
    id: 'fun_nut_214',
    category: 'Cholesterol & Fatty Liver',
    question:
        "Taking cholesterol-lowering supplements allows you to eat unlimited fried foods safely.",
    isFact: false,
    explanation:
        "Supplements cannot offset high saturated and trans fat intake from fried foods.",
  ),
  QuizQuestion(
    id: 'fun_nut_215',
    category: 'PCOS & Nutrition',
    question:
        "Low-glycemic index foods like whole grains and legumes help manage PCOS symptoms.",
    isFact: true,
    explanation:
        "Stable blood sugar improves hormone balance and reduces insulin resistance common in PCOS.",
  ),
  QuizQuestion(
    id: 'fun_nut_216',
    category: 'PCOS & Nutrition',
    question:
        "Supplements alone can normalize PCOS hormones without diet changes.",
    isFact: false,
    explanation:
        "Nutrition and lifestyle interventions are primary; supplements only support therapy.",
  ),
  QuizQuestion(
    id: 'fun_nut_217',
    category: 'Anemia',
    question:
        "Combining iron-rich foods with vitamin C sources like lemon improves absorption.",
    isFact: true,
    explanation:
        "Vitamin C enhances non-heme iron absorption from plant-based sources.",
  ),
  QuizQuestion(
    id: 'fun_nut_218',
    category: 'Anemia',
    question:
        "Iron supplements are always more effective than iron-rich foods for preventing anemia.",
    isFact: false,
    explanation:
        "Whole foods provide additional nutrients and co-factors necessary for red blood cell production.",
  ),
  QuizQuestion(
    id: 'fun_nut_219',
    category: 'Nutrition Psychology',
    question:
        "Eating a colorful plate of vegetables and fruits can improve mood and energy levels.",
    isFact: true,
    explanation:
        "Vitamins, minerals, and antioxidants in plant foods support brain function and reduce fatigue.",
  ),
  QuizQuestion(
    id: 'fun_nut_220',
    category: 'Nutrition Psychology',
    question:
        "Food color and variety have no impact on mental energy or motivation.",
    isFact: false,
    explanation:
        "Visual appeal and nutrient variety influence appetite, satisfaction, and psychological well-being.",
  ),
  QuizQuestion(
    id: 'fun_nut_221',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Nutrition therapy complements medicines for chronic diseases, improving long-term outcomes.",
    isFact: true,
    explanation:
        "Balanced diets regulate glucose, lipids, and hormones, reducing dependence on higher medication doses.",
  ),
  QuizQuestion(
    id: 'fun_nut_222',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Medicines alone can provide energy, immunity, and overall wellness without diet changes.",
    isFact: false,
    explanation:
        "Medication manages symptoms but cannot provide holistic energy and preventive benefits of nutrition.",
  ),
  QuizQuestion(
    id: 'fun_nut_223',
    category: 'Food Myths',
    question:
        "Brown rice is not automatically healthier than white rice in all contexts.",
    isFact: true,
    explanation:
        "Glycemic response depends on cooking, portion size, and meal composition, not just color.",
  ),
  QuizQuestion(
    id: 'fun_nut_224',
    category: 'Food Myths',
    question:
        "Honey can be consumed in unlimited amounts to sweeten Indian desserts safely.",
    isFact: false,
    explanation:
        "Honey still raises blood sugar; moderation is essential, especially for diabetics.",
  ),
  QuizQuestion(
    id: 'fun_nut_225',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Drinking warm water with lemon in the morning supports hydration and digestion.",
    isFact: true,
    explanation:
        "Warm water aids digestion; lemon provides vitamin C and antioxidants.",
  ),
  QuizQuestion(
    id: 'fun_nut_226',
    category: 'Indian Lifestyle Nutrition',
    question:
        "Green tea alone can melt belly fat without dietary or lifestyle changes.",
    isFact: false,
    explanation:
        "Green tea supports metabolism but cannot replace proper diet and exercise.",
  ),
  QuizQuestion(
    id: 'fun_nut_227',
    category: 'Interesting Facts',
    question:
        "Fenugreek seeds can also reduce cholesterol while helping manage blood sugar.",
    isFact: true,
    explanation:
        "Fenugreek contains soluble fiber and saponins that lower cholesterol and improve insulin sensitivity.",
  ),
  QuizQuestion(
    id: 'fun_nut_228',
    category: 'Interesting Facts',
    question:
        "Eating spicy Indian food increases metabolism enough to counteract high-calorie meals entirely.",
    isFact: false,
    explanation:
        "Spices provide mild thermogenic effect but cannot offset excess calorie intake.",
  ),
  QuizQuestion(
    id: 'fun_nut_229',
    category: 'Gut Health',
    question:
        "Including fiber-rich Indian foods daily helps prevent constipation and improves gut microbiota.",
    isFact: true,
    explanation:
        "Fiber feeds beneficial gut bacteria and promotes regular bowel movements.",
  ),
  QuizQuestion(
    id: 'fun_nut_230',
    category: 'Gut Health',
    question:
        "Probiotics from packaged drinks are always as effective as homemade fermented foods.",
    isFact: false,
    explanation:
        "Commercial drinks often contain added sugar and lower bacterial counts compared to traditional fermented foods.",
  ),
  QuizQuestion(
    id: 'fun_nut_231',
    category: 'Nutrition Awareness',
    question:
        "Eating slowly and focusing on meals increases satiety and prevents overeating.",
    isFact: true,
    explanation:
        "Mindful eating helps regulate appetite hormones and reduces calorie intake.",
  ),
  QuizQuestion(
    id: 'fun_nut_232',
    category: 'Nutrition Awareness',
    question: "Mindless snacking has no effect on weight or energy levels.",
    isFact: false,
    explanation:
        "Unplanned snacking increases calorie intake and can cause energy fluctuations.",
  ),
  QuizQuestion(
    id: 'fun_nut_233',
    category: 'Chronic Disease & Energy',
    question:
        "Balanced Indian meals support sustained energy throughout the day.",
    isFact: true,
    explanation:
        "Protein, fiber, and complex carbs prevent sugar spikes and crashes.",
  ),
  QuizQuestion(
    id: 'fun_nut_234',
    category: 'Chronic Disease & Energy',
    question:
        "Energy levels only depend on medications taken for chronic disease.",
    isFact: false,
    explanation:
        "Diet, hydration, sleep, and activity play major roles in daily energy levels.",
  ),
  QuizQuestion(
    id: 'fun_nut_235',
    category: 'Nutrition Psychology',
    question:
        "Eating a variety of textures and flavors improves satisfaction and reduces cravings.",
    isFact: true,
    explanation:
        "Sensory diversity in meals enhances satiety and psychological satisfaction.",
  ),
  QuizQuestion(
    id: 'fun_nut_236',
    category: 'Nutrition Psychology',
    question:
        "All foods taste the same and have no impact on mood or motivation.",
    isFact: false,
    explanation:
        "Flavor, aroma, and variety influence mood, appetite, and mental well-being.",
  ),
  QuizQuestion(
    id: 'fun_nut_237',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Nutrition therapy can prevent progression of chronic diseases if started early.",
    isFact: true,
    explanation:
        "Dietary interventions improve metabolic and hormonal health, reducing complications and medication needs.",
  ),
  QuizQuestion(
    id: 'fun_nut_238',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Medication alone guarantees prevention of long-term complications without lifestyle change.",
    isFact: false,
    explanation:
        "Medications manage symptoms; nutrition and lifestyle changes prevent disease progression.",
  ),
  QuizQuestion(
    id: 'fun_nut_239',
    category: 'Interesting Facts',
    question:
        "Cinnamon in daily Indian cooking may reduce fasting blood sugar slightly over time.",
    isFact: true,
    explanation:
        "Cinnamon improves insulin sensitivity and supports blood sugar control.",
  ),
  QuizQuestion(
    id: 'fun_nut_240',
    category: 'Interesting Facts',
    question: "Just adding cinnamon to sweet dishes will cure diabetes.",
    isFact: false,
    explanation:
        "Cinnamon is supportive but cannot replace dietary control and medications.",
  ),
  QuizQuestion(
    id: 'fun_nut_241',
    category: 'Indian Food Myths',
    question:
        "Eating roti made from whole wheat or millets is better than refined flour for energy and blood sugar control.",
    isFact: true,
    explanation:
        "Whole grains release glucose slowly and provide sustained energy.",
  ),
  QuizQuestion(
    id: 'fun_nut_242',
    category: 'Indian Food Myths',
    question:
        "All roti, regardless of flour type, has the same effect on blood sugar.",
    isFact: false,
    explanation:
        "Refined flour roti spikes glucose faster than whole grain or millet roti.",
  ),
  QuizQuestion(
    id: 'fun_nut_243',
    category: 'Gut Health',
    question:
        "Drinking buttermilk with roasted cumin seeds supports digestion and reduces bloating.",
    isFact: true,
    explanation:
        "Probiotics and digestive spices aid microbiome balance and gut comfort.",
  ),
  QuizQuestion(
    id: 'fun_nut_244',
    category: 'Gut Health',
    question:
        "Carbonated soft drinks are harmless to gut health even if consumed daily.",
    isFact: false,
    explanation:
        "High sugar and carbonation can disrupt gut microbiota and cause bloating.",
  ),
  QuizQuestion(
    id: 'fun_nut_245',
    category: 'Nutrition Therapy & Energy',
    question:
        "Eating a balanced plate with carbs, protein, fiber, and healthy fats supports long-lasting energy.",
    isFact: true,
    explanation:
        "Macronutrient balance prevents sugar crashes and maintains metabolic stability.",
  ),
  QuizQuestion(
    id: 'fun_nut_246',
    category: 'Nutrition Therapy & Energy',
    question: "Energy comes only from medicines; diet has no role.",
    isFact: false,
    explanation:
        "Diet and lifestyle are primary contributors to energy and metabolic health.",
  ),
  QuizQuestion(
    id: 'fun_nut_247',
    category: 'Chronic Disease Awareness',
    question:
        "Switching to a nutrition-focused Indian diet can reduce dependency on medications over time.",
    isFact: true,
    explanation:
        "Balanced diet and lifestyle interventions improve blood sugar, blood pressure, and hormone balance.",
  ),
  QuizQuestion(
    id: 'fun_nut_248',
    category: 'Chronic Disease Awareness',
    question: "Taking more medicines allows you to ignore diet and lifestyle.",
    isFact: false,
    explanation:
        "Medication manages symptoms; diet and lifestyle prevent progression and improve overall wellness.",
  ),
  QuizQuestion(
    id: 'fun_nut_249',
    category: 'Interesting Facts',
    question:
        "Including turmeric, cumin, coriander, and fenugreek daily has synergistic health benefits.",
    isFact: true,
    explanation:
        "These spices collectively reduce inflammation, improve digestion, and support metabolic health.",
  ),
  QuizQuestion(
    id: 'fun_nut_250',
    category: 'Interesting Facts',
    question:
        "Just sprinkling spices occasionally without balanced diet provides full chronic disease protection.",
    isFact: false,
    explanation:
        "Spices are supportive but cannot replace balanced diet and healthy lifestyle.",
  ),
  QuizQuestion(
    id: 'lifehack_251',
    category: 'Daily Nutrition Hacks',
    question:
        "Drinking warm water first thing in the morning helps kickstart digestion and metabolism.",
    isFact: true,
    explanation:
        "Warm water stimulates digestive enzymes and improves bowel movement, aiding metabolic health.",
  ),
  QuizQuestion(
    id: 'lifehack_252',
    category: 'Daily Nutrition Hacks',
    question:
        "Skipping breakfast has no effect on energy levels or blood sugar throughout the day.",
    isFact: false,
    explanation:
        "Skipping breakfast can cause energy dips and blood sugar spikes later in the day.",
  ),
  QuizQuestion(
    id: 'lifehack_253',
    category: 'Chronic Disease & Indian Meals',
    question:
        "Pairing dal with brown rice or millets provides a complete protein source for vegetarians.",
    isFact: true,
    explanation:
        "Combining legumes and grains supplies all essential amino acids required for energy and repair.",
  ),
  QuizQuestion(
    id: 'lifehack_254',
    category: 'Chronic Disease & Indian Meals',
    question:
        "Eating dal alone without grains is sufficient to meet protein needs.",
    isFact: false,
    explanation:
        "Dal provides protein but may lack certain amino acids; pairing with grains ensures completeness.",
  ),
  QuizQuestion(
    id: 'lifehack_255',
    category: 'Diabetes Management',
    question:
        "Eating slowly and chewing thoroughly reduces post-meal glucose spikes.",
    isFact: true,
    explanation:
        "Slower eating enhances satiety and allows better digestion and glucose control.",
  ),
  QuizQuestion(
    id: 'lifehack_256',
    category: 'Diabetes Management',
    question:
        "Rapidly eating food has no effect on blood sugar or insulin response.",
    isFact: false,
    explanation:
        "Quick eating can lead to higher glucose spikes and overeating, impacting insulin levels.",
  ),
  QuizQuestion(
    id: 'lifehack_257',
    category: 'Gut Health',
    question:
        "Including fibrous vegetables like spinach, carrots, and beans daily improves digestion and prevents bloating.",
    isFact: true,
    explanation:
        "Fiber feeds beneficial gut bacteria, regulates bowel movements, and prevents constipation.",
  ),
  QuizQuestion(
    id: 'lifehack_258',
    category: 'Gut Health',
    question: "Gut health depends solely on probiotic supplements, not diet.",
    isFact: false,
    explanation:
        "Dietary fiber and fermented foods are essential for maintaining a healthy microbiome.",
  ),
  QuizQuestion(
    id: 'lifehack_259',
    category: 'Hypertension & Lifestyle',
    question:
        "Walking 20 minutes after meals helps maintain blood pressure and glucose control.",
    isFact: true,
    explanation:
        "Post-meal activity improves insulin sensitivity and prevents blood pressure spikes.",
  ),
  QuizQuestion(
    id: 'lifehack_260',
    category: 'Hypertension & Lifestyle',
    question:
        "Physical activity has no impact on hypertension if you take medicines regularly.",
    isFact: false,
    explanation:
        "Exercise directly affects vascular tone and metabolism, complementing medication effects.",
  ),
  QuizQuestion(
    id: 'lifehack_261',
    category: 'Fatty Liver Awareness',
    question:
        "Reducing refined sugar and deep-fried foods helps reverse fatty liver changes over time.",
    isFact: true,
    explanation:
        "Dietary control reduces liver fat accumulation and improves liver enzyme levels.",
  ),
  QuizQuestion(
    id: 'lifehack_262',
    category: 'Fatty Liver Awareness',
    question:
        "Fatty liver can be cured by supplements alone without dietary or lifestyle changes.",
    isFact: false,
    explanation:
        "Supplements support liver function but cannot reverse fatty liver without diet modification.",
  ),
  QuizQuestion(
    id: 'lifehack_263',
    category: 'PCOS & Lifestyle',
    question:
        "Regular meals with low-GI foods improve insulin sensitivity in PCOS.",
    isFact: true,
    explanation:
        "Stable glucose levels reduce androgen imbalance and support hormonal health.",
  ),
  QuizQuestion(
    id: 'lifehack_264',
    category: 'PCOS & Lifestyle',
    question:
        "PCOS symptoms can be fully controlled with supplements while ignoring diet.",
    isFact: false,
    explanation:
        "Dietary and lifestyle interventions are primary; supplements are supportive.",
  ),
  QuizQuestion(
    id: 'lifehack_265',
    category: 'Anemia & Nutrition',
    question:
        "Iron absorption is enhanced when consumed with vitamin C-rich foods like oranges or lemon.",
    isFact: true,
    explanation:
        "Vitamin C converts non-heme iron to a more absorbable form in the gut.",
  ),
  QuizQuestion(
    id: 'lifehack_266',
    category: 'Anemia & Nutrition',
    question:
        "Iron tablets alone guarantee normal hemoglobin without dietary support.",
    isFact: false,
    explanation:
        "Whole foods provide co-factors like B12, folate, and protein necessary for RBC synthesis.",
  ),
  QuizQuestion(
    id: 'lifehack_267',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Nutrition therapy focuses on root causes of chronic disease, not just symptoms.",
    isFact: true,
    explanation:
        "Diet and lifestyle adjustments improve metabolism, immunity, and hormonal balance over time.",
  ),
  QuizQuestion(
    id: 'lifehack_268',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Medicine alone can replace the benefits of nutrition therapy for chronic disease prevention.",
    isFact: false,
    explanation:
        "Medications treat symptoms; diet and lifestyle prevent progression and support energy and longevity.",
  ),
  QuizQuestion(
    id: 'lifehack_269',
    category: 'Indian Spices & Chronic Disease',
    question:
        "Fenugreek seeds help reduce cholesterol and regulate blood sugar when included regularly in meals.",
    isFact: true,
    explanation:
        "Soluble fiber and saponins in fenugreek improve lipid profile and glucose metabolism.",
  ),
  QuizQuestion(
    id: 'lifehack_270',
    category: 'Indian Spices & Chronic Disease',
    question:
        "Fenugreek seeds alone can completely replace diabetes medications.",
    isFact: false,
    explanation:
        "Fenugreek supports glucose control but cannot replace prescribed medication.",
  ),
  QuizQuestion(
    id: 'lifehack_271',
    category: 'Interesting Food Facts',
    question:
        "Consuming a mix of colorful vegetables provides antioxidants that improve immunity and energy.",
    isFact: true,
    explanation:
        "Different pigments indicate various phytonutrients that combat oxidative stress.",
  ),
  QuizQuestion(
    id: 'lifehack_272',
    category: 'Interesting Food Facts',
    question:
        "Eating one type of vegetable every day provides all required nutrients.",
    isFact: false,
    explanation:
        "Variety ensures intake of all essential vitamins, minerals, and antioxidants.",
  ),
  QuizQuestion(
    id: 'lifehack_273',
    category: 'Weight Management',
    question:
        "Mindful eating and portion control help maintain a healthy weight sustainably.",
    isFact: true,
    explanation:
        "Awareness of hunger and fullness prevents overeating and promotes energy balance.",
  ),
  QuizQuestion(
    id: 'lifehack_274',
    category: 'Weight Management',
    question:
        "Eating as much as you want is fine if you exercise occasionally.",
    isFact: false,
    explanation:
        "Exercise alone cannot counterbalance chronic overconsumption of calories.",
  ),
  QuizQuestion(
    id: 'lifehack_275',
    category: 'Hydration & Energy',
    question:
        "Adequate water intake throughout the day improves energy, digestion, and skin health.",
    isFact: true,
    explanation:
        "Hydration supports cellular metabolism, nutrient transport, and toxin elimination.",
  ),
  QuizQuestion(
    id: 'lifehack_276',
    category: 'Hydration & Energy',
    question: "Hydration has no impact on fatigue or mental alertness.",
    isFact: false,
    explanation:
        "Even mild dehydration can cause tiredness, headaches, and reduced focus.",
  ),
  QuizQuestion(
    id: 'lifehack_277',
    category: 'Chronic Disease Awareness',
    question:
        "Balanced Indian meals reduce dependence on medications over time in conditions like diabetes and hypertension.",
    isFact: true,
    explanation:
        "Stable blood sugar and blood pressure through diet reduce medication escalation.",
  ),
  QuizQuestion(
    id: 'lifehack_278',
    category: 'Chronic Disease Awareness',
    question:
        "Medication use means diet can be ignored for chronic disease management.",
    isFact: false,
    explanation:
        "Medication alone manages symptoms but does not prevent disease progression or fatigue.",
  ),
  QuizQuestion(
    id: 'lifehack_279',
    category: 'Energy & Lifestyle',
    question:
        "Including nuts, seeds, and healthy oils in snacks provides long-lasting energy.",
    isFact: true,
    explanation:
        "Healthy fats slow digestion, stabilize blood sugar, and prevent mid-day energy dips.",
  ),
  QuizQuestion(
    id: 'lifehack_280',
    category: 'Energy & Lifestyle',
    question:
        "Energy comes only from caffeine or sugar; healthy fats have no effect.",
    isFact: false,
    explanation:
        "Balanced macronutrients, including fats, provide sustained energy without crashes.",
  ),
  QuizQuestion(
    id: 'lifehack_281',
    category: 'Gut Health & Indian Foods',
    question:
        "Buttermilk, curd, and fermented foods improve digestion and immunity.",
    isFact: true,
    explanation:
        "Probiotics from fermentation support gut microbiota and enhance nutrient absorption.",
  ),
  QuizQuestion(
    id: 'lifehack_282',
    category: 'Gut Health & Indian Foods',
    question: "Carbonated soft drinks and soda have no effect on gut health.",
    isFact: false,
    explanation:
        "High sugar and carbonation can harm microbiota and cause bloating.",
  ),
  QuizQuestion(
    id: 'lifehack_283',
    category: 'Practical Nutrition Tips',
    question:
        "Eating seasonal fruits and vegetables maximizes nutrient intake and freshness.",
    isFact: true,
    explanation:
        "Seasonal produce contains higher vitamins, antioxidants, and flavor compared to off-season options.",
  ),
  QuizQuestion(
    id: 'lifehack_284',
    category: 'Practical Nutrition Tips',
    question:
        "All fruits provide the same nutrients regardless of season or ripeness.",
    isFact: false,
    explanation:
        "Nutrient levels vary with season, ripeness, and freshness, impacting health benefits.",
  ),
  QuizQuestion(
    id: 'lifehack_285',
    category: 'Mindful Eating',
    question: "Eating without distractions enhances satiety and digestion.",
    isFact: true,
    explanation:
        "Focused eating improves awareness of fullness and supports better nutrient absorption.",
  ),
  QuizQuestion(
    id: 'lifehack_286',
    category: 'Mindful Eating',
    question:
        "Watching TV or phone while eating has no effect on digestion or portion control.",
    isFact: false,
    explanation:
        "Distractions lead to overeating and slower recognition of satiety cues.",
  ),
  QuizQuestion(
    id: 'lifehack_287',
    category: 'Chronic Disease Prevention',
    question:
        "Early adoption of nutrition therapy can prevent progression of chronic diseases like diabetes and hypertension.",
    isFact: true,
    explanation:
        "Proactive dietary changes stabilize metabolism and reduce complications over time.",
  ),
  QuizQuestion(
    id: 'lifehack_288',
    category: 'Chronic Disease Prevention',
    question:
        "Starting nutrition therapy late has the same benefits as early intervention.",
    isFact: false,
    explanation:
        "Delayed intervention limits benefits; early lifestyle changes prevent disease progression more effectively.",
  ),
  QuizQuestion(
    id: 'lifehack_289',
    category: 'Indian Lifestyle & Energy',
    question:
        "Walking or yoga in the morning boosts metabolism and energy for the whole day.",
    isFact: true,
    explanation:
        "Morning activity improves circulation, hormone balance, and alertness.",
  ),
  QuizQuestion(
    id: 'lifehack_290',
    category: 'Indian Lifestyle & Energy',
    question: "Morning activity has no effect on energy or metabolism.",
    isFact: false,
    explanation:
        "Physical activity at any time boosts energy and metabolism; morning timing can improve hormonal rhythm.",
  ),
  QuizQuestion(
    id: 'lifehack_291',
    category: 'Nutrition Therapy & Supplements',
    question:
        "Supplements support health but cannot replace a balanced diet for chronic disease management.",
    isFact: true,
    explanation:
        "Whole foods provide a combination of fiber, micronutrients, and phytonutrients not replicated in supplements.",
  ),
  QuizQuestion(
    id: 'lifehack_292',
    category: 'Nutrition Therapy & Supplements',
    question:
        "Taking multiple supplements allows ignoring nutrition completely.",
    isFact: false,
    explanation:
        "Supplements cannot provide the synergistic benefits of whole foods and balanced meals.",
  ),
  QuizQuestion(
    id: 'lifehack_293',
    category: 'Food Myths',
    question:
        "White rice in moderate portions can be included in a diabetes-friendly diet when balanced with protein and fiber.",
    isFact: true,
    explanation:
        "Portion control and meal balance prevent rapid glucose spikes even with refined carbs.",
  ),
  QuizQuestion(
    id: 'lifehack_294',
    category: 'Food Myths',
    question: "Eating any amount of white rice is harmful for diabetics.",
    isFact: false,
    explanation:
        "Moderation, pairing with fiber and protein, and portion control are key for blood sugar management.",
  ),
  QuizQuestion(
    id: 'lifehack_295',
    category: 'Interesting Facts',
    question:
        "Coriander seeds and leaves have anti-inflammatory and digestive benefits when used regularly.",
    isFact: true,
    explanation:
        "Coriander contains antioxidants and digestive enzymes that aid metabolism and reduce inflammation.",
  ),
  QuizQuestion(
    id: 'lifehack_296',
    category: 'Interesting Facts',
    question:
        "Just sprinkling coriander occasionally is enough to prevent chronic disease.",
    isFact: false,
    explanation:
        "Regular diet patterns and overall nutrition matter more than sporadic spice use.",
  ),
  QuizQuestion(
    id: 'lifehack_297',
    category: 'Nutrition Psychology',
    question:
        "Eating colorful meals with variety increases satisfaction and reduces cravings.",
    isFact: true,
    explanation:
        "Visual appeal and variety improve satiety and psychological satisfaction.",
  ),
  QuizQuestion(
    id: 'lifehack_298',
    category: 'Nutrition Psychology',
    question: "Monotonous meals have no effect on appetite, mood, or cravings.",
    isFact: false,
    explanation:
        "Lack of variety can increase cravings and reduce meal satisfaction.",
  ),
  QuizQuestion(
    id: 'lifehack_299',
    category: 'Lifestyle & Chronic Disease',
    question:
        "Combining diet, activity, and stress management enhances long-term chronic disease outcomes.",
    isFact: true,
    explanation:
        "Holistic lifestyle changes address root causes, improve energy, and prevent complications.",
  ),
  QuizQuestion(
    id: 'lifehack_300',
    category: 'Lifestyle & Chronic Disease',
    question:
        "Focusing only on medications is enough for long-term chronic disease prevention.",
    isFact: false,
    explanation:
        "Medications treat symptoms; lifestyle interventions are essential for prevention and sustained wellness.",
  ),

  QuizQuestion(
    id: 'scenario_301',
    category: 'Interactive Lifestyle',
    question:
        "If you feel low on energy after lunch, having a small serving of nuts and curd can help sustain energy.",
    isFact: true,
    explanation:
        "Protein and healthy fats slow digestion and provide stable energy without sugar spikes.",
  ),
  QuizQuestion(
    id: 'scenario_302',
    category: 'Interactive Lifestyle',
    question:
        "Drinking sweetened soda is the best way to recover from mid-day fatigue.",
    isFact: false,
    explanation:
        "High sugar drinks cause quick spikes followed by energy crashes; balanced snacks are better.",
  ),
  QuizQuestion(
    id: 'scenario_303',
    category: 'Diabetes Management',
    question:
        "Adding a portion of moong dal or chickpeas to your meal helps prevent post-meal sugar spikes.",
    isFact: true,
    explanation:
        "Legumes have low glycemic index and high fiber, stabilizing blood sugar levels.",
  ),
  QuizQuestion(
    id: 'scenario_304',
    category: 'Diabetes Management',
    question:
        "Taking insulin or medication alone allows eating anything without sugar concerns.",
    isFact: false,
    explanation:
        "Medication must be complemented by balanced diet to maintain stable glucose levels.",
  ),
  QuizQuestion(
    id: 'scenario_305',
    category: 'Hypertension',
    question:
        "Replacing fried snacks with roasted chana or makhana can help maintain healthy blood pressure.",
    isFact: true,
    explanation:
        "Low-sodium, high-fiber snacks reduce salt load and support vascular health.",
  ),
  QuizQuestion(
    id: 'scenario_306',
    category: 'Hypertension',
    question:
        "Salt restriction alone is sufficient to control hypertension regardless of diet or lifestyle.",
    isFact: false,
    explanation:
        "Other factors like weight, exercise, stress, and balanced diet also influence blood pressure.",
  ),
  QuizQuestion(
    id: 'scenario_307',
    category: 'Gut Health',
    question:
        "Including fermented foods like idli, dosa, and homemade curd daily improves gut microbiome.",
    isFact: true,
    explanation:
        "Probiotics support digestion, immunity, and nutrient absorption.",
  ),
  QuizQuestion(
    id: 'scenario_308',
    category: 'Gut Health',
    question: "Gut health depends solely on supplements; food does not matter.",
    isFact: false,
    explanation:
        "Dietary fiber and fermented foods are essential for maintaining microbiome balance.",
  ),
  QuizQuestion(
    id: 'scenario_309',
    category: 'Fatty Liver',
    question:
        "Replacing sugary drinks with lemon water and herbal teas supports liver health.",
    isFact: true,
    explanation:
        "Reducing sugar intake decreases fat accumulation in the liver and supports detoxification.",
  ),
  QuizQuestion(
    id: 'scenario_310',
    category: 'Fatty Liver',
    question:
        "You can continue regular sugar-rich drinks if you take liver supplements.",
    isFact: false,
    explanation:
        "Supplements cannot counteract the negative effects of high sugar on the liver.",
  ),
  QuizQuestion(
    id: 'scenario_311',
    category: 'PCOS Management',
    question:
        "Regular small meals with low-GI foods stabilize insulin and reduce PCOS symptoms.",
    isFact: true,
    explanation:
        "Stable glucose reduces androgen imbalance, supporting hormonal health.",
  ),
  QuizQuestion(
    id: 'scenario_312',
    category: 'PCOS Management',
    question:
        "PCOS can be fully managed by taking supplements alone without dietary control.",
    isFact: false,
    explanation:
        "Diet and lifestyle modifications are primary; supplements only support therapy.",
  ),
  QuizQuestion(
    id: 'scenario_313',
    category: 'Anemia',
    question:
        "Pairing iron-rich foods like spinach with vitamin C sources enhances absorption.",
    isFact: true,
    explanation:
        "Vitamin C converts non-heme iron into a more absorbable form in the gut.",
  ),
  QuizQuestion(
    id: 'scenario_314',
    category: 'Anemia',
    question:
        "Iron supplements are always enough to prevent anemia without dietary support.",
    isFact: false,
    explanation:
        "Whole foods provide co-factors like folate, B12, and protein necessary for RBC production.",
  ),
  QuizQuestion(
    id: 'scenario_315',
    category: 'Nutrition Psychology',
    question:
        "Eating colorful plates with variety of textures improves satisfaction and reduces cravings.",
    isFact: true,
    explanation:
        "Visual and sensory diversity enhances satiety and psychological well-being.",
  ),
  QuizQuestion(
    id: 'scenario_316',
    category: 'Nutrition Psychology',
    question: "Monotonous meals have no effect on appetite or mood.",
    isFact: false,
    explanation:
        "Lack of variety can increase cravings and reduce meal satisfaction.",
  ),
  QuizQuestion(
    id: 'scenario_317',
    category: 'Weight Management',
    question:
        "Mindful eating and portion control support sustainable weight loss.",
    isFact: true,
    explanation:
        "Awareness of hunger and fullness prevents overeating and improves energy balance.",
  ),
  QuizQuestion(
    id: 'scenario_318',
    category: 'Weight Management',
    question:
        "Skipping meals or crash diets is effective for long-term weight loss.",
    isFact: false,
    explanation:
        "Skipping meals slows metabolism and may lead to overeating later.",
  ),
  QuizQuestion(
    id: 'scenario_319',
    category: 'Energy & Lifestyle',
    question:
        "Adding nuts, seeds, and healthy fats to snacks provides steady energy throughout the day.",
    isFact: true,
    explanation:
        "Fats slow digestion and help maintain blood sugar levels, preventing mid-day crashes.",
  ),
  QuizQuestion(
    id: 'scenario_320',
    category: 'Energy & Lifestyle',
    question: "Caffeine or sugar alone are sufficient for sustained energy.",
    isFact: false,
    explanation:
        "Balanced macronutrients, hydration, and sleep are essential for consistent energy levels.",
  ),
  QuizQuestion(
    id: 'scenario_321',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Nutrition therapy focuses on root causes of chronic disease rather than only symptoms.",
    isFact: true,
    explanation:
        "Diet and lifestyle adjustments improve metabolism, immunity, and hormonal balance over time.",
  ),
  QuizQuestion(
    id: 'scenario_322',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Medication alone can replace benefits of nutrition therapy for chronic disease prevention.",
    isFact: false,
    explanation:
        "Medication treats symptoms; diet and lifestyle prevent progression and enhance energy and longevity.",
  ),
  QuizQuestion(
    id: 'scenario_323',
    category: 'Hydration & Energy',
    question:
        "Drinking enough water throughout the day improves digestion, focus, and energy.",
    isFact: true,
    explanation:
        "Hydration supports cellular metabolism and prevents fatigue and cognitive decline.",
  ),
  QuizQuestion(
    id: 'scenario_324',
    category: 'Hydration & Energy',
    question:
        "Hydration has no effect on fatigue, mental alertness, or metabolism.",
    isFact: false,
    explanation:
        "Even mild dehydration can reduce energy, impair focus, and slow metabolism.",
  ),
  QuizQuestion(
    id: 'scenario_325',
    category: 'Chronic Disease Prevention',
    question:
        "Early adoption of nutrition therapy can prevent progression of diabetes, hypertension, and fatty liver.",
    isFact: true,
    explanation:
        "Proactive dietary changes stabilize metabolism and reduce complications over time.",
  ),
  QuizQuestion(
    id: 'scenario_326',
    category: 'Chronic Disease Prevention',
    question:
        "Starting nutrition therapy late has same benefits as early intervention.",
    isFact: false,
    explanation:
        "Delayed intervention limits benefits; early lifestyle changes prevent disease progression more effectively.",
  ),
  QuizQuestion(
    id: 'scenario_327',
    category: 'Indian Spices',
    question:
        "Black pepper enhances turmeric absorption and maximizes anti-inflammatory effects.",
    isFact: true,
    explanation: "Piperine in black pepper increases curcumin bioavailability.",
  ),
  QuizQuestion(
    id: 'scenario_328',
    category: 'Indian Spices',
    question:
        "Sprinkling spices occasionally without consistent diet change will fully prevent chronic disease.",
    isFact: false,
    explanation:
        "Spices are supportive but overall diet and lifestyle are critical for chronic disease prevention.",
  ),
  QuizQuestion(
    id: 'scenario_329',
    category: 'Meal Timing',
    question:
        "Having a light snack like fruits or nuts before 5 PM can prevent energy crashes in the evening.",
    isFact: true,
    explanation:
        "Small balanced snacks stabilize blood sugar and energy levels between meals.",
  ),
  QuizQuestion(
    id: 'scenario_330',
    category: 'Meal Timing',
    question: "Meal timing has no impact on energy or metabolic health.",
    isFact: false,
    explanation:
        "Consistent timing supports circadian rhythm and metabolic stability.",
  ),
  QuizQuestion(
    id: 'scenario_331',
    category: 'Gut Health',
    question:
        "Including seasonal fruits and vegetables provides fiber and micronutrients that support gut microbiome.",
    isFact: true,
    explanation:
        "Seasonal produce is rich in nutrients and prebiotic fibers that nourish healthy gut bacteria.",
  ),
  QuizQuestion(
    id: 'scenario_332',
    category: 'Gut Health',
    question: "Fresh produce has no effect on gut microbiome or digestion.",
    isFact: false,
    explanation:
        "Fiber and phytonutrients from fresh fruits and vegetables are essential for gut health.",
  ),
  QuizQuestion(
    id: 'scenario_333',
    category: 'Weight & Energy',
    question:
        "Balancing carbs, protein, and healthy fats in meals provides long-lasting energy and prevents sugar crashes.",
    isFact: true,
    explanation:
        "Macronutrient balance ensures steady glucose and sustained energy.",
  ),
  QuizQuestion(
    id: 'scenario_334',
    category: 'Weight & Energy',
    question:
        "Only eating carbs or sugar provides better energy than balanced meals.",
    isFact: false,
    explanation:
        "Carb-only meals cause quick spikes and crashes; protein and fat are essential for sustained energy.",
  ),
  QuizQuestion(
    id: 'scenario_335',
    category: 'Practical Tips',
    question:
        "Walking after dinner aids digestion and prevents blood sugar spikes.",
    isFact: true,
    explanation:
        "Post-meal activity enhances insulin sensitivity and reduces glucose excursions.",
  ),
  QuizQuestion(
    id: 'scenario_336',
    category: 'Practical Tips',
    question:
        "Resting immediately after dinner has no effect on digestion or metabolism.",
    isFact: false,
    explanation:
        "Lack of movement slows digestion and may cause bloating or glucose spikes.",
  ),
  QuizQuestion(
    id: 'scenario_337',
    category: 'Nutrition Psychology',
    question:
        "Meal variety and colorful presentation increase satisfaction and reduce cravings.",
    isFact: true,
    explanation:
        "Visual and sensory diversity improves psychological satisfaction and satiety.",
  ),
  QuizQuestion(
    id: 'scenario_338',
    category: 'Nutrition Psychology',
    question: "All meals taste the same and do not affect mood or cravings.",
    isFact: false,
    explanation:
        "Meal appeal and variety influence appetite, satisfaction, and psychological well-being.",
  ),
  QuizQuestion(
    id: 'scenario_339',
    category: 'Supplements vs Food',
    question:
        "Supplements support health but cannot replace a balanced diet for long-term chronic disease management.",
    isFact: true,
    explanation:
        "Whole foods provide fiber, phytonutrients, and cofactors not found in supplements.",
  ),
  QuizQuestion(
    id: 'scenario_340',
    category: 'Supplements vs Food',
    question:
        "Taking multiple supplements allows ignoring diet and lifestyle completely.",
    isFact: false,
    explanation:
        "Supplements cannot replicate benefits of balanced diet and healthy lifestyle.",
  ),
  QuizQuestion(
    id: 'scenario_341',
    category: 'Chronic Disease & Lifestyle',
    question:
        "Combining diet, physical activity, and stress management improves long-term chronic disease outcomes.",
    isFact: true,
    explanation:
        "Holistic lifestyle interventions prevent complications, enhance energy, and support longevity.",
  ),
  QuizQuestion(
    id: 'scenario_342',
    category: 'Chronic Disease & Lifestyle',
    question:
        "Focusing only on medications ensures prevention of long-term complications.",
    isFact: false,
    explanation:
        "Medications manage symptoms; lifestyle changes address root causes and sustain health.",
  ),
  QuizQuestion(
    id: 'scenario_343',
    category: 'Indian Food Facts',
    question:
        "Whole grains like bajra, jowar, and brown rice release glucose slowly and provide sustained energy.",
    isFact: true,
    explanation:
        "Low-GI grains prevent sugar spikes and support metabolic health.",
  ),
  QuizQuestion(
    id: 'scenario_344',
    category: 'Indian Food Facts',
    question:
        "All grains have the same impact on blood sugar regardless of type.",
    isFact: false,
    explanation:
        "Refined grains spike glucose faster than whole grains or millets.",
  ),
  QuizQuestion(
    id: 'scenario_345',
    category: 'Hydration',
    question:
        "Starting the day with water or herbal tea supports metabolism and detoxification.",
    isFact: true,
    explanation: "Hydration improves cellular function, digestion, and energy.",
  ),
  QuizQuestion(
    id: 'scenario_346',
    category: 'Hydration',
    question: "Hydration has no impact on metabolism or toxin elimination.",
    isFact: false,
    explanation:
        "Adequate fluid intake is essential for metabolism and excretion of waste.",
  ),
  QuizQuestion(
    id: 'scenario_347',
    category: 'Energy & Indian Lifestyle',
    question:
        "Morning walks or yoga boost alertness, metabolism, and energy throughout the day.",
    isFact: true,
    explanation:
        "Physical activity improves circulation, hormone balance, and mental clarity.",
  ),
  QuizQuestion(
    id: 'scenario_348',
    category: 'Energy & Indian Lifestyle',
    question: "Morning activity has no effect on energy or alertness.",
    isFact: false,
    explanation:
        "Physical activity increases energy and supports metabolic health, with morning activity benefiting circadian rhythm.",
  ),
  QuizQuestion(
    id: 'scenario_349',
    category: 'Meal Pairing',
    question:
        "Pairing dal with vegetables and whole grains ensures complete nutrients and steady energy.",
    isFact: true,
    explanation:
        "Combining protein, fiber, and micronutrients optimizes digestion and energy release.",
  ),
  QuizQuestion(
    id: 'scenario_350',
    category: 'Meal Pairing',
    question:
        "Pairing dal with refined flour roti has no impact on nutrient balance or glucose response.",
    isFact: false,
    explanation:
        "Refined flour spikes glucose faster; pairing with fiber-rich grains improves balance.",
  ),
  QuizQuestion(
    id: 'advanced_351',
    category: 'Nutrition Therapy & Chronic Disease',
    question:
        "Consistent use of nutrition therapy can reduce medication dependency in diabetes and hypertension over time.",
    isFact: true,
    explanation:
        "Dietary changes stabilize blood sugar and blood pressure, supporting better long-term outcomes.",
  ),
  QuizQuestion(
    id: 'advanced_352',
    category: 'Nutrition Therapy & Chronic Disease',
    question:
        "Medications alone can eliminate the need for dietary interventions in chronic diseases.",
    isFact: false,
    explanation:
        "Medications treat symptoms but cannot address root causes or improve energy long-term.",
  ),
  QuizQuestion(
    id: 'advanced_353',
    category: 'Fatty Liver Healing',
    question:
        "Including leafy greens, cruciferous vegetables, and whole grains supports liver detoxification.",
    isFact: true,
    explanation:
        "Fiber and phytonutrients help reduce liver fat and improve enzyme function.",
  ),
  QuizQuestion(
    id: 'advanced_354',
    category: 'Fatty Liver Healing',
    question:
        "Supplements alone without dietary adjustments are enough to reverse fatty liver.",
    isFact: false,
    explanation:
        "Lifestyle and nutrition changes are essential to effectively reduce liver fat.",
  ),
  QuizQuestion(
    id: 'advanced_355',
    category: 'PCOS & Nutrition',
    question:
        "Low-GI foods, regular meals, and physical activity improve insulin sensitivity in PCOS.",
    isFact: true,
    explanation:
        "Balanced meals and lifestyle interventions reduce androgen imbalance and symptoms.",
  ),
  QuizQuestion(
    id: 'advanced_356',
    category: 'PCOS & Nutrition',
    question:
        "Hormonal imbalance in PCOS can be fully corrected by supplements alone.",
    isFact: false,
    explanation:
        "Dietary and lifestyle interventions are the primary strategy for long-term symptom control.",
  ),
  QuizQuestion(
    id: 'advanced_357',
    category: 'Anemia & Nutrition',
    question:
        "Eating iron-rich foods with vitamin C and adequate protein supports long-term hemoglobin improvement.",
    isFact: true,
    explanation:
        "Vitamin C enhances absorption, and protein provides essential co-factors for RBC production.",
  ),
  QuizQuestion(
    id: 'advanced_358',
    category: 'Anemia & Nutrition',
    question:
        "Iron tablets alone guarantee normal hemoglobin without balanced meals.",
    isFact: false,
    explanation:
        "Whole foods provide cofactors like folate and B12, crucial for red blood cell synthesis.",
  ),
  QuizQuestion(
    id: 'advanced_359',
    category: 'Chronic Disease Awareness',
    question:
        "Understanding nutrition psychology helps in maintaining adherence to long-term healthy habits.",
    isFact: true,
    explanation:
        "Awareness of appetite, cravings, and meal satisfaction improves consistency in dietary choices.",
  ),
  QuizQuestion(
    id: 'advanced_360',
    category: 'Chronic Disease Awareness',
    question:
        "Willpower alone without structured nutrition strategies is sufficient for lifestyle change.",
    isFact: false,
    explanation:
        "Structured guidance and habit-based strategies are more effective than relying solely on willpower.",
  ),
  QuizQuestion(
    id: 'advanced_361',
    category: 'Gut Health & Indian Diet',
    question:
        "Daily consumption of fermented foods like idli, dosa, curd, and pickles supports gut microbiome.",
    isFact: true,
    explanation:
        "Probiotics nourish gut bacteria, improving digestion, immunity, and overall health.",
  ),
  QuizQuestion(
    id: 'advanced_362',
    category: 'Gut Health & Indian Diet',
    question:
        "Probiotics alone can maintain gut health without fiber and fermented foods.",
    isFact: false,
    explanation:
        "Dietary fiber and fermented foods are essential for a balanced gut microbiome.",
  ),
  QuizQuestion(
    id: 'advanced_363',
    category: 'Energy & Lifestyle',
    question:
        "Balanced meals with protein, fiber, and healthy fats provide steady energy throughout the day.",
    isFact: true,
    explanation:
        "Macronutrient balance prevents spikes and crashes, supporting physical and mental energy.",
  ),
  QuizQuestion(
    id: 'advanced_364',
    category: 'Energy & Lifestyle',
    question:
        "Caffeine or sugar are sufficient for sustained energy without balanced meals.",
    isFact: false,
    explanation:
        "Single nutrients provide temporary energy, whereas balanced meals sustain metabolism.",
  ),
  QuizQuestion(
    id: 'advanced_365',
    category: 'Weight Management',
    question:
        "Gradual, sustainable changes in portion sizes and meal composition lead to long-term weight control.",
    isFact: true,
    explanation:
        "Slow, consistent lifestyle changes prevent rebound weight gain and support energy balance.",
  ),
  QuizQuestion(
    id: 'advanced_366',
    category: 'Weight Management',
    question: "Crash diets or skipping meals ensures permanent weight loss.",
    isFact: false,
    explanation:
        "Extreme measures may cause metabolic slowdown and are not sustainable.",
  ),
  QuizQuestion(
    id: 'advanced_367',
    category: 'Indian Spices & Chronic Disease',
    question:
        "Turmeric, ginger, and cinnamon have anti-inflammatory and metabolic benefits when used regularly.",
    isFact: true,
    explanation:
        "Bioactive compounds in these spices support glucose regulation, lipid metabolism, and inflammation control.",
  ),
  QuizQuestion(
    id: 'advanced_368',
    category: 'Indian Spices & Chronic Disease',
    question:
        "Using spices occasionally without overall dietary changes fully prevents chronic disease.",
    isFact: false,
    explanation:
        "Spices support health but comprehensive diet and lifestyle changes are essential.",
  ),
  QuizQuestion(
    id: 'advanced_369',
    category: 'Hydration & Energy',
    question:
        "Starting the day with water or herbal teas improves digestion, metabolism, and detoxification.",
    isFact: true,
    explanation:
        "Hydration supports cellular metabolism and elimination of waste.",
  ),
  QuizQuestion(
    id: 'advanced_370',
    category: 'Hydration & Energy',
    question:
        "Hydration has minimal effect on metabolism or daily energy levels.",
    isFact: false,
    explanation:
        "Even mild dehydration can lead to fatigue, poor focus, and slower metabolic rate.",
  ),
  QuizQuestion(
    id: 'advanced_371',
    category: 'Meal Timing',
    question:
        "Eating smaller, balanced meals every 3–4 hours helps stabilize glucose and energy levels.",
    isFact: true,
    explanation:
        "Frequent balanced meals prevent glucose spikes and sustain energy.",
  ),
  QuizQuestion(
    id: 'advanced_372',
    category: 'Meal Timing',
    question:
        "Eating only two large meals a day has no impact on energy or metabolism.",
    isFact: false,
    explanation:
        "Meal timing affects insulin response, satiety, and energy throughout the day.",
  ),
  QuizQuestion(
    id: 'advanced_373',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Nutrition therapy treats root causes and improves long-term outcomes, whereas medicine primarily addresses symptoms.",
    isFact: true,
    explanation:
        "Dietary interventions improve metabolism, immunity, and hormonal balance sustainably.",
  ),
  QuizQuestion(
    id: 'advanced_374',
    category: 'Nutrition Therapy vs Medicine',
    question:
        "Medicine can replace nutrition therapy in treating chronic diseases completely.",
    isFact: false,
    explanation:
        "Medications manage symptoms; nutrition therapy supports prevention and holistic health.",
  ),
  QuizQuestion(
    id: 'advanced_375',
    category: 'Chronic Disease & Lifestyle',
    question:
        "Combining diet, exercise, stress management, and sleep maximizes healing and energy in chronic conditions.",
    isFact: true,
    explanation:
        "Holistic interventions address root causes and improve long-term outcomes and vitality.",
  ),
  QuizQuestion(
    id: 'advanced_376',
    category: 'Chronic Disease & Lifestyle',
    question:
        "Focusing only on one aspect, like medication or exercise, is enough for full recovery.",
    isFact: false,
    explanation:
        "Multiple lifestyle factors together are essential to prevent disease progression and maintain energy.",
  ),
  QuizQuestion(
    id: 'advanced_377',
    category: 'Practical Indian Meal Tips',
    question:
        "Pairing dal, vegetables, and whole grains ensures complete nutrients and stable glucose.",
    isFact: true,
    explanation:
        "Combination provides protein, fiber, vitamins, and minerals for balanced energy.",
  ),
  QuizQuestion(
    id: 'advanced_378',
    category: 'Practical Indian Meal Tips',
    question:
        "Eating dal with refined flour roti has the same effect as whole grains on glucose control.",
    isFact: false,
    explanation:
        "Refined flour is digested faster, causing glucose spikes compared to whole grains.",
  ),
  QuizQuestion(
    id: 'advanced_379',
    category: 'Mindful Eating',
    question:
        "Eating slowly and focusing on meals enhances satiety and digestion.",
    isFact: true,
    explanation:
        "Mindful eating improves awareness of fullness and supports nutrient absorption.",
  ),
  QuizQuestion(
    id: 'advanced_380',
    category: 'Mindful Eating',
    question:
        "Eating quickly while distracted has no impact on digestion or portion control.",
    isFact: false,
    explanation:
        "Distraction can lead to overeating and slower recognition of fullness.",
  ),
  QuizQuestion(
    id: 'advanced_381',
    category: 'Energy & Indian Lifestyle',
    question:
        "Morning yoga or walks boost metabolism, hormone balance, and mental alertness.",
    isFact: true,
    explanation:
        "Morning activity improves circulation, supports circadian rhythm, and enhances energy.",
  ),
  QuizQuestion(
    id: 'advanced_382',
    category: 'Energy & Indian Lifestyle',
    question: "Skipping morning activity does not affect metabolism or energy.",
    isFact: false,
    explanation:
        "Lack of activity slows circulation and can reduce alertness and energy levels.",
  ),
  QuizQuestion(
    id: 'advanced_383',
    category: 'Gut Health & Indian Foods',
    question:
        "Seasonal fruits and vegetables provide fiber and micronutrients that nourish gut bacteria.",
    isFact: true,
    explanation:
        "Prebiotic fibers feed beneficial gut microbiota, improving digestion and immunity.",
  ),
  QuizQuestion(
    id: 'advanced_384',
    category: 'Gut Health & Indian Foods',
    question: "Fresh produce has little effect on gut microbiome.",
    isFact: false,
    explanation:
        "Fiber and phytonutrients from fresh foods are essential for gut health.",
  ),
  QuizQuestion(
    id: 'advanced_385',
    category: 'Chronic Disease Awareness',
    question:
        "Understanding nutrition helps in making sustainable lifestyle changes for long-term health.",
    isFact: true,
    explanation:
        "Knowledge empowers individuals to apply dietary strategies effectively.",
  ),
  QuizQuestion(
    id: 'advanced_386',
    category: 'Chronic Disease Awareness',
    question:
        "Education on nutrition has minimal impact on disease prevention.",
    isFact: false,
    explanation:
        "Awareness improves adherence to healthy habits and reduces chronic disease risk.",
  ),
  QuizQuestion(
    id: 'advanced_387',
    category: 'Supplements vs Food',
    question:
        "Supplements can support health but cannot replace balanced diet for long-term chronic disease management.",
    isFact: true,
    explanation:
        "Whole foods provide fiber, cofactors, and phytonutrients not found in supplements.",
  ),
  QuizQuestion(
    id: 'advanced_388',
    category: 'Supplements vs Food',
    question:
        "Taking multiple supplements allows ignoring nutrition completely.",
    isFact: false,
    explanation:
        "Supplements cannot replicate the synergistic benefits of whole foods.",
  ),
  QuizQuestion(
    id: 'advanced_389',
    category: 'Weight & Energy',
    question:
        "Balancing carbs, protein, and healthy fats in meals prevents energy crashes.",
    isFact: true,
    explanation:
        "Balanced macronutrients support stable blood sugar and sustained energy.",
  ),
  QuizQuestion(
    id: 'advanced_390',
    category: 'Weight & Energy',
    question: "Carb or sugar-heavy meals alone provide long-lasting energy.",
    isFact: false,
    explanation:
        "High carb meals cause spikes and crashes; protein and fat are essential for steady energy.",
  ),
  QuizQuestion(
    id: 'advanced_391',
    category: 'Meal Planning',
    question:
        "Planning meals ahead helps ensure nutrient balance and supports chronic disease management.",
    isFact: true,
    explanation:
        "Structured meal planning helps include protein, fiber, vitamins, and minerals consistently.",
  ),
  QuizQuestion(
    id: 'advanced_392',
    category: 'Meal Planning',
    question:
        "Random eating without planning has no impact on nutrient intake or disease risk.",
    isFact: false,
    explanation:
        "Unplanned meals often lack nutrient balance, contributing to disease progression.",
  ),
  QuizQuestion(
    id: 'advanced_393',
    category: 'Lifestyle & Chronic Disease',
    question:
        "Combining diet, sleep, stress management, and exercise supports holistic healing.",
    isFact: true,
    explanation:
        "Multiple lifestyle factors synergistically improve metabolism, immunity, and energy.",
  ),
  QuizQuestion(
    id: 'advanced_394',
    category: 'Lifestyle & Chronic Disease',
    question:
        "Focusing only on one healthy habit is enough for chronic disease prevention.",
    isFact: false,
    explanation:
        "Multiple habits together are necessary to address root causes and sustain health.",
  ),
  QuizQuestion(
    id: 'advanced_395',
    category: 'Indian Spices',
    question:
        "Ginger, garlic, and turmeric in daily meals provide anti-inflammatory benefits.",
    isFact: true,
    explanation:
        "Bioactive compounds reduce inflammation and support immune and metabolic health.",
  ),
  QuizQuestion(
    id: 'advanced_396',
    category: 'Indian Spices',
    question:
        "Spices alone can fully prevent chronic diseases without other dietary changes.",
    isFact: false,
    explanation:
        "Spices support health but comprehensive diet and lifestyle are essential.",
  ),
  QuizQuestion(
    id: 'advanced_397',
    category: 'Mindful Eating',
    question:
        "Being mindful of hunger cues and chewing properly improves digestion and satiety.",
    isFact: true,
    explanation:
        "Mindful eating enhances nutrient absorption and prevents overeating.",
  ),
  QuizQuestion(
    id: 'advanced_398',
    category: 'Mindful Eating',
    question:
        "Mindless eating has no impact on satiety, digestion, or energy levels.",
    isFact: false,
    explanation:
        "Distraction during meals can lead to overeating and reduced nutrient absorption.",
  ),
  QuizQuestion(
    id: 'advanced_399',
    category: 'Energy & Hydration',
    question:
        "Adequate hydration supports metabolism, energy, and cognitive function.",
    isFact: true,
    explanation:
        "Water is essential for cellular reactions, nutrient transport, and toxin elimination.",
  ),
  QuizQuestion(
    id: 'advanced_400',
    category: 'Energy & Hydration',
    question:
        "Daily hydration has minimal effect on energy or mental alertness.",
    isFact: false,
    explanation:
        "Even mild dehydration can impair focus, energy, and overall performance.",
  ),
];
