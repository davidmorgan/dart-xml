library xml.test.mutate_test;

import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'assertions.dart';

void mutatingTest(String description, String before,
    void action(XmlElement node), String after) {
  test(description, () {
    final document = parse(before);
    action(document.rootElement);
    document.normalize();
    expect(after, document.toXmlString(), reason: 'should have been modified');
    assertTreeInvariants(document);
  });
}

void throwingTest(String description, String before,
    void action(XmlElement node), Matcher matcher) {
  test(description, () {
    final document = parse(before);
    expect(() => action(document.rootElement), matcher);
    expect(document.toXmlString(), before,
        reason: 'should not have been modified');
    assertTreeInvariants(document);
  });
}

void main() {
  group('update', () {
    mutatingTest(
      'element (attribute value)',
      '<element attr="value" />',
      (node) => node.attributes.first.value = 'update',
      '<element attr="update" />',
    );
    throwingTest(
      'element (null attribute value)',
      '<element attr="value" />',
      (node) => node.attributes.first.value = null,
      throwsArgumentError,
    );
    mutatingTest(
      'cdata (text)',
      '<element><![CDATA[text]]></element>',
      (node) => (node.children.first as XmlCDATA).text = 'update',
      '<element><![CDATA[update]]></element>',
    );
    throwingTest(
      'cdata (null text)',
      '<element><![CDATA[text]]></element>',
      (node) => (node.children.first as XmlCDATA).text = null,
      throwsArgumentError,
    );
    mutatingTest(
      'comment (text)',
      '<element><!--comment--></element>',
      (node) => (node.children.first as XmlComment).text = 'update',
      '<element><!--update--></element>',
    );
    throwingTest(
      'comment (null text)',
      '<element><!--comment--></element>',
      (node) => (node.children.first as XmlComment).text = null,
      throwsArgumentError,
    );
    test('processing (text)', () {
      final document = parse('<?xml processing?><element />');
      (document.firstChild as XmlProcessing).text = 'update';
      expect(document.toXmlString(), '<?xml update?><element />');
    });
    test('processing (null text)', () {
      final document = parse('<?xml processing ?><element />');
      expect(() => (document.firstChild as XmlProcessing).text = null,
          throwsArgumentError);
    });
    mutatingTest(
      'text (text)',
      '<element>Hello World</element>',
      (node) => (node.children.first as XmlText).text = 'Dart rocks',
      '<element>Dart rocks</element>',
    );
    throwingTest(
      'text (null text)',
      '<element>Hello World</element>',
      (node) => (node.children.first as XmlText).text = null,
      throwsArgumentError,
    );
  });
  group('add', () {
    mutatingTest(
      'element (attributes)',
      '<element />',
      (node) => node.attributes.add(XmlAttribute(XmlName('attr'), 'value')),
      '<element attr="value" />',
    );
    mutatingTest(
      'element (children)',
      '<element />',
      (node) => node.children.add(XmlText('Hello World')),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr="value"><element2 /></element1>',
      (node) =>
          node.children.first.attributes.add(node.attributes.first.copy()),
      '<element1 attr="value"><element2 attr="value" /></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2 /></element1>',
      (node) => node.children.add(node.children.first.copy()),
      '<element1><element2 /><element2 /></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1 />',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element2')),
          XmlComment('comment'),
        ]);
        node.children.add(fragment);
      },
      '<element1>Hello<element2 /><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1 />',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element2'))]);
        node.children..add(fragment)..add(fragment);
      },
      '<element1><element2 /><element2 /></element1>',
    );
    throwingTest(
      'element (null attributes)',
      '<element />',
      (node) => node.attributes.add(null),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (null children)',
      '<element />',
      (node) => node.children.add(null),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (attribute children)',
      '<element />',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.add(wrong);
      },
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2 /></element1>',
      (node) => node.children.add(node.firstChild),
      throwsA(isXmlParentError),
    );
  });
  group('addAll', () {
    mutatingTest(
      'element (attributes)',
      '<element />',
      (node) =>
          node.attributes.addAll([XmlAttribute(XmlName('attr'), 'value')]),
      '<element attr="value" />',
    );
    mutatingTest(
      'element (children)',
      '<element />',
      (node) => node.children.addAll([XmlText('Hello World')]),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr="value"><element2 /></element1>',
      (node) =>
          node.children.first.attributes.addAll([node.attributes.first.copy()]),
      '<element1 attr="value"><element2 attr="value" /></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2 /></element1>',
      (node) => node.children.addAll([node.children.first.copy()]),
      '<element1><element2 /><element2 /></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1 />',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element2')),
          XmlComment('comment'),
        ]);
        node.children.addAll([fragment]);
      },
      '<element1>Hello<element2 /><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1 />',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element2'))]);
        node.children.addAll([fragment, fragment]);
      },
      '<element1><element2 /><element2 /></element1>',
    );
    throwingTest(
      'element (null attributes)',
      '<element />',
      (node) => node.attributes.addAll([null]),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (null children)',
      '<element />',
      (node) => node.children.addAll([null]),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (attribute children)',
      '<element />',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.addAll([wrong]);
      },
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2 /></element1>',
      (node) => node.children.addAll([node.firstChild]),
      throwsA(isXmlParentError),
    );
  });
  group('insert', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" />',
      (node) =>
          node.attributes.insert(1, XmlAttribute(XmlName('attr2'), 'value2')),
      '<element attr1="value1" attr2="value2" />',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello</element>',
      (node) => node.children.insert(1, XmlText(' World')),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr1="value1"><element2 attr2="value2"/></element1>',
      (node) => node.children.first.attributes
          .insert(1, node.attributes.first.copy()),
      '<element1 attr1="value1"><element2 attr2="value2" attr1="value1" /></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2 /></element1>',
      (node) => node.children.insert(1, node.children.first.copy()),
      '<element1><element2 /><element2 /></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1><element2 /></element1>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element3')),
          XmlComment('comment'),
        ]);
        node.children.insert(1, fragment);
      },
      '<element1><element2 />Hello<element3 /><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1><element2 /></element1>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element3'))]);
        node.children..insert(0, fragment)..insert(2, fragment);
      },
      '<element1><element3 /><element2 /><element3 /></element1>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1" />',
      (node) =>
          node.attributes.insert(2, XmlAttribute(XmlName('attr2'), 'value2')),
      throwsRangeError,
    );
    throwingTest(
      'element (null attributes)',
      '<element />',
      (node) => node.attributes.insert(0, null),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children.insert(2, XmlText(' World')),
      throwsRangeError,
    );
    throwingTest(
      'element (null children)',
      '<element />',
      (node) => node.children.insert(0, null),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (attribute children)',
      '<element />',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.insert(0, wrong);
      },
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2 /></element1>',
      (node) => node.children.insert(0, node.firstChild),
      throwsA(isXmlParentError),
    );
  });
  group('insertAll', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" />',
      (node) => node.attributes
          .insertAll(1, [XmlAttribute(XmlName('attr2'), 'value2')]),
      '<element attr1="value1" attr2="value2" />',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello</element>',
      (node) => node.children.insertAll(1, [XmlText(' World')]),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr1="value1"><element2 attr2="value2"/></element1>',
      (node) => node.children.first.attributes
          .insertAll(1, [node.attributes.first.copy()]),
      '<element1 attr1="value1"><element2 attr2="value2" attr1="value1" /></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2 /></element1>',
      (node) => node.children.insertAll(1, [node.children.first.copy()]),
      '<element1><element2 /><element2 /></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1><element2 /></element1>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element3')),
          XmlComment('comment'),
        ]);
        node.children.insertAll(1, [fragment]);
      },
      '<element1><element2 />Hello<element3 /><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1><element2 /></element1>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element3'))]);
        node.children.insertAll(0, [fragment, fragment]);
      },
      '<element1><element3 /><element3 /><element2 /></element1>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1" />',
      (node) => node.attributes
          .insertAll(2, [XmlAttribute(XmlName('attr2'), 'value2')]),
      throwsRangeError,
    );
    throwingTest(
      'element (null attributes)',
      '<element />',
      (node) => node.attributes.insertAll(0, [null]),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children.insertAll(2, [XmlText(' World')]),
      throwsRangeError,
    );
    throwingTest(
      'element (null children)',
      '<element />',
      (node) => node.children.insertAll(0, [null]),
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (attribute children)',
      '<element />',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.insertAll(0, [wrong]);
      },
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2 /></element1>',
      (node) => node.children.insertAll(0, [node.firstChild]),
      throwsA(isXmlParentError),
    );
  });
  group('[]=', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" />',
      (node) => node.attributes[0] = XmlAttribute(XmlName('attr2'), 'value2'),
      '<element attr2="value2" />',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children[0] = XmlText('Dart rocks'),
      '<element>Dart rocks</element>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1" />',
      (node) => node.attributes[2] = XmlAttribute(XmlName('attr2'), 'value2'),
      throwsRangeError,
    );
    throwingTest(
      'element (null attributes)',
      '<element attr="value" />',
      (node) => node.attributes[0] = null,
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children[2] = XmlText(' World'),
      throwsRangeError,
    );
    throwingTest(
      'element (null children)',
      '<element />',
      (node) => node.children[0] = null,
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (attribute children)',
      '<element1><element2 /></element1>',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children[0] = wrong;
      },
      throwsA(isXmlNodeTypeError),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2 /></element1>',
      (node) => node.children[0] = node.firstChild,
      throwsA(isXmlParentError),
    );
  });
  group('remove', () {
    mutatingTest(
      'element (attributes)',
      '<element attr="value" />',
      (node) => node.attributes.remove(node.attributes.first),
      '<element />',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.remove(node.children.first),
      '<element />',
    );
    mutatingTest(
      'element (null attributes)',
      '<element attr="value" />',
      (node) => node.attributes.remove(null),
      '<element attr="value" />',
    );
    mutatingTest(
      'element (null children)',
      '<element>Hello World</element>',
      (node) => node.children.remove(null),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (attribute children)',
      '<element>Hello World</element>',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.remove(wrong);
      },
      '<element>Hello World</element>',
    );
  });
  group('removeAt', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeAt(1),
      '<element attr1="value1" />',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeAt(2),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.removeAt(0),
      '<element />',
    );
    throwingTest(
      'element (children range error',
      '<element>Hello World</element>',
      (node) => node.children.removeAt(2),
      throwsRangeError,
    );
  });
  group('removeWhere', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeWhere(
          (node) => node is XmlAttribute && node.name.local == 'attr2'),
      '<element attr1="value1" />',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.removeWhere(
          (node) => node is XmlElement && node.name.local == 'element3'),
      '<element1><element2 /></element1>',
    );
  });
  group('retainWhere', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.retainWhere(
          (node) => node is XmlAttribute && node.name.local == 'attr1'),
      '<element attr1="value1" />',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.retainWhere(
          (node) => node is XmlElement && node.name.local == 'element2'),
      '<element1><element2 /></element1>',
    );
  });
  group('clear', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.clear(),
      '<element />',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.clear(),
      '<element1 />',
    );
  });
  group('removeLast', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeLast(),
      '<element attr1="value1" />',
    );
    throwingTest(
      'element (attributes range error)',
      '<element />',
      (node) => node.attributes.removeLast(),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.removeLast(),
      '<element />',
    );
    throwingTest(
      'element (children range error',
      '<element />',
      (node) => node.children.removeLast(),
      throwsRangeError,
    );
  });
  group('removeRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeRange(0, 1),
      '<element attr2="value2" />',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.removeRange(0, 3),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.removeRange(1, 2),
      '<element1><element2 /></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.removeRange(0, 3),
      throwsRangeError,
    );
  });
  group('setRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes
          .setRange(0, 1, [XmlAttribute(XmlName('attr3'), 'value3')]),
      '<element attr3="value3" attr2="value2" />',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.setRange(0, 3, [null, null, null]),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.setRange(1, 2, [XmlElement(XmlName('element4'))]),
      '<element1><element2 /><element4 /></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.setRange(0, 3, [null, null, null]),
      throwsRangeError,
    );
  });
  group('replaceRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes
          .replaceRange(0, 1, [XmlAttribute(XmlName('attr3'), 'value3')]),
      '<element attr3="value3" attr2="value2" />',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2" />',
      (node) => node.attributes.replaceRange(0, 3, [null, null, null]),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2 /><element3 /></element1>',
      (node) =>
          node.children.replaceRange(1, 2, [XmlElement(XmlName('element4'))]),
      '<element1><element2 /><element4 /></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2 /><element3 /></element1>',
      (node) => node.children.replaceRange(0, 3, [null, null, null]),
      throwsRangeError,
    );
  });
  group('unsupported method', () {
    throwingTest(
      'fillRange',
      '<element />',
      (node) => node.children.fillRange(0, 1),
      throwsUnsupportedError,
    );
    throwingTest(
      'setAll',
      '<element />',
      (node) => node.children.setAll(0, []),
      throwsUnsupportedError,
    );
    throwingTest(
      'length',
      '<element />',
      (node) => node.children.length = 2,
      throwsUnsupportedError,
    );
  });
  group('normalizer', () {
    test('remove empty text', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText(''),
        XmlElement(XmlName('element1')),
        XmlText(''),
        XmlElement(XmlName('element2')),
        XmlText(''),
      ]);
      element.normalize();
      expect(element.children.length, 2);
      expect(
          element.toXmlString(), '<element><element1 /><element2 /></element>');
    });
    test('join adjacent text', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText('aaa'),
        XmlText('bbb'),
        XmlText('ccc'),
      ]);
      element.normalize();
      expect(element.children.length, 1);
      expect(element.toXmlString(), '<element>aaabbbccc</element>');
    });
    test('document fragment', () {
      final fragment = XmlDocumentFragment([
        XmlText(''),
        XmlText('aaa'),
        XmlText(''),
        XmlElement(XmlName('element1')),
        XmlText(''),
        XmlText('bbb'),
        XmlText(''),
        XmlText('ccc'),
        XmlText(''),
        XmlElement(XmlName('element2')),
        XmlText(''),
        XmlText('ddd'),
        XmlText(''),
      ]);
      fragment.normalize();
      final element = XmlElement(XmlName('element'));
      element.children.add(fragment);
      expect(element.children.length, 5);
      expect(element.toXmlString(),
          '<element>aaa<element1 />bbbccc<element2 />ddd</element>');
    });
  });
}