import 'package:flutter/material.dart';

/// Category for periodic table colour coding.
enum ElementCategory {
  alkaliMetal,
  alkalineEarthMetal,
  transitionMetal,
  postTransitionMetal,
  metalloid,
  nonmetal,
  halogen,
  nobleGas,
  lanthanide,
  actinide,
  unknown,
}

Color categoryColor(ElementCategory cat) {
  switch (cat) {
    case ElementCategory.alkaliMetal:
      return const Color(0xFFFF6B6B);
    case ElementCategory.alkalineEarthMetal:
      return const Color(0xFFFFAA5C);
    case ElementCategory.transitionMetal:
      return const Color(0xFFFFD43B);
    case ElementCategory.postTransitionMetal:
      return const Color(0xFF69DB7C);
    case ElementCategory.metalloid:
      return const Color(0xFF38D9A9);
    case ElementCategory.nonmetal:
      return const Color(0xFF00D2FF);
    case ElementCategory.halogen:
      return const Color(0xFF74C0FC);
    case ElementCategory.nobleGas:
      return const Color(0xFFB197FC);
    case ElementCategory.lanthanide:
      return const Color(0xFFE599F7);
    case ElementCategory.actinide:
      return const Color(0xFFF783AC);
    case ElementCategory.unknown:
      return const Color(0xFF868E96);
  }
}

class ChemElement {
  final int atomicNumber;
  final String symbol;
  final String name;
  final double mass;
  final ElementCategory category;
  final int row; // 1‑indexed period
  final int col; // 1‑indexed group (1‑18) or special for lanthanides/actinides

  const ChemElement({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.mass,
    required this.category,
    required this.row,
    required this.col,
  });

  Map<String, dynamic> toJson() => {
        'atomicNumber': atomicNumber,
        'symbol': symbol,
        'name': name,
        'mass': mass,
      };

  factory ChemElement.fromJson(Map<String, dynamic> json) {
    return allElements.firstWhere(
      (e) => e.atomicNumber == json['atomicNumber'],
    );
  }
}

