String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String formatDate(String dateStr) {
  return dateStr;
}

String masteryIcon(String mastery) {
  switch (mastery) {
    case 'mastered':
      return '✅';
    case 'learning':
      return '📖';
    default:
      return '🆕';
  }
}
