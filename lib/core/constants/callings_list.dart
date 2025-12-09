// MAPA DE ORGANIZACIONES Y LLAMAMIENTOS
const Map<String, List<String>> kLdsStructure = {
  'Obispado': [
    'Obispo',
    'Primer Consejero del Obispado',
    'Segundo Consejero del Obispado',
    'Secretario de Barrio',
    'Secretario Ejecutivo de Barrio',
    'Secretario Auxiliar',
  ],
  'Quórum de Élderes': [
    'Presidente del Quórum de Élderes',
    'Primer Consejero del Quórum de Élderes',
    'Segundo Consejero del Quórum de Élderes',
    'Secretario del Quórum de Élderes',
    'Secretario Auxiliar',
  ],
  'Sociedad de Socorro': [
    'Presidenta de la Sociedad de Socorro',
    'Primera Consejera de la Sociedad de Socorro',
    'Segunda Consejera de la Sociedad de Socorro',
    'Secretaria Auxiliar',
  ],
  'Sacerdocio Aarónico': [
    'Presidente del Quórum de Diáconos',
    'Primer Consejero del Quórum de Diáconos',
    'Segundo Consejero del Quórum de Diáconos',
    'Secretario del Quórum de Diáconos',
    'Asesor de Quórum de Diáconos',
    'Presidente del Quórum de Maestros',
    'Primer Consejero del Quórum de Maestros',
    'Segundo Consejero del Quórum de Maestros',
    'Secretario del Quórum de Maestros',
    'Asesor del Quórum de Maestros',
    'Primer Ayudante del Quórum de Presbíteros', // (El Obispo preside, el ayudante dirige)
    'Segundo Ayudante del Quórum de Presbíteros',
    'Secretario del Quórum de Presbíteros',
    'Asesor del Quórum de Presbíteros',
  ],
  'Mujeres Jóvenes': [
    'Presidenta de las Mujeres Jóvenes',
    'Primera Consejera de las Mujeres Jóvenes',
    'Segunda Consejera de las Mujeres Jóvenes',
    'Secretaria de las Mujeres Jóvenes',
    'Lider de Actividades de las Mujeres Jóvenes',
    'Presidenta de la Clase de 11-14',
    'Primera Consejera de la Clase de 11-14',
    'Segunda Consejera de la Clase de 11-14',
    'Secretaria de la Clase de 11-14',
    'Asesora de la Clase de 11-14',
    'Presidenta de la Clase de 15-17',
    'Primera Consejera de la Clase de 15-17',
    'Segunda Consejera de la Clase de 15-17',
    'Secretaria de la Clase de 15-17',
    'Asesora de la Clase de 15-17',
  ],
  'Primaria': [
    'Presidenta de la Primaria',
    'Primera Consejera de la Primaria',
    'Segunda Consejera de la Primaria',
    'Secretaria de la Primaria',
    'Líder de Música de la Primaria',
    'Líder de Actividades de la Primaria',
  ],
  'Escuela Dominical': [
    'Presidente de la Escuela Dominical',
    'Primer Consejero de la Escuela Dominical',
    'Segundo Consejero de la Escuela Dominical',
    'Secretario de la Escuela Dominical',
    'Maestro de la Escuela Dominical',
  ],
  'Templo e Historia Familiar': [
    'Líder de Templo e Historia Familiar',
    'Consultor de Templo e Historia Familiar',
  ],
  'Misiones del Barrio': [
    'Líder Misional de Barrio',
    'Misionero de Barrio',
  ],
  'Barrio': [
    'Miembro', // Rol genérico por si acaso
  ]
};