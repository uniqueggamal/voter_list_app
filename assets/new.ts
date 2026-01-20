import * as fuzz from 'fuzzball';

// Nepali surname to Devanagari mapping with category information
// Main categories:
// 1 = खस-आर्य (Khas-Arya) → Bahun, Chhetri, Thakuri, Sanyasi
// 2 = आदिवासी जनजाति (Adivasi Janajati)
// 3 = मधेशी (Madhesi)
// 4 = दलित (Dalit)
// 5 = नेवार (Newar)
// 6 = मुस्लिम (Muslim)
// 7 = अन्य (Other)

export interface SurnameInfo {
  devanagari: string;
  mainId: number;
  mainName: string;
  subId: number;
  subName: string;
}

export const mainCategories: Record<number, string> = {
  1: "खस-आर्य",
  2: "आदिवासी जनजाति",
  3: "मधेशी",
  4: "दलित",
  5: "नेवार",
  6: "मुस्लिम",
  7: "अन्य",
};

export const subCategories: Record<number, string> = {
  101: "ब्राह्मण (Bahun)",
  102: "क्षेत्री (Chhetri)",
  103: "ठकुरी (Thakuri)",
  104: "सन्यासी (Sanyasi)",
  201: "मगर (Magar)",
  202: "तामाङ (Tamang)",
  203: "राई (Rai)",
  204: "लिम्बू (Limbu)",
  205: "गुरुङ (Gurung)",
  206: "शेर्पा (Sherpa)",
  207: "थारू (Tharu)",
  208: "भोटे (Bhote)",
  209: "लेप्चा (Lepcha)",
  210: "सुनुवार (Sunuwar)",
  211: "थामी (Thami)",
  212: "चेपाङ (Chepang)",
  213: "जिरेल (Jirel)",
  214: "हायु (Hayu)",
  215: "किरात (Kirat)",
  216: "दनुवार (Danuwar)",
  217: "बोटे (Bote)",
  218: "माझी (Majhi)",
  219: "कुमाल (Kumal)",
  220: "थकाली (Thakali)",
  301: "यादव (Yadav)",
  302: "तेली (Teli)",
  303: "कुर्मी (Kurmi)",
  304: "कोइरी (Koiri)",
  305: "मुसहर (Musahar)",
  306: "धनुक (Dhanuk)",
  307: "मल्लाह (Mallah)",
  308: "कायस्थ (Kayastha)",
  309: "मधेशी ब्राह्मण (Madhesi Brahmin)",
  310: "राजपूत (Rajput)",
  311: "बनिया (Baniya)",
  312: "कहार (Kahar)",
  401: "कामी (Kami)",
  402: "दमाई (Damai)",
  403: "सार्की (Sarki)",
  404: "गाइने (Gaine)",
  405: "बादी (Badi)",
  406: "पहाडी दलित (Pahadi Dalit)",
  407: "मधेशी दलित (Madhesi Dalit)",
  501: "नेवार-श्रेष्ठ (Newar-Shrestha)",
  502: "नेवार-जोशी (Newar-Joshi)",
  503: "नेवार-महर्जन (Newar-Maharjan)",
  504: "नेवार-शाक्य (Newar-Shakya)",
  505: "नेवार-बज्राचार्य (Newar-Bajracharya)",
  506: "नेवार-प्रधान (Newar-Pradhan)",
  507: "नेवार-मानन्धर (Newar-Manandhar)",
  508: "नेवार-तुलाधर (Newar-Tuladhar)",
  509: "नेवार-कर्माचार्य (Newar-Karmacharya)",
  510: "नेवार अन्य (Newar Other)",
  601: "मुस्लिम (Muslim)",
  701: "अन्य (Other)",
};

