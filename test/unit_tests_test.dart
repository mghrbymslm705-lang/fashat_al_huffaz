import 'package:fashat_al_huffaz/core/utils/arabic_text.dart';
import 'package:fashat_al_huffaz/core/utils/range_parser.dart';
import 'package:fashat_al_huffaz/data/models/activity_model.dart';
import 'package:fashat_al_huffaz/data/models/category_resolver.dart';
import 'package:fashat_al_huffaz/domain/entities/range_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeParser', () {
    test('يمرر رقمًا صحيحًا', () {
      expect(RangeParser.parse(10).label, '10');
    });

    test('يمرر نطاقًا نصيًا', () {
      expect(RangeParser.parse('6-12').label, '6 - 12');
      expect(RangeParser.parse('6 - 12').label, '6 - 12');
    });

    test('يمرر كائنًا صريحًا', () {
      expect(RangeParser.parse({'min': 4, 'max': 20}).label, '4 - 20');
    });

    test('يمرر نطاقًا مفتوحًا', () {
      expect(RangeParser.parse('12+').isOpenEnded, isTrue);
      expect(RangeParser.parse('12+').min, 12);
    });

    test('يعيد القيمة الافتراضية عند غياب البيانات', () {
      expect(RangeParser.parse(null).isUnspecified, isTrue);
      expect(RangeParser.parse('').isUnspecified, isTrue);
    });
  });

  group('RangeValue', () {
    test('التداخل بين النطاقات', () {
      expect(const RangeValue(6, 12).overlapWith(const RangeValue(9, 15)), 3);
      expect(const RangeValue(6, 8).overlapWith(const RangeValue(9, 12)), 0);
    });
    test('تحديد النطاق غير المحدد', () {
      expect(const RangeValue(0, 0).isUnspecified, isTrue);
      expect(const RangeValue(0, 5).isUnspecified, isFalse);
    });
  });

  group('ArabicText', () {
    test('يطبّع التشكيل والحروف', () {
      expect(ArabicText.normalize('مَدْرَسة'), 'مدرسه');
      expect(ArabicText.normalize('إسلام'), 'اسلام');
      expect(ArabicText.normalize('آيات'), 'ايات');
      expect(ArabicText.normalize('مرسى'), 'مرسي');
    });

    test('يقطّع إلى كلمات', () {
      expect(ArabicText.tokens('مراجعة سورة البقرة'), hasLength(3));
    });
  });

  group('CategoryResolver', () {
    test('يحوّل الأسماء العربية إلى معرّفات', () {
      expect(CategoryResolver.resolve('الألعاب الحركية'), 'kinetic');
      expect(CategoryResolver.resolve('المسابقات الثقافية'), 'culture');
      expect(CategoryResolver.resolve('قرآني'), 'quranic');
    });

    test('يحوّل الأسماء الإنجليزية', () {
      expect(CategoryResolver.resolve('quranic'), 'quranic');
      expect(CategoryResolver.resolve('KINETIC'), 'kinetic');
    });

    test('يحتفظ بالمعرّفات المخصصة', () {
      expect(CategoryResolver.resolve('memory'), 'memory');
    });
  });

  group('ActivityModel', () {
    test('يحلّل نشاطًا كاملًا', () {
      final activity = ActivityModel.fromJson({
        'id': 'a1',
        'title': 'سباق التسميع',
        'category': 'قرآني',
        'types': ['قرآني', 'جماعي'],
        'participants': {'min': 4, 'max': 30},
        'age': '6-12',
        'duration': 15,
        'movement': 'حركية',
        'location': 'داخل أو خارج',
        'tools': ['سبورة'],
        'steps': ['الخطوة 1', 'الخطوة 2'],
        'benefits': ['فائدة'],
        'tips': ['نصيحة'],
        'videoUrl': 'https://example.com/watch',
        'source': {'name': 'كتاب الأنشطة', 'page': '12'},
      }, sourceFile: 'test.json');

      expect(activity.id, 'a1');
      expect(activity.title, 'سباق التسميع');
      expect(activity.category, 'قرآني');
      expect(activity.types, contains('قرآني'));
      expect(activity.participants.label, '4 - 30');
      expect(activity.age.label, '6 - 12');
      expect(activity.duration.min, 15);
      expect(activity.movement.label, 'حركية');
      expect(activity.location.label, 'داخل أو خارج');
      expect(activity.hasVideo, isTrue);
      expect(activity.source.file, 'test.json');
      expect(activity.source.name, 'كتاب الأنشطة');
    });

    test('يولّد معرّفًا عند غيابه', () {
      final activity = ActivityModel.fromJson({
        'title': 'نشاط بلا معرّف',
      }, sourceFile: 'test.json');
      expect(activity.id, isNotEmpty);
      expect(activity.id.startsWith('auto_'), isTrue);
    });

    test('لا يفشل مع بيانات ناقصة', () {
      final activity = ActivityModel.fromJson({}, sourceFile: 'empty.json');
      expect(activity.title, isEmpty);
      expect(activity.tools, isEmpty);
      expect(activity.participants.isUnspecified, isTrue);
      expect(activity.source.file, 'empty.json');
    });
  });
}
