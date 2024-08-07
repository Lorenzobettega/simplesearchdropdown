import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/custom.dart';

final List<ValueItem<Custom>> customListitems = [
  ValueItem(label: 'Lorenzo', value: Custom('Lorenzo', 134)),
  ValueItem(label: 'Peter', value: Custom('Peter', 1)),
  ValueItem(label: 'Lucas', value: Custom('Lucas', 3)),
  ValueItem(label: 'Gian', value: Custom('Gian', 70)),
  ValueItem(label: 'Lança', value: Custom('Lança', 70)),
  ValueItem(label: 'Não', value: Custom('Não', 70)),
];

final List<ValueItem> listitems = [
  const ValueItem(
    label: 'Lorenzo',
  ),
  const ValueItem(label: 'Teste', value: 'Teste'),
  const ValueItem(label: '3', value: '3'),
  const ValueItem(label: 'one more', value: 'one more2'),
  const ValueItem(label: '4', value: '4'),
  const ValueItem(label: '5', value: '5'),
  const ValueItem(label: '6', value: '6'),
  const ValueItem(label: '7', value: '7'),
  const ValueItem(label: '8', value: '8'),
  const ValueItem(label: '9', value: '9'),
  const ValueItem(label: '10', value: '10'),
  const ValueItem(label: '11', value: '11'),
  const ValueItem(label: '12', value: '12'),
  const ValueItem(label: '13', value: '13'),
  const ValueItem(label: '14', value: '14'),
  const ValueItem(label: '15', value: '15'),
  const ValueItem(label: '16', value: '16'),
  const ValueItem(label: '17', value: '17'),
  const ValueItem(label: '18', value: '18'),
  const ValueItem(label: '19', value: '19'),
  const ValueItem(label: '20', value: '20'),
  const ValueItem(label: '21', value: '21'),
  const ValueItem(label: '22', value: '22'),
  const ValueItem(label: '23', value: '23'),
  const ValueItem(label: '24', value: '24'),
  const ValueItem(label: '25', value: '25'),
  const ValueItem(label: '26', value: '26'),
  const ValueItem(label: '27', value: '27'),
  const ValueItem(label: '28', value: '28'),
  const ValueItem(label: '29', value: '29'),
  const ValueItem(label: '30', value: '30'),
  const ValueItem(label: '31', value: '31'),
  const ValueItem(label: '32', value: '32'),
  const ValueItem(label: '33', value: '33'),
  const ValueItem(label: '34', value: '34'),
  const ValueItem(label: '35', value: '35'),
  const ValueItem(label: '36', value: '36'),
  const ValueItem(label: '37', value: '37'),
  const ValueItem(label: '38', value: '38'),
  const ValueItem(label: '39', value: '39'),
  const ValueItem(label: '40', value: '40'),
  const ValueItem(label: '41', value: '41'),
  const ValueItem(label: '42', value: '42'),
  const ValueItem(label: '43', value: '43'),
  const ValueItem(label: '44', value: '44'),
  const ValueItem(label: '45', value: '45'),
  const ValueItem(label: '46', value: '46'),
  const ValueItem(label: '47', value: '47'),
  const ValueItem(label: '48', value: '48'),
  const ValueItem(label: '49', value: '49'),
  const ValueItem(label: '50', value: '50'),
  const ValueItem(label: '51', value: '51'),
  const ValueItem(label: '52', value: '52'),
  const ValueItem(label: '53', value: '53'),
  const ValueItem(label: '54', value: '54'),
  const ValueItem(label: '55', value: '55'),
  const ValueItem(label: '56', value: '56'),
  const ValueItem(label: '57', value: '57'),
  const ValueItem(label: '58', value: '58'),
  const ValueItem(label: '59', value: '59'),
  const ValueItem(label: '60', value: '60'),
  const ValueItem(label: '61', value: '61'),
  const ValueItem(label: '62', value: '62'),
  const ValueItem(label: '63', value: '63'),
  const ValueItem(label: '64', value: '64'),
  const ValueItem(label: '65', value: '65'),
  const ValueItem(label: '66', value: '66'),
  const ValueItem(label: '67', value: '67'),
  const ValueItem(label: '68', value: '68'),
  const ValueItem(label: '69', value: '69'),
  const ValueItem(label: '70', value: '70'),
  const ValueItem(label: '71', value: '71'),
  const ValueItem(label: '72', value: '72'),
  const ValueItem(label: '73', value: '73'),
  const ValueItem(label: '74', value: '74'),
  const ValueItem(label: '75', value: '75'),
  const ValueItem(label: '76', value: '76'),
  const ValueItem(label: '77', value: '77'),
  const ValueItem(label: '78', value: '78'),
  const ValueItem(label: '79', value: '79'),
  const ValueItem(label: '80', value: '80'),
  const ValueItem(label: '81', value: '81'),
  const ValueItem(label: '82', value: '82'),
  const ValueItem(label: '83', value: '83'),
  const ValueItem(label: '84', value: '84'),
  const ValueItem(label: '85', value: '85'),
  const ValueItem(label: '86', value: '86'),
  const ValueItem(label: '87', value: '87'),
  const ValueItem(label: '88', value: '88'),
  const ValueItem(label: '89', value: '89'),
  const ValueItem(label: '90', value: '90'),
  const ValueItem(label: '91', value: '91'),
  const ValueItem(label: '92', value: '92'),
  const ValueItem(label: '93', value: '93'),
  const ValueItem(label: '94', value: '94'),
  const ValueItem(label: '95', value: '95'),
  const ValueItem(label: '96', value: '96'),
  const ValueItem(label: '97', value: '97'),
  const ValueItem(label: '98', value: '98'),
  const ValueItem(label: '99', value: '99'),
  const ValueItem(label: '100', value: '100'),
  const ValueItem(label: '101', value: '101'),
  const ValueItem(label: '102', value: '102'),
  const ValueItem(label: '103', value: '103'),
  const ValueItem(label: '104', value: '104'),
  const ValueItem(label: '105', value: '105'),
  const ValueItem(label: '106', value: '106'),
  const ValueItem(label: '107', value: '107'),
  const ValueItem(label: '108', value: '108'),
  const ValueItem(label: '109', value: '109'),
  const ValueItem(label: '110', value: '110'),
  const ValueItem(label: '111', value: '111'),
  const ValueItem(label: '112', value: '112'),
  const ValueItem(label: '113', value: '113'),
  const ValueItem(label: '114', value: '114'),
  const ValueItem(label: '115', value: '115'),
  const ValueItem(label: '116', value: '116'),
  const ValueItem(label: '117', value: '117'),
  const ValueItem(label: '118', value: '118'),
  const ValueItem(label: '119', value: '119'),
  const ValueItem(label: '120', value: '120'),
  const ValueItem(label: '121', value: '121'),
  const ValueItem(label: '122', value: '122'),
  const ValueItem(label: '123', value: '123'),
  const ValueItem(label: '124', value: '124'),
  const ValueItem(label: '125', value: '125'),
  const ValueItem(label: '126', value: '126'),
  const ValueItem(label: '127', value: '127'),
  const ValueItem(label: '128', value: '128'),
  const ValueItem(label: '129', value: '129'),
  const ValueItem(label: '130', value: '130'),
];