// Known surname mappings - comprehensive Nepali surname database
export const knownSurnames: Record<string, SurnameInfo> = {
  // Bahun surnames
  "acharya": { devanagari: "आचार्य", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "adhikari": { devanagari: "अधिकारी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "aryal": { devanagari: "अर्याल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "awasthi": { devanagari: "अवस्थी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "baral": { devanagari: "बराल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "bashyal": { devanagari: "बस्याल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "bhandari": { devanagari: "भण्डारी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "bhattarai": { devanagari: "भट्टराई", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "bhusal": { devanagari: "भुसाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "chapagain": { devanagari: "चापागाईं", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "dahal": { devanagari: "दाहाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "devkota": { devanagari: "देवकोटा", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "dhakal": { devanagari: "ढकाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "dhital": { devanagari: "ढिटाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "dhungana": { devanagari: "ढुंगाना", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "dhungel": { devanagari: "ढुंगेल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "gautam": { devanagari: "गौतम", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "ghimire": { devanagari: "घिमिरे", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "giri": { devanagari: "गिरी", mainId: 1, mainName: "खस-आर्य", subId: 104, subName: "सन्यासी (Sanyasi)" },
  "gyawali": { devanagari: "ज्ञवाली", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "joshi": { devanagari: "जोशी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "kafle": { devanagari: "काफ्ले", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "khanal": { devanagari: "खनाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "koirala": { devanagari: "कोइराला", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "lamichhane": { devanagari: "लामिछाने", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "lamsal": { devanagari: "लम्साल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "luitel": { devanagari: "लुइटेल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "mainali": { devanagari: "मैनाली", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "mishra": { devanagari: "मिश्र", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "neupane": { devanagari: "न्यौपाने", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "ojha": { devanagari: "ओझा", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "padhya": { devanagari: "पाध्य", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pandey": { devanagari: "पाण्डे", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pandit": { devanagari: "पण्डित", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pant": { devanagari: "पन्त", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "parajuli": { devanagari: "पराजुली", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pathak": { devanagari: "पाठक", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "paudel": { devanagari: "पौडेल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "phuyal": { devanagari: "फुयाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pokharel": { devanagari: "पोखरेल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "poudyal": { devanagari: "पौड्याल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "prasai": { devanagari: "प्रसाईं", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "pudasaini": { devanagari: "पुडासैनी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "puri": { devanagari: "पुरी", mainId: 1, mainName: "खस-आर्य", subId: 104, subName: "सन्यासी (Sanyasi)" },
  "pyakurel": { devanagari: "प्याकुरेल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "regmi": { devanagari: "रेग्मी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "rijal": { devanagari: "रिजाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "rimal": { devanagari: "रिमाल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "sapkota": { devanagari: "सापकोटा", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "sharma": { devanagari: "शर्मा", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "sigdel": { devanagari: "सिग्देल", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "subedi": { devanagari: "सुवेदी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "timalsina": { devanagari: "तिमिल्सिना", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "tiwari": { devanagari: "तिवारी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "tripathi": { devanagari: "त्रिपाठी", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "upadhyay": { devanagari: "उपाध्याय", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  "upreti": { devanagari: "उप्रेती", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  
  // Chhetri surnames
  "basnet": { devanagari: "बस्नेत", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "bista": { devanagari: "बिष्ट", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "bogati": { devanagari: "बोगटी", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "bohara": { devanagari: "बोहरा", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "budha": { devanagari: "बुढा", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "budhathoki": { devanagari: "बुढाथोकी", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "chand": { devanagari: "चन्द", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "chhetri": { devanagari: "क्षेत्री", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "dangi": { devanagari: "डाँगी", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "gharti": { devanagari: "घर्ती", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "karki": { devanagari: "कार्की", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "kc": { devanagari: "के.सी.", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "khadka": { devanagari: "खड्का", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "khatri": { devanagari: "खत्री", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "kunwar": { devanagari: "कुँवर", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "oli": { devanagari: "ओली", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "pun": { devanagari: "पुन", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "rana": { devanagari: "राणा", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "raut": { devanagari: "राउत", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "rawat": { devanagari: "रावत", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "rawal": { devanagari: "रावल", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "rokaya": { devanagari: "रोकाया", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "saud": { devanagari: "साउद", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "shah": { devanagari: "शाह", mainId: 1, mainName: "खस-आर्य", subId: 103, subName: "ठकुरी (Thakuri)" },
  "shahi": { devanagari: "शाही", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "thapa": { devanagari: "थापा", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "gc": { devanagari: "जी.सी.", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "bc": { devanagari: "बी.सी.", mainId: 1, mainName: "खस-आर्य", subId: 102, subName: "क्षेत्री (Chhetri)" },
  "khatiwada": { devanagari: "खतिवडा", mainId: 1, mainName: "खस-आर्य", subId: 101, subName: "ब्राह्मण (Bahun)" },
  
  // Thakuri
  "thakuri": { devanagari: "ठकुरी", mainId: 1, mainName: "खस-आर्य", subId: 103, subName: "ठकुरी (Thakuri)" },
  
  // Magar
  "magar": { devanagari: "मगर", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "ale": { devanagari: "आले", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "rana magar": { devanagari: "राना मगर", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "thapa magar": { devanagari: "थापा मगर", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "bura": { devanagari: "बुरा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "roka": { devanagari: "रोका", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  "pulami": { devanagari: "पुलामी", mainId: 2, mainName: "आदिवासी जनजाति", subId: 201, subName: "मगर (Magar)" },
  
  // Tamang
  "tamang": { devanagari: "तामाङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "lama": { devanagari: "लामा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "bomjan": { devanagari: "बोम्जन", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "ghalan": { devanagari: "घलान", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "moktan": { devanagari: "मोक्तान", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "syangtan": { devanagari: "स्याङ्तान", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "waiba": { devanagari: "वाइबा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "thing": { devanagari: "थिङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "yonjan": { devanagari: "योञ्जन", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "bal": { devanagari: "बल", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "dong": { devanagari: "डोङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  "ghising": { devanagari: "घिसिङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 202, subName: "तामाङ (Tamang)" },
  
  // Rai
  "rai": { devanagari: "राई", mainId: 2, mainName: "आदिवासी जनजाति", subId: 203, subName: "राई (Rai)" },
  "bantawa": { devanagari: "बान्तवा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 203, subName: "राई (Rai)" },
  "chamling": { devanagari: "चाम्लिङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 203, subName: "राई (Rai)" },
  "kulung": { devanagari: "कुलुङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 203, subName: "राई (Rai)" },
  "thulung": { devanagari: "थुलुङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 203, subName: "राई (Rai)" },
  
  // Limbu
  "limbu": { devanagari: "लिम्बू", mainId: 2, mainName: "आदिवासी जनजाति", subId: 204, subName: "लिम्बू (Limbu)" },
  "chemjong": { devanagari: "चेम्जोङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 204, subName: "लिम्बू (Limbu)" },
  "subba": { devanagari: "सुब्बा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 204, subName: "लिम्बू (Limbu)" },
  "lingden": { devanagari: "लिङ्देन", mainId: 2, mainName: "आदिवासी जनजाति", subId: 204, subName: "लिम्बू (Limbu)" },
  "nembang": { devanagari: "नेम्बाङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 204, subName: "लिम्बू (Limbu)" },
  
  // Gurung
  "gurung": { devanagari: "गुरुङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 205, subName: "गुरुङ (Gurung)" },
  "ghale": { devanagari: "घले", mainId: 2, mainName: "आदिवासी जनजाति", subId: 205, subName: "गुरुङ (Gurung)" },
  
  // Sherpa
  "sherpa": { devanagari: "शेर्पा", mainId: 2, mainName: "आदिवासी जनजाति", subId: 206, subName: "शेर्पा (Sherpa)" },
  
  // Tharu
  "tharu": { devanagari: "थारू", mainId: 2, mainName: "आदिवासी जनजाति", subId: 207, subName: "थारू (Tharu)" },
  "chaudhary": { devanagari: "चौधरी", mainId: 2, mainName: "आदिवासी जनजाति", subId: 207, subName: "थारू (Tharu)" },
  
  // Newar surnames
  "shrestha": { devanagari: "श्रेष्ठ", mainId: 5, mainName: "नेवार", subId: 501, subName: "नेवार-श्रेष्ठ (Newar-Shrestha)" },
  "shakya": { devanagari: "शाक्य", mainId: 5, mainName: "नेवार", subId: 504, subName: "नेवार-शाक्य (Newar-Shakya)" },
  "bajracharya": { devanagari: "बज्राचार्य", mainId: 5, mainName: "नेवार", subId: 505, subName: "नेवार-बज्राचार्य (Newar-Bajracharya)" },
  "pradhan": { devanagari: "प्रधान", mainId: 5, mainName: "नेवार", subId: 506, subName: "नेवार-प्रधान (Newar-Pradhan)" },
  "manandhar": { devanagari: "मानन्धर", mainId: 5, mainName: "नेवार", subId: 507, subName: "नेवार-मानन्धर (Newar-Manandhar)" },
  "tuladhar": { devanagari: "तुलाधर", mainId: 5, mainName: "नेवार", subId: 508, subName: "नेवार-तुलाधर (Newar-Tuladhar)" },
  "karmacharya": { devanagari: "कर्माचार्य", mainId: 5, mainName: "नेवार", subId: 509, subName: "नेवार-कर्माचार्य (Newar-Karmacharya)" },
  "maharjan": { devanagari: "महर्जन", mainId: 5, mainName: "नेवार", subId: 503, subName: "नेवार-महर्जन (Newar-Maharjan)" },
  "sthapit": { devanagari: "स्थापित", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "dangol": { devanagari: "डंगोल", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "maharana": { devanagari: "महाराणा", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "kansakar": { devanagari: "कंसाकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "malla": { devanagari: "मल्ल", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "tamrakar": { devanagari: "ताम्राकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "chitrakar": { devanagari: "चित्रकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "ranjitkar": { devanagari: "रञ्जितकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "amatya": { devanagari: "अमात्य", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "rajbhandari": { devanagari: "राजभण्डारी", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "maskey": { devanagari: "मास्के", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "koju": { devanagari: "कोजु", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "lohani": { devanagari: "लोहनी", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "duwal": { devanagari: "दुवाल", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "napit": { devanagari: "नापित", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "shilpakar": { devanagari: "शिल्पकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "suwal": { devanagari: "सुवाल", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "awale": { devanagari: "आवाले", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "sayami": { devanagari: "सायमी", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  "byanjankar": { devanagari: "ब्यञ्जनकार", mainId: 5, mainName: "नेवार", subId: 510, subName: "नेवार अन्य (Newar Other)" },
  
  // Dalit surnames
  "kami": { devanagari: "कामी", mainId: 4, mainName: "दलित", subId: 401, subName: "कामी (Kami)" },
  "bishwakarma": { devanagari: "विश्वकर्मा", mainId: 4, mainName: "दलित", subId: 401, subName: "कामी (Kami)" },
  "sunar": { devanagari: "सुनार", mainId: 4, mainName: "दलित", subId: 401, subName: "कामी (Kami)" },
  "lohar": { devanagari: "लोहार", mainId: 4, mainName: "दलित", subId: 401, subName: "कामी (Kami)" },
  "damai": { devanagari: "दमाई", mainId: 4, mainName: "दलित", subId: 402, subName: "दमाई (Damai)" },
  "pariyar": { devanagari: "परियार", mainId: 4, mainName: "दलित", subId: 402, subName: "दमाई (Damai)" },
  "darji": { devanagari: "दर्जी", mainId: 4, mainName: "दलित", subId: 402, subName: "दमाई (Damai)" },
  "sarki": { devanagari: "सार्की", mainId: 4, mainName: "दलित", subId: 403, subName: "सार्की (Sarki)" },
  "mijar": { devanagari: "मिजार", mainId: 4, mainName: "दलित", subId: 403, subName: "सार्की (Sarki)" },
  "gaine": { devanagari: "गाइने", mainId: 4, mainName: "दलित", subId: 404, subName: "गाइने (Gaine)" },
  "nepali": { devanagari: "नेपाली", mainId: 4, mainName: "दलित", subId: 406, subName: "पहाडी दलित (Pahadi Dalit)" },
  "bk": { devanagari: "बि.क.", mainId: 4, mainName: "दलित", subId: 401, subName: "कामी (Kami)" },
  
  // Madhesi surnames
  "yadav": { devanagari: "यादव", mainId: 3, mainName: "मधेशी", subId: 301, subName: "यादव (Yadav)" },
  "sah": { devanagari: "साह", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "gupta": { devanagari: "गुप्ता", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "jha": { devanagari: "झा", mainId: 3, mainName: "मधेशी", subId: 309, subName: "मधेशी ब्राह्मण (Madhesi Brahmin)" },
  "jain": { devanagari: "जैन", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "mahato": { devanagari: "महतो", mainId: 3, mainName: "मधेशी", subId: 303, subName: "कुर्मी (Kurmi)" },
  "mandal": { devanagari: "मण्डल", mainId: 3, mainName: "मधेशी", subId: 307, subName: "मल्लाह (Mallah)" },
  "paswan": { devanagari: "पासवान", mainId: 3, mainName: "मधेशी", subId: 407, subName: "मधेशी दलित (Madhesi Dalit)" },
  "das": { devanagari: "दास", mainId: 3, mainName: "मधेशी", subId: 407, subName: "मधेशी दलित (Madhesi Dalit)" },
  "thakur": { devanagari: "ठाकुर", mainId: 3, mainName: "मधेशी", subId: 310, subName: "राजपूत (Rajput)" },
  "singh": { devanagari: "सिंह", mainId: 3, mainName: "मधेशी", subId: 310, subName: "राजपूत (Rajput)" },
  "mehta": { devanagari: "मेहता", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "agrawal": { devanagari: "अग्रवाल", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "baniya": { devanagari: "बनिया", mainId: 3, mainName: "मधेशी", subId: 311, subName: "बनिया (Baniya)" },
  "kayastha": { devanagari: "कायस्थ", mainId: 3, mainName: "मधेशी", subId: 308, subName: "कायस्थ (Kayastha)" },
  "teli": { devanagari: "तेली", mainId: 3, mainName: "मधेशी", subId: 302, subName: "तेली (Teli)" },
  "kurmi": { devanagari: "कुर्मी", mainId: 3, mainName: "मधेशी", subId: 303, subName: "कुर्मी (Kurmi)" },
  "koiri": { devanagari: "कोइरी", mainId: 3, mainName: "मधेशी", subId: 304, subName: "कोइरी (Koiri)" },
  "dhanuk": { devanagari: "धानुक", mainId: 3, mainName: "मधेशी", subId: 306, subName: "धनुक (Dhanuk)" },
  "chamar": { devanagari: "चमार", mainId: 3, mainName: "मधेशी", subId: 407, subName: "मधेशी दलित (Madhesi Dalit)" },
  "musahar": { devanagari: "मुसहर", mainId: 3, mainName: "मधेशी", subId: 305, subName: "मुसहर (Musahar)" },
  "harijan": { devanagari: "हरिजन", mainId: 3, mainName: "मधेशी", subId: 407, subName: "मधेशी दलित (Madhesi Dalit)" },
  "majhi": { devanagari: "माझी", mainId: 2, mainName: "आदिवासी जनजाति", subId: 218, subName: "माझी (Majhi)" },
  "kumal": { devanagari: "कुमाल", mainId: 2, mainName: "आदिवासी जनजाति", subId: 219, subName: "कुमाल (Kumal)" },
  "danuwar": { devanagari: "दनुवार", mainId: 2, mainName: "आदिवासी जनजाति", subId: 216, subName: "दनुवार (Danuwar)" },
  "bote": { devanagari: "बोटे", mainId: 2, mainName: "आदिवासी जनजाति", subId: 217, subName: "बोटे (Bote)" },
  "chepang": { devanagari: "चेपाङ", mainId: 2, mainName: "आदिवासी जनजाति", subId: 212, subName: "चेपाङ (Chepang)" },
  "thakali": { devanagari: "थकाली", mainId: 2, mainName: "आदिवासी जनजाति", subId: 220, subName: "थकाली (Thakali)" },
  "jirel": { devanagari: "जिरेल", mainId: 2, mainName: "आदिवासी जनजाति", subId: 213, subName: "जिरेल (Jirel)" },
  "sunuwar": { devanagari: "सुनुवार", mainId: 2, mainName: "आदिवासी जनजाति", subId: 210, subName: "सुनुवार (Sunuwar)" },
  "hayu": { devanagari: "हायु", mainId: 2, mainName: "आदिवासी जनजाति", subId: 214, subName: "हायु (Hayu)" },
  
  // Muslim surnames
  "khan": { devanagari: "खान", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "ansari": { devanagari: "अन्सारी", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "sheikh": { devanagari: "शेख", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "siddiqui": { devanagari: "सिद्दिकी", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "miya": { devanagari: "मियाँ", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "muslim": { devanagari: "मुस्लिम", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "mansur": { devanagari: "मन्सुर", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "ahmad": { devanagari: "अहमद", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
  "ali": { devanagari: "अली", mainId: 6, mainName: "मुस्लिम", subId: 601, subName: "मुस्लिम (Muslim)" },
};

export interface SurnameCluster {
  clusterId: number;
  canonicalEnglish: string;
  devanagari: string;
  mainId: number;
  mainNameNp: string;
  subId: number;
  subNameNp: string;
  allVariations: string[];
  confidence: 'high' | 'medium' | 'low';
  notes: string;
}
// Normalize surname for comparison
function normalize(s: string): string {
  return s.toLowerCase()
    .replace(/[^a-z]/g, '')
    .replace(/aa/g, 'a')
    .replace(/ee/g, 'i')
    .replace(/oo/g, 'u')
    .replace(/th/g, 't')
    .replace(/bh/g, 'b')
    .replace(/dh/g, 'd')
    .replace(/gh/g, 'g')
    .replace(/kh/g, 'k')
    .replace(/ph/g, 'p')
    .replace(/chh/g, 'ch')
    .replace(/shh/g, 'sh');
}
// Calculate similarity between two surnames
function similarity(a: string, b: string): number {
  const ratioScore = fuzz.ratio(a, b);
  const partialScore = fuzz.partial_ratio(a, b);
  const tokenSort = fuzz.token_sort_ratio(a, b);
  // Weight the scores
  return Math.max(ratioScore, partialScore * 0.95, tokenSort * 0.9);
}
// Find the best canonical form (most common/cleanest spelling)
function findCanonical(variations: string[]): string {
  // Score each variation
  const scores = variations.map(v => {
    let score = 0;
    const lower = v.toLowerCase();

    // Prefer versions without double letters unless they're meaningful
    if (!/(.)\1{2,}/.test(lower)) score += 2;

    // Prefer versions with standard length
    if (lower.length >= 4 && lower.length <= 10) score += 2;

    // Prefer versions that match known surnames exactly
    if (knownSurnames[lower]) score += 10;

    // Prefer versions without unusual characters
    if (/^[a-z]+$/i.test(v)) score += 1;

    // Prefer longer versions (more complete spelling)
    score += lower.length * 0.1;

    return { name: v, score };
  });
  // Sort by score descending
  scores.sort((a, b) => b.score - a.score);
  // Return the best match, properly capitalized
  const best = scores[0]?.name || variations[0];
  return best.charAt(0).toUpperCase() + best.slice(1).toLowerCase();
}
// Guess Devanagari based on transliteration rules
function guessDevanagari(english: string): string {
  const lower = english.toLowerCase();
  // Common transliteration mappings
  const map: [RegExp, string][] = [
    [/shrestha/gi, 'श्रेष्ठ'],
    [/regmi/gi, 'रेग्मी'],
    [/thapa/gi, 'थापा'],
    [/tamang/gi, 'तामाङ'],
    [/gurung/gi, 'गुरुङ'],
    [/magar/gi, 'मगर'],
    [/rai/gi, 'राई'],
    [/limbu/gi, 'लिम्बू'],
    [/sherpa/gi, 'शेर्पा'],
    [/lama/gi, 'लामा'],
    [/adhikari/gi, 'अधिकारी'],
    [/sharma/gi, 'शर्मा'],
    [/paudel/gi, 'पौडेल'],
    [/pokharel/gi, 'पोखरेल'],
    [/ghimire/gi, 'घिमिरे'],
    [/bhattarai/gi, 'भट्टराई'],
    [/bhandari/gi, 'भण्डारी'],
    [/kc/gi, 'के.सी.'],
    [/gc/gi, 'जी.सी.'],
    [/bc/gi, 'बी.सी.'],
    [/bk/gi, 'बि.क.'],
    [/chhetri/gi, 'क्षेत्री'],
    [/chetri/gi, 'क्षेत्री'],
    [/kshetri/gi, 'क्षेत्री'],
    [/khatri/gi, 'खत्री'],
    [/basnet/gi, 'बस्नेत'],
    [/bista/gi, 'बिष्ट'],
    [/karki/gi, 'कार्की'],
    [/khadka/gi, 'खड्का'],
  ];
  for (const [pattern, replacement] of map) {
    if (pattern.test(lower)) {
      return replacement;
    }
  }
  // Basic transliteration for unknown surnames
  let result = lower
    .replace(/shh/g, 'श्')
    .replace(/chh/g, 'छ')
    .replace(/th/g, 'थ')
    .replace(/dh/g, 'ध')
    .replace(/bh/g, 'भ')
    .replace(/gh/g, 'घ')
    .replace(/kh/g, 'ख')
    .replace(/ph/g, 'फ')
    .replace(/sh/g, 'श')
    .replace(/ng/g, 'ङ')
    .replace(/aa/g, 'आ')
    .replace(/ee/g, 'ई')
    .replace(/oo/g, 'ऊ')
    .replace(/ai/g, 'ाइ')
    .replace(/au/g, 'ाउ')
    .replace(/a/g, 'ा')
    .replace(/i/g, 'ि')
    .replace(/u/g, 'ु')
    .replace(/e/g, 'े')
    .replace(/o/g, 'ो')
    .replace(/k/g, 'क')
    .replace(/g/g, 'ग')
    .replace(/c/g, 'च')
    .replace(/j/g, 'ज')
    .replace(/t/g, 'त')
    .replace(/d/g, 'द')
    .replace(/n/g, 'न')
    .replace(/p/g, 'प')
    .replace(/b/g, 'ब')
    .replace(/m/g, 'म')
    .replace(/y/g, 'य')
    .replace(/r/g, 'र')
    .replace(/l/g, 'ल')
    .replace(/v/g, 'व')
    .replace(/w/g, 'व')
    .replace(/s/g, 'स')
    .replace(/h/g, 'ह');

  return result || english;
}
export function clusterSurnames(surnames: string[], threshold: number = 85): SurnameCluster[] {
  const clusters: Map<number, string[]> = new Map();
  const assigned: Set<string> = new Set();
  let clusterId = 1;
  // Sort surnames for consistent processing
  const sortedSurnames = [...surnames]
    .filter(s => s && s.length > 1)
    .map(s => s.toUpperCase())
    .filter((v, i, a) => a.indexOf(v) === i) // unique
    .sort();
  for (const surname of sortedSurnames) {
    if (assigned.has(surname)) continue;

    const normalizedCurrent = normalize(surname);
    const currentCluster: string[] = [surname];
    assigned.add(surname);

    // Find all similar surnames
    for (const other of sortedSurnames) {
      if (assigned.has(other)) continue;

      const normalizedOther = normalize(other);
      const sim = similarity(normalizedCurrent, normalizedOther);

      if (sim >= threshold) {
        currentCluster.push(other);
        assigned.add(other);
      }
    }

    clusters.set(clusterId, currentCluster);
    clusterId++;
  }
  // Convert clusters to output format
  const result: SurnameCluster[] = [];
  clusters.forEach((variations, id) => {
    const canonical = findCanonical(variations);
    const info = findSurnameInfo(canonical);

    let devanagari = '';
    let mainId = 7;
    let mainNameNp = 'अन्य';
    let subId = 701;
    let subNameNp = 'अन्य (Other)';
    let confidence: 'high' | 'medium' | 'low' = 'low';
    let notes = '';

    if (info) {
      devanagari = info.devanagari;
      mainId = info.mainId;
      mainNameNp = info.mainName;
      subId = info.subId;
      subNameNp = info.subName;
      confidence = 'high';
      notes = 'Matched from database';
    } else {
      // Try to guess based on patterns
      devanagari = guessDevanagari(canonical);
      confidence = 'low';
      notes = 'Auto-generated, needs verification';

      // Try to infer category from patterns
      const lower = canonical.toLowerCase();

      if (/acharya|aryal|bhattarai|dahal|dhakal|ghimire|koirala|lamichhane|neupane|pandey|paudel|pokharel|regmi|rijal|sharma|subedi|timalsina|tripathi|upadhyay/i.test(lower)) {
        mainId = 1;
        mainNameNp = 'खस-आर्य';
        subId = 101;
        subNameNp = 'ब्राह्मण (Bahun)';
        confidence = 'medium';
      } else if (/basnet|bista|bohara|budha|chhetri|chetri|dangi|gharti|karki|kc|khadka|khatri|kunwar|rana|rawat|rokaya|shah|shahi|thapa/i.test(lower)) {
        mainId = 1;
        mainNameNp = 'खस-आर्य';
        subId = 102;
        subNameNp = 'क्षेत्री (Chhetri)';
        confidence = 'medium';
      } else if (/magar|ale|pun|rana\s*magar|thapa\s*magar/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 201;
        subNameNp = 'मगर (Magar)';
        confidence = 'medium';
      } else if (/tamang|lama|bomjan|ghalan|moktan|thing|waiba|yonjan/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 202;
        subNameNp = 'तामाङ (Tamang)';
        confidence = 'medium';
      } else if (/rai|bantawa|chamling|kulung|thulung/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 203;
        subNameNp = 'राई (Rai)';
        confidence = 'medium';
      } else if (/limbu|chemjong|subba|nembang|lingden/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 204;
        subNameNp = 'लिम्बू (Limbu)';
        confidence = 'medium';
      } else if (/gurung|ghale|tamu/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 205;
        subNameNp = 'गुरुङ (Gurung)';
        confidence = 'medium';
      } else if (/sherpa/i.test(lower)) {
        mainId = 2;
        mainNameNp = 'आदिवासी जनजाति';
        subId = 206;
        subNameNp = 'शेर्पा (Sherpa)';
        confidence = 'medium';
      } else if (/shrestha|shakya|bajracharya|pradhan|manandhar|tuladhar|maharjan|sthapit|dangol|kansakar|chitrakar|tamrakar|amatya|rajbhandari|maskey/i.test(lower)) {
        mainId = 5;
        mainNameNp = 'नेवार';
        subId = 510;
        subNameNp = 'नेवार अन्य (Newar Other)';
        confidence = 'medium';
      } else if (/kami|bishwakarma|sunar|lohar|bk/i.test(lower)) {
        mainId = 4;
        mainNameNp = 'दलित';
        subId = 401;
        subNameNp = 'कामी (Kami)';
        confidence = 'medium';
      } else if (/damai|pariyar|darji/i.test(lower)) {
        mainId = 4;
        mainNameNp = 'दलित';
        subId = 402;
        subNameNp = 'दमाई (Damai)';
        confidence = 'medium';
      } else if (/sarki|mijar/i.test(lower)) {
        mainId = 4;
        mainNameNp = 'दलित';
        subId = 403;
        subNameNp = 'सार्की (Sarki)';
        confidence = 'medium';
      } else if (/yadav|mahato|mandal|jha|sah|gupta|thakur|singh|chamar|paswan|das/i.test(lower)) {
        mainId = 3;
        mainNameNp = 'मधेशी';
        subId = 301;
        subNameNp = 'यादव (Yadav)';
        confidence = 'medium';
      } else if (/khan|ansari|sheikh|siddiqui|miya|muslim|ahmad|ali/i.test(lower)) {
        mainId = 6;
        mainNameNp = 'मुस्लिम';
        subId = 601;
        subNameNp = 'मुस्लिम (Muslim)';
        confidence = 'medium';
      }
    }

    result.push({
      clusterId: id,
      canonicalEnglish: canonical,
      devanagari,
      mainId,
      mainNameNp,
      subId,
      subNameNp,
      allVariations: variations,
      confidence,
      notes,
    });
  });
  // Sort by cluster ID
  result.sort((a, b) => a.clusterId - b.clusterId);
  return result;
}
// Export to CSV format
export function exportToCSV(clusters: SurnameCluster[]): string {
  const headers = [
    'cluster_id',
    'canonical_english',
    'devanagari',
    'main_id',
    'main_name_np',
    'sub_id',
    'sub_name_np',
    'all_variations',
    'confidence',
    'notes'
  ];
  const rows = clusters.map(c => [
    c.clusterId,
    c.canonicalEnglish,
    c.devanagari,
    c.mainId,
    c.mainNameNp,
    c.subId,
    c.subNameNp,
    `"${c.allVariations.join(', ')}"`,
    c.confidence,
    c.notes
  ].join(','));
  return [headers.join(','), ...rows].join('\n');
}

// Function to find best matching surname info
export function findSurnameInfo(surname: string): SurnameInfo | null {
  const normalized = surname.toLowerCase().trim();
  
  // Direct match
  if (knownSurnames[normalized]) {
    return knownSurnames[normalized];
  }
  
  // Try without common suffixes/variations
  const variations = [
    normalized.replace(/ee$/, 'i'),
    normalized.replace(/y$/, 'i'),
    normalized.replace(/aa/g, 'a'),
    normalized.replace(/ee/g, 'i'),
    normalized.replace(/oo/g, 'u'),
  ];
  
  for (const variant of variations) {
    if (knownSurnames[variant]) {
      return knownSurnames[variant];
    }
  }
  
  return null;
}