/// All 118 elements in standard‑table positions.
const List<ChemElement> allElements = [
  // ── Period 1 ──
  ChemElement(atomicNumber: 1,  symbol: 'H',  name: 'Hydrogen',      mass: 1.008,    category: ElementCategory.nonmetal,           row: 1, col: 1),
  ChemElement(atomicNumber: 2,  symbol: 'He', name: 'Helium',        mass: 4.003,    category: ElementCategory.nobleGas,           row: 1, col: 18),
  // ── Period 2 ──
  ChemElement(atomicNumber: 3,  symbol: 'Li', name: 'Lithium',       mass: 6.941,    category: ElementCategory.alkaliMetal,        row: 2, col: 1),
  ChemElement(atomicNumber: 4,  symbol: 'Be', name: 'Beryllium',     mass: 9.012,    category: ElementCategory.alkalineEarthMetal, row: 2, col: 2),
  ChemElement(atomicNumber: 5,  symbol: 'B',  name: 'Boron',         mass: 10.81,    category: ElementCategory.metalloid,          row: 2, col: 13),
  ChemElement(atomicNumber: 6,  symbol: 'C',  name: 'Carbon',        mass: 12.011,   category: ElementCategory.nonmetal,           row: 2, col: 14),
  ChemElement(atomicNumber: 7,  symbol: 'N',  name: 'Nitrogen',      mass: 14.007,   category: ElementCategory.nonmetal,           row: 2, col: 15),
  ChemElement(atomicNumber: 8,  symbol: 'O',  name: 'Oxygen',        mass: 15.999,   category: ElementCategory.nonmetal,           row: 2, col: 16),
  ChemElement(atomicNumber: 9,  symbol: 'F',  name: 'Fluorine',      mass: 18.998,   category: ElementCategory.halogen,            row: 2, col: 17),
  ChemElement(atomicNumber: 10, symbol: 'Ne', name: 'Neon',          mass: 20.180,   category: ElementCategory.nobleGas,           row: 2, col: 18),
  // ── Period 3 ──
  ChemElement(atomicNumber: 11, symbol: 'Na', name: 'Sodium',        mass: 22.990,   category: ElementCategory.alkaliMetal,        row: 3, col: 1),
  ChemElement(atomicNumber: 12, symbol: 'Mg', name: 'Magnesium',     mass: 24.305,   category: ElementCategory.alkalineEarthMetal, row: 3, col: 2),
  ChemElement(atomicNumber: 13, symbol: 'Al', name: 'Aluminium',     mass: 26.982,   category: ElementCategory.postTransitionMetal,row: 3, col: 13),
  ChemElement(atomicNumber: 14, symbol: 'Si', name: 'Silicon',       mass: 28.086,   category: ElementCategory.metalloid,          row: 3, col: 14),
  ChemElement(atomicNumber: 15, symbol: 'P',  name: 'Phosphorus',    mass: 30.974,   category: ElementCategory.nonmetal,           row: 3, col: 15),
  ChemElement(atomicNumber: 16, symbol: 'S',  name: 'Sulfur',        mass: 32.065,   category: ElementCategory.nonmetal,           row: 3, col: 16),
  ChemElement(atomicNumber: 17, symbol: 'Cl', name: 'Chlorine',      mass: 35.453,   category: ElementCategory.halogen,            row: 3, col: 17),
  ChemElement(atomicNumber: 18, symbol: 'Ar', name: 'Argon',         mass: 39.948,   category: ElementCategory.nobleGas,           row: 3, col: 18),
  // ── Period 4 ──
  ChemElement(atomicNumber: 19, symbol: 'K',  name: 'Potassium',     mass: 39.098,   category: ElementCategory.alkaliMetal,        row: 4, col: 1),
  ChemElement(atomicNumber: 20, symbol: 'Ca', name: 'Calcium',       mass: 40.078,   category: ElementCategory.alkalineEarthMetal, row: 4, col: 2),
  ChemElement(atomicNumber: 21, symbol: 'Sc', name: 'Scandium',      mass: 44.956,   category: ElementCategory.transitionMetal,    row: 4, col: 3),
  ChemElement(atomicNumber: 22, symbol: 'Ti', name: 'Titanium',      mass: 47.867,   category: ElementCategory.transitionMetal,    row: 4, col: 4),
  ChemElement(atomicNumber: 23, symbol: 'V',  name: 'Vanadium',      mass: 50.942,   category: ElementCategory.transitionMetal,    row: 4, col: 5),
  ChemElement(atomicNumber: 24, symbol: 'Cr', name: 'Chromium',      mass: 51.996,   category: ElementCategory.transitionMetal,    row: 4, col: 6),
  ChemElement(atomicNumber: 25, symbol: 'Mn', name: 'Manganese',     mass: 54.938,   category: ElementCategory.transitionMetal,    row: 4, col: 7),
  ChemElement(atomicNumber: 26, symbol: 'Fe', name: 'Iron',          mass: 55.845,   category: ElementCategory.transitionMetal,    row: 4, col: 8),
  ChemElement(atomicNumber: 27, symbol: 'Co', name: 'Cobalt',        mass: 58.933,   category: ElementCategory.transitionMetal,    row: 4, col: 9),
  ChemElement(atomicNumber: 28, symbol: 'Ni', name: 'Nickel',        mass: 58.693,   category: ElementCategory.transitionMetal,    row: 4, col: 10),
  ChemElement(atomicNumber: 29, symbol: 'Cu', name: 'Copper',        mass: 63.546,   category: ElementCategory.transitionMetal,    row: 4, col: 11),
  ChemElement(atomicNumber: 30, symbol: 'Zn', name: 'Zinc',          mass: 65.380,   category: ElementCategory.transitionMetal,    row: 4, col: 12),
  ChemElement(atomicNumber: 31, symbol: 'Ga', name: 'Gallium',       mass: 69.723,   category: ElementCategory.postTransitionMetal,row: 4, col: 13),
  ChemElement(atomicNumber: 32, symbol: 'Ge', name: 'Germanium',     mass: 72.630,   category: ElementCategory.metalloid,          row: 4, col: 14),
  ChemElement(atomicNumber: 33, symbol: 'As', name: 'Arsenic',       mass: 74.922,   category: ElementCategory.metalloid,          row: 4, col: 15),
  ChemElement(atomicNumber: 34, symbol: 'Se', name: 'Selenium',      mass: 78.971,   category: ElementCategory.nonmetal,           row: 4, col: 16),
  ChemElement(atomicNumber: 35, symbol: 'Br', name: 'Bromine',       mass: 79.904,   category: ElementCategory.halogen,            row: 4, col: 17),
  ChemElement(atomicNumber: 36, symbol: 'Kr', name: 'Krypton',       mass: 83.798,   category: ElementCategory.nobleGas,           row: 4, col: 18),
  // ── Period 5 ──
  ChemElement(atomicNumber: 37, symbol: 'Rb', name: 'Rubidium',      mass: 85.468,   category: ElementCategory.alkaliMetal,        row: 5, col: 1),
  ChemElement(atomicNumber: 38, symbol: 'Sr', name: 'Strontium',     mass: 87.620,   category: ElementCategory.alkalineEarthMetal, row: 5, col: 2),
  ChemElement(atomicNumber: 39, symbol: 'Y',  name: 'Yttrium',       mass: 88.906,   category: ElementCategory.transitionMetal,    row: 5, col: 3),
  ChemElement(atomicNumber: 40, symbol: 'Zr', name: 'Zirconium',     mass: 91.224,   category: ElementCategory.transitionMetal,    row: 5, col: 4),
  ChemElement(atomicNumber: 41, symbol: 'Nb', name: 'Niobium',       mass: 92.906,   category: ElementCategory.transitionMetal,    row: 5, col: 5),
  ChemElement(atomicNumber: 42, symbol: 'Mo', name: 'Molybdenum',    mass: 95.950,   category: ElementCategory.transitionMetal,    row: 5, col: 6),
  ChemElement(atomicNumber: 43, symbol: 'Tc', name: 'Technetium',    mass: 98.000,   category: ElementCategory.transitionMetal,    row: 5, col: 7),
  ChemElement(atomicNumber: 44, symbol: 'Ru', name: 'Ruthenium',     mass: 101.07,   category: ElementCategory.transitionMetal,    row: 5, col: 8),
  ChemElement(atomicNumber: 45, symbol: 'Rh', name: 'Rhodium',       mass: 102.91,   category: ElementCategory.transitionMetal,    row: 5, col: 9),
  ChemElement(atomicNumber: 46, symbol: 'Pd', name: 'Palladium',     mass: 106.42,   category: ElementCategory.transitionMetal,    row: 5, col: 10),
  ChemElement(atomicNumber: 47, symbol: 'Ag', name: 'Silver',        mass: 107.87,   category: ElementCategory.transitionMetal,    row: 5, col: 11),
  ChemElement(atomicNumber: 48, symbol: 'Cd', name: 'Cadmium',       mass: 112.41,   category: ElementCategory.transitionMetal,    row: 5, col: 12),
  ChemElement(atomicNumber: 49, symbol: 'In', name: 'Indium',        mass: 114.82,   category: ElementCategory.postTransitionMetal,row: 5, col: 13),
  ChemElement(atomicNumber: 50, symbol: 'Sn', name: 'Tin',           mass: 118.71,   category: ElementCategory.postTransitionMetal,row: 5, col: 14),
  ChemElement(atomicNumber: 51, symbol: 'Sb', name: 'Antimony',      mass: 121.76,   category: ElementCategory.metalloid,          row: 5, col: 15),
  ChemElement(atomicNumber: 52, symbol: 'Te', name: 'Tellurium',     mass: 127.60,   category: ElementCategory.metalloid,          row: 5, col: 16),
  ChemElement(atomicNumber: 53, symbol: 'I',  name: 'Iodine',        mass: 126.90,   category: ElementCategory.halogen,            row: 5, col: 17),
  ChemElement(atomicNumber: 54, symbol: 'Xe', name: 'Xenon',         mass: 131.29,   category: ElementCategory.nobleGas,           row: 5, col: 18),
  // ── Period 6 ──
  ChemElement(atomicNumber: 55, symbol: 'Cs', name: 'Caesium',       mass: 132.91,   category: ElementCategory.alkaliMetal,        row: 6, col: 1),
  ChemElement(atomicNumber: 56, symbol: 'Ba', name: 'Barium',        mass: 137.33,   category: ElementCategory.alkalineEarthMetal, row: 6, col: 2),
  // Lanthanides (row 8 for display)
  ChemElement(atomicNumber: 57, symbol: 'La', name: 'Lanthanum',     mass: 138.91,   category: ElementCategory.lanthanide,         row: 8, col: 3),
  ChemElement(atomicNumber: 58, symbol: 'Ce', name: 'Cerium',        mass: 140.12,   category: ElementCategory.lanthanide,         row: 8, col: 4),
  ChemElement(atomicNumber: 59, symbol: 'Pr', name: 'Praseodymium',  mass: 140.91,   category: ElementCategory.lanthanide,         row: 8, col: 5),
  ChemElement(atomicNumber: 60, symbol: 'Nd', name: 'Neodymium',     mass: 144.24,   category: ElementCategory.lanthanide,         row: 8, col: 6),
  ChemElement(atomicNumber: 61, symbol: 'Pm', name: 'Promethium',    mass: 145.00,   category: ElementCategory.lanthanide,         row: 8, col: 7),
  ChemElement(atomicNumber: 62, symbol: 'Sm', name: 'Samarium',      mass: 150.36,   category: ElementCategory.lanthanide,         row: 8, col: 8),
  ChemElement(atomicNumber: 63, symbol: 'Eu', name: 'Europium',      mass: 151.96,   category: ElementCategory.lanthanide,         row: 8, col: 9),
  ChemElement(atomicNumber: 64, symbol: 'Gd', name: 'Gadolinium',    mass: 157.25,   category: ElementCategory.lanthanide,         row: 8, col: 10),
  ChemElement(atomicNumber: 65, symbol: 'Tb', name: 'Terbium',       mass: 158.93,   category: ElementCategory.lanthanide,         row: 8, col: 11),
  ChemElement(atomicNumber: 66, symbol: 'Dy', name: 'Dysprosium',    mass: 162.50,   category: ElementCategory.lanthanide,         row: 8, col: 12),
  ChemElement(atomicNumber: 67, symbol: 'Ho', name: 'Holmium',       mass: 164.93,   category: ElementCategory.lanthanide,         row: 8, col: 13),
  ChemElement(atomicNumber: 68, symbol: 'Er', name: 'Erbium',        mass: 167.26,   category: ElementCategory.lanthanide,         row: 8, col: 14),
  ChemElement(atomicNumber: 69, symbol: 'Tm', name: 'Thulium',       mass: 168.93,   category: ElementCategory.lanthanide,         row: 8, col: 15),
  ChemElement(atomicNumber: 70, symbol: 'Yb', name: 'Ytterbium',     mass: 173.05,   category: ElementCategory.lanthanide,         row: 8, col: 16),
  ChemElement(atomicNumber: 71, symbol: 'Lu', name: 'Lutetium',      mass: 174.97,   category: ElementCategory.lanthanide,         row: 8, col: 17),
  // Back to period 6
  ChemElement(atomicNumber: 72, symbol: 'Hf', name: 'Hafnium',       mass: 178.49,   category: ElementCategory.transitionMetal,    row: 6, col: 4),
  ChemElement(atomicNumber: 73, symbol: 'Ta', name: 'Tantalum',      mass: 180.95,   category: ElementCategory.transitionMetal,    row: 6, col: 5),
  ChemElement(atomicNumber: 74, symbol: 'W',  name: 'Tungsten',      mass: 183.84,   category: ElementCategory.transitionMetal,    row: 6, col: 6),
  ChemElement(atomicNumber: 75, symbol: 'Re', name: 'Rhenium',       mass: 186.21,   category: ElementCategory.transitionMetal,    row: 6, col: 7),
  ChemElement(atomicNumber: 76, symbol: 'Os', name: 'Osmium',        mass: 190.23,   category: ElementCategory.transitionMetal,    row: 6, col: 8),
  ChemElement(atomicNumber: 77, symbol: 'Ir', name: 'Iridium',       mass: 192.22,   category: ElementCategory.transitionMetal,    row: 6, col: 9),
  ChemElement(atomicNumber: 78, symbol: 'Pt', name: 'Platinum',      mass: 195.08,   category: ElementCategory.transitionMetal,    row: 6, col: 10),
  ChemElement(atomicNumber: 79, symbol: 'Au', name: 'Gold',          mass: 196.97,   category: ElementCategory.transitionMetal,    row: 6, col: 11),
  ChemElement(atomicNumber: 80, symbol: 'Hg', name: 'Mercury',       mass: 200.59,   category: ElementCategory.transitionMetal,    row: 6, col: 12),
  ChemElement(atomicNumber: 81, symbol: 'Tl', name: 'Thallium',      mass: 204.38,   category: ElementCategory.postTransitionMetal,row: 6, col: 13),
  ChemElement(atomicNumber: 82, symbol: 'Pb', name: 'Lead',          mass: 207.20,   category: ElementCategory.postTransitionMetal,row: 6, col: 14),
  ChemElement(atomicNumber: 83, symbol: 'Bi', name: 'Bismuth',       mass: 208.98,   category: ElementCategory.postTransitionMetal,row: 6, col: 15),
  ChemElement(atomicNumber: 84, symbol: 'Po', name: 'Polonium',      mass: 209.00,   category: ElementCategory.postTransitionMetal,row: 6, col: 16),
  ChemElement(atomicNumber: 85, symbol: 'At', name: 'Astatine',      mass: 210.00,   category: ElementCategory.halogen,            row: 6, col: 17),
  ChemElement(atomicNumber: 86, symbol: 'Rn', name: 'Radon',         mass: 222.00,   category: ElementCategory.nobleGas,           row: 6, col: 18),
  // ── Period 7 ──
  ChemElement(atomicNumber: 87, symbol: 'Fr', name: 'Francium',      mass: 223.00,   category: ElementCategory.alkaliMetal,        row: 7, col: 1),
  ChemElement(atomicNumber: 88, symbol: 'Ra', name: 'Radium',        mass: 226.00,   category: ElementCategory.alkalineEarthMetal, row: 7, col: 2),
  // Actinides (row 9 for display)
  ChemElement(atomicNumber: 89, symbol: 'Ac', name: 'Actinium',      mass: 227.00,   category: ElementCategory.actinide,           row: 9, col: 3),
  ChemElement(atomicNumber: 90, symbol: 'Th', name: 'Thorium',       mass: 232.04,   category: ElementCategory.actinide,           row: 9, col: 4),
  ChemElement(atomicNumber: 91, symbol: 'Pa', name: 'Protactinium',  mass: 231.04,   category: ElementCategory.actinide,           row: 9, col: 5),
  ChemElement(atomicNumber: 92, symbol: 'U',  name: 'Uranium',       mass: 238.03,   category: ElementCategory.actinide,           row: 9, col: 6),
  ChemElement(atomicNumber: 93, symbol: 'Np', name: 'Neptunium',     mass: 237.00,   category: ElementCategory.actinide,           row: 9, col: 7),
  ChemElement(atomicNumber: 94, symbol: 'Pu', name: 'Plutonium',     mass: 244.00,   category: ElementCategory.actinide,           row: 9, col: 8),
  ChemElement(atomicNumber: 95, symbol: 'Am', name: 'Americium',     mass: 243.00,   category: ElementCategory.actinide,           row: 9, col: 9),
  ChemElement(atomicNumber: 96, symbol: 'Cm', name: 'Curium',        mass: 247.00,   category: ElementCategory.actinide,           row: 9, col: 10),
  ChemElement(atomicNumber: 97, symbol: 'Bk', name: 'Berkelium',     mass: 247.00,   category: ElementCategory.actinide,           row: 9, col: 11),
  ChemElement(atomicNumber: 98, symbol: 'Cf', name: 'Californium',   mass: 251.00,   category: ElementCategory.actinide,           row: 9, col: 12),
  ChemElement(atomicNumber: 99, symbol: 'Es', name: 'Einsteinium',   mass: 252.00,   category: ElementCategory.actinide,           row: 9, col: 13),
  ChemElement(atomicNumber: 100, symbol: 'Fm', name: 'Fermium',      mass: 257.00,   category: ElementCategory.actinide,           row: 9, col: 14),
  ChemElement(atomicNumber: 101, symbol: 'Md', name: 'Mendelevium',  mass: 258.00,   category: ElementCategory.actinide,           row: 9, col: 15),
  ChemElement(atomicNumber: 102, symbol: 'No', name: 'Nobelium',     mass: 259.00,   category: ElementCategory.actinide,           row: 9, col: 16),
  ChemElement(atomicNumber: 103, symbol: 'Lr', name: 'Lawrencium',   mass: 266.00,   category: ElementCategory.actinide,           row: 9, col: 17),
  // Back to period 7
  ChemElement(atomicNumber: 104, symbol: 'Rf', name: 'Rutherfordium', mass: 267.00,  category: ElementCategory.transitionMetal,    row: 7, col: 4),
  ChemElement(atomicNumber: 105, symbol: 'Db', name: 'Dubnium',       mass: 268.00,  category: ElementCategory.transitionMetal,    row: 7, col: 5),
  ChemElement(atomicNumber: 106, symbol: 'Sg', name: 'Seaborgium',    mass: 269.00,  category: ElementCategory.transitionMetal,    row: 7, col: 6),
  ChemElement(atomicNumber: 107, symbol: 'Bh', name: 'Bohrium',       mass: 270.00,  category: ElementCategory.transitionMetal,    row: 7, col: 7),
  ChemElement(atomicNumber: 108, symbol: 'Hs', name: 'Hassium',       mass: 277.00,  category: ElementCategory.transitionMetal,    row: 7, col: 8),
  ChemElement(atomicNumber: 109, symbol: 'Mt', name: 'Meitnerium',    mass: 278.00,  category: ElementCategory.unknown,            row: 7, col: 9),
  ChemElement(atomicNumber: 110, symbol: 'Ds', name: 'Darmstadtium',  mass: 281.00,  category: ElementCategory.unknown,            row: 7, col: 10),
  ChemElement(atomicNumber: 111, symbol: 'Rg', name: 'Roentgenium',   mass: 282.00,  category: ElementCategory.unknown,            row: 7, col: 11),
  ChemElement(atomicNumber: 112, symbol: 'Cn', name: 'Copernicium',   mass: 285.00,  category: ElementCategory.transitionMetal,    row: 7, col: 12),
  ChemElement(atomicNumber: 113, symbol: 'Nh', name: 'Nihonium',      mass: 286.00,  category: ElementCategory.unknown,            row: 7, col: 13),
  ChemElement(atomicNumber: 114, symbol: 'Fl', name: 'Flerovium',     mass: 289.00,  category: ElementCategory.unknown,            row: 7, col: 14),
  ChemElement(atomicNumber: 115, symbol: 'Mc', name: 'Moscovium',     mass: 290.00,  category: ElementCategory.unknown,            row: 7, col: 15),
  ChemElement(atomicNumber: 116, symbol: 'Lv', name: 'Livermorium',   mass: 293.00,  category: ElementCategory.unknown,            row: 7, col: 16),
  ChemElement(atomicNumber: 117, symbol: 'Ts', name: 'Tennessine',    mass: 294.00,  category: ElementCategory.unknown,            row: 7, col: 17),
  ChemElement(atomicNumber: 118, symbol: 'Og', name: 'Oganesson',     mass: 294.00,  category: ElementCategory.unknown,            row: 7, col: 18),
];
